/*
1_create_custom_insurance_table_sm_version_alt.sql
*/

USE [SMS];

SET ANSI_WARNINGS ON
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

----------------------------------------------------------------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS SMS.dbo.[DISTINCT_ENCOUNTERS_FOR_REPORTING_ALT]

GO

CREATE TABLE SMS.DBO.[DISTINCT_ENCOUNTERS_FOR_REPORTING_ALT] (
	[PA-PT-NO-WOSCD] DECIMAL(11, 0) NOT NULL,
	[PA-PT-NO-SCD] CHAR(1) NOT NULL,
	[PA-UNIT-NO] DECIMAL(4, 0) NULL,
	[ADMIT_DATE] DATETIME NULL,
	[DSCH_DATE] DATETIME NULL,
	[PA-UNIT-DATE] DATETIME NULL,
	[PA-CTL-PAA-XFER-DATE] DATETIME NULL,
	[PA-UNIT-STS] VARCHAR(1) NULL,
	[PA-ACCT-TYPE] CHAR(1) NULL,
	[PA-MED-REC-NO] CHAR(12) NULL,
	[PA-PT-NAME] CHAR(25) NULL
	);

INSERT INTO [DISTINCT_ENCOUNTERS_FOR_REPORTING_alt] (
	[PA-PT-NO-WOSCD],
	[PA-PT-NO-SCD],
	[PA-UNIT-NO],
	[ADMIT_DATE],
	[DSCH_DATE],
	[PA-UNIT-DATE],
	[PA-CTL-PAA-XFER-DATE],
	[PA-UNIT-STS],
	[PA-ACCT-TYPE],
	[PA-MED-REC-NO],
	[PA-PT-NAME]
	)
SELECT [PA-PT-NO-WOSCD],
	[PA-PT-NO-SCD],
	[PA-UNIT-NO],
	[ADMIT_DATE],
	[DSCH_DATE],
	[PA-UNIT-DATE],
	[PA-CTL-PAA-XFER-DATE],
	[PA-UNIT-STS],
	[PA-ACCT-TYPE],
	[PA-MED-REC-NO],
	[PA-PT-NAME]
FROM SMS.[dbo].[ENCOUNTERS_FOR_REPORTING]
--WHERE [pa-unit-sts] <> 'U' OR [pa-unit-no] = '0'
GROUP BY [PA-PT-NO-WOSCD],
	[PA-PT-NO-SCD],
	[PA-UNIT-NO],
	[ADMIT_DATE],
	[DSCH_DATE],
	[PA-UNIT-DATE],
	[PA-CTL-PAA-XFER-DATE],
	[PA-UNIT-STS],
	[PA-ACCT-TYPE],
	[PA-MED-REC-NO],
	[PA-PT-NAME]

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS SMS.dbo.[DISTINCT_ENCOUNTERS_FOR_REPORTING_2_alt]

GO

CREATE TABLE SMS.DBO.[DISTINCT_ENCOUNTERS_FOR_REPORTING_2_ALT] (
	[PA-PT-NO-WOSCD] DECIMAL(11, 0) NOT NULL,
	[PA-PT-NO-SCD] CHAR(1) NOT NULL,
	[PA-UNIT-NO] DECIMAL(4, 0) NULL,
	[ADMIT_DATE] DATETIME NULL,
	[DSCH_DATE] DATETIME NULL,
	[PA-UNIT-DATE] DATETIME NULL,
	[PA-CTL-PAA-XFER-DATE] DATETIME NULL,
	[PA-UNIT-STS] VARCHAR(1) NULL,
	[PA-ACCT-TYPE] CHAR(1) NULL,
	[PA-MED-REC-NO] CHAR(12) NULL,
	[PA-PT-NAME] CHAR(25) NULL
	);

INSERT INTO [DISTINCT_ENCOUNTERS_FOR_REPORTING_2_ALT] (
	[PA-PT-NO-WOSCD],
	[PA-PT-NO-SCD],
	[PA-UNIT-NO],
	[ADMIT_DATE],
	[DSCH_DATE],
	[PA-UNIT-DATE],
	[PA-CTL-PAA-XFER-DATE],
	[PA-UNIT-STS],
	[PA-ACCT-TYPE],
	[PA-MED-REC-NO],
	[PA-PT-NAME]
	)
SELECT [PA-PT-NO-WOSCD],
	[PA-PT-NO-SCD],
	[PA-UNIT-NO],
	[ADMIT_DATE],
	[DSCH_DATE],
	[PA-UNIT-DATE],
	[PA-CTL-PAA-XFER-DATE],
	[PA-UNIT-STS],
	[PA-ACCT-TYPE],
	[PA-MED-REC-NO],
	[PA-PT-NAME]
FROM SMS.[dbo].[ENCOUNTERS_FOR_REPORTING]
WHERE [pa-unit-sts] <> 'U'
	OR [pa-unit-no] = '0'
GROUP BY [PA-PT-NO-WOSCD],
	[PA-PT-NO-SCD],
	[PA-UNIT-NO],
	[ADMIT_DATE],
	[DSCH_DATE],
	[PA-UNIT-DATE],
	[PA-CTL-PAA-XFER-DATE],
	[PA-UNIT-STS],
	[PA-ACCT-TYPE],
	[PA-MED-REC-NO],
	[PA-PT-NAME]

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

/*Roll Up Payments to the Insurance Plan Level*/

USE [SMS]

DROP TABLE IF EXISTS dbo.[Ins_Plan_Payment_Rollup_Alt]

GO

SELECT [pa-pt-no-woscd],
	[pa-pt-no-scd],
	[pa-ctl-paa-xfer-date],
	cast([pa-pt-no-woscd] AS VARCHAR) + CAST([pa-pt-no-scd] AS VARCHAR) AS 'PT-NO',
	[pa-unit-no],
	[unit-date],
	[pa-dtl-ins-co-cd],
	[pa-dtl-ins-plan-no],
	CASE 
		WHEN LEN(ltrim(rtrim([pa-dtl-ins-plan-no]))) = '1'
			THEN CAST(CAST(LTRIM(RTRIM([pa-dtl-ins-co-cd])) AS VARCHAR) + CONVERT(VARCHAR(1), 0) + CAST(LTRIM(RTRIM([pa-dtl-ins-plan-no])) AS VARCHAR) AS VARCHAR)
		WHEN LEN(LTRIM(RTRIM([pa-dtl-ins-plan-no]))) = '2'
			THEN CAST(CAST(LTRIM(RTRIM([pa-dtl-ins-co-cd])) AS VARCHAR) + CAST(LTRIM(RTRIM([pa-dtl-ins-plan-no])) AS VARCHAR) AS VARCHAR)
		END AS 'PA-INS-PLAN',
	[pa-unit-sts],
	MIN([1ST-PAID-DATE]) AS '1st-paid-date',
	sum([tot-payments]) AS 'Tot_Ins_Pymts'
INTO [Ins_Plan_Payment_Rollup_Alt]
FROM [SMS].dbo.[Payments_For_Reporting_Ins_Plan_Level_ALT]
--where [pa-pt-no-woscd] = '1003829155'
--WHERE [pa-pt-no-woscd] = '1000214949'
--where [pa-pt-no-woscd]  = '1008169495'
GROUP BY [pa-pt-no-woscd],
	[pa-pt-no-scd],
	[pa-ctl-paa-xfer-date],
	[pa-unit-no],
	[unit-date],
	[pa-dtl-ins-co-cd],
	[pa-dtl-ins-plan-no],
	[pa-unit-sts]

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

/*Create Custom Insurance Table*/

DROP TABLE IF EXISTS DBO.[CUSTOMINSURANCE_SM_1_ALT]

GO;

-- Add new table
CREATE TABLE [CUSTOMINSURANCE_SM_1_ALT] (
	[PA-PT-NO-WOSCD] DECIMAL(11, 0) NOT NULL,
	[PA-PT-NO-SCD] CHAR(1) NOT NULL,
	[PA-CTL-PAA-XFER-DATE] DATETIME NULL,
	[PA-UNIT-STS] VARCHAR(1) NULL,
	[pa-unit-no] DECIMAL(4, 0) NULL,
	[PA-UNIT-DATE] DATETIME NULL,
	--[PA-INS-PRTY] DECIMAL(1,0) NULL,
	[PA-INS-PLAN] VARCHAR(100) NULL,
	[PA-INS-POL-NO] CHAR(11) NULL,
	[PA-INS-SUBSCR-INS-GROUP-ID] CHAR(20) NULL,
	[PA-INS-GRP-NO] CHAR(6) NULL,
	[PA-LAST-INS-PAY-DATE] DATETIME NULL,
	[PA-BAL-INS-PROR-NET-AMT] MONEY NULL,
	[INS-PAY-AMT] MONEY NULL,
	[RANK1] CHAR(4) NULL --,
	--[IM-IND] VARCHAR(50) NULL
	--[REPORT-GROUP] VARCHAR(75) NULL
	);

INSERT INTO [CustomInsurance_SM_1_ALT] (
	[PA-PT-NO-WOSCD],
	[PA-PT-NO-SCD],
	[PA-CTL-PAA-XFER-DATE],
	[PA-UNIT-STS],
	[PA-UNIT-NO],
	[PA-UNIT-DATE],
	[PA-INS-PLAN],
	[PA-INS-POL-NO],
	[PA-INS-SUBSCR-INS-GROUP-ID],
	[PA-INS-GRP-NO],
	[PA-LAST-INS-PAY-DATE],
	[PA-BAL-INS-PROR-NET-AMT],
	[INS-PAY-AMT],
	[RANK1]
	) --,[IM-IND])--,[REPORT-GROUP])
SELECT DISTINCT (a.[PA-PT-NO-WOSCD]),
	a.[PA-PT-NO-SCD],
	A.[PA-CTL-PAA-XFER-DATE],
	A.[PA-UNIT-STS],
	A.[PA-UNIT-NO],
	A.[PA-UNIT-DATE],
	--B.[PA-INS-PRTY],
	CASE 
		WHEN LEN(ltrim(rtrim(b.[pa-ins-plan-no]))) = '1'
			THEN CAST(CAST(LTRIM(RTRIM(B.[pa-ins-co-cd])) AS VARCHAR) + CONVERT(VARCHAR(1), 0) + CAST(LTRIM(RTRIM(B.[pa-ins-plan-no])) AS VARCHAR) AS VARCHAR)
		WHEN LEN(LTRIM(RTRIM(b.[pa-ins-plan-no]))) = '2'
			THEN CAST(CAST(LTRIM(RTRIM(B.[pa-ins-co-cd])) AS VARCHAR) + CAST(LTRIM(RTRIM(B.[pa-ins-plan-no])) AS VARCHAR) AS VARCHAR)
				--ELSE 'SELF_PAY'
		END AS 'PA-INS-PLAN',
	[PA-INS-POL-NO],
	[PA-INS-SUBSCR-INS-GROUP-ID],
	[PA-INS-GRP-NO],
	CASE 
		WHEN A.[PA-UNIT-STS] <> 'U'
			THEN B.[PA-LAST-INS-PAY-DATE]
		ELSE NULL
		END AS [PA-LAST-INS-PAY-DATE],
	CASE 
		WHEN A.[PA-UNIT-STS] <> 'U'
			THEN B.[PA-BAL-INS-PROR-NET-AMT]
		ELSE NULL
		END AS [PA-BAL-INS-PROR-NET-AMT],
	CASE 
		WHEN A.[PA-UNIT-STS] <> 'U'
			THEN ISNULL(B.[PA-BAL-INS-PAY-AMT], 0)
		ELSE NULL
		END AS 'Ins-Pay-Amt',
	RANK() OVER (
		PARTITION BY B.[PA-PT-NO-WOSCD],
		A.[PA-UNIT-DATE] ORDER BY b.[pa-ins-prty] ASC,
			b.[pa-bal-ins-pay-amt] ASC,
			b.[pa-ins-co-cd] ASC,
			b.[pa-ins-plan-no] ASC
		) AS 'RANK1'
--C.[IM-IND]
FROM [SMS].[dbo].[DISTINCT_ENCOUNTERS_FOR_REPORTING_ALT] a
INNER JOIN [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Archive].DBO.INSURANCEINFORMATION B ON a.[pa-pt-no-woscd] = b.[pa-pt-no-woscd]
	AND a.[pa-ctl-paa-xfer-date] = b.[pa-ctl-paa-xfer-date]
--left outer join SMS.[UHMC\smathesi].[IM_Patients] C
--ON A.[PA-PT-NO-WOSCD] = C.[PA-PT-NO-WOSCD]
--where [pa-bal-ins-pror-net-amt] is not null
--WHERE A.[PA-DELETE-DATE] IS NULL
--ORDER BY a.[pa-pt-no-woscd]
--WHERE a.[pa-pt-no-woscd] = '1014280155'
--WHERE a.[pa-pt-no-woscd] = '1014280144'
--WHERE a.[pa-pt-no-woscd] = '1003829155'--Unit

UNION

SELECT DISTINCT (a.[PA-PT-NO-WOSCD]),
	a.[PA-PT-NO-SCD],
	A.[PA-CTL-PAA-XFER-DATE],
	A.[PA-UNIT-STS],
	A.[PA-UNIT-NO],
	A.[PA-UNIT-DATE],
	--B.[PA-INS-PRTY],
	CASE 
		WHEN LEN(ltrim(rtrim(b.[pa-ins-plan-no]))) = '1'
			THEN CAST(CAST(LTRIM(RTRIM(B.[pa-ins-co-cd])) AS VARCHAR) + CONVERT(VARCHAR(1), 0) + CAST(LTRIM(RTRIM(B.[pa-ins-plan-no])) AS VARCHAR) AS VARCHAR)
		WHEN LEN(LTRIM(RTRIM(b.[pa-ins-plan-no]))) = '2'
			THEN CAST(CAST(LTRIM(RTRIM(B.[pa-ins-co-cd])) AS VARCHAR) + CAST(LTRIM(RTRIM(B.[pa-ins-plan-no])) AS VARCHAR) AS VARCHAR)
				--ELSE 'SELF_PAY'
		END AS 'PA-INS-PLAN',
	[PA-INS-POL-NO],
	[PA-INS-SUBSCR-INS-GROUP-ID],
	[PA-INS-GRP-NO],
	CASE 
		WHEN A.[PA-UNIT-STS] <> 'U'
			THEN B.[PA-LAST-INS-PAY-DATE]
		ELSE NULL
		END AS [PA-LAST-INS-PAY-DATE],
	CASE 
		WHEN A.[PA-UNIT-STS] <> 'U'
			THEN B.[PA-BAL-INS-PROR-NET-AMT]
		ELSE NULL
		END AS [PA-BAL-INS-PROR-NET-AMT],
	CASE 
		WHEN A.[PA-UNIT-STS] <> 'U'
			THEN ISNULL(B.[PA-BAL-INS-PAY-AMT], 0)
		ELSE NULL
		END AS 'Ins-Pay-Amt',
	RANK() OVER (
		PARTITION BY B.[PA-PT-NO-WOSCD],
		A.[PA-UNIT-DATE] ORDER BY b.[pa-ins-prty] ASC,
			b.[pa-bal-ins-pay-amt] ASC,
			b.[pa-ins-co-cd] ASC,
			b.[pa-ins-plan-no] ASC
		) AS 'RANK1'
--C.[IM-IND]
FROM [SMS].[dbo].[DISTINCT_ENCOUNTERS_FOR_REPORTING_ALT] a
INNER JOIN [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[echo_active].DBO.INSURANCEINFORMATION B ON a.[pa-pt-no-woscd] = b.[pa-pt-no-woscd]
	AND a.[pa-ctl-paa-xfer-date] = b.[pa-ctl-paa-xfer-date]
	--WHERE a.[pa-pt-no-woscd] = '1014280155'
	--WHERE a.[pa-pt-no-woscd] = '1014280144'
	--WHERE a.[pa-pt-no-woscd] = '1003829155'--Unit
    --WHERE [pa-pt-no-woscd] =

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*Pivot Ins Payment Rollup And Add Insurance Rank*/

DROP TABLE IF EXISTS [dbo].[PIVOT_INS_PYMT_ROLLUPS_ADD_RANK_ALT]
GO

CREATE TABLE [PIVOT_INS_PYMT_ROLLUPS_ADD_RANK_ALT] (
	[PA-PT-NO-woscd] VARCHAR(12) NOT NULL,
	[pa-pt-no-scd] VARCHAR(1) NOT NULL,
	[pa-ctl-paa-xfer-date] DATETIME NULL,
	[pt-no] VARCHAR(13) NULL,
	[pa-unit-no] CHAR(4) NULL,
	[pa-unit-date] DATETIME NULL,
	[pa-ins-plan] VARCHAR(4) NULL,
	[pa-unit-sts] VARCHAR(1) NULL,
	[rank1] VARCHAR(3) NULL,
	[1st-Paid-Date] DATETIME NULL,
	[tot_ins_pymts] MONEY NULL
	);

INSERT INTO [PIVOT_INS_PYMT_ROLLUPS_ADD_RANK_ALT] (
	[pa-pt-no-woscd],
	[pa-pt-no-scd],
	[pa-ctl-paa-xfer-date],
	[PT-NO],
	[pa-unit-no],
	[pa-unit-date],
	[PA-INS-PLAN],
	[PA-UNIT-STS],
	[RANK1],
	[1ST-PAID-DATE],
	[TOT_INS_PYMTS]
	)
SELECT A.[PA-PT-NO-woscd],
	A.[pa-pt-no-scd],
	A.[pa-ctl-paa-xfer-date],
	A.[pt-no],
	A.[pa-unit-no],
	A.[unit-date],
	A.[pa-ins-plan],
	A.[pa-unit-sts],
	B.[rank1],
	a.[1st-paid-date],
	A.[tot_ins_pymts]
FROM [Ins_Plan_Payment_Rollup_Alt] A
INNER JOIN [CustomInsurance_SM_1_ALT] B ON a.[pa-pt-no-woscd] = b.[pa-pt-no-woscd]
	AND a.[pa-ctl-paa-xfer-date] = b.[pa-ctl-paa-xfer-date]
	AND a.[unit-date] = b.[pa-unit-date]
	AND a.[pa-ins-plan] = b.[pa-ins-plan]
--inner JOIN [CustomInsurance_SM_1] C
--ON a.[pa-pt-no-woscd] = C.[pa-pt-no-woscd] and a.[pa-ctl-paa-xfer-date] = C.[pa-ctl-paa-xfer-date] and a.[unit-date]=C.[pa-unit-date] and a.[pa-ins-plan]=C.[pa-ins-plan] and c.[rank1] = '2'
--inner JOIN [CustomInsurance_SM_1] d
--ON a.[pa-pt-no-woscd] = d.[pa-pt-no-woscd] and a.[pa-ctl-paa-xfer-date] = d.[pa-ctl-paa-xfer-date] and a.[unit-date]=d.[pa-unit-date] and a.[pa-ins-plan]=d.[pa-ins-plan] and d.[rank1] = '3'
--inner JOIN [CustomInsurance_SM_1] e
--ON a.[pa-pt-no-woscd] = e.[pa-pt-no-woscd] and a.[pa-ctl-paa-xfer-date] = e.[pa-ctl-paa-xfer-date] and a.[unit-date]=e.[pa-unit-date] and a.[pa-ins-plan]=e.[pa-ins-plan] and e.[rank1] = '4'
--WHERE a.[pa-pt-no-woscd] = '1003829155'
--WHERE a.[pa-pt-no-woscd] = '1014280155'
--WHERE a.[pa-pt-no-woscd] = '1014280144'

UNION

SELECT A.[PA-PT-NO-woscd],
	A.[pa-pt-no-scd],
	A.[pa-ctl-paa-xfer-date],
	A.[pt-no],
	A.[pa-unit-no],
	A.[unit-date],
	A.[pa-ins-plan],
	A.[pa-unit-sts],
	B.[rank1],
	a.[1st-paid-date],
	A.[tot_ins_pymts]
FROM [Ins_Plan_Payment_Rollup_Alt] A
INNER JOIN [CustomInsurance_SM_1_ALT] B ON a.[pa-pt-no-woscd] = b.[pa-pt-no-woscd]
	AND a.[pa-ctl-paa-xfer-date] = b.[pa-ctl-paa-xfer-date]
	AND a.[pa-unit-sts] <> 'U'
	AND a.[pa-ins-plan] = b.[pa-ins-plan]
	--inner JOIN [CustomInsurance_SM_1] C
	--ON a.[pa-pt-no-woscd] = C.[pa-pt-no-woscd] and a.[pa-ctl-paa-xfer-date] = C.[pa-ctl-paa-xfer-date] and a.[pa-unit-sts] <> 'U' and a.[pa-ins-plan]=C.[pa-ins-plan] and c.[rank1] = '2'
	--inner JOIN [CustomInsurance_SM_1] d
	--ON a.[pa-pt-no-woscd] = d.[pa-pt-no-woscd] and a.[pa-ctl-paa-xfer-date] = d.[pa-ctl-paa-xfer-date] and a.[pa-unit-sts] <> 'U' and a.[pa-ins-plan]=d.[pa-ins-plan] and d.[rank1] = '3'
	--inner JOIN [CustomInsurance_SM_1] e
	--ON a.[pa-pt-no-woscd] = e.[pa-pt-no-woscd] and a.[pa-ctl-paa-xfer-date] = e.[pa-ctl-paa-xfer-date] and a.[pa-unit-sts] <> 'U' and a.[pa-ins-plan]=e.[pa-ins-plan] and e.[rank1] = '4'
	--WHERE a.[pa-pt-no-woscd] = '1003829155'
	--AND b.[Rank1] is not null
	--AND c.[Rank1] is not null
	--AND d.[Rank1] is not null
	--WHERE a.[pa-pt-no-woscd] = '1014280155'
	--WHERE a.[pa-pt-no-woscd] = '1014280144'

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

/* Filter Out Unit Records From Custom Insurance SM 1*/

DROP TABLE IF EXISTS [dbo].[CustomInsurance_SM_1A_ALT]
GO

SELECT *
INTO dbo.[CustomInsurance_SM_1A_ALT]
FROM dbo.[CustomInsurance_SM_1_ALT]
WHERE [pa-unit-date] IS NULL

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

/*Pivot Insurance Data*/

DROP TABLE IF EXISTS [dbo].[CUSTOM_INSURANCE_PIVOT_SM_ALT]
GO

CREATE TABLE [CUSTOM_INSURANCE_PIVOT_SM_ALT] (
	[PA-PT-NO-woscd] VARCHAR(12) NOT NULL,
	[pa-pt-no-scd] VARCHAR(1) NOT NULL,
	[pa-ctl-paa-xfer-date] DATETIME NULL,
	[pa-unit-no] CHAR(6) NULL,
	[pa-med-rec-no] CHAR(12) NULL,
	[pa-pt-name] CHAR(60) NULL,
	[admit_date] DATETIME NULL,
	[dsch_date] DATETIME NULL,
	[pa-unit-date] DATETIME NULL,
	[pa-acct-type] CHAR(2) NULL,
	[COB_1] CHAR(4) NULL,
	[INS1] CHAR(4) NULL,
	[INS1_POL_NO] CHAR(30) NULL,
	[INS1_SUBSCR_GROUP_ID] CHAR(30) NULL,
	[INS1_GRP_NO] CHAR(30) NULL,
	--[INS1_PYMTS] MONEY NULL,
	[INS1_BALANCE] MONEY NULL,
	[COB_2] CHAR(4) NULL,
	[INS2] CHAR(4) NULL,
	[INS2_POL_NO] CHAR(30) NULL,
	[INS2_SUBSCR_GROUP_ID] CHAR(30) NULL,
	[INS2_GRP_NO] CHAR(30) NULL,
	--[INS2_PYMTS] MONEY NULL,
	[INS2_BALANCE] MONEY NULL,
	[COB_3] CHAR(4) NULL,
	[INS3] CHAR(4) NULL,
	[INS3_POL_NO] CHAR(30) NULL,
	[INS3_SUBSCR_GROUP_ID] CHAR(30) NULL,
	[INS3_GRP_NO] CHAR(30) NULL,
	--[INS3_PYMTS] MONEY NULL,
	[INS3_BALANCE] MONEY NULL,
	[COB_4] CHAR(4) NULL,
	[INS4] CHAR(4) NULL,
	[INS4_POL_NO] CHAR(30) NULL,
	[INS4_SUBSCR_GROUP_ID] CHAR(30) NULL,
	[INS4_GRP_NO] CHAR(30) NULL,
	--[INS4_PYMTS] MONEY NULL,
	[INS4_BALANCE] MONEY NULL
	);

INSERT INTO [CUSTOM_INSURANCE_PIVOT_SM_ALT] (
	[pa-pt-no-woscd],
	[pa-pt-no-scd],
	[pa-ctl-paa-xfer-date],
	[pa-unit-no],
	[pa-med-rec-no],
	[pa-pt-name],
	[admit_date],
	[dsch_date],
	[pa-unit-date],
	[pa-acct-type],
	[COB_1],
	[INS1],
	[INS1_POL_NO],
	[INS1_SUBSCR_GROUP_ID],
	[INS1_GRP_NO],
	[INS1_BALANCE],
	[COB_2],
	[INS2],
	[INS2_POL_NO],
	[INS2_SUBSCR_GROUP_ID],
	[INS2_GRP_NO],
	[INS2_BALANCE],
	[COB_3],
	[INS3],
	[INS3_POL_NO],
	[INS3_SUBSCR_GROUP_ID],
	[INS3_GRP_NO],
	[INS3_BALANCE],
	[COB_4],
	[INS4],
	[INS4_POL_NO],
	[INS4_SUBSCR_GROUP_ID],
	[INS4_GRP_NO],
	[INS4_BALANCE]
	)
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
	b.[rank1] AS 'COB_1',
	b.[pa-ins-plan] AS 'INS1',
	CASE 
		WHEN LEN(b.[pa-ins-pol-no]) = '0'
			THEN NULL
		ELSE b.[pa-ins-pol-no]
		END AS 'INS1_POL_NO',
	--b.[pa-ins-pol-no] AS 'INS1_POL_NO',
	CASE 
		WHEN LEN(b.[pa-ins-subscr-ins-group-id]) = '0'
			THEN NULL
		ELSE b.[pa-ins-subscr-ins-group-id]
		END AS 'INS1_SUBSCR_GROUP_ID',
	CASE 
		WHEN LEN(b.[pa-ins-grp-no]) = '0'
			THEN NULL
		ELSE b.[pa-ins-grp-no]
		END AS 'INS1_GRP_NO',
	B.[PA-BAL-INS-PROR-NET-AMT] 'INS1_BALANCE',
	c.[rank1] AS 'COB_2',
	c.[pa-ins-plan] AS 'INS2',
	c.[pa-ins-pol-no] AS 'INS2_POL_NO',
	c.[pa-ins-subscr-ins-group-id] AS 'INS2_SUBSCR_GROUP_ID',
	c.[pa-ins-grp-no] AS 'INS2_GRP_NO',
	C.[PA-BAL-INS-PROR-NET-AMT] 'INS2_BALANCE',
	d.[rank1] AS 'COB_3',
	d.[pa-ins-plan] AS 'INS3',
	d.[pa-ins-pol-no] AS 'INS3_POL_NO',
	d.[pa-ins-subscr-ins-group-id] AS 'INS3_SUBSCR_GROUP_ID',
	d.[pa-ins-grp-no] AS 'INS3_GRP_NO',
	D.[PA-BAL-INS-PROR-NET-AMT] 'INS3_BALANCE',
	e.[rank1] AS 'COB_4',
	e.[pa-ins-plan] AS 'INS4',
	e.[pa-ins-pol-no] AS 'INS4_POL_NO',
	e.[pa-ins-subscr-ins-group-id] AS 'INS4_SUBSCR_GROUP_ID',
	e.[pa-ins-grp-no] AS 'INS4_GRP_NO',
	E.[PA-BAL-INS-PROR-NET-AMT] 'INS4_BALANCE'
FROM SMS.[dbo].[DISTINCT_ENCOUNTERS_FOR_REPORTING_2_ALT] a
LEFT OUTER JOIN [SMS].[dbo].[CUSTOMINSURANCE_SM_1A_ALT] b ON a.[pa-pt-no-woscd] = b.[pa-pt-no-woscd]
	AND b.[rank1] = '1'
	AND a.[pa-ctl-paa-xfer-date] = b.[pa-ctl-paa-xfer-date]
LEFT OUTER JOIN [SMS].[dbo].[CUSTOMINSURANCE_SM_1A_ALT] c ON a.[pa-pt-no-woscd] = c.[pa-pt-no-woscd]
	AND c.[rank1] = '2'
	AND a.[pa-ctl-paa-xfer-date] = c.[pa-ctl-paa-xfer-date]
LEFT OUTER JOIN [SMS].[dbo].[CUSTOMINSURANCE_SM_1A_ALT] d ON a.[pa-pt-no-woscd] = d.[pa-pt-no-woscd]
	AND d.[rank1] = '3'
	AND a.[pa-ctl-paa-xfer-date] = d.[pa-ctl-paa-xfer-date]
LEFT OUTER JOIN [SMS].[dbo].[CUSTOMINSURANCE_SM_1A_ALT] e ON a.[pa-pt-no-woscd] = e.[pa-pt-no-woscd]
	AND e.[rank1] = '4'
	AND a.[pa-ctl-paa-xfer-date] = e.[pa-ctl-paa-xfer-date]
--WHERE a.[pa-pt-no-woscd] = '1003829155'
WHERE a.[pa-unit-date] IS NULL

UNION

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
	b.[rank1] AS 'COB_1',
	b.[pa-ins-plan] AS 'INS1',
	CASE 
		WHEN LEN(b.[pa-ins-pol-no]) = '0'
			THEN NULL
		ELSE b.[pa-ins-pol-no]
		END AS 'INS1_POL_NO',
	--b.[pa-ins-pol-no] AS 'INS1_POL_NO',
	CASE 
		WHEN LEN(b.[pa-ins-subscr-ins-group-id]) = '0'
			THEN NULL
		ELSE b.[pa-ins-subscr-ins-group-id]
		END AS 'INS1_SUBSCR_GROUP_ID',
	CASE 
		WHEN LEN(b.[pa-ins-grp-no]) = '0'
			THEN NULL
		ELSE b.[pa-ins-grp-no]
		END AS 'INS1_GRP_NO',
	B.[PA-BAL-INS-PROR-NET-AMT] 'INS1_BALANCE',
	c.[rank1] AS 'COB_2',
	c.[pa-ins-plan] AS 'INS2',
	c.[pa-ins-pol-no] AS 'INS2_POL_NO',
	c.[pa-ins-subscr-ins-group-id] AS 'INS2_SUBSCR_GROUP_ID',
	c.[pa-ins-grp-no] AS 'INS2_GRP_NO',
	C.[PA-BAL-INS-PROR-NET-AMT] 'INS2_BALANCE',
	d.[rank1] AS 'COB_3',
	d.[pa-ins-plan] AS 'INS3',
	d.[pa-ins-pol-no] AS 'INS3_POL_NO',
	d.[pa-ins-subscr-ins-group-id] AS 'INS3_SUBSCR_GROUP_ID',
	d.[pa-ins-grp-no] AS 'INS3_GRP_NO',
	D.[PA-BAL-INS-PROR-NET-AMT] 'INS3_BALANCE',
	e.[rank1] AS 'COB_4',
	e.[pa-ins-plan] AS 'INS4',
	e.[pa-ins-pol-no] AS 'INS4_POL_NO',
	e.[pa-ins-subscr-ins-group-id] AS 'INS4_SUBSCR_GROUP_ID',
	e.[pa-ins-grp-no] AS 'INS4_GRP_NO',
	E.[PA-BAL-INS-PROR-NET-AMT] 'INS4_BALANCE'
FROM SMS.[dbo].[Encounters_For_REPORTING] a
LEFT OUTER JOIN [SMS].[dbo].[CUSTOMINSURANCE_SM_1_ALT] b ON a.[pa-pt-no-woscd] = b.[pa-pt-no-woscd]
	AND b.[rank1] = '1'
	AND a.[pa-ctl-paa-xfer-date] = b.[pa-ctl-paa-xfer-date]
	AND a.[pa-unit-date] = b.[pa-unit-date]
LEFT OUTER JOIN [dbo].[CUSTOMINSURANCE_SM_1_ALT] c ON a.[pa-pt-no-woscd] = c.[pa-pt-no-woscd]
	AND c.[rank1] = '2'
	AND a.[pa-ctl-paa-xfer-date] = c.[pa-ctl-paa-xfer-date]
	AND a.[pa-unit-date] = c.[pa-unit-date]
LEFT OUTER JOIN [dbo].[CUSTOMINSURANCE_SM_1_ALT] d ON a.[pa-pt-no-woscd] = d.[pa-pt-no-woscd]
	AND d.[rank1] = '3'
	AND a.[pa-ctl-paa-xfer-date] = d.[pa-ctl-paa-xfer-date]
	AND a.[pa-unit-date] = d.[pa-unit-date]
LEFT OUTER JOIN [dbo].[CUSTOMINSURANCE_SM_1_ALT] e ON a.[pa-pt-no-woscd] = e.[pa-pt-no-woscd]
	AND e.[rank1] = '4'
	AND a.[pa-ctl-paa-xfer-date] = e.[pa-ctl-paa-xfer-date]
	AND a.[pa-unit-date] = e.[pa-unit-date]
--left outer join [dbo].[#CUSTOMINSURANCE] f
--ON a.[pa-pt-no-woscd]=f.[pa-pt-no-woscd] and f.[rank1]='5' --AND a.[pa-unit-no] is null
--left outer join [dbo].[#CUSTOMINSURANCE] g
--ON a.[pa-pt-no-woscd]=g.[pa-pt-no-woscd] and g.[rank1]='6'  --AND a.[pa-unit-no] is null
--left outer join [dbo].[#CUSTOMINSURANCE] h
--ON a.[pa-pt-no-woscd]=h.[pa-pt-no-woscd] and h.[rank1]='7' -- AND a.[pa-unit-no] is null
--left outer join [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Active].dbo.[UnitizedAccounts] m
--on a.[pa-pt-no-woscd] = m.[pa-pt-no-woscd] and a.[pa-unit-date]=m.[pa-unit-date]
--WHERE a.[pa-pt-no-woscd] = '1003829155'
WHERE a.[pa-unit-date] IS NOT NULL

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

/*Pivot Insurance Data And Add Unit Info*/

DROP TABLE IF EXISTS [dbo].[CUSTOM_INSURANCE_SM_2_ALT]
GO

CREATE TABLE [CUSTOM_INSURANCE_SM_2_ALT] (
	[PA-PT-NO-woscd] VARCHAR(12) NOT NULL,
	[pa-pt-no-scd] VARCHAR(1) NOT NULL,
	[pa-ctl-paa-xfer-date] DATETIME NULL,
	[pa-unit-no] CHAR(6) NULL,
	[pa-med-rec-no] CHAR(12) NULL,
	[pa-pt-name] CHAR(60) NULL,
	[admit_date] DATETIME NULL,
	[dsch_date] DATETIME NULL,
	[pa-unit-date] DATETIME NULL,
	[pa-acct-type] CHAR(2) NULL,
	[COB_1] CHAR(4) NULL,
	[INS1] CHAR(4) NULL,
	[INS1_POL_NO] CHAR(30) NULL,
	[INS1_SUBSCR_GROUP_ID] CHAR(30) NULL,
	[INS1_GRP_NO] CHAR(30) NULL,
	--[INS1_PYMTS] MONEY NULL,
	--[INS1-FIRST-PAID-DATE] DATETIME NULL,
	[INS1_BALANCE] MONEY NULL,
	[COB_2] CHAR(4) NULL,
	[INS2] CHAR(4) NULL,
	[INS2_POL_NO] CHAR(30) NULL,
	[INS2_SUBSCR_GROUP_ID] CHAR(30) NULL,
	[INS2_GRP_NO] CHAR(30) NULL,
	--[INS2_PYMTS] MONEY NULL,
	--[INS2-FIRST-PAID-DATE] DATETIME NULL,
	[INS2_BALANCE] MONEY NULL,
	[COB_3] CHAR(4) NULL,
	[INS3] CHAR(4) NULL,
	[INS3_POL_NO] CHAR(30) NULL,
	[INS3_SUBSCR_GROUP_ID] CHAR(30) NULL,
	[INS3_GRP_NO] CHAR(30) NULL,
	--[INS3_PYMTS] MONEY NULL,
	--[INS3-FIRST-PAID-DATE] DATETIME NULL,
	[INS3_BALANCE] MONEY NULL,
	[COB_4] CHAR(4) NULL,
	[INS4] CHAR(4) NULL,
	[INS4_POL_NO] CHAR(30) NULL,
	[INS4_SUBSCR_GROUP_ID] CHAR(30) NULL,
	[INS4_GRP_NO] CHAR(30) NULL,
	--[INS4_PYMTS] MONEY NULL,
	--[INS4-FIRST-PAID-DATE] NULL,
	[INS4_BALANCE] MONEY NULL
	);

INSERT INTO [CUSTOM_INSURANCE_SM_2_ALT] (
	[pa-pt-no-woscd],
	[pa-pt-no-scd],
	[pa-ctl-paa-xfer-date],
	[pa-unit-no],
	[pa-med-rec-no],
	[pa-pt-name],
	[admit_date],
	[dsch_date],
	[pa-unit-date],
	[pa-acct-type],
	[COB_1],
	[INS1],
	[INS1_POL_NO],
	[INS1_SUBSCR_GROUP_ID],
	[INS1_GRP_NO],
	[INS1_BALANCE],
	[COB_2],
	[INS2],
	[INS2_POL_NO],
	[INS2_SUBSCR_GROUP_ID],
	[INS2_GRP_NO],
	[INS2_BALANCE],
	[COB_3],
	[INS3],
	[INS3_POL_NO],
	[INS3_SUBSCR_GROUP_ID],
	[INS3_GRP_NO],
	[INS3_BALANCE],
	[COB_4],
	[INS4],
	[INS4_POL_NO],
	[INS4_SUBSCR_GROUP_ID],
	[INS4_GRP_NO],
	[INS4_BALANCE]
	)
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
	a.[COB_1],
	a.[INS1],
	a.[INS1_POL_NO],
	a.[INS1_SUBSCR_GROUP_ID],
	a.[INS1_GRP_NO],
	COALESCE(n.[pa-unit-ins1-bal], M.[PA-UNIT-INS1-BAL], A.[INS1_BALANCE]) AS 'INS1_BALANCE',
	a.[COB_2],
	a.[INS2],
	a.[INS2_POL_NO],
	a.[INS2_SUBSCR_GROUP_ID],
	a.[INS2_GRP_NO],
	COALESCE(n.[pa-unit-ins2-bal], M.[PA-UNIT-INS2-BAL], A.[INS2_BALANCE]) AS 'INS2_BALANCE',
	A.[COB_3],
	A.[INS3],
	A.[INS3_POL_NO],
	A.[INS3_SUBSCR_GROUP_ID],
	A.[INS3_GRP_NO],
	COALESCE(n.[pa-unit-ins3-bal], M.[PA-UNIT-INS3-BAL], A.[INS3_BALANCE]) AS 'INS3_BALANCE',
	A.[COB_4],
	A.[INS4],
	A.[INS4_POL_NO],
	A.[INS4_SUBSCR_GROUP_ID],
	A.[INS4_GRP_NO],
	COALESCE(n.[pa-unit-ins4-bal], M.[PA-UNIT-INS4-BAL], A.[INS4_BALANCE]) AS 'INS4_BALANCE'
FROM [CUSTOM_INSURANCE_PIVOT_SM_ALT] a
LEFT OUTER JOIN [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Active].dbo.[UnitizedAccounts] m ON a.[pa-pt-no-woscd] = m.[pa-pt-no-woscd]
	AND a.[pa-unit-date] = M.[pa-unit-date]
	AND a.[pa-ctl-paa-xfer-date] = m.[pa-ctl-paa-xfer-date]
LEFT OUTER JOIN [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Archive].dbo.[UnitizedAccounts] n ON a.[pa-pt-no-woscd] = n.[pa-pt-no-woscd]
	AND a.[pa-unit-date] = n.[pa-unit-date]
	AND a.[pa-ctl-paa-xfer-date] = n.[pa-ctl-paa-xfer-date]
--WHERE  a.[pa-pt-no-woscd] = '1000214949'
--WHERE a.[pa-pt-no-woscd] = '1003829155'
WHERE a.[pa-unit-date] IS NOT NULL

UNION

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
	a.[COB_1],
	a.[INS1],
	a.[INS1_POL_NO],
	a.[INS1_SUBSCR_GROUP_ID],
	a.[INS1_GRP_NO],
	COALESCE(n.[pa-unit-ins1-bal], M.[PA-UNIT-INS1-BAL], A.[INS1_BALANCE]) AS 'INS1_BALANCE',
	a.[COB_2],
	a.[INS2],
	a.[INS2_POL_NO],
	a.[INS2_SUBSCR_GROUP_ID],
	a.[INS2_GRP_NO],
	COALESCE(n.[pa-unit-ins2-bal], M.[PA-UNIT-INS2-BAL], A.[INS2_BALANCE]) AS 'INS2_BALANCE',
	A.[COB_3],
	A.[INS3],
	A.[INS3_POL_NO],
	A.[INS3_SUBSCR_GROUP_ID],
	A.[INS3_GRP_NO],
	COALESCE(n.[pa-unit-ins3-bal], M.[PA-UNIT-INS3-BAL], A.[INS3_BALANCE]) AS 'INS3_BALANCE',
	A.[COB_4],
	A.[INS4],
	A.[INS4_POL_NO],
	A.[INS4_SUBSCR_GROUP_ID],
	A.[INS4_GRP_NO],
	COALESCE(n.[pa-unit-ins4-bal], M.[PA-UNIT-INS4-BAL], A.[INS4_BALANCE]) AS 'INS4_BALANCE'
FROM [CUSTOM_INSURANCE_PIVOT_SM_ALT] a
LEFT OUTER JOIN [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Active].dbo.[UnitizedAccounts] m ON a.[pa-pt-no-woscd] = m.[pa-pt-no-woscd]
	AND a.[pa-unit-no] = M.[pa-unit-no]
	AND a.[pa-ctl-paa-xfer-date] = m.[pa-ctl-paa-xfer-date]
LEFT OUTER JOIN [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Archive].dbo.[UnitizedAccounts] n ON a.[pa-pt-no-woscd] = n.[pa-pt-no-woscd]
	AND a.[pa-unit-no] = n.[pa-unit-no]
	AND a.[pa-ctl-paa-xfer-date] = n.[pa-ctl-paa-xfer-date]
--WHERE  a.[pa-pt-no-woscd] = '1000214949'
--WHERE a.[pa-pt-no-woscd] = '1003829155'
WHERE a.[pa-unit-date] IS NULL

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

/*Create Insurance Final Ins Table*/

DROP TABLE IF EXISTS [SMS].[dbo].[CUSTOM_INSURANCE_SM_ALT]
GO
 
CREATE TABLE [CUSTOM_INSURANCE_SM_ALT] (
	[PA-PT-NO-woscd] VARCHAR(12) NOT NULL,
	[pa-pt-no-scd] VARCHAR(1) NOT NULL,
	[pa-ctl-paa-xfer-date] DATETIME NULL,
	[pa-unit-no] CHAR(6) NULL,
	[pa-med-rec-no] CHAR(12) NULL,
	[pa-pt-name] CHAR(60) NULL,
	[admit_date] DATETIME NULL,
	[dsch_date] DATETIME NULL,
	[pa-unit-date] DATETIME NULL,
	[pa-acct-type] CHAR(2) NULL,
	[COB_1] CHAR(4) NULL,
	[INS1] CHAR(4) NULL,
	[INS1_POL_NO] CHAR(30) NULL,
	[INS1_SUBSCR_GROUP_ID] CHAR(30) NULL,
	[INS1_GRP_NO] CHAR(30) NULL,
	[INS1_PYMTS] MONEY NULL,
	[INS1_FIRST_PAID] DATETIME NULL,
	[INS1_BALANCE] MONEY NULL,
	[COB_2] CHAR(4) NULL,
	[INS2] CHAR(4) NULL,
	[INS2_POL_NO] CHAR(30) NULL,
	[INS2_SUBSCR_GROUP_ID] CHAR(30) NULL,
	[INS2_GRP_NO] CHAR(30) NULL,
	[INS2_PYMTS] MONEY NULL,
	[INS2_FIRST_PAID] DATETIME NULL,
	[INS2_BALANCE] MONEY NULL,
	[COB_3] CHAR(4) NULL,
	[INS3] CHAR(4) NULL,
	[INS3_POL_NO] CHAR(30) NULL,
	[INS3_SUBSCR_GROUP_ID] CHAR(30) NULL,
	[INS3_GRP_NO] CHAR(30) NULL,
	[INS3_PYMTS] MONEY NULL,
	[INS3_FIRST_PAID] DATETIME NULL,
	[INS3_BALANCE] MONEY NULL,
	[COB_4] CHAR(4) NULL,
	[INS4] CHAR(4) NULL,
	[INS4_POL_NO] CHAR(30) NULL,
	[INS4_SUBSCR_GROUP_ID] CHAR(30) NULL,
	[INS4_GRP_NO] CHAR(30) NULL,
	[INS4_PYMTS] MONEY NULL,
	[INS4_FIRST_PAID] DATETIME NULL,
	[INS4_BALANCE] MONEY NULL
	);

INSERT INTO [CUSTOM_INSURANCE_SM_ALT] (
	[pa-pt-no-woscd],
	[pa-pt-no-scd],
	[pa-ctl-paa-xfer-date],
	[pa-unit-no],
	[pa-med-rec-no],
	[pa-pt-name],
	[admit_date],
	[dsch_date],
	[pa-unit-date],
	[pa-acct-type],
	[COB_1],
	[INS1],
	[INS1_POL_NO],
	[INS1_SUBSCR_GROUP_ID],
	[INS1_GRP_NO],
	[INS1_PYMTS],
	[INS1_FIRST_PAID],
	[INS1_BALANCE],
	[COB_2],
	[INS2],
	[INS2_POL_NO],
	[INS2_SUBSCR_GROUP_ID],
	[INS2_GRP_NO],
	[INS2_PYMTS],
	[INS2_FIRST_PAID],
	[INS2_BALANCE],
	[COB_3],
	[INS3],
	[INS3_POL_NO],
	[INS3_SUBSCR_GROUP_ID],
	[INS3_GRP_NO],
	[INS3_PYMTS],
	[INS3_FIRST_PAID],
	[INS3_BALANCE],
	[COB_4],
	[INS4],
	[INS4_POL_NO],
	[INS4_SUBSCR_GROUP_ID],
	[INS4_GRP_NO],
	[INS4_PYMTS],
	[INS4_FIRST_PAID],
	[INS4_BALANCE]
	)
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
	a.[COB_1],
	a.[INS1],
	a.[INS1_POL_NO],
	a.[INS1_SUBSCR_GROUP_ID],
	a.[INS1_GRP_NO],
	b.[tot_ins_pymts] AS 'INS1_PYMTS',
	b.[1st-paid-date] AS 'INS1_FIRST_PAID',
	a.[INS1_BALANCE],
	a.[COB_2],
	a.[INS2],
	a.[INS2_POL_NO],
	a.[INS2_SUBSCR_GROUP_ID],
	a.[INS2_GRP_NO],
	c.[tot_ins_pymts] AS 'INS2_PYMTS',
	C.[1ST-PAID-DATE] AS 'INS2_FIRST_PAID',
	a.[INS2_BALANCE],
	a.[COB_3],
	a.[INS3],
	a.[INS3_POL_NO],
	a.[INS3_SUBSCR_GROUP_ID],
	a.[INS3_GRP_NO],
	d.[tot_ins_pymts] AS 'INS3_PYMTS',
	D.[1ST-PAID-DATE] AS 'INS3_FIRST_PAID',
	a.[INS3_BALANCE],
	a.[COB_4],
	a.[INS4],
	a.[INS4_POL_NO],
	a.[INS4_SUBSCR_GROUP_ID],
	a.[INS4_GRP_NO],
	e.[tot_ins_pymts] AS 'INS4_PYMTS',
	E.[1ST-PAID-DATE] AS 'INS4_FIRST_PAID',
	a.[INS4_BALANCE] --,
FROM [CUSTOM_INSURANCE_SM_2_ALT] a
LEFT OUTER JOIN [Ins_Plan_Payment_Rollup_Alt] b ON a.[pa-pt-no-woscd] = b.[pa-pt-no-woscd]
	AND a.[pa-unit-date] = b.[unit-date]
	AND a.[ins1] = b.[pa-ins-plan]
	AND a.[pa-ctl-paa-xfer-date] = b.[pa-ctl-paa-xfer-date]
LEFT OUTER JOIN [Ins_Plan_Payment_Rollup_Alt] c ON a.[pa-pt-no-woscd] = c.[pa-pt-no-woscd]
	AND a.[pa-unit-date] = c.[unit-date]
	AND a.[ins2] = c.[pa-ins-plan]
	AND a.[pa-ctl-paa-xfer-date] = c.[pa-ctl-paa-xfer-date]
LEFT OUTER JOIN [Ins_Plan_Payment_Rollup_Alt] d ON a.[pa-pt-no-woscd] = d.[pa-pt-no-woscd]
	AND a.[pa-unit-date] = d.[unit-date]
	AND a.[ins3] = d.[pa-ins-plan]
	AND a.[pa-ctl-paa-xfer-date] = d.[pa-ctl-paa-xfer-date]
LEFT OUTER JOIN [Ins_Plan_Payment_Rollup_Alt] e ON a.[pa-pt-no-woscd] = e.[pa-pt-no-woscd]
	AND a.[pa-unit-date] = e.[unit-date]
	AND a.[ins4] = e.[pa-ins-plan]
	AND a.[pa-ctl-paa-xfer-date] = e.[pa-ctl-paa-xfer-date]
--left outer join [Ins_Plan_Payment_Rollup] ff
--ON a.[pa-pt-no-woscd]= ff.[pa-pt-no-woscd] and a.[pa-unit-date] is null and a.[ins1]=ff.[pa-ins-plan]
--left outer join [Ins_Plan_Payment_Rollup] gg
--ON a.[pa-pt-no-woscd]= gg.[pa-pt-no-woscd] and a.[pa-unit-date] is null and a.[ins2]=gg.[pa-ins-plan]
--left outer join [Ins_Plan_Payment_Rollup] hh
--ON a.[pa-pt-no-woscd]= hh.[pa-pt-no-woscd] and a.[pa-unit-date] is null and a.[ins3]=hh.[pa-ins-plan]
--left outer join [Ins_Plan_Payment_Rollup] ii
--ON a.[pa-pt-no-woscd]= ii.[pa-pt-no-woscd] and a.[pa-unit-date] is null and a.[ins4]=ii.[pa-ins-plan]
--where a.[pa-pt-no-woscd] = '1003829155'
WHERE a.[pa-unit-date] IS NOT NULL

UNION

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
	a.[COB_1],
	a.[INS1],
	a.[INS1_POL_NO],
	a.[INS1_SUBSCR_GROUP_ID],
	a.[INS1_GRP_NO],
	ff.[tot_ins_pymts] AS 'INS1_PYMTS',
	ff.[1st-paid-date] AS 'INS1_FIRST_PAID',
	a.[INS1_BALANCE],
	a.[COB_2],
	a.[INS2],
	a.[INS2_POL_NO],
	a.[INS2_SUBSCR_GROUP_ID],
	a.[INS2_GRP_NO],
	gg.[tot_ins_pymts] AS 'INS2_PYMTS',
	GG.[1ST-PAID-DATE] AS 'INS2_FIRST_PAID',
	a.[INS2_BALANCE],
	a.[COB_3],
	a.[INS3],
	a.[INS3_POL_NO],
	a.[INS3_SUBSCR_GROUP_ID],
	a.[INS3_GRP_NO],
	hh.[tot_ins_pymts] AS 'INS3_PYMTS',
	HH.[1ST-PAID-DATE] AS 'INS3_FIRST_PAID',
	a.[INS3_BALANCE],
	a.[COB_4],
	a.[INS4],
	a.[INS4_POL_NO],
	a.[INS4_SUBSCR_GROUP_ID],
	a.[INS4_GRP_NO],
	ii.[tot_ins_pymts] AS 'INS4_PYMTS',
	II.[1ST-PAID-DATE] AS 'INS4_FIRST_PAID',
	a.[INS4_BALANCE] --,
FROM [CUSTOM_INSURANCE_SM_2_ALT] a
LEFT OUTER JOIN [Ins_Plan_Payment_Rollup_Alt] ff ON a.[pa-pt-no-woscd] = ff.[pa-pt-no-woscd]
	AND a.[pa-unit-date] IS NULL
	AND a.[ins1] = ff.[pa-ins-plan]
	AND a.[pa-ctl-paa-xfer-date] = ff.[pa-ctl-paa-xfer-date]
	AND ff.[unit-date] IS NULL
LEFT OUTER JOIN [Ins_Plan_Payment_Rollup_Alt] gg ON a.[pa-pt-no-woscd] = gg.[pa-pt-no-woscd]
	AND a.[pa-unit-date] IS NULL
	AND a.[ins2] = gg.[pa-ins-plan]
	AND a.[pa-ctl-paa-xfer-date] = gg.[pa-ctl-paa-xfer-date]
	AND gg.[unit-date] IS NULL
LEFT OUTER JOIN [Ins_Plan_Payment_Rollup_Alt] hh ON a.[pa-pt-no-woscd] = hh.[pa-pt-no-woscd]
	AND a.[pa-unit-date] IS NULL
	AND a.[ins3] = hh.[pa-ins-plan]
	AND a.[pa-ctl-paa-xfer-date] = hh.[pa-ctl-paa-xfer-date]
	AND hh.[unit-date] IS NULL
LEFT OUTER JOIN [Ins_Plan_Payment_Rollup_Alt] ii ON a.[pa-pt-no-woscd] = ii.[pa-pt-no-woscd]
	AND a.[pa-unit-date] IS NULL
	AND a.[ins4] = ii.[pa-ins-plan]
	AND a.[pa-ctl-paa-xfer-date] = ii.[pa-ctl-paa-xfer-date]
	AND ii.[unit-date] IS NULL
--where a.[pa-pt-no-woscd] = '1003829155'
WHERE a.[pa-unit-date] IS NULL
GO



---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

USE [SMS]
DROP TABLE IF EXISTS SMS.dbo.[DISTINCT_ENCOUNTERS_FOR_REPORTING_ALT]
DROP TABLE IF EXISTS SMS.dbo.[DISTINCT_ENCOUNTERS_FOR_REPORTING_2_ALT]
DROP TABLE IF EXISTS dbo.[Ins_Plan_Payment_Rollup_Alt]
DROP TABLE IF EXISTS DBO.[CUSTOMINSURANCE_SM_1_ALT]
DROP TABLE IF EXISTS [dbo].[PIVOT_INS_PYMT_ROLLUPS_ADD_RANK_ALT]
DROP TABLE IF EXISTS [dbo].[CustomInsurance_SM_1A_ALT]
DROP TABLE IF EXISTS [dbo].[CUSTOM_INSURANCE_PIVOT_SM_ALT]
DROP TABLE IF EXISTS [dbo].[CUSTOM_INSURANCE_SM_2_ALT]
GO
;