/*

Description:
Create Reporting Groups for DSH

*/
USE [DSH_2019];

--SET ANSI_WARNINGS OFF;
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-----------------------------------------------------------------------
/*

Create Table For Inpatient Inmate Patients

*/
DROP TABLE IF EXISTS dbo.IM_Patients

CREATE TABLE dbo.[IM_Patients] (
	[PA-PT-NO-WOSCD] DECIMAL(11, 0) NOT NULL,
	[PA-PT-NO-SCD] CHAR(1) NOT NULL,
	[IM-IND] VARCHAR(50) NOT NULL,
	[PA-ACCT-TYPE] CHAR(5) NULL
	)

INSERT INTO dbo.IM_Patients (
	[PA-PT-NO-WOSCD],
	[PA-PT-NO-SCD],
	[IM-IND],
	[PA-ACCT-TYPE]
	)
SELECT [pa-pt-no-woscd],
	[pa-pt-no-scd-1],
	'JAIL' AS 'IM-IND',
	[PA-ACCT-TYPE]
FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_ACTIVE].dbo.[NADInformation]
WHERE [pa-nad-cd] = 'PTGAR'
	AND [pa-acct-type] NOT IN ('0', '6', '7') -- exclude outpatient codes
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
	'JAIL' AS 'IM-IND',
	[PA-ACCT-TYPE]
FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_ARCHIVE].dbo.[NADInformation]
WHERE [pa-nad-cd] = 'PTGAR'
	AND [pa-acct-type] NOT IN ('0', '6', '7') -- exclude outpatient codes
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
-----------------------------------------------------------------------
/*

Get listing of disctinct encounters for DSH
Think of this as the base population for DSH encounters
This helps with insurance rankings as insurance exists at the
encounter level and does not differ at the unit level.

*/
DROP TABLE IF EXISTS dbo.[DISTINCT_ENCOUNTERS_FOR_DSH]
	
CREATE TABLE dbo.[DISTINCT_ENCOUNTERS_FOR_DSH] (
	[PA-PT-NO-WOSCD] DECIMAL(11, 0) NOT NULL,
	[PA-PT-NO-SCD] CHAR(1) NOT NULL,
	[PA-CTL-PAA-XFER-DATE] DATETIME NULL
	);

INSERT INTO dbo.[DISTINCT_ENCOUNTERS_FOR_DSH] (
	[PA-PT-NO-WOSCD],
	[PA-PT-NO-SCD],
	[PA-CTL-PAA-XFER-DATE]
	)
SELECT [PA-PT-NO-WOSCD],
	[PA-PT-NO-SCD],
	[PA-CTL-PAA-XFER-DATE]
FROM dbo.[ENCOUNTERS_FOR_DSH]
	--GROUP BY [PA-PT-NO-WOSCD],
	--	[PA-PT-NO-SCD],
	--	[PA-CTL-PAA-XFER-DATE]
GO

-----------------------------------------------------------------------
/*

Create Custom Insurance Table
This is done to ensure an accurate ranking of COB's. This is done in case
of duplicative insurance priorities.

Ranking is based upon the following ordering criteria:
come back to this and re-visit order by clause after review of groupings

1. b.[pa-bal-ins-pay-amt] ASC (Ascending due to payments being a negative against AR, so the most negative paid the most on the account)
2. b.[pa-ins-prty] ASC - Insurance Priority Code
3. b.[pa-ins-co-cd] ASC - Insurance Plan - Alpha Code
4. b.[pa-ins-plan-no] ASC - Insurance Plan Number - Numeric Code

EDIT 5/2/2021 SPS
RE-WRITE CUSTOM INSURANCE TABLE LOGIC TO FIX THE RANKING ISSUE

*/
DROP TABLE IF EXISTS #TEMP_CUSTOM_INS
SELECT A.*
INTO #TEMP_CUSTOM_INS
FROM (
	SELECT DISTINCT (A.[PA-PT-NO-WOSCD]),
		A.[PA-PT-NO-SCD],
		B.[PA-CTL-PAA-XFER-DATE],
		B.[PA-INS-PRTY],
		CASE 
			WHEN LEN(ltrim(rtrim(b.[pa-ins-plan-no]))) = '1'
				THEN CAST(CAST(LTRIM(RTRIM(B.[pa-ins-co-cd])) AS VARCHAR) + CONVERT(VARCHAR(1), 0) + CAST(LTRIM(RTRIM(B.[pa-ins-plan-no])) AS VARCHAR) AS VARCHAR)
			WHEN LEN(LTRIM(RTRIM(b.[pa-ins-plan-no]))) = '2'
				THEN CAST(CAST(LTRIM(RTRIM(B.[pa-ins-co-cd])) AS VARCHAR) + CAST(LTRIM(RTRIM(B.[pa-ins-plan-no])) AS VARCHAR) AS VARCHAR)
			ELSE 'SELF_PAY'
			END AS 'PA-INS-PLAN',
		B.[PA-LAST-INS-PAY-DATE],
		B.[PA-LAST-INS-BL-DATE] AS 'PA-LAST-INS-BILL-DATE',
		ISNULL(B.[PA-BAL-INS-PAY-AMT], 0) AS 'Ins-Pay-Amt',
		RANK() OVER (
			PARTITION BY A.[PA-PT-NO-WOSCD],
			-- EDIT SPS 12/14/2021
			A.[PA-PT-NO-SCD],
			-- END EDIT SPS
			B.[PA-CTL-PAA-XFER-DATE] ORDER BY b.[pa-bal-ins-pay-amt] ASC,
				b.[pa-ins-prty] ASC,
				b.[pa-ins-co-cd] ASC,
				b.[pa-ins-plan-no] ASC
			) AS 'RANK1',
		ISNULL([IM-IND], 0) AS 'IM-IND'
	FROM dbo.[Distinct_Encounters_For_DSH] A
	-- THE BELOW JOIN IS PULLING IN AGGREGATE PAYMENTS OVER ALL TIME FOR THE DSH IDENTIFIED ENCOUNTERS, NOT JUST THE DSH YEAR IN QUESTION (DISCOVERED 01-07-2020, DOES THIS AFFECT DOWNSTREAM WORK?)
	--EXAMPLE ACCOUNT [PT-NO] = '10105953581'
	INNER JOIN [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_ARCHIVE].dbo.INSURANCEINFORMATION B ON A.[PA-PT-NO-WOSCD] = B.[PA-PT-NO-WOSCD]
	LEFT OUTER JOIN dbo.[IM_PATIENTS] C ON A.[PA-PT-NO-WOSCD] = C.[PA-PT-NO-WOSCD]

	UNION

	SELECT DISTINCT (A.[PA-PT-NO-WOSCD]),
		A.[PA-PT-NO-SCD],
		B.[PA-CTL-PAA-XFER-DATE],
		B.[PA-INS-PRTY],
		CASE 
			WHEN LEN(ltrim(rtrim(b.[pa-ins-plan-no]))) = '1'
				THEN CAST(CAST(LTRIM(RTRIM(B.[pa-ins-co-cd])) AS VARCHAR) + CONVERT(VARCHAR(1), 0) + CAST(LTRIM(RTRIM(B.[pa-ins-plan-no])) AS VARCHAR) AS VARCHAR)
			WHEN LEN(LTRIM(RTRIM(b.[pa-ins-plan-no]))) = '2'
				THEN CAST(CAST(LTRIM(RTRIM(B.[pa-ins-co-cd])) AS VARCHAR) + CAST(LTRIM(RTRIM(B.[pa-ins-plan-no])) AS VARCHAR) AS VARCHAR)
			ELSE 'SELF_PAY'
			END AS 'PA-INS-PLAN',
		B.[PA-LAST-INS-PAY-DATE],
		B.[PA-LAST-INS-BL-DATE] AS 'PA-LAST-INS-BILL-DATE',
		ISNULL(B.[PA-BAL-INS-PAY-AMT], 0) AS 'Ins-Pay-Amt',
		RANK() OVER (
			PARTITION BY A.[PA-PT-NO-WOSCD],
			-- EDIT SPS 12/14/2021
			A.[PA-PT-NO-SCD],
			-- END EDIT SPS
			B.[PA-CTL-PAA-XFER-DATE] ORDER BY b.[pa-bal-ins-pay-amt] ASC,
				b.[pa-ins-prty] ASC,
				b.[pa-ins-co-cd] ASC,
				b.[pa-ins-plan-no] ASC
			) AS 'RANK1',
		ISNULL([IM-IND], 0) AS 'IM-IND'
	FROM dbo.[DISTINCT_ENCOUNTERS_FOR_DSH] A
	INNER JOIN [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_ACTIVE].dbo.INSURANCEINFORMATION B ON A.[PA-PT-NO-WOSCD] = B.[PA-PT-NO-WOSCD]
	LEFT OUTER JOIN [dbo].[IM_PATIENTS] C ON A.[PA-PT-NO-WOSCD] = C.[PA-PT-NO-WOSCD]
) AS A;

DROP TABLE IF EXISTS dbo.CUSTOMINSURANCE
GO

CREATE TABLE dbo.CUSTOMINSURANCE (
	[PA-PT-NO-WOSCD] DECIMAL(11, 0) NOT NULL,
	[PA-PT-NO-SCD] CHAR(1) NOT NULL,
	[PA-CTL-PAA-XFER-DATE] DATETIME NULL,
	[PA-INS-PRTY] DECIMAL(1, 0) NULL,
	[PA-INS-PLAN] VARCHAR(100) NULL,
	[PA-LAST-INS-PAY-DATE] DATETIME NULL,
	[PA-LAST-INS-BILL-DATE] DATETIME NULL,
	[INS-PAY-AMT] MONEY NULL,
	[RANK1] CHAR(4) NULL,
	[IM-IND] VARCHAR(50) NULL
	);

INSERT INTO dbo.[CUSTOMINSURANCE] (
	[PA-PT-NO-WOSCD],
	[PA-PT-NO-SCD],
	[PA-CTL-PAA-XFER-DATE],
	[PA-INS-PRTY],
	[PA-INS-PLAN],
	[PA-LAST-INS-PAY-DATE],
	[PA-LAST-INS-BILL-DATE],
	[INS-PAY-AMT],
	[RANK1],
	[IM-IND]
	)
SELECT A.[PA-PT-NO-WOSCD],
[PA-PT-NO-SCD],
[PA-CTL-PAA-XFER-DATE],
[PA-INS-PRTY],
[PA-INS-PLAN],
[PA-LAST-INS-PAY-DATE],
[PA-LAST-INS-BILL-DATE],
[INS-PAY-AMT],
[RANK1_FINAL] = ROW_NUMBER() OVER(
	PARTITION BY [PA-PT-NO-WOSCD], [PA-PT-NO-SCD], [PA-CTL-PAA-XFER-DATE]
	ORDER BY CAST([RANK1] AS INT)
	),
[IM-IND]
FROM #TEMP_CUSTOM_INS AS A


--WHERE A.[PA-DELETE-DATE] IS NULL
-----------------------------------------------------------------------
/*

Create Temp Table of Primary Payer Designations
This is the I.[indicator] below
Only considers rank 1 insurances from the custom insurance table

*/
DROP TABLE IF EXISTS dbo.[Primary_Ins_Type]

CREATE TABLE dbo.[Primary_Ins_Type] (
	[PA-PT-NO-WOSCD] DECIMAL(11, 0) NOT NULL,
	[PA-PT-NO-SCD] CHAR(1) NOT NULL,
	[PA-CTL-PAA-XFER-DATE] DATETIME NULL,
	[RANK1] CHAR(4),
	[PA-INS-PLAN] VARCHAR(100) NULL,
	[INDICATOR] VARCHAR(100) NOT NULL
	)

INSERT INTO dbo.[Primary_Ins_Type] (
	[PA-PT-NO-WOSCD],
	[PA-PT-NO-SCD],
	[PA-CTL-PAA-XFER-DATE],
	[RANK1],
	[PA-INS-PLAN],
	[INDICATOR]
	)
SELECT [PA-PT-NO-WOSCD],
	[PA-PT-NO-SCD],
	[PA-CTL-PAA-XFER-DATE],
	[RANK1],
	[PA-INS-PLAN],
	CASE 
		WHEN [PA-INS-PLAN] IN ('D01', 'D02', 'D101', 'D102', 'D99')
			AND [RANK1] IN ('1')
			THEN 'PRIMARY MEDICAID'
		WHEN (
				LEFT([PA-INS-PLAN], 1) IN ('H')
				OR [PA-INS-PLAN] = 'SELF_PAY'
				)
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
		WHEN (
				LEFT([PA-INS-PLAN], 1) NOT IN ('D', 'H', 'U', 'A', 'B', 'M')
				OR [PA-INS-PLAN] = 'SELF_PAY'
				)
			AND [PA-INS-PLAN] NOT IN ('K01', 'K20')
			AND [RANK1] = '1'
			THEN 'OTHER PRIMARY PAYER'
		ELSE 'Non-Primary'
		END AS 'Indicator'
FROM dbo.[CUSTOMINSURANCE]
GO

--select *  FROM DBO.PRIMARY_INS_TYPE
-----------------------------------------------------------------------
/*

Create Temp Table of Secondary Indicators At The Plan Code Level

*/
DROP TABLE IF EXISTS dbo.[Secondary_Ins_Indicators_Detail]
GO
-- Add new table
CREATE TABLE dbo.[Secondary_Ins_Indicators_Detail] (
	[PA-PT-NO-WOSCD] DECIMAL(11, 0) NOT NULL,
	[PA-PT-NO-SCD] CHAR(1) NOT NULL,
	[PA-CTL-PAA-XFER-DATE] DATETIME NULL,
	[PA-INS-PLAN] VARCHAR(100) NOT NULL,
	[INS-PAY-AMT] MONEY NULL,
	[2NDRY-MEDICAID-ELIGIBLE] DECIMAL(1, 0) NOT NULL,
	[2NDRY-MEDICAID-FFS] DECIMAL(1, 0) NOT NULL,
	[2NDRY-MEDICAID-PENDING-IND] DECIMAL(1, 0) NOT NULL,
	[2NDRY-MEDICAID-OUT-OF-STATE-IND] DECIMAL(1, 0) NOT NULL,
	[2NDRY-OTHER-INS-IND] DECIMAL(1, 0) NOT NULL,
	[2NDRY-MEDICARE-IND] DECIMAL(1, 0) NOT NULL,
	[2NDRY-SELF-PAY-IND] DECIMAL(1, 0) NOT NULL,
	[2NDRY-MEDICAID-MANAGED] DECIMAL(1, 0) NOT NULL
	);

INSERT INTO dbo.[Secondary_Ins_Indicators_Detail] (
	[PA-PT-NO-WOSCD],
	[PA-PT-NO-SCD],
	[PA-CTL-PAA-XFER-DATE],
	[PA-INS-PLAN],
	[INS-PAY-AMT],
	[2NDRY-MEDICAID-ELIGIBLE],
	[2NDRY-MEDICAID-FFS],
	[2NDRY-MEDICAID-PENDING-IND],
	[2NDRY-MEDICAID-OUT-OF-STATE-IND],
	[2NDRY-OTHER-INS-IND],
	[2NDRY-MEDICARE-IND],
	[2NDRY-SELF-PAY-IND],
	[2NDRY-MEDICAID-MANAGED]
	)
SELECT [PA-PT-NO-WOSCD],
	[PA-PT-NO-SCD],
	[PA-CTL-PAA-XFER-DATE],
	[PA-INS-PLAN],
	[INS-PAY-AMT],
	CASE 
		-- DO NOT DELETE UNTIL YOU HAVE RE-RUN AND CHECKED ALL REPORT GROUP AMOUNTS
		--WHEN [RANK1] <> '1'
		--       AND LEFT([PA-INS-PLAN], 1) IN ('D')
		--       AND [PA-INS-PLAN] NOT IN ('D03', 'D98', 'D01', 'D02', 'D101', 'D102', 'D99')
		--       THEN 1
		WHEN [RANK1] <> '1'
			AND LEFT([PA-INS-PLAN], 1) NOT IN ('D')
			AND [IM-IND] = 'JAIL'
			THEN 1
		ELSE 0
		END AS '2NDRY-MEDICAID-ELIGIBLE',
	CASE 
		WHEN [RANK1] <> '1'
			AND [pa-ins-plan] IN ('D01', 'D02', 'D101', 'D102', 'D99')
			THEN 1
		WHEN [IM-IND] = 'JAIL'
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
		END AS '2NDRY-SELF-PAY-IND',
	CASE 
		WHEN [RANK1] <> 1
			AND LEFT([PA-INS-PLAN], 1) IN ('U')
			THEN 1
		ELSE 0
		END AS '2NDRY-MEDICAID-MANAGED'
FROM dbo.[CUSTOMINSURANCE]
GO

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*

Create Secondary Indicator Summary At Encounter Level

*/
DROP TABLE IF EXISTS dbo.[Secondary_Ins_Indicators_Summary] 
GO
--Add New Table
CREATE TABLE dbo.[Secondary_Ins_Indicators_Summary] (
	[PA-PT-NO-WOSCD] DECIMAL(11, 0) NOT NULL,
	[PA-PT-NO-SCD] CHAR(1) NOT NULL,
	[PA-CTL-PAA-XFER-DATE] DATETIME NULL,
	[2NDRY-MEDICAID-FFS] DECIMAL(1, 0) NOT NULL,
	[2NDRY-MEDICAID-ELIGIBLE] DECIMAL(1, 0) NOT NULL,
	[2NDRY-MEDICAID-PENDING-IND] DECIMAL(1, 0) NOT NULL,
	[2NDRY-MEDICAID-OUT-OF-STATE-IND] DECIMAL(1, 0) NOT NULL,
	[2NDRY-OTHER-INS-IND] DECIMAL(1, 0) NOT NULL,
	[2NDRY-MEDICARE-IND] DECIMAL(1, 0) NOT NULL,
	[2NDRY-SELF-PAY-IND] DECIMAL(1, 0) NOT NULL,
	[2NDRY-MEDICAID-MANAGED] DECIMAL(1, 0) NOT NULL,
	[TOT-INS-PAYMTS] MONEY NULL
	);

INSERT INTO dbo.[Secondary_Ins_Indicators_Summary] (
	[PA-PT-NO-WOSCD],
	[PA-PT-NO-SCD],
	[PA-CTL-PAA-XFER-DATE],
	[2NDRY-MEDICAID-FFS],
	[2NDRY-MEDICAID-ELIGIBLE],
	[2NDRY-MEDICAID-PENDING-IND],
	[2NDRY-MEDICAID-OUT-OF-STATE-IND],
	[2NDRY-OTHER-INS-IND],
	[2NDRY-MEDICARE-IND],
	[2NDRY-SELF-PAY-IND],
	[2NDRY-MEDICAID-MANAGED],
	[TOT-INS-PAYMTS]
	)
SELECT B.[pa-pt-no-woscd],
	B.[pa-pt-no-scd],
	B.[PA-CTL-PAA-XFER-DATE],
	sum(B.[2NDRY-MEDICAID-FFS]) AS '2NDRY-MEDICAID-FFS',
	SUM(b.[2NDRY-MEDICAID-ELIGIBLE]) AS '2NDRY-MEDICAID-ELIGIBLE',
	SUM(b.[2NDRY-MEDICAID-PENDING-IND]) AS '2NDRY-MEDICAID-PENDING-IND',
	SUM(b.[2NDRY-MEDICAID-OUT-OF-STATE-IND]) AS '2NDRY-MEDICAID-OUT-OF-STATE-IND',
	SUM(B.[2NDRY-OTHER-INS-IND]) AS '2NDRY-OTHER-INS-IND',
	SUM(B.[2NDRY-MEDICARE-IND]) AS '2NDRY-MEDICARE-IND',
	SUM(B.[2NDRY-SELF-PAY-IND]) AS '2NDRY-SELF-PAY-IND',
	SUM(B.[2NDRY-MEDICAID-MANAGED]) AS '2NDRY-MEDICAID-MANAGED',
	SUM(B.[INS-PAY-AMT]) AS 'TOT-INS-PAYMTS'
FROM dbo.[Secondary_Ins_Indicators_Detail] B
GROUP BY B.[pa-pt-no-woscd],
	B.[pa-pt-no-scd],
	B.[PA-CTL-PAA-XFER-DATE]
GO

-----------------------------------------------------------------------
/*

Encounters excluded because of certain denial codes
This is dependent upon the query that makes the table:
[DSH_2019].[dbo].[DSH_Denials_Detail]

*/
DROP TABLE IF EXISTS [dbo].[DSH_DENIALS_ENCOUNTERS_W_SELECTED_DENIALS]
--GO
CREATE TABLE [dbo].[DSH_DENIALS_ENCOUNTERS_W_SELECTED_DENIALS] (
	[PA-PT-NO-WOSCD] VARCHAR(50) NOT NULL,
	[PA-PT-NO-SCD] CHAR(1) NOT NULL,
	[PT-NO] VARCHAR(51) NOT NULL,
	[PA-UNIT-NO] VARCHAR(50) NULL,
	[UNIT-DATE] DATETIME NULL,
	--[PA-DTL-UNIT-DATE] VARCHAR(50) NULL,
	[DENIAL-IND] VARCHAR(1) NULL,
	[TOTAL-DENIALS] MONEY
	);

INSERT INTO [dbo].[DSH_DENIALS_ENCOUNTERS_W_SELECTED_DENIALS] (
    [PA-PT-NO-WOSCD],
    [PA-PT-NO-SCD],
    [PT-NO],
    [PA-UNIT-NO],
    [UNIT-DATE],
    [DENIAL-IND],
    [TOTAL-DENIALS]
    )
SELECT [PA-PT-NO-WOSCD],
	[PA-PT-NO-SCD],
	[PT-NO],
	[PA-UNIT-NO],
	[UNIT-DATE],
	--CASE 
	--	WHEN [PA-UNIT-NO] IS NULL
	--		THEN NULL
	--	ELSE CAST([PA-DTL-UNIT-DATE] AS DATE)
	--	END AS [PA-DTL-UNIT-DATE],
	'1' AS 'DENIAL-IND',
	SUM([TOT-CHARGES]) AS 'TOTAL-DENIALS'
FROM [dbo].[DSH_Denials_Detail]
GROUP BY [PA-PT-NO-WOSCD],
	[PA-PT-NO-SCD],
	[PT-NO],
	[PA-UNIT-NO],
	[UNIT-DATE]
	--[PA-DTL-UNIT-DATE]
GO

-----------------------------------------------------------------------
/*

Create the Medicaid Payment Indicator from payment code 108084

If the payment code exists and the sum of the payments is less than 0 (payment against AR)
Then put a 1 else place a 0

If the indicator equals 0 then Medicaid made no payment and we will shift to MEDICAID FFS DUAL ELIGIBLE (FOR 2015 DSH, THESE WERE SHIFTED TO SELF PAY.  DURING 2015 DSH AUDIT, KPMG SAID SELF PAY GROUPING SHOULD
NOT HAVE ANY ENCOUNTERS WITH THIRD PARTY INSURANCE.  THUS, ROB SAID TO PUT UNDER MEDICAID FFS DUAL ELGIBLE FOR DSH 

*/
DROP TABLE IF EXISTS [dbo].[DSH_MEDICAID_PMT_INDICATOR] 
GO

CREATE TABLE [dbo].[DSH_MEDICAID_PMT_INDICATOR] (
	[PA-PT-NO-WOSCD] VARCHAR(50) NOT NULL,
	[PA-PT-NO-SCD] CHAR(1) NOT NULL,
	[PT-NO] VARCHAR(51) NOT NULL,
	[PA-UNIT-NO] VARCHAR(50) NULL,
	[PA-DTL-UNIT-DATE] VARCHAR(50) NULL,
	[MEDICAID-PM-IP-OP-IND] INT NULL,
	[TOTAL-PAYMENTS] MONEY
	);

INSERT INTO [dbo].[DSH_MEDICAID_PMT_INDICATOR] (
    [PA-PT-NO-WOSCD],
    [PA-PT-NO-SCD],
    [PT-NO],
    [PA-UNIT-NO],
    [PA-DTL-UNIT-DATE],
    [MEDICAID-PM-IP-OP-IND],
    [TOTAL-PAYMENTS]
    )
SELECT [PA-PT-NO-WOSCD],
	[PA-PT-NO-SCD],
	[PT-NO],
	[PA-UNIT-NO],
	CASE 
		WHEN [PA-UNIT-NO] IS NULL
			THEN NULL
		ELSE CAST([PA-DTL-UNIT-DATE] AS DATE)
		END AS [PA-DTL-UNIT-DATE],
	CASE 
		WHEN LTRIM(RTRIM([PA-DTL-SVC-CD])) = '108084'
			AND SUM([TOT-PAYMENTS]) < 0
			THEN 1
		ELSE 0
		END AS [MEDICAID FFS DUAL ELIGIBLE],
	SUM([TOT-PAYMENTS]) AS [TOTAL-PAYMENTS]
FROM [dbo].[DSH_Payments]
WHERE LTRIM(RTRIM([PA-DTL-SVC-CD])) = '108084'
GROUP BY [PA-PT-NO-WOSCD],
	[PA-PT-NO-SCD],
	[PT-NO],
	[PA-UNIT-NO],
	[PA-DTL-UNIT-DATE],
	[PA-DTL-SVC-CD];


-----------------------------------------------------------------------
/*

Create the Reporting groups

*/
DROP TABLE IF EXISTS dbo.[DSH_INSURANCE_TABLE_W_REPORT_GROUPS] 
GO
--Add New Table
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
	b.[rank1] AS 'COB1',
	b.[pa-ins-plan] AS 'INS1',
	b.[pa-last-ins-bill-date] AS 'INS1_LAST_BL_DATE',
	c.[rank1] AS 'COB2',
	c.[pa-ins-plan] AS 'INS2',
	c.[pa-last-ins-bill-date] AS 'INS2_LAST_BL_DATE',
	d.[rank1] AS 'COB3',
	d.[pa-ins-plan] AS 'INS3',
	d.[pa-last-ins-bill-date] AS 'INS3_LAST_BL_DATE',
	e.[rank1] AS 'COB4',
	e.[pa-ins-plan] AS 'INS4',
	e.[pa-last-ins-bill-date] AS 'INS4_LAST_BL_DATE',
	f.[rank1] AS 'COB5',
	f.[pa-ins-plan] AS 'INS5',
	f.[pa-last-ins-bill-date] AS 'INS5_LAST_BL_DATE',
	g.[rank1] AS 'COB6',
	g.[pa-ins-plan] AS 'INS6',
	g.[pa-last-ins-bill-date] AS 'INS6_LAST_BL_DATE',
	h.[rank1] AS 'COB7',
	h.[pa-ins-plan] AS 'INS7',
	h.[pa-last-ins-bill-date] AS 'INS7_LAST_BL_DATE',
	CASE 
		WHEN (
				(
					DI1.[DENIAL-IND] = '1'
					OR DI2.[DENIAL-IND] = '1'
					)
				AND (
					(
						i.[indicator] = 'PRIMARY MEDICAID'
						OR i.[indicator] = 'PRIMARY MANAGED MEDICAID'
						OR i.[indicator] = 'PRIMARY SELF PAY'
						OR i.[indicator] IS NULL
						OR j.[2NDRY-MEDICAID-ELIGIBLE] > '0'
						OR J.[2NDRY-MEDICAID-OUT-OF-STATE-IND] > '0'
						OR J.[2NDRY-MEDICAID-PENDING-IND] > '0'
						OR J.[2NDRY-MEDICAID-MANAGED] > '0'
						OR J.[2NDRY-MEDICAID-FFS] > '0'
						)
					OR (
						i.[indicator] IN ('OTHER PRIMARY PAYER', 'PRIMARY MEDICARE')
						AND (
							j.[2NDRY-MEDICAID-ELIGIBLE] > '0'
							OR J.[2NDRY-MEDICAID-OUT-OF-STATE-IND] > '0'
							OR J.[2NDRY-MEDICAID-PENDING-IND] > '0'
							OR J.[2NDRY-MEDICAID-MANAGED] > '0'
							OR J.[2NDRY-MEDICAID-FFS] > '0'
							)
						)
					)
				)
			THEN 'DSH DENIAL'
				-- The secondary self pay indicator is not evaluated in the primary medicaid group. If included then
				-- it would restrict to all those accounts that are either 1 or 0 but not both
				-- if secondary self pay indicator = 1 then you are saying patient must have
				-- secondary self pay on the account. If the indicator = 0 then you are saying
				-- there can be no secondary self pay on the account
				-- If set to 1 then you would only get those that are primary medicaid and secondary self pay
				-- thereby limiting the grouping to those patients only.
				-- Since and evaluation line below is not included for secondary self pay
				-- all medicaid primary with any self pay secondary are included.
		WHEN i.[indicator] = 'PRIMARY MEDICAID'
			AND j.[2NDRY-MEDICAID-ELIGIBLE] = '0'
			AND J.[2NDRY-MEDICAID-OUT-OF-STATE-IND] = '0'
			AND J.[2NDRY-MEDICAID-PENDING-IND] = '0'
			AND J.[2NDRY-MEDICARE-IND] = '0'
			AND J.[2NDRY-OTHER-INS-IND] = '0'
			AND J.[2NDRY-MEDICAID-MANAGED] = '0'
			AND (
				MPI.[MEDICAID-PM-IP-OP-IND] = '1' -- this means medicaid paid
				OR MPI2.[MEDICAID-PM-IP-OP-IND] = '1' -- this means medicaid paid
				)
			THEN 'PRIMARY MEDICAID'
		-- EDIT SPS 04/08/2021
		WHEN B.[PA-INS-PLAN] = 'D01'
			AND C.[PA-INS-PLAN] IN ('SELF_PAY', 'K01')
			THEN 'PRIMARY MEDICAID'
		-- END EDIT
        -- EDIT SPS 11/29/2021
        WHEN B.[PA-INS-PLAN] = 'D99'
            AND C.[PA-INS-PLAN] = 'SELF_PAY'
            AND D.[PA-INS-PLAN] IS NULL
            AND E.[PA-INS-PLAN] IS NULL
            AND (
                MPI.[MEDICAID-PM-IP-OP-IND] = '1' -- this means medicaid paid
                OR MPI2.[MEDICAID-PM-IP-OP-IND] = '1' -- this means medicaid paid
                )
            THEN 'PRIMARY MEDICAID'    
        -- END EDIT
		WHEN (
				(
					i.[indicator] = 'PRIMARY MEDICAID'
					AND (
						J.[2NDRY-MEDICAID-ELIGIBLE] > '0'
						OR J.[2NDRY-MEDICARE-IND] > '0'
						OR J.[2NDRY-OTHER-INS-IND] > '0'
						OR J.[2NDRY-MEDICAID-OUT-OF-STATE-IND] > '0'
						OR J.[2NDRY-MEDICAID-PENDING-IND] > '0'
						OR J.[2NDRY-MEDICARE-IND] > '0'
						OR J.[2NDRY-MEDICAID-FFS] > '0'
						OR J.[2NDRY-MEDICAID-MANAGED] > '0'
						)
					)
				OR (
					I.INDICATOR = 'PRIMARY MEDICAID'
					AND (
						(
							MPI.[MEDICAID-PM-IP-OP-IND] = '0'
							OR MPI.[MEDICAID-PM-IP-OP-IND] IS NULL
							)
						OR (
							MPI2.[MEDICAID-PM-IP-OP-IND] = '0'
							OR MPI2.[MEDICAID-PM-IP-OP-IND] IS NULL
							)
						)
					)
				)
                -- EDIT SPS 11/29/2021
                AND B.[PA-INS-PLAN] != '496'
                -- END EDIT
			THEN 'MEDICAID FFS DUAL ELIGIBLE'
		-- EDIT 3/10/2021 STEVE
		WHEN LEFT(b.[pa-ins-plan], 1) = 'H'
			AND C.[PA-INS-PLAN] IN (
				'D01','D02','D03','D04','D11','D99'
			)
			THEN 'MEDICAID FFS DUAL ELIGIBLE'
		-- END EDIT
		-- EDIT SPS 11/30/2021
		WHEN B.[PA-INS-PLAN] = 'SELF_PAY'
			AND C.[PA-INS-PLAN] = 'G01'
			AND D.[PA-INS-PLAN] = 'D99'
			AND E.[PA-INS-PLAN] IS NULL
			THEN 'MEDICAID FFS DUAL ELIGIBLE'
		-- END EDIT
        -- EDIT 3/29/2021
        WHEN B.[PA-INS-PLAN] = 'SELF_PAY'
            AND LEFT(C.[PA-INS-PLAN], 1) IN ('D')
            THEN 'MEDICAID FFS DUAL ELIGIBLE'
        -- END EDIT 
		WHEN I.[INDICATOR] IN ('OTHER PRIMARY PAYER', 'PRIMARY MEDICARE')
			AND (
				j.[2ndry-medicaid-ffs] != '0'
				AND J.[2NDRY-MEDICAID-ELIGIBLE] = '0'
				AND J.[2NDRY-MEDICAID-OUT-OF-STATE-IND] = '0'
				AND J.[2NDRY-MEDICAID-MANAGED] = '0'
				)
            -- EDIT SPS 11/23/2021
            AND B.[PA-INS-PLAN] != '496'
			THEN 'MEDICAID FFS DUAL ELIGIBLE'
		-- EDIT 4/21/2021 SPS
		WHEN LEFT(B.[PA-INS-PLAN], 1) NOT IN ('D','U')
        -- EDIT SPS 11/29/2021
            AND B.[PA-INS-PLAN] != '496'
        -- END EDIT
            AND LEFT(C.[PA-INS-PLAN], 1) = 'D'
            AND LEFT(D.[PA-INS-PLAN], 1) = 'U'
            THEN 'MEDICAID FFS DUAL ELIGIBLE'
        WHEN LEFT(B.[PA-INS-PLAN], 1) NOT IN ('D','U')
        -- EDIT SPS 11/29/2021
            AND B.[PA-INS-PLAN] != '496'
        -- END EDIT
            AND LEFT(C.[PA-INS-PLAN], 1) NOT IN ('D', 'U')
            AND LEFT(D.[PA-INS-PLAN], 1) = 'D'
            AND LEFT(E.[PA-INS-PLAN], 1) = 'U'
            THEN 'MEDICAID FFS DUAL ELIGIBLE'
        WHEN LEFT(B.[PA-INS-PLAN], 1) NOT IN ('D','U')
        -- EDIT SPS 11/29/2021
            AND B.[PA-INS-PLAN] != '496'
        -- END EDIT
            AND LEFT(C.[PA-INS-PLAN], 1) = 'D'
            AND LEFT(D.[PA-INS-PLAN], 1) NOT IN ('D','U')
            AND LEFT(E.[PA-INS-PLAN], 1) = 'U'
            THEN 'MEDICAID FFS DUAL ELIGIBLE'
		-- END EDIT
		WHEN I.[INDICATOR] = 'PRIMARY MANAGED MEDICAID'
			AND j.[2NDRY-MEDICAID-ELIGIBLE] = '0'
			AND J.[2NDRY-MEDICAID-OUT-OF-STATE-IND] = '0'
			AND J.[2NDRY-MEDICAID-PENDING-IND] = '0'
			AND J.[2NDRY-MEDICARE-IND] = '0'
			AND J.[2NDRY-OTHER-INS-IND] = '0'
			AND J.[2NDRY-MEDICAID-MANAGED] = '0'
            -- EDIT SPS 11/29/2021
            AND B.[PA-INS-PLAN] != '496'
            -- END EDIT
			THEN 'PRIMARY MEDICAID MANAGED CARE'
		-- EDIT SPS 12/1/2021
		WHEN LEFT(B.[PA-INS-PLAN], 1) = 'H'
			AND LEFT(C.[PA-INS-PLAN], 1) = 'U'
			AND D.[PA-INS-PLAN] = 'D99'
			AND E.[PA-INS-PLAN] IS NULL
			THEN 'PRIMARY MEDICAID MANAGED CARE'
		-- END EDIT
		-- EDIT 4/18/2021 SPS
		WHEN LEFT(B.[PA-INS-PLAN], 1) = 'U'
			AND LEFT(B.[PA-INS-PLAN], 1) = 'D'
			AND (
				DI1.[DENIAL-IND] = '0'
				OR DI2.[DENIAL-IND] = '0'
			)
			THEN 'PRIMARY MEDICAID MANAGED CARE'
        WHEN LEFT(B.[PA-INS-PLAN], 1) = 'U'
            AND LEFT(C.[PA-INS-PLAN], 1) = 'U'
            AND LEFT(D.[PA-INS-PLAN], 1) = 'D'
            THEN 'PRIMARY MEDICAID MANAGED CARE'
        WHEN LEFT (B.[PA-INS-PLAN], 1) = 'U'
            AND C.[PA-INS-PLAN] = 'SELF_PAY'
            AND LEFT(D.[PA-INS-PLAN], 1) = 'D'
            THEN 'PRIMARY MEDICAID MANAGED CARE'
		-- END EDIT
		-- EDIT 4/19/2021 SPS
		WHEN LEFT(B.[PA-INS-PLAN], 1) = 'U'
			AND LEFT(C.[PA-INS-PLAN], 1) = 'D'
			AND (
				D.[PA-INS-PLAN] IS NULL
				OR LEFT(D.[PA-INS-PLAN], 1) = 'U'
				OR D.[PA-INS-PLAN] IN ('H80','SELF_PAY')
			)
			THEN 'PRIMARY MEDICAID MANAGED CARE'
		-- END EDIT
		WHEN I.[INDICATOR] = 'PRIMARY MANAGED MEDICAID'
			AND (
				j.[2NDRY-MEDICAID-ELIGIBLE] > '0'
				OR J.[2NDRY-MEDICAID-OUT-OF-STATE-IND] > '0'
				OR J.[2NDRY-MEDICAID-PENDING-IND] > '0'
				OR J.[2NDRY-MEDICARE-IND] > '0'
				OR J.[2NDRY-OTHER-INS-IND] > '0'
				OR J.[2NDRY-MEDICAID-MANAGED] <> '0'
				)
            -- EDIT SPS 11/29/2021
            AND B.[PA-INS-PLAN] != '496'
            -- END EDIT
			THEN 'MEDICAID MANAGED CARE DUAL ELIGIBLE'
		WHEN I.[INDICATOR] IN ('OTHER PRIMARY PAYER', 'PRIMARY MEDICARE')
			AND (
				J.[2NDRY-MEDICAID-MANAGED] > '0'
				OR J.[2NDRY-MEDICAID-ELIGIBLE] > '0'
				)
            -- EDIT SPS 11/29/2021
            AND B.[PA-INS-PLAN] != '496'
            -- END EDIT
			THEN 'MEDICAID MANAGED CARE DUAL ELIGIBLE'
        -- EDIT 3/16/2021
        WHEN B.[PA-INS-PLAN] = 'SELF_PAY'
            AND LEFT(C.[PA-INS-PLAN], 1) = 'C'
            AND LEFT(D.[PA-INS-PLAN], 1) = 'U'
            AND LEFT(E.[PA-INS-PLAN], 1) = 'D'
            AND (
                	DI1.[DENIAL-IND] = '0'
					OR DI1.[DENIAL-IND] IS NULL
				)
			AND (
					DI2.[DENIAL-IND] = '0'
					OR DI2.[DENIAL-IND]  IS NULL
				)
            THEN 'MEDICAID MANAGED CARE DUAL ELIGIBLE'
        -- END EDIT
		-- EDIT 3/29/2021
		WHEN B.[PA-INS-PLAN] = 'SELF_PAY'
			AND LEFT(C.[PA-INS-PLAN], 1) = 'U'
			THEN 'MEDICAID MANAGED CARE DUAL ELIGIBLE'
		-- END EDIT
		-- EDIT 3/10/2021
		WHEN (
                B.[PA-INS-PLAN] = 'SELF_PAY'
                OR LEFT(B.[PA-INS-PLAN], 1) = 'H'
            )
            -- EDIT SPS 11/29/2021
            AND B.[PA-INS-PLAN] != '496'
            -- END EDIT
			AND LEFT(C.[PA-INS-PLAN], 1) = 'L'
			THEN 'UN-GROUPED'
		-- END EDIT
        -- EDIT 3/17/2021 SPS
        WHEN (
            B.[PA-INS-PLAN] = 'SELF_PAY'
            OR LEFT(B.[PA-INS-PLAN], 1) = 'H'
        )
            -- EDIT SPS 11/29/2021
            AND B.[PA-INS-PLAN] != '496'
            -- END EDIT
            AND LEFT(C.[PA-INS-PLAN], 1) IN ('P','J')
            THEN 'UN-GROUPED'
        -- END EDIT
		-- EDIT 3/22/2021
		WHEN LEFT(B.[PA-INS-PLAN], 1) = 'H'
			AND LEFT(C.[PA-INS-PLAN],1) IN ('M','Y')
			THEN 'UN-GROUPED'
		-- END EDIT
        -- EDIT 3/29/2021
        WHEN B.[PA-INS-PLAN] = 'SELF_PAY'
            AND LEFT(D.[PA-INS-PLAN], 1) = 'J'
            THEN 'UN-GROUPED'
        -- END EDIT
		-- EDIT 4/6/2021
		WHEN B.[PA-INS-PLAN] = 'SELF_PAY'
			AND LEFT(C.[PA-INS-PLAN], 1) = 'O'
			THEN 'UN-GROUPED'
		-- END EDIT
		WHEN (
				I.INDICATOR = 'PRIMARY SELF PAY'
				OR I.INDICATOR IS NULL
				)
            -- EDIT SPS 12/07/2021
            AND B.[PA-INS-PLAN] != '496'
            OR (
                B.[PA-INS-PLAN] = 'SELF_PAY'
                AND LEFT(C.[PA-INS-PLAN], 1) IN ('B','C','G','M')
                AND (
                    LEFT(D.[PA-INS-PLAN], 1) IN ('B','P')
                    OR D.[PA-INS-PLAN] IS NULL
                    )
                AND E.[PA-INS-PLAN] IS NULL
                AND (
                    DI1.[DENIAL-IND] = '0'
                    OR DI2.[DENIAL-IND] = '0'
                )
            )
            AND (
                B.[PA-INS-PLAN] IS NOT NULL
                AND LEFT(C.[PA-INS-PLAN], 1) != 'Y'
                AND D.[PA-INS-PLAN] IS NOT NULL
                AND E.[PA-INS-PLAN] IS NOT NULL
                AND (
                    DI1.[DENIAL-IND] = '0'
                    OR DI2.[DENIAL-IND] = '0'
                )
            )
            -- END EDIT
			THEN 'PRIMARY SELF PAY'
		WHEN I.[INDICATOR] = 'PRIMARY OUT OF STATE MEDICAID'
			AND j.[2NDRY-MEDICAID-ELIGIBLE] = '0'
			AND J.[2NDRY-MEDICAID-OUT-OF-STATE-IND] = '0'
			AND J.[2NDRY-MEDICAID-PENDING-IND] = '0'
			AND J.[2NDRY-MEDICARE-IND] = '0'
			AND J.[2NDRY-OTHER-INS-IND] = '0'
			AND J.[2NDRY-MEDICAID-MANAGED] = '0'
            -- EDIT SPS 11/29/2021
            AND B.[PA-INS-PLAN] != '496'
            -- END EDIT
			THEN 'PRIMARY OUT OF STATE MEDICAID'
		WHEN I.[INDICATOR] = 'PRIMARY OUT OF STATE MEDICAID'
			AND (
				j.[2NDRY-MEDICAID-ELIGIBLE] > '0'
				OR J.[2NDRY-MEDICAID-OUT-OF-STATE-IND] > '0'
				OR J.[2NDRY-MEDICAID-PENDING-IND] > '0'
				OR J.[2NDRY-MEDICARE-IND] > '0'
				OR J.[2NDRY-OTHER-INS-IND] > '0'
				)
            -- EDIT SPS 11/29/2021
            AND B.[PA-INS-PLAN] != '496'
            -- END EDIT
			THEN 'DUAL ELIGIBLE OUT OF STATE MEDICAID'
		WHEN I.[INDICATOR] IN ('OTHER PRIMARY PAYER', 'PRIMARY MEDICARE')
			AND (
				J.[2NDRY-MEDICAID-FFS] = '0'
				AND J.[2NDRY-MEDICAID-ELIGIBLE] = '0'
				AND J.[2NDRY-MEDICAID-OUT-OF-STATE-IND] > '0'
				)
            -- EDIT SPS 11/29/2021
            AND B.[PA-INS-PLAN] != '496'
            -- END EDIT
			THEN 'DUAL ELIGIBLE OUT OF STATE MEDICAID'
			
			--BELOW LINES WERE ADDED SO THAT TEACHING ENCOUNTERS NOT PART OF ABOVE REPORTING GROUPS
			--ARE NOW INCLUDED IN PRIMARY SELF PAY.  THIS CODING WAS ADDED AFTER IT WAS DISCOVERED
			--THAT SOME TEACHING ENCOUNTERS WERE NOT PART OF DSH B/C THEY WERE FALLING INTO UN-GROUPED (2-8-21)
		WHEN (
				b.[pa-ins-plan] = 'T01'
				OR C.[pa-ins-plan] = 'T01'
				OR D.[pa-ins-plan] = 'T01'
				OR E.[pa-ins-plan] = 'T01'
				)
			AND i.[indicator] = 'OTHER PRIMARY PAYER'
            -- EDIT SPS 12/07/2021
            AND B.[PA-INS-PLAN] != '496'
            OR (
                B.[PA-INS-PLAN] = 'SELF_PAY'
                AND LEFT(C.[PA-INS-PLAN], 1) IN ('B','C','G','M')
                AND (
                    LEFT(D.[PA-INS-PLAN], 1) IN ('B','P')
                    OR D.[PA-INS-PLAN] IS NULL
                    )
                AND E.[PA-INS-PLAN] IS NULL
                AND (
                    DI1.[DENIAL-IND] = '0'
                    OR DI2.[DENIAL-IND] = '0'
                )
            )
            AND (
                B.[PA-INS-PLAN] IS NOT NULL
                AND LEFT(C.[PA-INS-PLAN], 1) != 'Y'
                AND D.[PA-INS-PLAN] IS NOT NULL
                AND E.[PA-INS-PLAN] IS NOT NULL
                AND (
                    DI1.[DENIAL-IND] = '0'
                    OR DI2.[DENIAL-IND] = '0'
                )
            )
            -- END EDIT
			THEN 'PRIMARY SELF PAY'

			--BELOW LINES WERE ADDED SO THAT ADAP ENCOUNTERS NOT PART OF ABOVE REPORTING GROUPS
			--ARE NOW INCLUDED IN PRIMARY SELF PAY.  THIS CODING WAS ADDED AFTER IT WAS DISCOVERED
			--THAT SOME ADAP ENCOUNTERS WERE NOT PART OF DSH B/C THEY WERE FALLING INTO UN-GROUPED (2-11-21)


		WHEN B.[PA-INS-PLAN] = 'Q99'
			AND (
				LEFT(B.[PA-INS-PLAN],1) NOT IN ('A','B','C','D','E','F','G','I','J','K','L','M','N','O','P','R','T','U','X','Y')
				OR B.[PA-INS-PLAN] IS NULL
				)
			AND (
				LEFT(C.[PA-INS-PLAN],1) NOT IN ('A','B','C','D','E','F','G','I','J','K','L','M','N','O','P','R','T','U','X','Y')
				OR C.[PA-INS-PLAN] IS NULL
				)
			AND (
				LEFT(D.[PA-INS-PLAN],1) NOT IN ('A','B','C','D','E','F','G','I','J','K','L','M','N','O','P','R','T','U','X','Y')
				OR D.[PA-INS-PLAN] IS NULL
				)
			AND (
				LEFT(E.[PA-INS-PLAN],1) NOT IN ('A','B','C','D','E','F','G','I','J','K','L','M','N','O','P','R','T','U','X','Y')
				OR E.[PA-INS-PLAN] IS NULL
				)
			AND (
				LEFT(F.[PA-INS-PLAN],1) NOT IN ('A','B','C','D','E','F','G','I','J','K','L','M','N','O','P','R','T','U','X','Y')
				OR F.[PA-INS-PLAN] IS NULL
				)
			AND (
				LEFT(G.[PA-INS-PLAN],1) NOT IN ('A','B','C','D','E','F','G','I','J','K','L','M','N','O','P','R','T','U','X','Y')
				OR G.[PA-INS-PLAN] IS NULL
				)
            OR (
                B.[PA-INS-PLAN] = 'SELF_PAY'
                AND LEFT(C.[PA-INS-PLAN], 1) IN ('B','C','G','M')
                AND (
                    LEFT(D.[PA-INS-PLAN], 1) IN ('B','P')
                    OR D.[PA-INS-PLAN] IS NULL
                    )
                AND E.[PA-INS-PLAN] IS NULL
                AND (
                    DI1.[DENIAL-IND] = '0'
                    OR DI2.[DENIAL-IND] = '0'
                )
            )
            AND (
                B.[PA-INS-PLAN] IS NOT NULL
                AND LEFT(C.[PA-INS-PLAN], 1) != 'Y'
                AND D.[PA-INS-PLAN] IS NOT NULL
                AND E.[PA-INS-PLAN] IS NOT NULL
                AND (
                    DI1.[DENIAL-IND] = '0'
                    OR DI2.[DENIAL-IND] = '0'
                )
            )
			THEN 'PRIMARY SELF PAY'
		WHEN (
				(
					I.[INDICATOR] = 'OTHER PRIMARY PAYER'
					AND J.[2NDRY-MEDICAID-ELIGIBLE] = '0'
					AND J.[2NDRY-MEDICAID-FFS] = '0'
					AND J.[2NDRY-MEDICAID-MANAGED] = '0'
					AND J.[2NDRY-MEDICAID-OUT-OF-STATE-IND] = '0'
					AND J.[2NDRY-MEDICAID-PENDING-IND] = '0'
					AND J.[2NDRY-MEDICARE-IND] = '0'
					AND J.[2NDRY-OTHER-INS-IND] = '0'
					AND J.[2NDRY-SELF-PAY-IND] != '0'
					)
				OR (
					I.[INDICATOR] = 'OTHER PRIMARY PAYER'
					AND J.[2NDRY-MEDICAID-ELIGIBLE] = '0'
					AND J.[2NDRY-MEDICAID-FFS] = '0'
					AND J.[2NDRY-MEDICAID-MANAGED] = '0'
					AND J.[2NDRY-MEDICAID-OUT-OF-STATE-IND] = '0'
					AND J.[2NDRY-MEDICAID-PENDING-IND] = '0'
					AND J.[2NDRY-MEDICARE-IND] = '0'
					AND J.[2NDRY-OTHER-INS-IND] = '0'
					AND J.[2NDRY-SELF-PAY-IND] = '0'
					)
				)
			THEN 'UN-GROUPED'
		ELSE 'UN-GROUPED'
		END AS 'REPORTING GROUP',
	CASE 
		WHEN (
				(
					DI1.[DENIAL-IND] = '1'
					OR DI2.[DENIAL-IND] = '1'
					)
				AND (
					i.[indicator] = 'PRIMARY MEDICAID'
					OR i.[indicator] = 'PRIMARY MANAGED MEDICAID'
					OR i.[indicator] = 'PRIMARY SELF PAY'
					OR i.[indicator] IS NULL
					OR j.[2NDRY-MEDICAID-ELIGIBLE] = '1'
					OR J.[2NDRY-MEDICAID-OUT-OF-STATE-IND] = '1'
					OR J.[2NDRY-MEDICAID-PENDING-IND] = '1'
					OR J.[2NDRY-MEDICAID-MANAGED] = '1'
					OR J.[2NDRY-MEDICAID-FFS] = '1'
					)
				)
			THEN 'DSH DENIAL'
		ELSE ''
		END AS 'TEST-DSH-DENIAL',
	CASE 
		WHEN i.[indicator] = 'PRIMARY MEDICAID'
			AND j.[2NDRY-MEDICAID-ELIGIBLE] = '0'
			AND J.[2NDRY-MEDICAID-OUT-OF-STATE-IND] = '0'
			AND J.[2NDRY-MEDICAID-PENDING-IND] = '0'
			AND J.[2NDRY-MEDICARE-IND] = '0'
			AND J.[2NDRY-OTHER-INS-IND] = '0'
			AND J.[2NDRY-MEDICAID-MANAGED] = '0'
			AND (
				MPI.[MEDICAID-PM-IP-OP-IND] = '1' -- this means medicaid paid
				OR MPI2.[MEDICAID-PM-IP-OP-IND] = '1' -- this means medicaid paid
				)
			THEN 'PRIMARY MEDICAID'
		ELSE ''
		END AS 'TEST-PRIMARY-MEDICAID',
	CASE 
		WHEN (
				(
					i.[indicator] = 'PRIMARY MEDICAID'
					AND (
						J.[2NDRY-MEDICAID-ELIGIBLE] > '0'
						OR J.[2NDRY-MEDICARE-IND] > '0'
						OR J.[2NDRY-OTHER-INS-IND] > '0'
						OR J.[2NDRY-MEDICAID-OUT-OF-STATE-IND] > '0'
						OR J.[2NDRY-MEDICAID-PENDING-IND] > '0'
						OR J.[2NDRY-MEDICARE-IND] > '0'
						OR J.[2NDRY-MEDICAID-FFS] > '0'
						OR J.[2NDRY-MEDICAID-MANAGED] > '0'
						)
					)
				OR (
					I.INDICATOR = 'PRIMARY MEDICAID'
					AND (
						(
							MPI.[MEDICAID-PM-IP-OP-IND] = '0'
							OR MPI.[MEDICAID-PM-IP-OP-IND] IS NULL
							)
						OR (
							MPI2.[MEDICAID-PM-IP-OP-IND] = '0'
							OR MPI2.[MEDICAID-PM-IP-OP-IND] IS NULL
							)
						)
					)
				OR (
					I.[INDICATOR] IN ('OTHER PRIMARY PAYER', 'PRIMARY MEDICARE')
					AND (
						j.[2ndry-medicaid-ffs] > '0'
						AND J.[2NDRY-MEDICAID-ELIGIBLE] = '0'
						AND J.[2NDRY-MEDICAID-OUT-OF-STATE-IND] = '0'
						AND J.[2NDRY-MEDICAID-MANAGED] = '0'
						)
					)
				)
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
			AND J.[2NDRY-MEDICAID-MANAGED] = '0'
			THEN 'PRIMARY MEDICAID MANAGED CARE'
		ELSE ''
		END AS 'TEST-PRIMARY-MEDICAID-MANAGED-CARE',
	CASE 
		WHEN (
				(
					I.[INDICATOR] = 'PRIMARY MANAGED MEDICAID'
					AND (
						j.[2NDRY-MEDICAID-ELIGIBLE] > '0'
						OR J.[2NDRY-MEDICAID-OUT-OF-STATE-IND] > '0'
						OR J.[2NDRY-MEDICAID-PENDING-IND] > '0'
						OR J.[2NDRY-MEDICARE-IND] > '0'
						OR J.[2NDRY-OTHER-INS-IND] > '0'
						OR J.[2NDRY-MEDICAID-MANAGED] <> '0'
						)
					)
				OR (
					I.[INDICATOR] IN ('OTHER PRIMARY PAYER', 'PRIMARY MEDICARE')
					AND (
						J.[2NDRY-MEDICAID-MANAGED] > '0'
						OR J.[2NDRY-MEDICAID-ELIGIBLE] > '0'
						)
					)
				)
			THEN 'MEDICAID MANAGED CARE DUAL ELIGIBLE'
		ELSE ''
		END AS 'TEST-MEDICAID-MGD-CARE-DUAL-ELIG',
	CASE 
		WHEN (
				I.INDICATOR = 'PRIMARY SELF PAY'
				OR I.INDICATOR IS NULL
				)
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
			AND J.[2NDRY-MEDICAID-MANAGED] = '0'
			THEN 'PRIMARY OUT OF STATE MEDICAID'
		ELSE ''
		END AS 'TEST-PRIMARY-OUT-OF-STATE-MEDICAID',
	CASE 
		WHEN (
				(
					I.[INDICATOR] = 'PRIMARY OUT OF STATE MEDICAID'
					AND (
						j.[2NDRY-MEDICAID-ELIGIBLE] > '0'
						OR J.[2NDRY-MEDICAID-OUT-OF-STATE-IND] > '0'
						OR J.[2NDRY-MEDICAID-PENDING-IND] > '0'
						OR J.[2NDRY-MEDICARE-IND] > '0'
						OR J.[2NDRY-OTHER-INS-IND] > '0'
						)
					)
				OR (
					I.[INDICATOR] IN ('OTHER PRIMARY PAYER', 'PRIMARY MEDICARE')
					AND (
						J.[2NDRY-MEDICAID-FFS] = '0'
						AND J.[2NDRY-MEDICAID-ELIGIBLE] = '0'
						AND J.[2NDRY-MEDICAID-OUT-OF-STATE-IND] > '0'
						)
					)
				)
			THEN 'DUAL ELIGIBLE OUT OF STATE MEDICAID'
		ELSE ''
		END AS 'TEST-DUAL-ELIG-OUT-OF-STATE-MEDICAID',
	isnull(i.[indicator], 'SELF PAY') AS 'PRIMARY-TYPE',
	J.[2NDRY-MEDICAID-FFS],
	j.[2NDRY-MEDICAID-ELIGIBLE],
	j.[2NDRY-MEDICAID-PENDING-IND],
	j.[2NDRY-MEDICAID-OUT-OF-STATE-IND],
	j.[2NDRY-OTHER-INS-IND],
	j.[2NDRY-MEDICARE-IND],
	j.[2NDRY-SELF-PAY-IND],
	J.[2NDRY-MEDICAID-MANAGED],
	ISNULL(COALESCE(MPI.[MEDICAID-PM-IP-OP-IND], MPI2.[MEDICAID-PM-IP-OP-IND]), 0) AS [MEDICAID-PM-IP-OP-IND],
	ISNULL(COALESCE(DI2.[DENIAL-IND], DI1.[DENIAL-IND]), 0) AS 'DENIAL-IND',
	J.[TOT-INS-PAYMTS],
	k.[im-ind]
INTO #DSH_INSURANCE_TABLE_W_REPORT_GROUPS_TEMP
FROM dbo.[Encounters_For_DSH] a
LEFT OUTER JOIN dbo.[CUSTOMINSURANCE] b ON a.[pa-pt-no-woscd] = b.[pa-pt-no-woscd]
	AND a.[PA-CTL-PAA-XFER-DATE] = b.[PA-CTL-PAA-XFER-DATE]
	AND b.[rank1] = '1'
LEFT OUTER JOIN dbo.[CUSTOMINSURANCE] c ON a.[pa-pt-no-woscd] = c.[pa-pt-no-woscd]
	AND a.[PA-CTL-PAA-XFER-DATE] = c.[PA-CTL-PAA-XFER-DATE]
	AND c.[rank1] = '2'
LEFT OUTER JOIN dbo.[CUSTOMINSURANCE] d ON a.[pa-pt-no-woscd] = d.[pa-pt-no-woscd]
	AND a.[PA-CTL-PAA-XFER-DATE] = d.[PA-CTL-PAA-XFER-DATE]
	AND d.[rank1] = '3'
LEFT OUTER JOIN dbo.[CUSTOMINSURANCE] e ON a.[pa-pt-no-woscd] = e.[pa-pt-no-woscd]
	AND a.[PA-CTL-PAA-XFER-DATE] = e.[PA-CTL-PAA-XFER-DATE]
	AND e.[rank1] = '4'
LEFT OUTER JOIN dbo.[CUSTOMINSURANCE] f ON a.[pa-pt-no-woscd] = f.[pa-pt-no-woscd]
	AND a.[PA-CTL-PAA-XFER-DATE] = f.[PA-CTL-PAA-XFER-DATE]
	AND f.[rank1] = '5'
LEFT OUTER JOIN dbo.[CUSTOMINSURANCE] g ON a.[pa-pt-no-woscd] = g.[pa-pt-no-woscd]
	AND a.[PA-CTL-PAA-XFER-DATE] = g.[PA-CTL-PAA-XFER-DATE]
	AND g.[rank1] = '6'
LEFT OUTER JOIN dbo.[CUSTOMINSURANCE] h ON a.[pa-pt-no-woscd] = h.[pa-pt-no-woscd]
	AND a.[PA-CTL-PAA-XFER-DATE] = h.[PA-CTL-PAA-XFER-DATE]
	AND h.[rank1] = '7'
LEFT OUTER JOIN dbo.[Primary_Ins_Type] i ON a.[pa-pt-no-woscd] = i.[pa-pt-no-woscd]
	AND a.[PA-CTL-PAA-XFER-DATE] = i.[PA-CTL-PAA-XFER-DATE]
	AND i.[rank1] = '1'
LEFT OUTER JOIN dbo.[Secondary_Ins_Indicators_Summary] j ON a.[pa-pt-no-woscd] = j.[pa-pt-no-woscd]
	AND a.[PA-CTL-PAA-XFER-DATE] = j.[PA-CTL-PAA-XFER-DATE]
LEFT OUTER JOIN dbo.[IM_Patients] k ON a.[pa-pt-no-woscd] = k.[pa-pt-no-woscd]
LEFT OUTER JOIN [DBO].[DSH_MEDICAID_PMT_INDICATOR] AS MPI ON A.[PA-PT-NO-WOSCD] = MPI.[PA-PT-NO-WOSCD]
	AND A.[PA-PT-NO-SCD] = MPI.[PA-PT-NO-SCD]
	AND A.[pa-unit-no] IS NULL
LEFT OUTER JOIN [DBO].[DSH_MEDICAID_PMT_INDICATOR] AS MPI2 ON A.[PA-PT-NO-WOSCD] = MPI2.[PA-PT-NO-WOSCD]
	AND A.[PA-PT-NO-SCD] = MPI2.[PA-PT-NO-SCD]
	AND MPI2.[PA-UNIT-NO] IS NOT NULL
	AND A.[pa-unit-no] = MPI2.[PA-UNIT-NO]
LEFT OUTER JOIN [DBO].[DSH_DENIALS_ENCOUNTERS_W_SELECTED_DENIALS] AS DI1 ON A.[PA-PT-NO-WOSCD] = DI1.[PA-PT-NO-WOSCD]
	AND A.[PA-PT-NO-SCD] = DI1.[PA-PT-NO-SCD]
	AND A.[pa-unit-no] IS NULL
LEFT OUTER JOIN [DBO].[DSH_DENIALS_ENCOUNTERS_W_SELECTED_DENIALS] AS DI2 ON A.[PA-PT-NO-WOSCD] = DI2.[PA-PT-NO-WOSCD]
	AND A.[PA-PT-NO-SCD] = DI2.[PA-PT-NO-SCD]
	AND DI2.[PA-UNIT-NO] IS NOT NULL
	AND A.[pa-unit-no] = DI2.[PA-UNIT-NO];


SELECT [PA-PT-NO-WOSCD],
	[PA-PT-NO-SCD],
	[PA-CTL-PAA-XFER-DATE],
	[pa-unit-no],
	[pa-med-rec-no],
	[pa-pt-name],
	[admit_date],
	[dsch_date],
	[pa-unit-date],
	[pa-acct-type],
	[COB1],
	[INS1],
	[COB2],
	[INS2],
	[COB3],
	[INS3],
	[COB4],
	[INS4],
	[COB5],
	[INS5],
	[COB6],
	[INS6],
	[COB7],
	[INS7],
	[REPORTING GROUP],
	[TEST-PRIMARY-MEDICAID],
	[TEST-MEDICIAD-FFS-DUAL-ELIGIBLE],
	[TEST-PRIMARY-MEDICAID-MANAGED-CARE],
	[TEST-MEDICAID-MGD-CARE-DUAL-ELIG],
	[TEST-PRIMARY-SELF-PAY],
	[TEST-PRIMARY-OUT-OF-STATE-MEDICAID],
	[TEST-DUAL-ELIG-OUT-OF-STATE-MEDICAID],
	--[TEST-MEDICAID-FFS-DUAL-ELIG-2],
	--[TEST-MEDICAID-MGD-DUAL-ELIG-2],
	--[TEST-DUAL-ELIG-OUT-OF-STATE-MCAID-2],
	--[TEST-PRIMARY-SELF-PAY-2],
	[PRIMARY-TYPE],
	[2NDRY-MEDICAID-FFS],
	[2NDRY-MEDICAID-ELIGIBLE],
	[2NDRY-MEDICAID-PENDING-IND],
	[2NDRY-MEDICAID-OUT-OF-STATE-IND],
	[2NDRY-OTHER-INS-IND],
	[2NDRY-MEDICARE-IND],
	[2NDRY-SELF-PAY-IND],
	[2NDRY-MEDICAID-MANAGED],
	[MEDICAID-PM-IP-OP-IND],
	[DENIAL-IND],
	[TOT-INS-PAYMTS],
	[im-ind]
INTO dbo.[DSH_INSURANCE_TABLE_W_REPORT_GROUPS]
FROM #DSH_INSURANCE_TABLE_W_REPORT_GROUPS_TEMP AS A
GROUP BY [PA-PT-NO-WOSCD],
	[PA-PT-NO-SCD],
	[PA-CTL-PAA-XFER-DATE],
	[pa-unit-no],
	[pa-med-rec-no],
	[pa-pt-name],
	[admit_date],
	[dsch_date],
	[pa-unit-date],
	[pa-acct-type],
	[COB1],
	[INS1],
	[COB2],
	[INS2],
	[COB3],
	[INS3],
	[COB4],
	[INS4],
	[COB5],
	[INS5],
	[COB6],
	[INS6],
	[COB7],
	[INS7],
	[REPORTING GROUP],
	[TEST-PRIMARY-MEDICAID],
	[TEST-MEDICIAD-FFS-DUAL-ELIGIBLE],
	[TEST-PRIMARY-MEDICAID-MANAGED-CARE],
	[TEST-MEDICAID-MGD-CARE-DUAL-ELIG],
	[TEST-PRIMARY-SELF-PAY],
	[TEST-PRIMARY-OUT-OF-STATE-MEDICAID],
	[TEST-DUAL-ELIG-OUT-OF-STATE-MEDICAID],
	--[TEST-MEDICAID-FFS-DUAL-ELIG-2],
	--[TEST-MEDICAID-MGD-DUAL-ELIG-2],
	--[TEST-DUAL-ELIG-OUT-OF-STATE-MCAID-2],
	--[TEST-PRIMARY-SELF-PAY-2],
	[PRIMARY-TYPE],
	[2NDRY-MEDICAID-FFS],
	[2NDRY-MEDICAID-ELIGIBLE],
	[2NDRY-MEDICAID-PENDING-IND],
	[2NDRY-MEDICAID-OUT-OF-STATE-IND],
	[2NDRY-OTHER-INS-IND],
	[2NDRY-MEDICARE-IND],
	[2NDRY-SELF-PAY-IND],
	[2NDRY-MEDICAID-MANAGED],
	[MEDICAID-PM-IP-OP-IND],
	[DENIAL-IND],
	[TOT-INS-PAYMTS],
	[im-ind]
GO
;

DROP TABLE IF EXISTS #DSH_INSURANCE_TABLE_W_REPORT_GROUPS_TEMP
DROP TABLE IF EXISTS [dbo].[DSH_DENIALS_ENCOUNTERS_W_SELECTED_DENIALS]
GO
;