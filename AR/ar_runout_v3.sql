DECLARE @start_date DATE;
DECLARE @end_date DATE;

SET @start_date = '2022-09-01';
SET @end_date = '2022-10-01';

DROP TABLE IF EXISTS #c_comp_ar_tbl;
DROP TABLE IF EXISTS #start_tbl;

SELECT Active_Archive,
	Hosp_Svc,
	Payer_organization,
	product_class,
	Pt_No,
	Unit_No,
	Unit_Date,
	Admit_Date,
	Dsch_Date,
	[start_date] = DATEADD(DAY, -1, EOMONTH_Timestamp),
	[start_fc] = FC,
	[start_ar_balance] = ISNULL(Balance, 0),
	[start_tot_chgs] = ISNULL(Tot_Chgs, 0),
	[start_tot_pay] = ISNULL(Tot_Pay_Amt, 0),
	[start_sys_allowance_amt] = ISNULL(SysAlw_Amt, 0)
INTO #start_tbl
FROM PARA.dbo.Pt_Accounting_Reporting_ALT_Backup
WHERE EOMonth_Timestamp = @start_date
AND FC NOT LIKE '%[0-9]%';

SELECT snap.Active_Archive,
	snap.Hosp_Svc,
	snap.Payer_organization,
	snap.product_class,
	snap.Pt_No,
	snap.Unit_no,
	snap.Unit_Date,
	snap.Admit_Date,
	snap.Dsch_Date,
	snap.start_date,
	snap.start_fc,
	[end_fc] = comp.fc,
	snap.start_ar_balance,
	[end_ar_balance] = comp.Balance,
	snap.start_tot_chgs,
	[end_tot_chgs] = comp.Tot_Chgs,
	snap.start_tot_pay,
	[end_tot_pay] = ISNULL(comp.Tot_Pay_Amt, 0),
	[start_sys_allowance_amt] = ISNULL(snap.start_sys_allowance_amt, 0),
	[end_sys_allowance_amt] = ISNULL(comp.SysAlw_Amt, 0),
	[change_in_ar_balance] = ISNULL(snap.start_ar_balance, 0) - ISNULL(comp.Balance, 0),
	[change_in_tot_chgs]  = ISNULL(snap.start_tot_chgs, 0) - ISNULL(comp.tot_chgs, 0),
	[change_in_tot_pay] = ISNULL(snap.start_tot_pay, 0) - ISNULL(comp.Tot_Pay_Amt, 0),
	[change_in_sys_allowance_amt] = ISNULL(snap.start_sys_allowance_amt, 0) - ISNULL(comp.SysAlw_Amt, 0)
INTO #c_comp_ar_tbl
FROM #start_tbl AS snap
LEFT JOIN PARA.dbo.Pt_Accounting_Reporting_ALT_Backup AS comp ON snap.Pt_No = comp.pt_no
	AND ISNULL(SNAP.UNIT_DATE, '') = ISNULL(COMP.Unit_Date, '')
	AND comp.EOMonth_Timestamp = @end_date
--AND comp.FC NOT LIKE '%[0-9]%'
--AND SNAP.Pt_No = '10081753302';

--select sum(start_ar_balance) from #start_tbl;
--select sum(start_ar_balance) from #c_comp_ar_tbl;

/*

Get the subsequent charges, so the charges from snapshot to comparison period

*/

DROP TABLE IF EXISTS #c_temp_subseq_chgs;

SELECT [pt_no] = chgs.Pt_No,
	[unit_date] = chgs.[unit-date],
	[unit_seq_no] = chgs.[PA-UNIT-NO],
	[subsequent_charges] = SUM([TOT-CHARGES])
INTO #c_temp_subseq_chgs
FROM SMS.dbo.Charges_For_Reporting_on_svc_date_and_post_date AS chgs
INNER JOIN #c_comp_ar_tbl AS b ON chgs.pt_no = b.Pt_No
    AND ISNULL(chgs.[unit-date], '') = ISNULL(b.Unit_Date, '')
WHERE chgs.[PA-DTL-POST-DATE] >= @start_date
    AND chgs.[PA-DTL-POST-DATE] < @end_date
GROUP BY chgs.Pt_No,
	chgs.[unit-date],
	chgs.[PA-UNIT-NO]

/*
------------------------------------------------------------

Get the subsequent payments and allowances -- keep at the prior month end so t
that if we run this in the middle of the month we get the correct values

------------------------------------------------------------
*/
DROP TABLE IF EXISTS #c_temp_subseq_pay_allow;
	SELECT pmts.PT_NO,
		b.Unit_Date,
		b.unit_no,
		pmts.DTL_Type_Ind,
		pmts.SVC_CD,
		pmts.CDM_DESCRIPTION,
		PMTS.FC,
		[pay_type] = CASE 
			WHEN PMTS.SVC_CD IN ('201426', '201376', '201392', '201434', '201400', '201442', '201475', '210286', '231266', '201368', '201483', '201459', '201384', '201418', '201467', '201491')
				THEN 'Charity'
			WHEN PMTS.FC LIKE '%[1-9]%'
				THEN 'Bad_Debt_' + PMTS.Transaction_Type
			ELSE PMTS.Transaction_Type
			END,
		[tot_pmts] = SUM(pmts.[PA-DTL-CHG-AMT])
	INTO #c_temp_subseq_pay_allow
	FROM sms.dbo.Payments_Adjustments_For_Reporting AS pmts
	INNER JOIN #c_comp_ar_tbl AS b ON pmts.pt_no = b.Pt_No
	WHERE (
			b.Unit_Date = pmts.Unit_Date
			OR b.Unit_Date IS NULL
			)
		AND pmts.[PA-DTL-POST-DATE] >= @start_date
		AND pmts.[PA-DTL-POST-DATE] < @end_date
		AND pmts.DTL_Type_Ind IN ('1', '3')
	GROUP BY pmts.PT_NO,
		b.Unit_Date,
		b.unit_no,
		pmts.DTL_Type_Ind,
		pmts.SVC_CD,
		pmts.CDM_DESCRIPTION,
		PMTS.FC,
		CASE 
			WHEN PMTS.SVC_CD IN ('201426', '201376', '201392', '201434', '201400', '201442', '201475', '210286', '231266', '201368', '201483', '201459', '201384', '201418', '201467', '201491')
				THEN 'Charity'
			WHEN PMTS.FC LIKE '%[1-9]%'
				THEN 'Bad_Debt_' + PMTS.Transaction_Type
			ELSE PMTS.Transaction_Type
			END;

-- Make runout payments and allowances rollup
DROP TABLE IF EXISTS #c_temp_subseq_pay_allow_rollup;
SELECT rr.PT_NO,
	rr.Unit_Date,
	rr.pay_type,
	sum(rr.tot_pmts) AS [tot_pmts]
INTO #c_temp_subseq_pay_allow_rollup
FROM #c_temp_subseq_pay_allow AS rr
GROUP BY rr.PT_NO,
	rr.Unit_Date,
	rr.pay_type;

/* Pull It all together */
DROP TABLE IF EXISTS #c_temp_runout_tbl;
SELECT A.Pt_No,
	A.Unit_Date,
	A.Unit_No,
	A.Admit_Date,
	A.Dsch_Date,
	A.Active_Archive,
	A.Hosp_Svc,
	A.Payer_organization,
	A.product_class,
	[snapshot_start_date] = start_date,
	[snapshot_end_date] = DATEADD(DAY, -1, @end_date),
	A.start_fc,
	A.end_fc,
	A.start_tot_chgs,
	A.end_tot_chgs,
	A.start_tot_pay,
	A.end_tot_pay,
	A.start_ar_balance,
	A.end_ar_balance,
	[subsequent_charges] = ISNULL((
		SELECT E.subsequent_charges
		FROM #c_temp_subseq_chgs AS E
		WHERE E.pt_no = A.Pt_No
			AND ISNULL(E.unit_date, '') = ISNULL(A.Unit_Date, '')
	), 0),
	[runout_payments] = ISNULL(
		(
			SELECT SUM(E.tot_pmts)
			FROM #c_temp_subseq_pay_allow_rollup AS E
			WHERE E.pay_type = 'Payment'
			AND E.PT_NO = A.Pt_No
			AND ISNULL(E.Unit_Date, '') = ISNULL(A.Unit_Date, '')
		)
	, 0),
	[runout_allowances] = ISNULL((
		SELECT SUM(E.tot_pmts)
		FROM #c_temp_subseq_pay_allow_rollup AS E
		WHERE E.pay_type = 'Adjustment'
			AND E.PT_NO = A.Pt_No
			AND ISNULL(E.Unit_Date, '') = ISNULL(A.Unit_Date, '')
	), 0),
	[runout_bad_debt_recovery] = ISNULL((
		SELECT SUM(E.tot_pmts)
		FROM #c_temp_subseq_pay_allow_rollup AS E
		WHERE E.pay_type = 'Bad_Debt_Payment'
			AND E.PT_NO = A.Pt_No
			AND ISNULL(E.Unit_Date, '') = ISNULL(A.Unit_Date, '')	
	), 0),
	[runout_bad_debt_adjustment] = ISNULL((
		SELECT SUM(E.tot_pmts)
		FROM #c_temp_subseq_pay_allow_rollup AS E
		WHERE E.pay_type = 'Bad_Debt_Adjustment'
			AND E.PT_NO = A.Pt_No
			AND ISNULL(E.Unit_Date, '') = ISNULL(A.Unit_Date, '')	
	), 0),
	[runout_charity] = ISNULL((
		SELECT SUM(E.tot_pmts)
		FROM #c_temp_subseq_pay_allow_rollup AS E
		WHERE E.pay_type = 'Charity'
			AND E.PT_NO = A.Pt_No
			AND ISNULL(E.Unit_Date, '') = ISNULL(A.Unit_Date, '')	
	), 0),
	[runout_other] = ISNULL((
		SELECT SUM(E.tot_pmts)
		FROM #c_temp_subseq_pay_allow_rollup AS E
		WHERE E.pay_type NOT IN ('Payment', 'Adjustment', 'Bad_Debt_Payment', 'Bad_Debt_Adjustment', 'Charity')
			AND E.PT_NO = A.Pt_No
			AND ISNULL(E.Unit_Date, '') = ISNULL(A.Unit_Date, '')	
	), 0)
INTO #c_temp_runout_tbl
FROM #c_comp_ar_tbl AS A;
--WHERE a.Pt_No = '10081753302';

WITH final_tbl AS (
	SELECT *,
		[check_var] = (
			ISNULL(start_ar_balance, 0) 
			+ ISNULL(subsequent_charges, 0)
			+ ISNULL(runout_payments, 0)
			+ ISNULL(runout_allowances, 0)
			+ ISNULL(runout_bad_debt_recovery, 0)
			+ ISNULL(runout_bad_debt_adjustment, 0)
			+ ISNULL(runout_charity, 0)
			+ ISNULL(runout_other, 0)
		)
	FROM #c_temp_runout_tbl
)

SELECT Active_Archive,
	Payer_organization,
	product_class,
	start_fc,
	end_fc,
	[start_date] = @start_date,
	[end_date] = @end_date,
	[accounts] = COUNT(PT_NO),
	[tot_start_ar] = SUM(ISNULL(start_ar_balance, 0)),
	[tot_end_ar] = SUM(ISNULL(end_ar_balance, 0)),
	[tot_subsequent_chgs] = SUM(ISNULL(subsequent_charges, 0)),
	[tot_runout_payments] = SUM(ISNULL(runout_payments, 0)),
	[tot_runout_allowances] = SUM(ISNULL(runout_allowances, 0)),
	[tot_runout_bad_debt_recovery] = SUM(ISNULL(runout_bad_debt_recovery, 0)),
	[tot_runout_bad_debt_adjustment] = SUM(ISNULL(runout_bad_debt_adjustment, 0)),
	[tot_runout_charity] = SUM(ISNULL(runout_charity, 0)),
	[tot_runout_other] = SUM(ISNULL(runout_other, 0)),
	[tot_check_var] = SUM(ISNULL(check_var, 0)),
	[reconciling_variance] = SUM(ISNULL(end_ar_balance, 0) - ISNULL(check_var, 0))
FROM final_tbl
GROUP BY Active_Archive,
	Payer_organization,
	product_class,
	start_fc,
	end_fc
ORDER BY Active_Archive,
	Payer_organization,
	product_class,
	start_fc,
	end_fc;

-- testing

--SELECT * FROM #c_comp_ar_tbl where pt_no = '10215193664'
--SELECT * FROM #c_temp_subseq_chgs where pt_no = '10215193664'
--SELECT * FROM #c_temp_subseq_pay_allow_rollup where pt_no = '10215193664'