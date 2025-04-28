DECLARE @start_date DATE;
DECLARE @end_date DATE;

SET @start_date = '2023-08-01';
SET @end_date = DATEADD(MONTH, 12, @START_DATE);

DROP TABLE IF EXISTS #c_comp_ar_tbl;
DROP TABLE IF EXISTS #start_tbl;

	SELECT Active_Archive,
		Payer_organization,
		product_class,
		Acct_Type,
		Pt_No,
		Unit_No,
		Unit_Date,
		Admit_Date,
		Dsch_Date,
		[start_date] = DATEADD(DAY, - 1, EOMONTH_Timestamp),
		[start_fc] = FC,
		[start_ar_balance] = ISNULL(Balance, 0),
		[start_tot_chgs] = ISNULL(Tot_Chgs, 0),
		[start_tot_pay] = ISNULL(Tot_Pay_Amt, 0),
		[start_sys_allowance_amt] = ISNULL(SysAlw_Amt, 0)
	INTO #start_tbl
	FROM PARA.dbo.Pt_Accounting_Reporting_ALT_Backup
	WHERE EOMonth_Timestamp = @start_date
		AND FC IN ('P', 'I')
		AND Active_Archive = 'ACTIVE';

/*
------------------------------------------------------------

Get the subsequent payments and allowances -- keep at the prior month end so t
that if we run this in the middle of the month we get the correct values

------------------------------------------------------------
*/
DROP TABLE IF EXISTS #c_temp_subseq_pay_allow;

	SELECT pmts.PT_NO,
		b.Unit_Date,
		[post_date] = pmts.[PA-DTL-POST-DATE],
		PMTS.FC,
		PMTS.Transaction_Type,
		[pt_ins_pay] = CASE 
			WHEN PMTS.DTL_TYPE_IND = '1'
				AND (
					PMTS.GL_NO IN ('102', '103')
					OR PMTS.SVC_CD = '102756'
					)
				THEN 'Patient'
			WHEN PMTS.DTL_Type_Ind = '1'
				AND NOT (
					PMTS.GL_NO IN ('102', '103')
					OR PMTS.SVC_CD = '102756'
					)
				THEN 'Insurance'
			ELSE ''
			END,
		[pay_type] = CASE 
			WHEN PMTS.SVC_CD IN ('201426', '201376', '201392', '201434', '201400', '201442', '201475', '210286', '231266', '201368', '201483', '201459', '201384', '201418', '201467', '201491')
				THEN 'Charity'
			WHEN PMTS.FC LIKE '%[1-9]%'
				THEN 'Bad Debt ' + PMTS.Transaction_Type
			ELSE PMTS.Transaction_Type
			END,
		[tot_pmts] = pmts.[PA-DTL-CHG-AMT]
	INTO #c_temp_subseq_pay_allow
	FROM sms.dbo.Payments_Adjustments_For_Reporting AS pmts
	INNER JOIN #start_tbl AS b ON pmts.pt_no = b.Pt_No
        AND ISNULL(B.UNIT_DATE, '') = ISNULL(PMTS.UNIT_DATE, '')
		-- ADD FC IS IN I OR P
		--AND PMTS.FC IN ('I','P')
		-- ADD INS PLAN CD IS PT PAY
		AND PMTS.INS_PLAN = '00'
	WHERE pmts.[PA-DTL-POST-DATE] >= @start_date
		AND pmts.[PA-DTL-POST-DATE] < @end_date
		AND pmts.DTL_Type_Ind IN ('1', '3');

-- Make runout payments and allowances rollup
DROP TABLE IF EXISTS #c_temp_subseq_pay_allow_rollup;
	SELECT rr.Pt_No,
		rr.Unit_Date,
		rr.FC,
		[post_month_yr] = EOMONTH(rr.post_date),
		rr.Transaction_Type,
		rr.pt_ins_pay,
		rr.pay_type,
		sum(rr.tot_pmts) AS [tot_pmts]
	INTO #c_temp_subseq_pay_allow_rollup
	FROM #c_temp_subseq_pay_allow AS rr
	GROUP BY rr.PT_NO,
		rr.Unit_Date,
		rr.fc,
		EOMONTH(rr.post_date),
		rr.Transaction_Type,
		rr.pt_ins_pay,
		rr.pay_type;

DROP TABLE IF EXISTS #end_tbl;
SELECT a.Pt_No,
	[unit_date] = cast(a.Unit_Date AS DATE),
	A.Acct_Type,
	A.start_fc,
	b.FC,
	a.start_ar_balance,
	a.Active_Archive,
	a.Payer_organization,
	a.product_class,
	[snapshot_start_date] = cast(a.[start_date] AS DATE),
	b.post_month_yr,
	b.Transaction_Type,
	b.pt_ins_pay,
	b.pay_type,
	[full_transaction_type] = CONCAT(
		b.pt_ins_pay,
		' ',
		b.pay_type
		),
	[tot_pay_adj_amt] = SUM(ISNULL(b.tot_pmts, 0))
INTO #end_tbl
FROM #start_tbl AS a
LEFT JOIN #c_temp_subseq_pay_allow_rollup AS b ON a.Pt_No = b.PT_NO
	AND isnull(a.unit_date, '') = isnull(b.unit_date, '')
GROUP BY A.pt_no,
	cast(A.unit_date as date),
	A.Acct_Type,
	A.start_fc,
	b.FC,
	a.start_ar_balance,
	a.Active_Archive,
	a.Payer_organization,
	a.product_class,
	cast(a.[start_date] AS DATE),
	b.post_month_yr,
	b.Transaction_Type,
	b.pt_ins_pay,
	b.pay_type,
	CONCAT (
		b.pt_ins_pay,
		' ',
		b.pay_type
		);

WITH CTE AS (
	SELECT *,
		[rec_no] = ROW_NUMBER() OVER(
			PARTITION BY PT_NO, ISNULL(CAST(UNIT_DATE AS DATE), '')
			ORDER BY PT_NO, ISNULL(CAST(UNIT_DATE AS DATE), ''), post_month_yr
		),
		[distinct_rec_ind] = CASE
			WHEN ROW_NUMBER() OVER(
				PARTITION BY PT_NO, ISNULL(CAST(UNIT_DATE AS DATE), '') 
				ORDER BY PT_NO, ISNULL(CAST(UNIT_DATE AS DATE), ''), POST_MONTH_YR
			) = 1
				THEN 1
			ELSE 0
			END
	FROM #end_tbl
)

SELECT pt_no,
	[unit_date] = ISNULL(CAST(UNIT_DATE AS DATE), ''),
	acct_type,
	start_fc,
	fc,
	start_ar_balance,
	active_archive,
	payer_organization,
	product_class,
	snapshot_start_date,
	post_month_yr,
	transaction_type,
	pt_ins_pay,
	pay_type,
	full_transaction_type,
	tot_pay_adj_amt,
	distinct_rec_ind,
	[running_total] = SUM(tot_pay_adj_amt) OVER(
		PARTITION BY PT_NO, ISNULL(CAST(UNIT_DATE AS DATE), '')
		ORDER BY PT_NO, ISNULL(CAST(UNIT_DATE AS DATE), ''), REC_NO
	)
FROM CTE
ORDER BY pt_no, isnull(cast(unit_date as date), ''), post_month_yr;