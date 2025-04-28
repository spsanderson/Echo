DECLARE @SNAP_DATE DATE;

SET @SNAP_DATE = (
		SELECT MAX(EOMonth_Timestamp)
		FROM PARA.[dbo].[Pt_Accounting_Reporting_ALT_Backup]
		);

DECLARE @PRSUP_FC_DATE DATETIME;
DECLARE @CW_FC_DATE DATETIME;

SET @PRSUP_FC_DATE = (
		SELECT MAX(FileCreated)
		FROM SMS.DBO.CW_PRSUP_TBL
		);
SET @CW_FC_DATE = (
		SELECT MAX(FileCreated)
		FROM SMS.DBO.CW_PRWKL_tbl
		);

-- LAST WORKLIST ASSIGNMENT DEPT
DROP TABLE IF EXISTS #WORKLIST_DEPT_TBL;
	SELECT A.[WKLST ID],
		A.[WORKLIST DESC],
		[DEPARTMENT] = COALESCE(B.[GROUP NAME], C.[GROUP NAME]),
		[SUPV_ID] = COALESCE(B.[SUPV ID], C.[SUPV ID])
	INTO #WORKLIST_DEPT_TBL
	FROM SMS.DBO.CW_PRWKL_tbl AS A
	LEFT JOIN SMS.DBO.CW_PRSUP_tbl AS B ON A.COLLID = B.[SUPV ID]
		AND B.FileCreated = @PRSUP_FC_DATE
	LEFT JOIN SMS.DBO.CW_PRSUP_tbl AS C ON A.[SUPV ID] = C.[SUPV ID]
		AND C.FileCreated = @PRSUP_FC_DATE
	WHERE A.FileCreated = @CW_FC_DATE
	ORDER BY A.[WKLST ID];

-- GET REP NUMBER DEPARMTNET ASSIGNMENTS
DROP TABLE IF EXISTS #PT_REP_DEPT;
	SELECT pt_rep_no = CAST([PATIENT REP NUMBERS] AS VARCHAR),
		department = Department
	INTO #PT_REP_DEPT
	FROM SMS.DBO.c_Rep_Number_Master_List_tbl;

UPDATE #PT_REP_DEPT
SET department = 'DENIALS AND APPEALS'
WHERE department = 'Denials & Appeals';

-- WHAT IS WORKABLE AND NON WORKABLE
DROP TABLE IF EXISTS #WORK_NOWORK_TBL;
	SELECT PT_NO,
		Unit_No,
		Unit_Date,
		Admit_Date,
		Dsch_Date,
		BALANCE,
		Pt_Balance,
		Ins1_Balance,
		Ins2_Balance,
		Ins3_Balance,
		Ins4_Balance,
		Pyr1_Pay_Amt,
		Pyr2_Pay_Amt,
		Pyr3_Pay_Amt,
		Pyr4_Pay_Amt,
		[FILE],
		AGE_BUCKET,
		Ins1_Cd,
		Ins2_Cd,
		Ins3_Cd,
		Ins4_Cd,
		[Worklist on Ins1],
		[Worklist on Ins2],
		[Worklist on Ins3],
		[Worklist on Ins4],
		FC,
		PT_REPRESENTATIVE,
		ACCT_TYPE,
		First_Ins_Bl_Date,
		[1st_Bl_Exported_Date],
		[LAST ACTIVITY CODE],
		[Last Activity Date],
		PAYER_ORGANIZATION,
		PRODUCT_CLASS,
		IfPJOC,
		Worklist,
		[Worklist Name],
		[WORKABLE_NOTWORKABLE_IND] = CASE 
			-- NON WORKABLE REP NUMBERS
			WHEN Pt_Representative IS NOT NULL
				AND [Worklist Name on Ins1] IS NULL
				AND [Worklist Name on Ins2] IS NULL
				AND [Worklist Name on Ins3] IS NULL
				AND [Worklist Name on Ins4] IS NULL 
				AND Pt_Representative IN ('001', '901', '902', '721', '722', '744', '746', '780', '781', '782', '783', '880', '600', '601', '607', '609', '612', '616', '644', '666', '500', '501', '502', '503', '530', '531', '532', '550', '570', '571', '572', '573', '580', '581', '582', '583', '590', '591', '592', '593')
				THEN 'NOT_WORKABLE'
					-- INHOUSE DNFB BAD DEBT AND NO WORKLIST
			WHEN [FILE] != 'A/R'
				AND (
					[Worklist on Ins1] IS NULL
					AND [Worklist on Ins2] IS NULL
					AND [Worklist on Ins3] IS NULL
					AND [Worklist on Ins4] IS NULL
					)
				THEN 'NOT_WORKABLE'
			WHEN product_class IN ('CHP', 'Commercial', 'Essential 1&2', 'Essential 3&4', 'Exchange', 'Medicaid FFS', 'Medicaid HMO', 'Medicare FFS', 'Medicare HMO', 'Special', 'Tricare', 'VA CCN')
				AND (
					(
						DATEDIFF(DAY, [1st_Bl_Exported_Date], DATEADD(DAY, -2, dateadd(wk, datediff(wk, 0, GETDATE()), 0))) < 30
						AND Unit_No IS NULL
						)
					OR (
						DATEDIFF(DAY, First_Ins_Bl_Date, DATEADD(DAY, -2, dateadd(wk, datediff(wk, 0, GETDATE()), 0))) < 45
						AND UNIT_NO > 0
						)
					)
				AND Ins1_Balance > 0
				AND FC NOT IN ('G', 'P', 'I')
				AND Pyr1_Pay_Amt IS NULL
				AND (
					[Worklist on Ins1] IS NULL
					AND [Worklist on Ins2] IS NULL
					AND [Worklist on Ins3] IS NULL
					AND [Worklist on Ins4] IS NULL
					)
				AND (
					Pt_Representative IS NULL
					OR Pt_Representative IN ('0', '000', '')
					)
				THEN 'NOT_WORKABLE'
					-- IF NOT ON A WORKLIST AND NO PT REP
			WHEN (
					[Worklist on Ins1] IS NULL
					AND [Worklist on Ins2] IS NULL
					AND [Worklist on Ins3] IS NULL
					AND [Worklist on Ins4] IS NULL
					)
				AND (
					Pt_Representative IS NULL
					OR Pt_Representative IN ('0', '000', '')
					)
				THEN 'NOT_WORKABLE'
					-- 
					-- NOT IN A SELF PAY FC
			WHEN FC IN ('G', 'P', 'I')
				AND (
					[Worklist on Ins1] IS NULL
					AND [Worklist on Ins2] IS NULL
					AND [Worklist on Ins3] IS NULL
					AND [Worklist on Ins4] IS NULL
					)
				THEN 'NOT_WORKABLE'
					-- THERE IS A BALANCE SITING WITH AN INS
			WHEN [FILE] = 'A/R'
				AND (
					INS1_BALANCE = 0
					AND INS2_BALANCE = 0
					AND INS3_BALANCE = 0
					AND INS4_BALANCE = 0
					)
				AND PT_BALANCE != 0
				AND (
					[Worklist on Ins1] IS NULL
					AND [Worklist on Ins2] IS NULL
					AND [Worklist on Ins3] IS NULL
					AND [Worklist on Ins4] IS NULL
					)
				THEN 'NOT_WORKABLE'
			WHEN FIRST_INS_BL_DATE IS NULL
				AND (
					[Worklist on Ins1] IS NULL
					AND [Worklist on Ins2] IS NULL
					AND [Worklist on Ins3] IS NULL
					AND [Worklist on Ins4] IS NULL
					)
				THEN 'NOT_WORKABLE'
			ELSE 'WORKABLE'
			END,
		[WORKLISTED] = CASE 
			WHEN (
					[Worklist on Ins1] IS NOT NULL
					OR [Worklist on Ins2] IS NOT NULL
					OR [Worklist on Ins3] IS NOT NULL
					OR [Worklist on Ins4] IS NOT NULL
					)
				THEN 'YES'
			ELSE 'NO'
			END,
		[INS_BUCKETS] = CASE 
			WHEN INS1_BALANCE = 0
				AND INS2_BALANCE = 0
				AND INS3_BALANCE = 0
				AND INS4_BALANCE = 0
				THEN 'PT BALANCE'
			WHEN INS1_BALANCE = 0
				AND INS2_BALANCE = 0
				AND INS3_BALANCE = 0
				AND INS4_BALANCE != 0
				THEN 'QUATERNARY'
			WHEN INS1_BALANCE = 0
				AND INS2_BALANCE = 0
				AND INS3_BALANCE != 0
				THEN 'TERTIARY'
			WHEN INS1_BALANCE = 0
				AND INS2_BALANCE != 0
				THEN 'SECONDARY'
			WHEN INS1_BALANCE != 0
				THEN 'PRIMARY'
			ELSE 'REVIEW'
			END,
		[BUCKET_INS_CODE] = CASE 
			WHEN INS1_BALANCE = 0
				AND INS2_BALANCE = 0
				AND INS3_BALANCE = 0
				AND INS4_BALANCE = 0
				THEN '*'
			WHEN INS1_BALANCE = 0
				AND INS2_BALANCE = 0
				AND INS3_BALANCE = 0
				AND INS4_BALANCE != 0
				THEN INS4_CD
			WHEN INS1_BALANCE = 0
				AND INS2_BALANCE = 0
				AND INS3_BALANCE != 0
				THEN INS3_CD
			WHEN INS1_BALANCE = 0
				AND INS2_BALANCE != 0
				THEN INS2_CD
			WHEN INS1_BALANCE != 0
				THEN INS1_CD
			ELSE 'REVIEW'
			END,
		[BUCKET_BALANCE] = CASE 
			WHEN INS1_BALANCE = 0
				AND INS2_BALANCE = 0
				AND INS3_BALANCE = 0
				AND INS4_BALANCE = 0
				THEN Pt_Balance
			WHEN INS1_BALANCE = 0
				AND INS2_BALANCE = 0
				AND INS3_BALANCE = 0
				AND INS4_BALANCE != 0
				THEN INS4_BALANCE
			WHEN INS1_BALANCE = 0
				AND INS2_BALANCE = 0
				AND INS3_BALANCE != 0
				THEN INS3_BALANCE
			WHEN INS1_BALANCE = 0
				AND INS2_BALANCE != 0
				THEN INS2_BALANCE
			WHEN INS1_BALANCE != 0
				THEN INS1_BALANCE
			ELSE 'REVIEW'
			END,
		Ins1_Last_BL_Date,
		Ins2_Last_BL_Date,
		Ins3_Last_BL_Date,
		Ins4_Last_BL_Date,
		Ins1_Last_Paid,
		Ins2_Last_Paid,
		Ins3_Last_Paid,
		Ins4_Last_Paid,
		DEPARTMENT = COALESCE(B.DEPARTMENT, C.DEPARTMENT)
	INTO #WORK_NOWORK_TBL
	--FROM SMS.DBO.PT_ACCOUNTING_REPORTING_ALT AS A
	FROM Pt_Accounting_Reporting_ALT_for_Tableau AS A
	LEFT JOIN #WORKLIST_DEPT_TBL AS B ON COALESCE(A.[Worklist on Ins1], A.[WORKLIST ON INS2], A.[WORKLIST ON INS3], A.[WORKLIST ON INS4]) = B.[WKLST ID]
	LEFT JOIN #PT_REP_DEPT AS C ON A.Pt_Representative = C.pt_rep_no

	--FROM PARA.[dbo].[Pt_Accounting_Reporting_ALT_Backup]
	WHERE TOT_CHGS > 0
		AND ACTIVE_ARCHIVE = 'ACTIVE'
		AND BALANCE != 0
		AND FC != 'X'
		--AND EOMONTH_TIMESTAMP = @SNAP_DATE
		--AND PT_NO = '10216951847';
		;

WITH CTE AS (
SELECT A.Pt_No,
	A.Unit_No,
	A.unit_date,
	A.Admit_Date,
	A.Dsch_Date,
	A.Balance,
	A.Pt_Balance,
	A.Ins1_Balance,
	A.Ins2_Balance,
	A.Ins3_Balance,
	A.Ins4_Balance,
	A.Pyr1_Pay_Amt,
	A.Pyr2_Pay_Amt,
	A.Pyr3_Pay_Amt,
	A.Pyr4_Pay_Amt,
	A.[FILE],
	A.Age_Bucket,
	A.Ins1_Cd,
	A.Ins2_Cd,
	A.Ins3_Cd,
	A.Ins4_Cd,
	A.[Worklist on Ins1],
	A.[Worklist on Ins2],
	A.[Worklist on Ins3],
	A.[Worklist on Ins4],
	A.FC,
	A.Pt_Representative,
	A.Acct_Type,
	A.First_Ins_Bl_Date,
	A.[LAST ACTIVITY CODE],
	A.[Last Activity Date],
	A.payer_organization,
	A.product_class,
	A.IfPJOC,
	A.WORKABLE_NOTWORKABLE_IND,
	A.WORKLISTED,
	A.INS_BUCKETS,
	A.BUCKET_INS_CODE,
	A.BUCKET_BALANCE,
	A.WORKLIST,
	A.[Worklist Name],
	[LAST_EXPORT_DATE] = CASE 
		WHEN INS_BUCKETS = 'PRIMARY'
			AND [BUCKET_INS_CODE] = f.Ins1_Cd
			THEN isnull(f.Ins1_Last_Finthrive_Bill_Date, a.[1st_Bl_Exported_Date])
		WHEN INS_BUCKETS = 'SECONDARY'
			AND [BUCKET_INS_CODE] = f.Ins2_Cd
			THEN f.Ins2_Last_Finthrive_Bill_Date
		WHEN INS_BUCKETS = 'TERTIARY'
			AND [BUCKET_INS_CODE] = f.Ins3_Cd
			THEN f.Ins3_Last_Finthrive_Bill_Date
		WHEN INS_BUCKETS = 'QUATERNARY'
			AND [BUCKET_INS_CODE] = f.Ins4_Cd
			THEN f.Ins4_Last_Finthrive_Bill_Date
		ELSE NULL
		END,
	[LAST_BILL_DATE] = CASE 
		WHEN INS_BUCKETS = 'PRIMARY'
			THEN A.Ins1_Last_BL_Date
		WHEN INS_BUCKETS = 'SECONDARY'
			THEN A.Ins2_Last_BL_Date
		WHEN INS_BUCKETS = 'TERTIARY'
			THEN A.Ins3_Last_BL_Date
		WHEN INS_BUCKETS = 'QUATERNARY'
			THEN A.Ins4_Last_BL_Date
		ELSE NULL
		END,
	[LAST_PAY_DATE] = CASE 
		WHEN INS_BUCKETS = 'PRIMARY'
			AND [BUCKET_INS_CODE] = f.Ins1_Cd
			THEN A.Ins1_Last_Paid
		WHEN INS_BUCKETS = 'SECONDARY'
			AND [BUCKET_INS_CODE] = f.Ins2_Cd
			THEN A.Ins2_Last_Paid
		WHEN INS_BUCKETS = 'TERTIARY'
			AND [BUCKET_INS_CODE] = f.Ins3_Cd
			THEN A.Ins3_Last_Paid
		WHEN INS_BUCKETS = 'QUATERNARY'
			AND [BUCKET_INS_CODE] = f.Ins4_Cd
			THEN A.Ins4_Last_Paid
		ELSE NULL
		END,
	DEPARTMENT =
	CASE 
		WHEN A.WORKABLE_NOTWORKABLE_IND = 'NOT_WORKABLE'
			AND A.FC IN ('1', '2', '3', '4', '5', '6', '7', '8')
			THEN 'BAD DEBT AG'
		WHEN WORKABLE_NOTWORKABLE_IND = 'NOT_WORKABLE'
			AND A.FC = '9'
			THEN 'BAD DEBT KOPP'
		WHEN WORKABLE_NOTWORKABLE_IND = 'NOT_WORKABLE'
			AND A.Ins1_Balance = 0
			AND A.Ins2_Balance = 0
			AND A.Ins3_Balance = 0
			AND A.Ins4_Balance = 0
			AND A.Pt_Balance != 0
			THEN 'PATIENT BALANCE'
		WHEN A.WORKABLE_NOTWORKABLE_IND = 'NOT_WORKABLE'
			AND A.[FILE] IN ('INHOUSE', 'DNFB')
			THEN 'INHOUSE/DNFB'
		WHEN A.WORKABLE_NOTWORKABLE_IND = 'NOT_WORKABLE'
			AND A.Pt_Representative IN ('500', '501', '503')
			THEN 'MED-METRIX'
		WHEN A.WORKABLE_NOTWORKABLE_IND = 'NOT_WORKABLE'
			AND A.Pt_Representative IN ('530', '531', '533')
			THEN 'JZANUS-MEDICAID APLICATIONS'
		WHEN A.WORKABLE_NOTWORKABLE_IND = 'NOT_WORKABLE'
			AND A.Pt_Representative IN ('570', '571', '573')
			THEN 'RTR'
		WHEN A.WORKABLE_NOTWORKABLE_IND = 'NOT_WORKABLE'
			AND A.Pt_Representative IN ('590', '591', '593')
			THEN 'MEDCO'
		WHEN A.WORKABLE_NOTWORKABLE_IND = 'NOT_WORKABLE'
			AND A.Pt_Representative IN ('780', '781', '783')
			THEN 'KOPP'
		WHEN A.WORKABLE_NOTWORKABLE_IND = 'NOT_WORKABLE'
			AND A.Pt_Representative IN ('721', '722')
			THEN 'NYAG'
		WHEN A.WORKABLE_NOTWORKABLE_IND = 'NOT_WORKABLE'
			AND A.Acct_Type = 'OP'
			AND (
				A.Unit_No IS NULL
				OR A.UNIT_NO != '0'
				)
			AND A.First_Ins_Bl_Date IS NULL
			THEN 'OP UNBILLED'
		WHEN A.WORKABLE_NOTWORKABLE_IND = 'NOT_WORKABLE'
			AND A.Acct_Type = 'OP'
			AND A.UNIT_NO = '0'
			THEN 'OP OPEN UNIT'
		WHEN A.WORKABLE_NOTWORKABLE_IND = 'NOT_WORKABLE'
			AND Ins1_Balance > 0
			AND payer_organization IN ('MEDICARE FFS', 'MEDICAID FFS')
			AND (
					(
						DATEDIFF(DAY, [1st_Bl_Exported_Date], DATEADD(DAY, -2, dateadd(wk, datediff(wk, 0, GETDATE()), 0))) < 30
						AND Unit_No IS NULL
						)
					OR (
						DATEDIFF(DAY, First_Ins_Bl_Date, DATEADD(DAY, -2, dateadd(wk, datediff(wk, 0, GETDATE()), 0))) < 45
						AND UNIT_NO > 0
						)
					)
			AND FC NOT IN ('G', 'P', 'I')
			AND Pyr1_Pay_Amt IS NULL
			AND (
				[Worklist on Ins1] IS NULL
				AND [Worklist on Ins2] IS NULL
				AND [Worklist on Ins3] IS NULL
				AND [Worklist on Ins4] IS NULL
				)
			AND (
				Pt_Representative IS NULL
				OR Pt_Representative IN ('0', '000', '')
				)
			THEN 'RECENTLY BILLED GOVERNMENTAL'
		WHEN A.WORKABLE_NOTWORKABLE_IND = 'NOT_WORKABLE'
			AND Ins1_Balance > 0
			AND A.UNIT_DATE IS NULL
			AND payer_organization NOT IN ('MEDICARE FFS', 'MEDICAID FFS')
			AND (
					DATEDIFF(DAY, [1st_Bl_Exported_Date], DATEADD(DAY, -2, dateadd(wk, datediff(wk, 0, GETDATE()), 0))) < 30
					AND Unit_No IS NULL
			)
			AND FC NOT IN ('G', 'P', 'I')
			AND Pyr1_Pay_Amt IS NULL
			AND (
				[Worklist on Ins1] IS NULL
				AND [Worklist on Ins2] IS NULL
				AND [Worklist on Ins3] IS NULL
				AND [Worklist on Ins4] IS NULL
				)
			AND (
				Pt_Representative IS NULL
				OR Pt_Representative IN ('0', '000', '')
				)
			THEN 'RECENTLY BILLED NON-GOVERNMENTAL'
		WHEN A.WORKABLE_NOTWORKABLE_IND = 'NOT_WORKABLE'
			AND Ins1_Balance > 0
			AND A.UNIT_DATE IS NOT NULL
			AND payer_organization NOT IN ('MEDICARE FFS', 'MEDICAID FFS')
			AND (
					DATEDIFF(DAY, First_Ins_Bl_Date, DATEADD(DAY, -2, dateadd(wk, datediff(wk, 0, GETDATE()), 0))) < 45
					AND UNIT_NO > 0
				)
			AND FC NOT IN ('G', 'P', 'I')
			AND Pyr1_Pay_Amt IS NULL
			AND (
				[Worklist on Ins1] IS NULL
				AND [Worklist on Ins2] IS NULL
				AND [Worklist on Ins3] IS NULL
				AND [Worklist on Ins4] IS NULL
				)
			AND (
				Pt_Representative IS NULL
				OR Pt_Representative IN ('0', '000', '')
				)
			THEN 'RECENTLY BILLED NON-GOVERNMENTAL UNITIZED FOLLOW UP'
		WHEN A.WORKABLE_NOTWORKABLE_IND = 'NOT_WORKABLE'
			AND LEFT(A.[BUCKET_INS_CODE], 1) IN ('C','G','J','M','O','P','U','Y')
			AND A.Pyr1_Pay_Amt IS NOT NULL 
			AND A.Unit_No IS NULL
			AND A.Age_Bucket != 'In House/DNFB'
			AND A.INS_BUCKETS = 'PRIMARY'
			AND A.[LAST ACTIVITY DATE] > DATEADD(day, -30, dateadd(wk, datediff(wk, 0, getdate()), -2))
			THEN 'VARIANCE UNIT PENDING'
		WHEN A.WORKABLE_NOTWORKABLE_IND = 'NOT_WORKABLE'
			AND LEFT(A.[BUCKET_INS_CODE], 1) IN ('C','G','J','M','N','O','P','U','Y')
			AND A.[1st_Bl_Exported_Date] < DATEADD(day, -30, dateadd(wk, datediff(wk, 0, getdate()), -2))
			AND A.Unit_No IS NULL
			AND A.Age_Bucket != 'In House/DNFB'
			THEN 'NON-GOVERNMENTAL FOLLOW UP'
		WHEN A.WORKABLE_NOTWORKABLE_IND = 'NOT_WORKABLE'
			AND (
				A.[BUCKET_INS_CODE] IN ('L60','L45')
				OR LEFT(A.[BUCKET_INS_CODE], 1) = 'N'
			)
			AND A.[1st_Bl_Exported_Date] < DATEADD(day, -30, dateadd(wk, datediff(wk, 0, getdate()), -2))
			AND A.[LAST ACTIVITY DATE] > DATEADD(day, -30, dateadd(wk, datediff(wk, 0, getdate()), -2))
			AND A.Age_Bucket != 'In House/DNFB'
			THEN 'NON-GOVERNMENTAL FOLLOW UP PENDING'
		WHEN A.WORKABLE_NOTWORKABLE_IND = 'NOT_WORKABLE'
			AND LEFT(A.[BUCKET_INS_CODE], 1) IN ('C','G','J','M','N','O','P','U','Y')
			AND A.[1st_Bl_Exported_Date] < DATEADD(day, -45, dateadd(wk, datediff(wk, 0, getdate()), -2))
			AND A.[LAST ACTIVITY DATE] > DATEADD(day, -30, dateadd(wk, datediff(wk, 0, getdate()), -2))
			AND A.Unit_No IS NOT NULL
			THEN 'UNITIZED FOLLOW UP PENDING'
		WHEN A.WORKABLE_NOTWORKABLE_IND = 'NOT_WORKABLE'
			AND (
				LEFT(A.[BUCKET_INS_CODE], 1) IN ('C','G','J','M','N','O','P','U','Y')
				OR A.[BUCKET_INS_CODE]  IN ('L60','L45')
			)
			THEN 'NON-GOVERNMENTAL BILLING'
		WHEN A.WORKABLE_NOTWORKABLE_IND = 'NOT_WORKABLE'
			AND LEFT(A.[BUCKET_INS_CODE], 1) IN ('H') 
			THEN 'SELF PAY AND FINANCIAL ASSIST.'
		WHEN A.WORKABLE_NOTWORKABLE_IND = 'NOT_WORKABLE'
			AND LEFT(A.[BUCKET_INS_CODE], 1) IN ('R') 
			THEN 'RESEARCH'
		WHEN A.WORKABLE_NOTWORKABLE_IND = 'NOT_WORKABLE'
			AND LEFT(A.[BUCKET_INS_CODE], 1) IN ('I','L','Q') 
			AND A.[BUCKET_INS_CODE] NOT IN ('L60','L45')
			THEN 'SPECIAL BILLING'
		WHEN A.WORKABLE_NOTWORKABLE_IND = 'NOT_WORKABLE'
			AND LEFT(A.[BUCKET_INS_CODE], 1) IN ('E','F') 
			THEN 'VENDOR MANAGEMENT'
		WHEN A.WORKABLE_NOTWORKABLE_IND = 'NOT_WORKABLE'
			AND A.[BUCKET_INS_CODE] = '*'
			AND A.BUCKET_BALANCE > 0
			THEN 'PATIENT-DEBIT'
		WHEN A.WORKABLE_NOTWORKABLE_IND = 'NOT_WORKABLE'
			AND A.[BUCKET_INS_CODE] = '*'
			AND A.BUCKET_BALANCE < 0 
			THEN 'PATIENT-CREDIT'
		WHEN A.WORKABLE_NOTWORKABLE_IND = 'NOT_WORKABLE'
			AND A.BUCKET_INS_CODE IS NULL
			THEN 'INSURANCE VERIFICATION'
		ELSE UPPER(A.DEPARTMENT)
		END
FROM #WORK_NOWORK_TBL AS A
LEFT JOIN SMS.dbo.c_Finthrive_Last_Bill_Date_tbl AS F ON A.Pt_No = F.pt_no
	AND A.Ins1_Cd = F.Ins1_Cd
	AND A.Ins2_Cd = F.Ins2_Cd
	AND A.Ins3_Cd = F.Ins3_Cd
	AND A.Ins4_Cd = F.Ins4_Cd
	AND A.Dsch_Date = F.Dsch_Date
)

SELECT A.Pt_No,
A.Unit_No,
A.unit_date,
A.Admit_Date,
A.Dsch_Date,
A.Balance,
A.Pt_Balance,
A.Ins1_Balance,
A.Ins2_Balance,
A.Ins3_Balance,
A.Ins4_Balance,
A.Pyr1_Pay_Amt,
A.Pyr2_Pay_Amt,
A.Pyr3_Pay_Amt,
A.Pyr4_Pay_Amt,
A.[FILE],
A.Age_Bucket,
A.Ins1_Cd,
A.Ins2_Cd,
A.Ins3_Cd,
A.Ins4_Cd,
A.[Worklist on Ins1],
A.[Worklist on Ins2],
A.[Worklist on Ins3],
A.[Worklist on Ins4],
A.FC,
A.Pt_Representative,
A.Acct_Type,
A.First_Ins_Bl_Date,
A.[LAST ACTIVITY CODE],
A.[Last Activity Date],
A.payer_organization,
A.product_class,
A.IfPJOC,
[WORKABLE_NOTWORKABLE_IND] = CASE
	WHEN A.DEPARTMENT IN ('INHOUSE/DNFB', 'OP UNBILLED')
		THEN 'INHOUSE_DNFB'
	ELSE A.WORKABLE_NOTWORKABLE_IND
	END,
A.WORKLISTED,
A.INS_BUCKETS,
A.BUCKET_INS_CODE,
A.BUCKET_BALANCE,
A.WORKLIST,
A.[Worklist Name],
A.LAST_EXPORT_DATE,
A.LAST_BILL_DATE,
A.LAST_PAY_DATE,
DEPARTMENT = CASE
	WHEN A.DEPARTMENT = 'INHOUSE/DNFB'
		THEN UPPER(A.[File])
	WHEN A.DEPARTMENT IS NULL
		AND A.LAST_EXPORT_DATE IS NULL
		AND A.WORKABLE_NOTWORKABLE_IND = 'NOT_WORKABLE'
		THEN 'SCRUBBER'
	ELSE A.DEPARTMENT
	END
FROM CTE AS A
--WHERE A.Pt_No = '10225197465'