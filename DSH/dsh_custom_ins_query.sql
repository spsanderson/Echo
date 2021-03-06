USE [DSH];

--SET ANSI_WARNINGS OFF;
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

----------------------------------------------------------------------------------------------------------------------------------------------------
/*Create Table For IM Patients*/
DROP TABLE

IF EXISTS IM_Patients
	CREATE TABLE [IM_Patients] (
		[PA-PT-NO-WOSCD] DECIMAL(11, 0) NOT NULL,
		[PA-PT-NO-SCD] CHAR(1) NOT NULL,
		[IM-IND] VARCHAR(50) NOT NULL
		)

INSERT INTO IM_Patients (
	[PA-PT-NO-WOSCD],
	[PA-PT-NO-SCD],
	[IM-IND]
	)
SELECT [pa-pt-no-woscd],
	[pa-pt-no-scd-1],
	'JAIL' AS 'IM-IND'
FROM [Echo_Active].dbo.[NADInformation]
WHERE [pa-nad-cd] = 'PTGAR'
	AND [pa-acct-type] NOT IN ('0', '6', '7')
	AND (
		(
			[pa-nad-last-or-orgz-name] LIKE '%JAIL %'
			OR [pa-nad-first-or-orgz-cntc] LIKE '%JAIL %'
			)
		OR (
			[pa-nad-last-or-orgz-name] LIKE '%JAIL'
			OR [pa-nad-first-or-orgz-cntc] LIKE '%JAIL'
			)
		)

UNION

SELECT [pa-pt-no-woscd],
	[pa-pt-no-scd-1],
	'JAIL' AS 'IM-IND'
FROM [Echo_Archive].dbo.[NADInformation]
WHERE [pa-nad-cd] = 'PTGAR'
	AND [pa-acct-type] NOT IN ('0', '6', '7')
	AND (
		(
			[pa-nad-last-or-orgz-name] LIKE '%JAIL %'
			OR [pa-nad-first-or-orgz-cntc] LIKE '%JAIL %'
			)
		OR (
			[pa-nad-last-or-orgz-name] LIKE '%JAIL'
			OR [pa-nad-first-or-orgz-cntc] LIKE '%JAIL'
			)
		)
GO

--SELECT * FROM #IM_Patients
----------------------------------------------------------------------------------------------------------------------------------------------------
DROP TABLE

IF EXISTS DISTINCT_ENCOUNTERS_FOR_DSH
	CREATE TABLE DISTINCT_ENCOUNTERS_FOR_DSH (
		[PA-PT-NO-WOSCD] DECIMAL(11, 0) NOT NULL,
		[PA-PT-NO-SCD] CHAR(1) NOT NULL
		);

INSERT INTO [DISTINCT_ENCOUNTERS_FOR_DSH] (
	[PA-PT-NO-WOSCD],
	[PA-PT-NO-SCD]
	)
SELECT [PA-PT-NO-WOSCD],
	[PA-PT-NO-SCD]
FROM [ENCOUNTERS_FOR_DSH]
GROUP BY [PA-PT-NO-WOSCD],
	[PA-PT-NO-SCD]
GO

----------------------------------------------------------------------------------------------------------------------------------------------------
/*Create Custom Insurance Table*/
DROP TABLE

IF EXISTS CUSTOMINSURANCE
	--GO
	-- Add new table
	CREATE TABLE CUSTOMINSURANCE (
		[PA-PT-NO-WOSCD] DECIMAL(11, 0) NOT NULL,
		[PA-PT-NO-SCD] CHAR(1) NOT NULL,
		[PA-CTL-PAA-XFER-DATE] DATETIME NULL,
		[PA-INS-PRTY] DECIMAL(1, 0) NULL,
		[PA-INS-PLAN] VARCHAR(100) NULL,
		[PA-LAST-INS-PAY-DATE] DATETIME NULL,
		[INS-PAY-AMT] MONEY NULL,
		[RANK1] CHAR(4) NULL,
		[IM-IND] VARCHAR(50) NULL
		--[REPORT-GROUP] VARCHAR(75) NULL
		);

INSERT INTO [CustomInsurance] (
	[PA-PT-NO-WOSCD],
	[PA-PT-NO-SCD],
	[PA-INS-PRTY],
	[PA-INS-PLAN],
	[PA-LAST-INS-PAY-DATE],
	[INS-PAY-AMT],
	[RANK1],
	[IM-IND]
	) --,[REPORT-GROUP])
SELECT DISTINCT (A.[PA-PT-NO-WOSCD]),
	A.[PA-PT-NO-SCD],
	--A.[PA-CTL-PAA-XFER-DATE],
	B.[PA-INS-PRTY],
	CASE 
		WHEN LEN(ltrim(rtrim(b.[pa-ins-plan-no]))) = '1'
			THEN CAST(CAST(LTRIM(RTRIM(B.[pa-ins-co-cd])) AS VARCHAR) + CONVERT(VARCHAR(1), 0) + CAST(LTRIM(RTRIM(B.[pa-ins-plan-no])) AS VARCHAR) AS VARCHAR)
		WHEN LEN(LTRIM(RTRIM(b.[pa-ins-plan-no]))) = '2'
			THEN CAST(CAST(LTRIM(RTRIM(B.[pa-ins-co-cd])) AS VARCHAR) + CAST(LTRIM(RTRIM(B.[pa-ins-plan-no])) AS VARCHAR) AS VARCHAR)
		ELSE 'SELF_PAY'
		END AS 'PA-INS-PLAN',
	B.[PA-LAST-INS-PAY-DATE],
	ISNULL(B.[PA-BAL-INS-PAY-AMT], 0) AS 'Ins-Pay-Amt',
	RANK() OVER (
		PARTITION BY A.[PA-PT-NO-WOSCD] ORDER BY b.[pa-bal-ins-pay-amt] ASC,
			b.[pa-ins-prty] ASC,
			b.[pa-ins-co-cd] ASC,
			b.[pa-ins-plan-no] ASC
		) AS 'RANK1',
	ISNULL([IM-IND], 0) AS 'IM-IND'
FROM [Distinct_Encounters_For_DSH] A
INNER JOIN [Echo_Archive].DBO.INSURANCEINFORMATION B ON A.[PA-PT-NO-WOSCD] = B.[PA-PT-NO-WOSCD] --AND A.[PA-CTL-PAA-XFER-DATE]=B.[PA-CTL-PAA-XFER-DATE]
LEFT OUTER JOIN [IM_PATIENTS] C ON A.[PA-PT-NO-WOSCD] = C.[PA-PT-NO-WOSCD]
--WHERE A.[PA-DELETE-DATE] IS NULL
--ORDER BY a.[pa-pt-no-woscd]

UNION

SELECT DISTINCT (A.[PA-PT-NO-WOSCD]),
	A.[PA-PT-NO-SCD],
	--A.[PA-CTL-PAA-XFER-DATE],
	B.[PA-INS-PRTY],
	CASE 
		WHEN LEN(ltrim(rtrim(b.[pa-ins-plan-no]))) = '1'
			THEN CAST(CAST(LTRIM(RTRIM(B.[pa-ins-co-cd])) AS VARCHAR) + CONVERT(VARCHAR(1), 0) + CAST(LTRIM(RTRIM(B.[pa-ins-plan-no])) AS VARCHAR) AS VARCHAR)
		WHEN LEN(LTRIM(RTRIM(b.[pa-ins-plan-no]))) = '2'
			THEN CAST(CAST(LTRIM(RTRIM(B.[pa-ins-co-cd])) AS VARCHAR) + CAST(LTRIM(RTRIM(B.[pa-ins-plan-no])) AS VARCHAR) AS VARCHAR)
		ELSE 'SELF_PAY'
		END AS 'PA-INS-PLAN',
	B.[PA-LAST-INS-PAY-DATE],
	ISNULL(B.[PA-BAL-INS-PAY-AMT], 0) AS 'Ins-Pay-Amt',
	RANK() OVER (
		PARTITION BY A.[PA-PT-NO-WOSCD] ORDER BY b.[pa-bal-ins-pay-amt] ASC,
			b.[pa-ins-prty] ASC,
			b.[pa-ins-co-cd] ASC,
			b.[pa-ins-plan-no] ASC
		) AS 'RANK1',
	ISNULL([IM-IND], 0) AS 'IM-IND'
FROM [Distinct_Encounters_For_DSH] A
INNER JOIN [Echo_Active].DBO.INSURANCEINFORMATION B ON A.[PA-PT-NO-WOSCD] = B.[PA-PT-NO-WOSCD] --AND A.[PA-CTL-PAA-XFER-DATE]=B.[PA-CTL-PAA-XFER-DATE]
LEFT OUTER JOIN [SMS].[UHMC\smathesi].[IM_PATIENTS] C ON A.[PA-PT-NO-WOSCD] = C.[PA-PT-NO-WOSCD]
GO

--WHERE A.[PA-DELETE-DATE] IS NULL
---------------------------------------------------------------------------------------------------------------------------------------------------
/*Create Temp Table of Primary Payer Designations*/
DROP TABLE

IF EXISTS [Primary_Ins_Type]
	--GO
	-- Add new table
	CREATE TABLE [Primary_Ins_Type] (
		[PA-PT-NO-WOSCD] DECIMAL(11, 0) NOT NULL,
		[PA-PT-NO-SCD] CHAR(1) NOT NULL,
		[RANK1] CHAR(4),
		[PA-INS-PLAN] VARCHAR(100) NULL,
		[INDICATOR] VARCHAR(100) NOT NULL
		)

INSERT INTO [Primary_Ins_Type] (
	[PA-PT-NO-WOSCD],
	[PA-PT-NO-SCD],
	[RANK1],
	[PA-INS-PLAN],
	[INDICATOR]
	) --,[REPORT-GROUP])
SELECT [PA-PT-NO-WOSCD],
	[PA-PT-NO-SCD],
	[RANK1],
	[PA-INS-PLAN],
	CASE 
		WHEN [PA-INS-PLAN] IN ('D01', 'D02', 'D101', 'D102', 'D99')
			AND [RANK1] IN ('1')
			THEN 'PRIMARY MEDICAID'
				--WHEN LEFT([PA-INS-PLAN],1) = 'D' AND [PA-INS-PLAN] NOT IN ('D01','D02','D101','D102','D99','D03','D98') AND [RANK1] = '1'  THEN 'MEDICAID ELIGIBLE'
		WHEN LEFT([PA-INS-PLAN], 1) = 'H'
			AND [RANK1] = '1'
			THEN 'PRIMARY SELF PAY'
		WHEN LEFT([PA-INS-PLAN], 1) = 'U'
			AND [RANK1] = '1'
			THEN 'PRIMARY MANAGED MEDICAID'
		WHEN LEFT([PA-INS-PLAN], 1) IN ('A', 'B', 'M')
			AND [RANK1] = '1'
			THEN 'PRIMARY MEDICARE'
		WHEN [PA-INS-PLAN] IN ('K01', 'K20')
			AND [RANK1] = '1'
			THEN 'MEDICAID PENDING'
		WHEN [PA-INS-PLAN] IN ('D03', 'D98')
			AND [RANK1] = '1'
			THEN 'PRIMARY OUT OF STATE MEDICAID'
		WHEN LEFT([PA-INS-PLAN], 1) NOT IN ('D', 'H', 'U', 'A', 'B', 'M')
			AND [PA-INS-PLAN] NOT IN ('K01', 'K20')
			AND [RANK1] = '1'
			THEN 'OTHER PRIMARY PAYER'
		ELSE 'Non-Primary'
		END AS 'Indicator'
FROM [CUSTOMINSURANCE]
GO

--GROUP BY [PA-PT-NO-WOSCD],
--[PA-PT-NO-SCD],
--[pa-ins-PLAN],
--[rank1]
--select *  FROM DBO.PRIMARY_INS_TYPE
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*Create Temp Table of Secondary Indicators At The Plan Code Level*/
DROP TABLE

IF EXISTS [Secondary_Ins_Indicators_Detail]
	--GO
	-- Add new table
	CREATE TABLE [Secondary_Ins_Indicators_Detail] (
		[PA-PT-NO-WOSCD] DECIMAL(11, 0) NOT NULL,
		[PA-PT-NO-SCD] CHAR(1) NOT NULL,
		[PA-INS-PLAN] VARCHAR(100) NOT NULL,
		[INS-PAY-AMT] MONEY NULL,
		[2NDRY-MEDICAID-ELIGIBLE] DECIMAL(1, 0) NOT NULL,
		[2NDRY-MEDICAID-FFS] DECIMAL(1, 0) NOT NULL,
		[2NDRY-MEDICAID-PENDING-IND] DECIMAL(1, 0) NOT NULL,
		[2NDRY-MEDICAID-OUT-OF-STATE-IND] DECIMAL(1, 0) NOT NULL,
		[2NDRY-OTHER-INS-IND] DECIMAL(1, 0) NOT NULL,
		[2NDRY-MEDICARE-IND] DECIMAL(1, 0) NOT NULL,
		[2NDRY-SELF-PAY-IND] DECIMAL(1, 0) NOT NULL
		);

INSERT INTO [Secondary_Ins_Indicators_Detail] (
	[PA-PT-NO-WOSCD],
	[PA-PT-NO-SCD],
	[PA-INS-PLAN],
	[INS-PAY-AMT],
	[2NDRY-MEDICAID-ELIGIBLE],
	[2NDRY-MEDICAID-FFS],
	[2NDRY-MEDICAID-PENDING-IND],
	[2NDRY-MEDICAID-OUT-OF-STATE-IND],
	[2NDRY-OTHER-INS-IND],
	[2NDRY-MEDICARE-IND],
	[2NDRY-SELF-PAY-IND]
	) --,[REPORT-GROUP])
SELECT [PA-PT-NO-WOSCD],
	[PA-PT-NO-SCD],
	[PA-INS-PLAN],
	[INS-PAY-AMT],
	CASE 
		WHEN [RANK1] <> '1'
			AND LEFT([PA-INS-PLAN], 1) IN ('U', 'D')
			AND [PA-INS-PLAN] NOT IN ('D03', 'D98', 'D01', 'D02', 'D101', 'D102', 'D99')
			THEN 1
		WHEN [RANK1] <> '1'
			AND LEFT([PA-INS-PLAN], 1) NOT IN ('U', 'D')
			AND [IM-IND] = 'JAIL'
			THEN 1
		ELSE 0
		END AS '2NDRY-MEDICAID-ELIGIBLE',
	CASE 
		WHEN [RANK1] <> '1'
			AND [pa-ins-plan] IN ('D01', 'D02', 'D101', 'D102', 'D99')
			THEN 1
		ELSE 0
		END AS '2NDRY-MEDICAID-FFS',
	CASE 
		WHEN [RANK1] <> '1'
			AND [PA-INS-PLAN] IN ('K01', 'K20')
			THEN 1
		ELSE 0
		END AS '2NDRY-MEDICAID-PENDING-IND',
	CASE 
		WHEN [RANK1] <> '1'
			AND [PA-INS-PLAN] IN ('D03', 'D98')
			THEN 1
		ELSE 0
		END AS '2NDRY-MEDICAID-OUT-OF-STATE-IND',
	CASE 
		WHEN [RANK1] <> '1'
			AND LEFT([PA-INS-PLAN], 1) NOT IN ('D', 'U', 'A', 'B', 'M', 'H')
			AND [PA-INS-PLAN] NOT IN ('K01', 'K20')
			AND [IM-IND] <> 'JAIL'
			THEN 1
		ELSE 0
		END AS '2NDRY-OTHER-INS-IND',
	CASE 
		WHEN [RANK1] <> '1'
			AND LEFT([PA-INS-PLAN], 1) IN ('A', 'B', 'M')
			AND [IM-IND] <> 'JAIL'
			THEN 1
		ELSE 0
		END AS '2NDRY-MEDICARE-IND',
	CASE 
		WHEN [RANK1] <> '1'
			AND LEFT([PA-INS-PLAN], 1) = 'H'
			AND [IM-IND] <> 'JAIL'
			THEN 1
		ELSE 0
		END AS '2NDRY-SELF-PAY-IND'
FROM [CUSTOMINSURANCE]
GO

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*Create Secondary Indicator Summary At Encounter Level*/
DROP TABLE

IF EXISTS [Secondary_Ins_Indicators_Summary] GO
	--Add New Table
	CREATE TABLE [Secondary_Ins_Indicators_Summary] (
		[PA-PT-NO-WOSCD] DECIMAL(11, 0) NOT NULL,
		[PA-PT-NO-SCD] CHAR(1) NOT NULL,
		[2NDRY-MEDICAID-FFS] DECIMAL(1, 0) NOT NULL,
		[2NDRY-MEDICAID-ELIGIBLE] DECIMAL(1, 0) NOT NULL,
		[2NDRY-MEDICAID-PENDING-IND] DECIMAL(1, 0) NOT NULL,
		[2NDRY-MEDICAID-OUT-OF-STATE-IND] DECIMAL(1, 0) NOT NULL,
		[2NDRY-OTHER-INS-IND] DECIMAL(1, 0) NOT NULL,
		[2NDRY-MEDICARE-IND] DECIMAL(1, 0) NOT NULL,
		[2NDRY-SELF-PAY-IND] DECIMAL(1, 0) NOT NULL,
		[TOT-INS-PAYMTS] MONEY NULL
		);

INSERT INTO [Secondary_Ins_Indicators_Summary] (
	[PA-PT-NO-WOSCD],
	[PA-PT-NO-SCD],
	[2NDRY-MEDICAID-FFS],
	[2NDRY-MEDICAID-ELIGIBLE],
	[2NDRY-MEDICAID-PENDING-IND],
	[2NDRY-MEDICAID-OUT-OF-STATE-IND],
	[2NDRY-OTHER-INS-IND],
	[2NDRY-MEDICARE-IND],
	[2NDRY-SELF-PAY-IND],
	[TOT-INS-PAYMTS]
	) --,[REPORT-GROUP])
SELECT B.[pa-pt-no-woscd],
	B.[pa-pt-no-scd],
	sum(B.[2NDRY-MEDICAID-FFS]) AS '2NDRY-MEDICAID-FFS',
	SUM(b.[2NDRY-MEDICAID-ELIGIBLE]) AS '2NDRY-MEDICAID-ELIGIBLE',
	SUM(b.[2NDRY-MEDICAID-PENDING-IND]) AS '2NDRY-MEDICAID-PENDING-IND',
	SUM(b.[2NDRY-MEDICAID-OUT-OF-STATE-IND]) AS '2NDRY-MEDICAID-OUT-OF-STATE-IND',
	SUM(B.[2NDRY-OTHER-INS-IND]) AS '2NDRY-OTHER-INS-IND',
	SUM(B.[2NDRY-MEDICARE-IND]) AS '2NDRY-MEDICARE-IND',
	SUM(B.[2NDRY-SELF-PAY-IND]) AS '2NDRY-SELF-PAY-IND',
	SUM(B.[INS-PAY-AMT]) AS 'TOT-INS-PAYMTS'
FROM [Secondary_Ins_Indicators_Detail] B
GROUP BY B.[pa-pt-no-woscd],
	B.[pa-pt-no-scd]
GO

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--SELECT *  FROM [#SECONDARY_INS_INDICATORS_DETAIL] 
----WHERE [PA-PT-NO-WOSCD] IN('1012317563','1012055193')
--WHERE [MEDICAID-NON-PRIME-IND]='1' AND LEFT([PA-INS-PLAN],1) NOT IN ('U','D')
--SELECT MAX([rank1])
--FROM [custominsurance]
/*Pivot Insurance Data*/
DROP TABLE

IF EXISTS DSH_INSURANCE_TABLE_W_REPORT_GROUPS
	SELECT a.[PA-PT-NO-WOSCD],
		a.[PA-PT-NO-SCD],
		a.[PA-CTL-PAA-XFER-DATE],
		a.[pa-unit-no],
		a.[pa-med-rec-no],
		a.[pa-pt-name],
		a.[admit_date],
		a.[dsch_date],
		a.[pa-unit-date],
		a.[pa-acct-type],
		CASE 
			WHEN a.[pa-acct-type] IN ('0', '6', '7')
				THEN 'OP'
			WHEN a.[pa-acct-type] IN ('1', '2', '4', '8')
				THEN 'IP'
			ELSE ''
			END AS [PtAcct-Type],
		b.[rank1] AS 'COB1',
		b.[pa-ins-plan] AS 'INS1',
		c.[rank1] AS 'COB2',
		c.[pa-ins-plan] AS 'INS2',
		d.[rank1] AS 'COB3',
		d.[pa-ins-plan] AS 'INS3',
		e.[rank1] AS 'COB4',
		e.[pa-ins-plan] AS 'INS4',
		f.[rank1] AS 'COB5',
		f.[pa-ins-plan] AS 'INS5',
		g.[rank1] AS 'COB6',
		g.[pa-ins-plan] AS 'INS6',
		h.[rank1] AS 'COB7',
		h.[pa-ins-plan] AS 'INS7',
		CASE 
			WHEN i.[indicator] = 'PRIMARY MEDICAID'
				AND j.[2NDRY-MEDICAID-ELIGIBLE] = '0'
				AND J.[2NDRY-MEDICAID-OUT-OF-STATE-IND] = '0'
				AND J.[2NDRY-MEDICAID-PENDING-IND] = '0'
				AND J.[2NDRY-MEDICARE-IND] = '0'
				AND J.[2NDRY-OTHER-INS-IND] = '0'
				THEN 'PRIMARY MEDICAID'
			WHEN i.[indicator] = 'PRIMARY MEDICAID'
				AND (
					J.[2NDRY-MEDICAID-ELIGIBLE] > '0'
					OR J.[2NDRY-MEDICARE-IND] > '0'
					OR J.[2NDRY-OTHER-INS-IND] > '0'
					)
				AND J.[2NDRY-MEDICAID-OUT-OF-STATE-IND] = '0'
				AND J.[2NDRY-MEDICAID-PENDING-IND] = '0'
				THEN 'MEDICAID FFS DUAL ELIGIBLE'
					--WHEN I.[INDICATOR] = 'PRIMARY MEDICAID' AND J.[2NDRY-MEDICARE-IND]>'0' THEN 'DUAL ELIGIBLE'
			WHEN I.[INDICATOR] = 'PRIMARY MANAGED MEDICAID'
				AND j.[2NDRY-MEDICAID-ELIGIBLE] = '0'
				AND J.[2NDRY-MEDICAID-OUT-OF-STATE-IND] = '0'
				AND J.[2NDRY-MEDICAID-PENDING-IND] = '0'
				AND J.[2NDRY-MEDICARE-IND] = '0'
				AND J.[2NDRY-OTHER-INS-IND] = '0'
				AND J.[2NDRY-MEDICAID-OUT-OF-STATE-IND] = '0'
				THEN 'PRIMARY MEDICAID MANAGED CARE'
			WHEN I.[INDICATOR] = 'PRIMARY MANAGED MEDICAID'
				AND (
					j.[2NDRY-MEDICAID-ELIGIBLE] > '0'
					OR J.[2NDRY-MEDICAID-OUT-OF-STATE-IND] > '0'
					OR J.[2NDRY-MEDICAID-PENDING-IND] > '0'
					OR J.[2NDRY-MEDICARE-IND] > '0'
					OR J.[2NDRY-OTHER-INS-IND] > '0'
					OR J.[2NDRY-MEDICARE-IND] > '0'
					)
				THEN 'MEDICAID MANAGED CARE DUAL ELIGIBLE'
					--WHEN I.[INDICATOR] = 'PRIMARY MANAGED MEDICAID' AND J.[2NDRY-MEDICARE-IND]>'0' THEN 'DUAL ELIGIBLE'
			WHEN I.[INDICATOR] = 'PRIMARY SELF PAY'
				THEN 'PRIMARY SELF PAY'
			WHEN I.[INDICATOR] = 'PRIMARY OUT OF STATE MEDICAID'
				AND j.[2NDRY-MEDICAID-ELIGIBLE] = '0'
				AND J.[2NDRY-MEDICAID-OUT-OF-STATE-IND] = '0'
				AND J.[2NDRY-MEDICAID-PENDING-IND] = '0'
				AND J.[2NDRY-MEDICARE-IND] = '0'
				AND J.[2NDRY-OTHER-INS-IND] = '0'
				THEN 'PRIMARY OUT OF STATE MEDICAID'
			WHEN I.[INDICATOR] = 'PRIMARY OUT OF STATE MEDICAID'
				AND (
					j.[2NDRY-MEDICAID-ELIGIBLE] > '0'
					OR J.[2NDRY-MEDICAID-OUT-OF-STATE-IND] > '0'
					OR J.[2NDRY-MEDICAID-PENDING-IND] > '0'
					AND J.[2NDRY-MEDICARE-IND] > '0'
					OR J.[2NDRY-OTHER-INS-IND] > '0'
					)
				THEN 'DUAL ELIGIBLE OUT OF STATE MEDICAID'
			WHEN I.[INDICATOR] IN ('OTHER PRIMARY PAYER', 'PRIMARY MEDICARE')
				AND (
					j.[2ndry-medicaid-ffs] > '0'
					AND J.[2NDRY-MEDICAID-ELIGIBLE] = '0'
					AND J.[2NDRY-MEDICAID-OUT-OF-STATE-IND] = '0'
					)
				THEN 'MEDICAID FFS DUAL ELIGIBLE'
			WHEN I.[INDICATOR] IN ('OTHER PRIMARY PAYER', 'PRIMARY MEDICARE')
				AND (
					J.[2NDRY-MEDICAID-FFS] > '0'
					AND J.[2NDRY-MEDICAID-ELIGIBLE] > '0'
					AND J.[2NDRY-MEDICAID-OUT-OF-STATE-IND] = '0'
					)
				THEN 'MEDICAID MANAGED CARE DUAL ELIGIBLE'
			WHEN I.[INDICATOR] IN ('OTHER PRIMARY PAYER', 'PRIMARY MEDICARE')
				AND (
					J.[2NDRY-MEDICAID-FFS] = '0'
					AND J.[2NDRY-MEDICAID-ELIGIBLE] = '0'
					AND J.[2NDRY-MEDICAID-OUT-OF-STATE-IND] > '0'
					)
				THEN 'DUAL ELIGIBLE OUT OF STATE MEDICAID'
			WHEN I.[INDICATOR] IS NULL
				THEN 'PRIMARY SELF PAY'
					--when I.[INDICATOR] ='PRIMARY MEDICAID'
					--and [2NDRY-OTHER-INS-IND] <>'0'
					--then 
			ELSE ''
			END AS 'REPORTING GROUP',
		CASE 
			WHEN i.[indicator] = 'PRIMARY MEDICAID'
				AND j.[2NDRY-MEDICAID-ELIGIBLE] = '0'
				AND J.[2NDRY-MEDICAID-OUT-OF-STATE-IND] = '0'
				AND J.[2NDRY-MEDICAID-PENDING-IND] = '0'
				AND J.[2NDRY-MEDICARE-IND] = '0'
				AND J.[2NDRY-OTHER-INS-IND] = '0'
				THEN 'PRIMARY MEDICAID'
			ELSE ''
			END AS 'TEST-PRIMARY-MEDICAID',
		CASE 
			WHEN i.[indicator] = 'PRIMARY MEDICAID'
				AND (
					J.[2NDRY-MEDICAID-ELIGIBLE] > '0'
					OR J.[2NDRY-MEDICARE-IND] > '0'
					OR J.[2NDRY-OTHER-INS-IND] > '0'
					)
				AND J.[2NDRY-MEDICAID-OUT-OF-STATE-IND] > '0'
				AND J.[2NDRY-MEDICAID-PENDING-IND] = '0'
				AND J.[2NDRY-MEDICARE-IND] = '0'
				THEN 'MEDICAID FFS DUAL ELIGIBLE'
			ELSE ''
			END AS 'TEST-MEDICIAD-FFS-DUAL-ELIGIBLE',
		CASE 
			WHEN I.[INDICATOR] = 'PRIMARY MANAGED MEDICAID'
				AND j.[2NDRY-MEDICAID-ELIGIBLE] = '0'
				AND J.[2NDRY-MEDICAID-OUT-OF-STATE-IND] = '0'
				AND J.[2NDRY-MEDICAID-PENDING-IND] = '0'
				AND J.[2NDRY-MEDICARE-IND] = '0'
				AND J.[2NDRY-OTHER-INS-IND] = '0'
				AND J.[2NDRY-MEDICAID-OUT-OF-STATE-IND] = '0'
				THEN 'PRIMARY MEDICAID MANAGED CARE'
			ELSE ''
			END AS 'TEST-PRIMARY-MEDICAID-MANAGED-CARE',
		CASE 
			WHEN I.[INDICATOR] = 'PRIMARY MANAGED MEDICAID'
				AND (
					j.[2NDRY-MEDICAID-ELIGIBLE] > '0'
					OR J.[2NDRY-MEDICAID-OUT-OF-STATE-IND] > '0'
					OR J.[2NDRY-MEDICAID-PENDING-IND] > '0'
					OR J.[2NDRY-MEDICARE-IND] > '0'
					OR J.[2NDRY-OTHER-INS-IND] > '0'
					OR J.[2NDRY-MEDICARE-IND] > '0'
					)
				THEN 'MEDICAID MANAGED CARE DUAL ELIGIBLE'
			ELSE ''
			END AS 'TEST-MEDICAID-MGD-CARE-DUAL-ELIG',
		CASE 
			WHEN I.[INDICATOR] = 'PRIMARY SELF PAY'
				THEN 'PRIMARY SELF PAY'
			ELSE ''
			END AS 'TEST-PRIMARY-SELF-PAY',
		CASE 
			WHEN I.[INDICATOR] = 'PRIMARY OUT OF STATE MEDICAID'
				AND j.[2NDRY-MEDICAID-ELIGIBLE] = '0'
				AND J.[2NDRY-MEDICAID-OUT-OF-STATE-IND] = '0'
				AND J.[2NDRY-MEDICAID-PENDING-IND] = '0'
				AND J.[2NDRY-MEDICARE-IND] = '0'
				AND J.[2NDRY-OTHER-INS-IND] = '0'
				THEN 'PRIMARY OUT OF STATE MEDICAID'
			ELSE ''
			END AS 'TEST-PRIMARY-OUT-OF-STATE-MEDICAID',
		CASE 
			WHEN I.[INDICATOR] = 'PRIMARY OUT OF STATE MEDICAID'
				AND (
					j.[2NDRY-MEDICAID-ELIGIBLE] > '0'
					OR J.[2NDRY-MEDICAID-OUT-OF-STATE-IND] > '0'
					OR J.[2NDRY-MEDICAID-PENDING-IND] > '0'
					AND J.[2NDRY-MEDICARE-IND] > '0'
					OR J.[2NDRY-OTHER-INS-IND] > '0'
					)
				THEN 'DUAL ELIGIBLE OUT OF STATE MEDICAID'
			ELSE ''
			END AS 'TEST-DUAL-ELIG-OUT-OF-STATE-MEDICAID',
		CASE 
			WHEN I.[INDICATOR] IN ('OTHER PRIMARY PAYER', 'PRIMARY MEDICARE')
				AND (
					j.[2ndry-medicaid-ffs] > '0'
					AND J.[2NDRY-MEDICAID-ELIGIBLE] = '0'
					AND J.[2NDRY-MEDICAID-OUT-OF-STATE-IND] = '0'
					)
				THEN 'MEDICAID FFS DUAL ELIGIBLE'
			ELSE ''
			END AS 'TEST-MEDICAID-FFS-DUAL-ELIG-2',
		CASE 
			WHEN I.[INDICATOR] IN ('OTHER PRIMARY PAYER', 'PRIMARY MEDICARE')
				AND (
					J.[2NDRY-MEDICAID-FFS] > '0'
					AND J.[2NDRY-MEDICAID-ELIGIBLE] > '0'
					AND J.[2NDRY-MEDICAID-OUT-OF-STATE-IND] = '0'
					)
				THEN 'MEDICAID MANAGED CARE DUAL ELIGIBLE'
			ELSE ''
			END AS 'TEST-MEDICAID-MGD-DUAL-ELIG-2',
		CASE 
			WHEN I.[INDICATOR] IN ('OTHER PRIMARY PAYER', 'PRIMARY MEDICARE')
				AND (
					J.[2NDRY-MEDICAID-FFS] = '0'
					AND J.[2NDRY-MEDICAID-ELIGIBLE] = '0'
					AND J.[2NDRY-MEDICAID-OUT-OF-STATE-IND] > '0'
					)
				THEN 'DUAL ELIGIBLE OUT OF STATE MEDICAID'
			ELSE ''
			END AS 'TEST-DUAL-ELIG-OUT-OF-STATE-MCAID-2',
		CASE 
			WHEN I.[INDICATOR] IS NULL
				THEN 'PRIMARY SELF PAY'
			ELSE ''
			END AS 'TEST-PRIMARY-SELF-PAY-2',
		isnull(i.[indicator], 'SELF PAY') AS 'PRIMARY-TYPE',
		j.[2NDRY-MEDICAID-ELIGIBLE],
		j.[2NDRY-MEDICAID-PENDING-IND],
		j.[2NDRY-MEDICAID-OUT-OF-STATE-IND],
		j.[2NDRY-OTHER-INS-IND],
		j.[2NDRY-MEDICARE-IND],
		j.[2NDRY-SELF-PAY-IND],
		J.[TOT-INS-PAYMTS],
		k.[im-ind]
	INTO [DSH_INSURANCE_TABLE_W_REPORT_GROUPS]
	FROM [Encounters_For_DSH] a
	LEFT OUTER JOIN [CUSTOMINSURANCE] b ON a.[pa-pt-no-woscd] = b.[pa-pt-no-woscd]
		AND b.[rank1] = '1'
	LEFT OUTER JOIN [CUSTOMINSURANCE] c ON a.[pa-pt-no-woscd] = c.[pa-pt-no-woscd]
		AND c.[rank1] = '2'
	LEFT OUTER JOIN [CUSTOMINSURANCE] d ON a.[pa-pt-no-woscd] = d.[pa-pt-no-woscd]
		AND d.[rank1] = '3'
	LEFT OUTER JOIN [CUSTOMINSURANCE] e ON a.[pa-pt-no-woscd] = e.[pa-pt-no-woscd]
		AND e.[rank1] = '4'
	LEFT OUTER JOIN [CUSTOMINSURANCE] f ON a.[pa-pt-no-woscd] = f.[pa-pt-no-woscd]
		AND f.[rank1] = '5'
	LEFT OUTER JOIN [CUSTOMINSURANCE] g ON a.[pa-pt-no-woscd] = g.[pa-pt-no-woscd]
		AND g.[rank1] = '6'
	LEFT OUTER JOIN [CUSTOMINSURANCE] h ON a.[pa-pt-no-woscd] = h.[pa-pt-no-woscd]
		AND h.[rank1] = '7'
	LEFT OUTER JOIN [Primary_Ins_Type] i ON a.[pa-pt-no-woscd] = i.[pa-pt-no-woscd]
		AND i.[rank1] = '1'
	LEFT OUTER JOIN [Secondary_Ins_Indicators_Summary] j ON a.[pa-pt-no-woscd] = j.[pa-pt-no-woscd]
	LEFT OUTER JOIN [IM_Patients] k ON a.[pa-pt-no-woscd] = k.[pa-pt-no-woscd]
		--WHERE [INDICATOR] = 'PRIMARY SELF PAY' AND J.[2NDRY-MEDICAID-ELIGIBLE]>'0'
		--AND (J.[2NDRY-MEDICAID-ELIGIBLE]>'0' OR J.[2NDRY-MEDICAID-OUT-OF-STATE-IND]> '0' OR J.[2NDRY-MEDICAID-PENDING-IND]>'0')
		----WHERE [indicator] = 'PRIMARY SELF PAY' --AND (c.[pa-ins-plan] in ('d03','d98') or d.[pa-ins-plan] in ('d03','d98')))--(j.[MEDICAID-ELIGIBLE]>'0' OR j.[MEDICAID-OUT-OF-STATE-NON-PRIME-IND]>'0' or j.[MEDICAID-PENDING-NON-PRIME-IND]>'0')
		--and (j.[2NDRY-MEDICAID-ELIGIBLE]>'0' OR j.[2NDRY-MEDICAID-PENDING-IND]>'0' OR j.[2NDRY-MEDICAID-OUT-OF-STATE-IND]>'0' OR j.[2NDRY-MEDICAID-OUT-OF-STATE-PENDING-IND]>'0' OR j.[2NDRY-OTHER-INS-IND] > '0' OR j.[2NDRY-MEDICARE-IND] >'0')
		--k.[im-ind]
		--WHERE K.[IM-IND] IS NOT NULL
GO

SELECT *
FROM [DSH_INSURANCE_TABLE_W_REPORT_GROUPS]
--where ([REPORTING GROUP] <>'' and [primary-type] <>'other primary payer')
ORDER BY 'primary-type'
