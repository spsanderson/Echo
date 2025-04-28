DECLARE @start_date DATE;
DECLARE @end_date DATE;

SET @start_date = '2022-09-01';
SET @end_date = '2022-10-01';

--DROP TABLE IF EXISTS #start_tbl;

--SELECT Active_Archive,
--	Hosp_Svc,
--	Payer_organization,
--	product_class,
--	Pt_No,
--	Unit_No,
--	Unit_Date
--INTO #start_tbl
--FROM PARA.dbo.Pt_Accounting_Reporting_ALT_Backup
--WHERE EOMonth_Timestamp = @start_date
--AND FC NOT LIKE '%[0-9]%';

-- Active data
DROP TABLE IF EXISTS #detail_tbl;

SELECT [pt_no] = CAST(A.[PA-PT-NO-WOSCD] AS varchar) + CAST(A.[PA-PT-NO-SCD-1] AS varchar),
	[active_archive] = 'Active',
	[dtl_unit_date] = CAST(A.[PA-DTL-UNIT-DATE] AS DATE),
	[post_date] = CAST(A.[PA-DTL-POST-DATE] AS date),
	[dtl_type_long] = CASE
		WHEN A.[PA-DTL-TYPE-IND] = '1'
			THEN 'Payment'
		WHEN A.[PA-DTL-TYPE-IND] = '2'
			THEN 'Balance Transfer Payment'
		WHEN A.[PA-DTL-TYPE-IND] = '3'
			THEN 'Adjustment' 
		WHEN A.[PA-DTL-TYPE-IND] = '4'
			THEN 'Balance Transfer Adjustment'
		WHEN A.[PA-DTL-TYPE-IND] = '5'
			THEN 'Statistical Charges'
		WHEN A.[PA-DTL-TYPE-IND] = '7'
			THEN 'Room Charge'
		WHEN A.[PA-DTL-TYPE-IND] = '8'
			THEN 'Ancillary Charge'
		WHEN A.[PA-DTL-TYPE-IND] = '9'
			THEN 'Late Statistical Charge'
		WHEN A.[PA-DTL-TYPE-IND] = 'A'
			THEN 'Late Ancillary Charge'
		WHEN A.[PA-DTL-TYPE-IND] = 'B'
			THEN 'Late Room Charge'
		END,
	[dtl_type_short] = CASE
		WHEN A.[PA-DTL-TYPE-IND] IN ('A','B','7','8')
			THEN 'Charges'
		WHEN A.[PA-DTL-TYPE-IND] IN ('5','9')
			THEN 'Statistical Charge'
		WHEN A.[PA-DTL-TYPE-IND] IN ('1')
			THEN 'Payment'
		WHEN A.[PA-DTL-TYPE-IND] IN ('2','4')
			THEN 'Transfer'
		WHEN A.[PA-DTL-TYPE-IND] IN ('3')
			THEN 'Adjustment'
		END,
	[dtl_fc] = A.[PA-DTL-FC],
	[bad_debt_ind] = CASE
		WHEN [PA-DTL-FC] LIKE '%[1-9]%'
			THEN 'Bad_Debt'
		ELSE 'Not_Bad_Debt'
		END,
	[cdm_svc_type] = CDM.[Svc Type],
	[pay_chg_type] = CASE
		WHEN CAST(A.[PA-DTL-SVC-CD-WOSCD] AS varchar) + CAST(A.[PA-DTL-SVC-CD-SCD] AS varchar) IN (
			'201426', '201376', '201392', '201434', '201400', '201442', '201475', '210286', '231266', '201368', '201483', '201459', '201384', '201418', '201467', '201491'
			)
			THEN 'Charity'
		ELSE CDM.[Svc Type]
		END,
	[tot_adj_pay_chg_amt] = A.[PA-DTL-CHG-AMT]
INTO #detail_tbl
FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].ECHO_ACTIVE.DBO.DETAILINFORMATION AS A
LEFT JOIN SWARM.dbo.CDM AS CDM ON CAST(A.[PA-DTL-SVC-CD-WOSCD] AS varchar) + CAST(A.[PA-DTL-SVC-CD-SCD] AS varchar) = cdm.[Service Code]
WHERE A.[PA-DTL-POST-DATE] >= @start_date
AND A.[PA-DTL-POST-DATE] < @end_date;

SELECT A.pt_no,
	A.active_archive,
	A.dtl_unit_date,
	a.post_date,
	A.dtl_type_long,
	A.dtl_type_short,
	A.DTL_FC,
	A.bad_debt_ind,
	[svc_type] = CASE
		WHEN A.cdm_svc_type IS NULL
			THEN A.dtl_type_long
		ELSE A.cdm_svc_type
		END,
	[pay_chg_type] = CASE
		WHEN A.pay_chg_type IS NULL
			THEN A.dtl_type_long
		ELSE A.pay_chg_type
		END,
	[pt_no_in_snapshot] = CASE
		WHEN A.pt_no IN (
			SELECT ZZZ.PT_NO
			FROM #start_tbl AS ZZZ
			WHERE A.pt_no = ZZZ.Pt_No
		)
			THEN 'YES'
		ELSE 'NO'
		END,
	A.tot_adj_pay_chg_amt
INTO #active_dtl
FROM #detail_tbl AS A;

-- archive data
DROP TABLE IF EXISTS #archive_detail_tbl;

SELECT [pt_no] = CAST(A.[PA-PT-NO-WOSCD] AS varchar) + CAST(A.[PA-PT-NO-SCD-1] AS varchar),
	[active_archive] = 'Active',
	[dtl_unit_date] = CAST(A.[PA-DTL-UNIT-DATE] AS DATE),
	[post_date] = CAST(A.[PA-DTL-POST-DATE] AS date),
	[dtl_type_long] = CASE
		WHEN A.[PA-DTL-TYPE-IND] = '1'
			THEN 'Payment'
		WHEN A.[PA-DTL-TYPE-IND] = '2'
			THEN 'Balance Transfer Payment'
		WHEN A.[PA-DTL-TYPE-IND] = '3'
			THEN 'Adjustment' 
		WHEN A.[PA-DTL-TYPE-IND] = '4'
			THEN 'Balance Transfer Adjustment'
		WHEN A.[PA-DTL-TYPE-IND] = '5'
			THEN 'Statistical Charges'
		WHEN A.[PA-DTL-TYPE-IND] = '7'
			THEN 'Room Charge'
		WHEN A.[PA-DTL-TYPE-IND] = '8'
			THEN 'Ancillary Charge'
		WHEN A.[PA-DTL-TYPE-IND] = '9'
			THEN 'Late Statistical Charge'
		WHEN A.[PA-DTL-TYPE-IND] = 'A'
			THEN 'Late Ancillary Charge'
		WHEN A.[PA-DTL-TYPE-IND] = 'B'
			THEN 'Late Room Charge'
		END,
	[dtl_type_short] = CASE
		WHEN A.[PA-DTL-TYPE-IND] IN ('A','B','7','8')
			THEN 'Charges'
		WHEN A.[PA-DTL-TYPE-IND] IN ('5','9')
			THEN 'Statistical Charge'
		WHEN A.[PA-DTL-TYPE-IND] IN ('1')
			THEN 'Payment'
		WHEN A.[PA-DTL-TYPE-IND] IN ('2','4')
			THEN 'Transfer'
		WHEN A.[PA-DTL-TYPE-IND] IN ('3')
			THEN 'Adjustment'
		END,
	[dtl_fc] = A.[PA-DTL-FC],
	[bad_debt_ind] = CASE
		WHEN [PA-DTL-FC] LIKE '%[1-9]%'
			THEN 'Bad_Debt'
		ELSE 'Not_Bad_Debt'
		END,
	[cdm_svc_type] = CDM.[Svc Type],
	[pay_chg_type] = CASE
		WHEN CAST(A.[PA-DTL-SVC-CD-WOSCD] AS varchar) + CAST(A.[PA-DTL-SVC-CD-SCD] AS varchar) IN (
			'201426', '201376', '201392', '201434', '201400', '201442', '201475', '210286', '231266', '201368', '201483', '201459', '201384', '201418', '201467', '201491'
			)
			THEN 'Charity'
		ELSE CDM.[Svc Type]
		END,
	[tot_adj_pay_chg_amt] = A.[PA-DTL-CHG-AMT]
INTO #archive_detail_tbl
FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].ECHO_ARCHIVE.DBO.DETAILINFORMATION AS A
LEFT JOIN SWARM.dbo.CDM AS CDM ON CAST(A.[PA-DTL-SVC-CD-WOSCD] AS varchar) + CAST(A.[PA-DTL-SVC-CD-SCD] AS varchar) = cdm.[Service Code]
WHERE A.[PA-DTL-POST-DATE] >= @start_date
AND A.[PA-DTL-POST-DATE] < @end_date;

SELECT A.pt_no,
	A.active_archive,
	A.dtl_unit_date,
	a.post_date,
	A.dtl_type_long,
	A.dtl_type_short,
	A.DTL_FC,
	A.bad_debt_ind,
	[svc_type] = CASE
		WHEN A.cdm_svc_type IS NULL
			THEN A.dtl_type_long
		ELSE A.cdm_svc_type
		END,
	[pay_chg_type] = CASE
		WHEN A.pay_chg_type IS NULL
			THEN A.dtl_type_long
		ELSE A.pay_chg_type
		END,
	[pt_no_in_snapshot] = CASE
		WHEN A.pt_no IN (
			SELECT ZZZ.PT_NO
			FROM #start_tbl AS ZZZ
			WHERE A.pt_no = ZZZ.Pt_No
		)
			THEN 'YES'
		ELSE 'NO'
		END,
	A.tot_adj_pay_chg_amt
INTO #archive_dtl
FROM #archive_detail_tbl AS A;