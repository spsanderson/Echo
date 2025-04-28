DECLARE @curr_mo_end DATETIME,
	@curr_year INT,
	@prior_year_end DATETIME,
	@strt_of_year DATETIME,
	@snapshot_date DATETIME;

SET @curr_year = YEAR(DATEADD(MONTH, - MONTH(sysdatetime()) + 1, (DATEADD(MONTH, DATEDIFF(MONTH, 0, sysdatetime()), 0))));
SET @prior_year_end = DATEADD(DAY, - 1, DATEADD(MONTH, - MONTH(sysdatetime()) + 1, (DATEADD(MONTH, DATEDIFF(MONTH, 0, sysdatetime()), 0))));
SET @strt_of_year = DATEADD(MONTH, - MONTH(sysdatetime()) + 1, (DATEADD(MONTH, DATEDIFF(MONTH, 0, sysdatetime()), 0)));
SET @curr_mo_end = DATEADD(DAY, - 1, (DATEADD(MONTH, DATEDIFF(MONTH, 0, sysdatetime()), 0)));
SET @snapshot_date = DATEADD(DAY, 1, @prior_year_end);

/* ---------------------------------------------------------

Get accounts from previous backup that are active accounts
we will use these to get subsequent charge activity

------------------------------------------------------------
*/
DROP TABLE IF EXISTS #prior_year_accounts;
	SELECT DISTINCT pt_no,
		Unit_Date,
		Unit_No
	INTO #prior_year_accounts
	FROM PARA.DBO.Pt_Accounting_Reporting_ALT_Backup
	WHERE eomonth_timestamp = @snapshot_date
		--AND Active_Archive = 'ACTIVE';

/*
------------------------------------------------------------

Get the subsequent charges

------------------------------------------------------------
*/
DROP TABLE IF EXISTS #c_temp_subsequent_chgs;
	SELECT b.Pt_No,
		b.Unit_Date,
		b.Unit_No,
		SUM(A.[TOT-CHARGES]) AS [runout_chgs]
	INTO #c_temp_subsequent_chgs
	FROM sms.dbo.Charges_For_Reporting AS A
	INNER JOIN #prior_year_accounts AS B ON a.Pt_No = B.Pt_No
		AND year(a.[pa-dtl-unit-date]) < @curr_year-- @strt_of_year
			--AND GETDATE()
		AND (
			B.Unit_Date = A.[PA-DTL-UNIT-DATE]
			OR B.Unit_Date IS NULL
			)
	GROUP BY B.PT_NO,
		B.UNIT_DATE,
		b.Unit_No;

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
	INNER JOIN #prior_year_accounts AS b ON pmts.pt_no = b.Pt_No
	WHERE (
			b.Unit_Date = pmts.Unit_Date
			OR b.Unit_Date IS NULL
			)
		AND pmts.[PA-DTL-POST-DATE] BETWEEN @strt_of_year
			AND GETDATE()
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
	rr.pay_type

/*

Get current AR

*/
DROP TABLE IF EXISTS #c_temp_curr_ar
SELECT [pt_no] = A.pt_no,
	[unit_date] = CAST(A.unit_date as date),
	A.unit_no,
	A.fc,
	[fc_description] = A.FC_Description,
	A.payer_organization,
	[ins1_cd] = A.Ins1_Cd,
	[active_archive] = A.Active_Archive,
	[acct_type] = A.Acct_Type,
	[pt_type] = A.Pt_Type,
	[pt_type_desc] = A.Pt_Type_Desc,
	[vst_yr] = DATEPART(YEAR, A.Admit_Date),
	[tot_amt_due] = A.Balance,
	[tot_chg_amt] = A.Tot_Chgs,
	[tot_bal_amt] = A.Balance,
	[fnl_bl_cnt] = 0,
	[snapshot_full_date] = GETDATE()
INTO #c_temp_curr_ar
FROM SMS.DBO.Pt_Accounting_Reporting_ALT AS A;

/*

Get current bad debt xfer amount

*/
DROP TABLE IF EXISTS #c_latest_bd_xfer_amt;
WITH LatestBDAmt AS (
select pt_no,
	Acct_Balance,
	Report_Date,
	rec_no = ROW_NUMBER() OVER(PARTITION BY PT_NO ORDER BY REPORT_DATE DESC)
from sms.dbo.Bad_Debt_XFER
),

CurrFC as (
select *,
	[rec_no] = ROW_NUMBER() OVER(PARTITION BY PT_NO ORDER BY [RANK] DESC)
from sms.dbo.c_fc_comments_tbl
--where fc like '%[0-9]%'
)

SELECT [pt_no] = A.pt_no,
	[latest_bad_debt_svc_date] = a.svc_date,
	[latest_bad_debt_post_date] = A.post_date,
	[latest_pa_smart_comment] = A.pa_smart_comment,
	[latest_fc] = A.fc,
	[latest_fc_class] = A.fc_class,
	[latest_fc_group] = a.fc_group,
	[latest_bad_debt_xfer_amt] = B.Acct_Balance,
	[latest_bad_debt_xfer_date] = b.Report_Date
INTO #c_latest_bd_xfer_amt
FROM CurrFC AS A
LEFT JOIN LatestBDAmt AS B ON A.pt_no = B.pt_no
	AND B.rec_no = 1
WHERE A.rec_no = 1;

/*

Use AR 111 Bad Debt Referral Table when accounts not found in Bad_Debt_XFER table

*/
DROP TABLE IF EXISTS #c_bdar111;
WITH BD_AR111 AS (
SELECT *,
	rec_no = ROW_NUMBER() OVER(PARTITION BY [PA-PT-NO] ORDER BY BD_REFERRAL_DATE DESC)
FROM SMS.dbo.Bad_Debt_Referrals_tbl
)

SELECT A.*
INTO #c_bdar111
FROM BD_AR111 AS A
WHERE A.rec_no = 1;

/*

Get AR Runout Table

*/
DROP TABLE IF EXISTS #c_temp_ar_runout_tbl;
SELECT A.pt_no,
	[unit_date] = CAST(A.unit_date as date),
	A.unit_no,
	[admit_date] = CAST(A.Admit_Date as date),
	[discharge_date] = CAST(A.Dsch_Date as date),
	[visit_yr] = DATEPART(year, A.dsch_date),
	[current_fc] = A.fc,
	[fc_description] = A.FC_Description,
	A.payer_organization,
	[ins1_cd] = A.Ins1_Cd,
	[active_archive] = A.Active_Archive,
	[acct_type] = A.Acct_Type,
	[pt_type] = A.Pt_Type,
	[pt_type_desc] = A.Pt_Type_Desc,
	[vst_yr] = DATEPART(YEAR, A.Admit_Date),
	[tot_amt_due] = A.Balance,
	[tot_chg_amt] = A.Tot_Chgs,
	[ar_balance] = CASE
		WHEN D.tot_bal_amt IS NULL THEN 0
		WHEN d.acct_type = 'Archive'
			AND G.latest_bad_debt_xfer_amt > 0
			THEN D.tot_bal_amt - G.latest_bad_debt_xfer_amt
		ELSE D.tot_bal_amt
		END,
	[current_total_charges] = ISNULL(COALESCE(D.tot_chg_amt, F.Tot_Chgs), 0),
	[subsequent_chgs] = ISNULL(COALESCE(D.tot_chg_amt, F.Tot_Chgs), 0) - ISNULL(A.Tot_Chgs, 0),
	[prior_year_charges] = ISNULL(
		(SELECT J.runout_chgs
		FROM #c_temp_subsequent_chgs AS J
		WHERE A.PT_NO = J.PT_NO
			AND ISNULL(A.Unit_Date, '') = ISNULL(J.Unit_Date, '')),
			0),
	[current_balance] = ISNULL(D.tot_bal_amt, 0),
	[balance_change] = ISNULL(d.tot_bal_amt, 0) - a.Balance,
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
	), 0),
	[bd_wo_dtime] = COALESCE(g.latest_bad_debt_xfer_date, (SELECT ZZZ.BD_Referral_Date FROM #c_bdar111 AS ZZZ WHERE ZZZ.[PA-PT-NO] = A.PT_NO)),
	[archive_date] = CASE WHEN A.Active_Archive = 'Active' THEN NULL ELSE A.PA_Ctl_PAA_Xfer_Date END,
	[current_bad_debt_amt] = g.latest_bad_debt_xfer_amt,
	[current_bad_debt_fc] = CASE WHEN g.latest_fc LIKE '%[0-9]%' THEN G.latest_fc ELSE NULL END
INTO #c_temp_ar_runout_tbl
FROM para.dbo.Pt_Accounting_Reporting_ALT_Backup AS A
LEFT JOIN #c_temp_curr_ar AS D ON A.Pt_No = D.pt_no
	AND ISNULL(A.UNIT_DATE, '') = ISNULL(D.UNIT_DATE,'')
LEFT JOIN SMS.DBO.Pt_Accounting_Reporting_ALT AS F ON A.PT_NO = F.PT_NO
	AND ISNULL(A.UNIT_DATE, '') = ISNULL(F.UNIT_DATE, '')
LEFT JOIN #c_latest_bd_xfer_amt AS G ON A.PT_NO = G.PT_NO
WHERE A.eomonth_timestamp = @snapshot_date
AND A.FC NOT LIKE '%[0-9]%';

SELECT i.pt_no,
	i.unit_date,
	i.unit_no,
	i.admit_date,
	i.discharge_date,
	i.visit_yr,
	i.current_fc,
	i.fc_description,
	i.Payer_organization,
	i.ins1_cd,
	i.active_archive,
	i.acct_type,
	i.pt_type,
	i.pt_type_desc,
	i.tot_chg_amt,
	i.bd_wo_dtime,
	i.archive_date,
	i.current_bad_debt_fc,
	i.ar_balance,
	i.tot_amt_due,
	i.current_total_charges,
	i.prior_year_charges,
	i.runout_payments,
	i.runout_allowances,
	i.runout_charity,
	i.runout_bad_debt_recovery,
	i.runout_other,
	i.current_bad_debt_amt,
	CAST((
	IsNull(i.AR_Balance, 0) - 
	i.tot_amt_due - 
	IsNull(i.current_total_charges, 0) + 
	i.prior_year_charges - 
	ISNULL(i.runout_payments, 0) - 
	ISNULL(i.runout_allowances, 0) - 
	ISNULL(i.runout_charity, 0) -
	ISNULL(i.runout_bad_debt_recovery, 0) - 
	ISNULL(i.runout_other, 0) -
	ISNULL(i.current_bad_debt_amt, 0)
	) AS MONEY)  AS 'Chk_Var' -- subtract snapshot charges add subsequent charges subtract snapshot payments and allowances
--INTO #c_temp2_ar_runout 
FROM #c_temp_ar_runout_tbl AS i
where CAST((
	IsNull(i.AR_Balance, 0) - 
	i.tot_amt_due - 
	IsNull(i.current_total_charges, 0) + 
	i.prior_year_charges - 
	ISNULL(i.runout_payments, 0) - 
	ISNULL(i.runout_allowances, 0) - 
	ISNULL(i.runout_charity, 0) -
	ISNULL(i.runout_bad_debt_recovery, 0) - 
	ISNULL(i.runout_other, 0) -
	ISNULL(i.current_bad_debt_amt, 0)
	) AS MONEY)  != 0;

	-- testing
	--SELECT EOMonth_Timestamp,
--	[snapshot_date] = DATEADD(DAY, -1, EOMONTH_TIMESTAMP)
--FROM PARA.DBO.Pt_Accounting_Reporting_ALT_Backup
--GROUP BY EOMonth_Timestamp
--ORDER BY EOMonth_Timestamp;
DECLARE @start_date DATE;
DECLARE @end_date DATE;

SET @start_date = '2024-01-01';
SET @end_date = '2024-09-01';

DROP TABLE IF EXISTS #c_comp_ar_tbl;

WITH snapshot_tbl AS (
	SELECT Active_Archive,
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
	FROM PARA.dbo.Pt_Accounting_Reporting_ALT_Backup
	WHERE EOMonth_Timestamp = @start_date
	AND FC NOT LIKE '%[0-9]%'
)

SELECT snap.Active_Archive,
	snap.Pt_No,
	snap.Unit_no,
	snap.Unit_Date,
	snap.Admit_Date,
	snap.Dsch_Date,
	snap.start_date,
	snap.start_fc,
	[comp_fc] = comp.fc,
	snap.start_ar_balance,
	[comp_ar_balance] = comp.Balance,
	snap.start_tot_chgs,
	[comp_tot_chgs] = comp.Tot_Chgs,
	snap.start_tot_pay,
	[comp_tot_pay] = ISNULL(comp.Tot_Pay_Amt, 0),
	[start_sys_allowance_amt] = ISNULL(snap.start_sys_allowance_amt, 0),
	[comp_sys_allowance_amt] = ISNULL(comp.SysAlw_Amt, 0),
	[change_in_ar_balance] = ISNULL(snap.start_ar_balance, 0) - ISNULL(comp.Balance, 0),
	[change_in_tot_chgs]  = ISNULL(snap.start_tot_chgs, 0) - ISNULL(comp.tot_chgs, 0),
	[change_in_tot_pay] = ISNULL(snap.start_tot_pay, 0) - ISNULL(comp.Tot_Pay_Amt, 0),
	[change_in_sys_allowance_amt] = ISNULL(snap.start_sys_allowance_amt, 0) - ISNULL(comp.SysAlw_Amt, 0)
INTO #c_comp_ar_tbl
FROM start_tbl AS snap
INNER JOIN PARA.dbo.Pt_Accounting_Reporting_ALT_Backup AS comp ON snap.Pt_No = comp.pt_no
	AND ISNULL(SNAP.UNIT_DATE, '') = ISNULL(COMP.Unit_Date, '')
WHERE comp.EOMonth_Timestamp = @end_date
AND comp.FC NOT LIKE '%[0-9]%'
--AND SNAP.Pt_No = '10214749789';

/*

Get the subsequent charges, so the charges from snapshot to comparison period

*/

DROP TABLE IF EXISTS #c_temp_subseq_chgs;
SELECT TOP 1 *
FROM SMS.dbo.Charges_For_Reporting_on_svc_date_and_post_date
WHERE [PA-DTL-POST-DATE] >= @start_date
	AND [PA-DTL-POST-DATE] < @end_date

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

SELECT A.*,
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
FROM #c_comp_ar_tbl AS A
where a.Pt_No = '10081753302'

--SELECT * FROM #c_comp_ar_tbl where Pt_No = '10081753302';
--SELECT * FROM #c_temp_subseq_pay_allow;
--SELECT * FROM #c_temp_subseq_pay_allow_rollup where PT_NO = '10081753302';