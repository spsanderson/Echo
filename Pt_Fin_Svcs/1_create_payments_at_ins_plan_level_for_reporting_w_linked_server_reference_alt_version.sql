/*
1_create_payments_at_ins_plan_level_for_reporting_w_linked_server_reference_alt_version.sql
*/

USE [SMS];

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



 

/*------------------------Create Unitized Charges Table-------------------------------------------------------------------------------*/

DROP TABLE IF EXISTS [Payments_For_Reporting_Ins_Plan_Level_ALT]

GO

 
CREATE TABLE [Payments_For_Reporting_Ins_Plan_Level_ALT] (
	[PA-PT-NO-WOSCD] VARCHAR(11) NOT NULL,
	[PA-PT-NO-SCD] CHAR(1) NOT NULL,
	[PA-CTL-PAA-XFER-DATE] DATETIME NULL,
	[PT-NO] VARCHAR(50) NOT NULL,
	[PA-UNIT-NO] DECIMAL(4, 0) NULL,
	[unit-date] DATETIME NULL,
	[PA-DTL-UNIT-DATE] DATETIME NULL,
	[TYPE] CHAR(3) NULL,
	[PA-DTL-TYPE-IND] CHAR(1) NULL,
	[PA-DTL-HOSP-SVC] VARCHAR(50) NOT NULL,
	[PA-DTL-INS-CO-CD] CHAR(1) NULL,
	[PA-DTL-INS-PLAN-NO] DECIMAL(3, 0) NULL,
	[PA-DTL-GL-NO] CHAR(3) NULL,
	[PA-DTL-SVC-CD] CHAR(9) NULL,
	[PA-DTL-CDM-DESCRIPTION] VARCHAR(50) NULL,
	[PA-UNIT-STS] CHAR(5) NULL,
	[1ST-PAID-DATE] DATETIME NULL,
	[TOT-PAYMENTS] MONEY NULL,
	);

INSERT INTO [Payments_For_Reporting_Ins_Plan_Level_ALT] (
	[PA-PT-NO-WOSCD],
	[PA-PT-NO-SCD],
	[PA-CTL-PAA-XFER-DATE],
	[PT-NO],
	[PA-UNIT-NO],
	[unit-date],
	[PA-DTL-UNIT-DATE],
	[TYPE],
	[PA-DTL-TYPE-IND],
	[PA-DTL-HOSP-SVC],
	[PA-DTL-INS-CO-CD],
	[PA-DTL-INS-PLAN-NO],
	[PA-DTL-GL-NO],
	[PA-DTL-SVC-CD],
	[PA-DTL-CDM-DESCRIPTION],
	[PA-UNIT-STS],
	[1ST-PAID-DATE],
	[TOT-PAYMENTS]
	)
SELECT a.[pa-pt-no-woscd],
	a.[pa-pt-no-scd-1] AS 'PA-PT-NO-SCD',
	a.[pa-ctl-paa-xfer-date],
	CAST(a.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(a.[pa-pt-no-scd-1] AS VARCHAR) AS 'PT-NO',
	B.[PA-UNIT-NO],
	b.[pa-unit-date] AS 'UNIT-DATE',
	A.[PA-DTL-UNIT-DATE],
	B.[PTACCT_TYPE] AS 'TYPE',
	A.[PA-DTL-TYPE-IND],
	A.[PA-DTL-HOSP-SVC],
	A.[PA-DTL-INS-CO-CD],
	A.[PA-DTL-INS-PLAN-NO],
	A.[PA-DTL-GL-NO],
	CAST(A.[PA-DTL-SVC-CD-WOSCD] AS VARCHAR) + CAST(A.[PA-DTL-SVC-CD-SCD] AS VARCHAR) AS 'PA-DTL-SVC-CD',
	A.[PA-DTL-CDM-DESCRIPTION],
	c.[PA-UNIT-STS],
	MIN(a.[pa-dtl-date]) AS '1ST-PAID-DATE',
	SUM(A.[PA-DTL-CHG-AMT]) AS 'TOT-PAYMENTS'
FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Archive].dbo.[DetailInformation] a
INNER JOIN dbo.[Encounters_For_Reporting] b ON a.[pa-pt-no-woscd] = b.[pa-pt-no-woscd]
	AND A.[PA-DTL-UNIT-DATE] = B.[pa-unit-date]
	AND a.[pa-ctl-paa-xfer-date] = b.[pa-ctl-paa-xfer-date]
LEFT JOIN [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Archive].dbo.[PatientDemographics] C ON A.[PA-PT-NO-WOSCD] = C.[PA-PT-NO-WOSCD]
	AND a.[pa-ctl-paa-xfer-date] = c.[pa-ctl-paa-xfer-date]
WHERE (
		a.[pa-dtl-type-ind] = '1'
		OR a.[pa-dtl-svc-cd-woscd] IN ('60320', '60215')
		)
GROUP BY a.[pa-pt-no-woscd],
	a.[pa-pt-no-scd-1],
	a.[pa-ctl-paa-xfer-date],
	B.[PA-UNIT-NO],
	b.[pa-unit-date],
	A.[PA-DTL-UNIT-DATE],
	B.[PTACCT_TYPE],
	A.[PA-DTL-TYPE-IND],
	A.[PA-DTL-HOSP-SVC],
	A.[PA-DTL-INS-CO-CD],
	A.[PA-DTL-INS-PLAN-NO],
	A.[PA-DTL-GL-NO],
	A.[PA-DTL-SVC-CD-WOSCD],
	A.[PA-DTL-SVC-CD-SCD],
	A.[PA-DTL-CDM-DESCRIPTION],
	c.[PA-UNIT-STS]

UNION

SELECT a.[pa-pt-no-woscd],
	a.[pa-pt-no-scd-1] AS 'PA-PT-NO-SCD',
	a.[pa-ctl-paa-xfer-date],
	CAST(a.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(a.[pa-pt-no-scd-1] AS VARCHAR) AS 'PT-NO',
	B.[PA-UNIT-NO],
	b.[pa-unit-date],
	A.[PA-DTL-UNIT-DATE],
	B.[PTACCT_TYPE] AS 'TYPE',
	A.[PA-DTL-TYPE-IND],
	A.[PA-DTL-HOSP-SVC],
	A.[PA-DTL-INS-CO-CD],
	A.[PA-DTL-INS-PLAN-NO],
	A.[PA-DTL-GL-NO],
	CAST(A.[PA-DTL-SVC-CD-WOSCD] AS VARCHAR) + CAST(A.[PA-DTL-SVC-CD-SCD] AS VARCHAR) AS 'PA-DTL-SVC-CD',
	A.[PA-DTL-CDM-DESCRIPTION],
	c.[PA-UNIT-STS],
	MIN(a.[pa-dtl-date]) AS '1ST-PAID-DATE',
	SUM(A.[PA-DTL-CHG-AMT]) AS 'TOT-PAYMENTS'
FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Active].dbo.[DetailInformation] a
INNER JOIN dbo.[Encounters_For_Reporting] b ON a.[pa-pt-no-woscd] = b.[pa-pt-no-woscd]
	AND A.[PA-DTL-UNIT-DATE] = B.[pa-unit-date]
	AND a.[pa-ctl-paa-xfer-date] = b.[pa-ctl-paa-xfer-date]
LEFT JOIN [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Active].dbo.[PatientDemographics] C ON A.[PA-PT-NO-WOSCD] = C.[PA-PT-NO-WOSCD]
	AND a.[pa-ctl-paa-xfer-date] = c.[pa-ctl-paa-xfer-date]
WHERE (
		a.[pa-dtl-type-ind] = '1'
		OR a.[pa-dtl-svc-cd-woscd] IN ('60320', '60215')
		)
GROUP BY a.[pa-pt-no-woscd],
	a.[pa-pt-no-scd-1],
	a.[pa-ctl-paa-xfer-date],
	B.[PA-UNIT-NO],
	b.[pa-unit-date],
	A.[PA-DTL-UNIT-DATE],
	B.[PTACCT_TYPE],
	A.[PA-DTL-TYPE-IND],
	A.[PA-DTL-HOSP-SVC],
	A.[PA-DTL-INS-CO-CD],
	A.[PA-DTL-INS-PLAN-NO],
	A.[PA-DTL-GL-NO],
	A.[PA-DTL-SVC-CD-WOSCD],
	A.[PA-DTL-SVC-CD-SCD],
	A.[PA-DTL-CDM-DESCRIPTION],
	c.[PA-UNIT-STS]

UNION

-- ----------------------------------------------------------------------------------------------------------------------------------------------------
-- /*----------Create Non-Unitized Pt Payments Table---------------------------*/
-- IF OBJECT_ID('tempdb.dbo.#NonUnit_Charges','U') IS NOT NULL
-- DROP TABLE #NonUnit_Charges;
-- GO
-- CREATE TABLE #NonUnit_Charges
--(
--[PA-PT-NO-WOSCD] VARCHAR(11) NOT NULL,
--[PA-PT-NO-SCD] CHAR(1) NOT NULL,
--[PA-UNIT-NO] DECIMAL(4,0) NULL,
--[PA-DTL-GL-NO] CHAR(3) NULL,
--[PA-DTL-SVC-CD] CHAR(9) NULL,
--[PA-DTL-CDM-DESCRIPTION] VARCHAR(30) NULL,
--[PA-DTL-CHG-QTY] DECIMAL(5,0) NULL,
--[PA-DTL-CHG-AMT] MONEY NULL,
--[TOT-CHARGES] MONEY NULL
--);
--INSERT INTO #NonUnit_Charges ([PA-PT-NO-WOSCD],[PA-PT-NO-SCD],[PA-UNIT-NO],[PA-DTL-GL-NO],[PA-DTL-SVC-CD],[PA-DTL-CDM-DESCRIPTION],[PA-DTL-CHG-QTY],[PA-DTL-CHG-AMT])
SELECT a.[pa-pt-no-woscd],
	a.[pa-pt-no-scd-1] AS 'PA-PT-NO-SCD',
	a.[pa-ctl-paa-xfer-date],
	CAST(a.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(a.[pa-pt-no-scd-1] AS VARCHAR) AS 'PT-NO',
	B.[PA-UNIT-NO],
	b.[pa-unit-date],
	-- EDIT 3-6-2019
	--A.[PA-DTL-UNIT-DATE],
	'',
	-- END EDIT
	B.[PTACCT_TYPE] AS 'TYPE',
	A.[PA-DTL-TYPE-IND],
	A.[PA-DTL-HOSP-SVC],
	A.[PA-DTL-INS-CO-CD],
	A.[PA-DTL-INS-PLAN-NO],
	A.[PA-DTL-GL-NO],
	CAST(A.[PA-DTL-SVC-CD-WOSCD] AS VARCHAR) + CAST(A.[PA-DTL-SVC-CD-SCD] AS VARCHAR) AS 'PA-DTL-SVC-CD',
	A.[PA-DTL-CDM-DESCRIPTION],
	c.[PA-UNIT-STS],
	MIN(a.[pa-dtl-date]) AS '1ST-PAID-DATE',
	SUM(A.[PA-DTL-CHG-AMT]) AS 'TOT-PAYMENTS'
FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Archive].dbo.[DetailInformation] a
INNER JOIN dbo.[Encounters_For_Reporting] b ON a.[pa-pt-no-woscd] = b.[pa-pt-no-woscd]
	AND b.[pa-unit-no] IS NULL
	AND a.[pa-ctl-paa-xfer-date] = b.[pa-ctl-paa-xfer-date] --DATEADD(DAY,-(DAY(DATEADD(MONTH, 1,a.[pa-dtl-date]))),DATEADD(MONTH,1,a.[pa-dtl-date]))
LEFT JOIN [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Archive].dbo.[PatientDemographics] C ON A.[PA-PT-NO-WOSCD] = C.[PA-PT-NO-WOSCD]
	AND a.[pa-ctl-paa-xfer-date] = c.[pa-ctl-paa-xfer-date]
WHERE (
		a.[pa-dtl-type-ind] = '1'
		OR a.[pa-dtl-svc-cd-woscd] IN ('60320', '60215')
		)
GROUP BY a.[pa-pt-no-woscd],
	a.[pa-pt-no-scd-1],
	a.[pa-ctl-paa-xfer-date],
	B.[PA-UNIT-NO],
	b.[pa-unit-date],
	--A.[PA-DTL-UNIT-DATE],
	B.[PTACCT_TYPE],
	A.[PA-DTL-TYPE-IND],
	A.[PA-DTL-HOSP-SVC],
	A.[PA-DTL-INS-CO-CD],
	A.[PA-DTL-INS-PLAN-NO],
	A.[PA-DTL-GL-NO],
	A.[PA-DTL-SVC-CD-WOSCD],
	A.[PA-DTL-SVC-CD-SCD],
	A.[PA-DTL-CDM-DESCRIPTION],
	c.[PA-UNIT-STS]

UNION

SELECT a.[pa-pt-no-woscd],
	a.[pa-pt-no-scd-1] AS 'PA-PT-NO-SCD',
	a.[pa-ctl-paa-xfer-date],
	CAST(a.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(a.[pa-pt-no-scd-1] AS VARCHAR) AS 'PT-NO',
	B.[PA-UNIT-NO],
	b.[pa-unit-date],
	-- EDIT 3-6-2019
	--A.[PA-DTL-UNIT-DATE],
	'',
	-- END EDIT
	--A.[PA-DTL-UNIT-DATE],
	B.[PTACCT_TYPE] AS 'TYPE',
	A.[PA-DTL-TYPE-IND],
	A.[PA-DTL-HOSP-SVC],
	A.[PA-DTL-INS-CO-CD],
	A.[PA-DTL-INS-PLAN-NO],
	A.[PA-DTL-GL-NO],
	CAST(A.[PA-DTL-SVC-CD-WOSCD] AS VARCHAR) + CAST(A.[PA-DTL-SVC-CD-SCD] AS VARCHAR) AS 'PA-DTL-SVC-CD',
	A.[PA-DTL-CDM-DESCRIPTION],
	c.[PA-UNIT-STS],
	MIN(a.[pa-dtl-date]) AS '1ST-PAID-DATE',
	SUM(A.[PA-DTL-CHG-AMT]) AS 'TOT-PAYMENTS'
FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_ACTIVE].dbo.[DetailInformation] a
INNER JOIN dbo.[Encounters_For_Reporting] b ON a.[pa-pt-no-woscd] = b.[pa-pt-no-woscd]
	AND b.[pa-unit-no] IS NULL
LEFT JOIN [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_ACTIVE].dbo.[PatientDemographics] C ON A.[PA-PT-NO-WOSCD] = C.[PA-PT-NO-WOSCD]
	AND a.[pa-ctl-paa-xfer-date] = c.[pa-ctl-paa-xfer-date]
-- Get the reporting group for a patient
WHERE (
		a.[pa-dtl-type-ind] = '1'
		OR a.[pa-dtl-svc-cd-woscd] IN ('60320', '60215')
		)
GROUP BY a.[pa-pt-no-woscd],
	a.[pa-pt-no-scd-1],
	a.[pa-ctl-paa-xfer-date],
	B.[PA-UNIT-NO],
	b.[pa-unit-date],
	--A.[PA-DTL-UNIT-DATE],
	B.[PTACCT_TYPE],
	A.[PA-DTL-TYPE-IND],
	A.[PA-DTL-HOSP-SVC],
	A.[PA-DTL-INS-CO-CD],
	A.[PA-DTL-INS-PLAN-NO],
	A.[PA-DTL-GL-NO],
	A.[PA-DTL-SVC-CD-WOSCD],
	A.[PA-DTL-SVC-CD-SCD],
	A.[PA-DTL-CDM-DESCRIPTION],
	c.[PA-UNIT-STS]
