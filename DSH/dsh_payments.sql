USE [DSH];

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/*------------------------Create Unitized Charges Table-------------------------------------------------------------------------------*/
DROP TABLE IF EXISTS [2016_DSH_Payments] 
GO

	CREATE TABLE [2016_DSH_Payments] (
		[PA-PT-NO-WOSCD] VARCHAR(11) NOT NULL,
		[PA-PT-NO-SCD] CHAR(1) NOT NULL,
		[PT-NO] VARCHAR(50) NOT NULL,
		[PA-UNIT-NO] DECIMAL(4, 0) NULL,
		[unit-date] DATETIME NULL,
		[PA-DTL-UNIT-DATE] DATETIME NULL,
		[TYPE] CHAR(3) NULL,
		[PA-DTL-TYPE-IND] CHAR(1) NULL,
		[PA-DTL-GL-NO] CHAR(3) NULL,
		[PA-DTL-SVC-CD] CHAR(9) NULL,
		[PA-DTL-CDM-DESCRIPTION] VARCHAR(50) NULL,
		[PA-UNIT-STS] CHAR(5) NULL,
		[REPORTING GROUP] CHAR(15) NULL,
		[TOT-PAYMENTS] MONEY NULL,
		);

INSERT INTO [2016_DSH_Payments] (
	[PA-PT-NO-WOSCD],
	[PA-PT-NO-SCD],
	[PT-NO],
	[PA-UNIT-NO],
	[unit-date],
	[PA-DTL-UNIT-DATE],
	[TYPE],
	[PA-DTL-TYPE-IND],
	[PA-DTL-GL-NO],
	[PA-DTL-SVC-CD],
	[PA-DTL-CDM-DESCRIPTION],
	[PA-UNIT-STS],
	[REPORTING GROUP],
	[TOT-PAYMENTS]
	)
SELECT a.[pa-pt-no-woscd],
	a.[pa-pt-no-scd-1] AS 'PA-PT-NO-SCD',
	CAST(a.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(a.[pa-pt-no-scd-1] AS VARCHAR) AS 'PT-NO',
	B.[PA-UNIT-NO],
	b.[pa-unit-date] AS 'UNIT-DATE',
	A.[PA-DTL-UNIT-DATE],
	B.[PTACCT_TYPE] AS 'TYPE',
	A.[PA-DTL-TYPE-IND],
	A.[PA-DTL-GL-NO],
	CAST(A.[PA-DTL-SVC-CD-WOSCD] AS VARCHAR) + CAST(A.[PA-DTL-SVC-CD-SCD] AS VARCHAR) AS 'PA-DTL-SVC-CD',
	A.[PA-DTL-CDM-DESCRIPTION],
	c.[PA-UNIT-STS],
    RPTGRP.[REPORTING GROUP],
	SUM(A.[PA-DTL-CHG-AMT]) AS 'TOT-PAYMENTS'
	
FROM [Echo_Archive].dbo.[DetailInformation] a
INNER JOIN [Encounters_For_DSH] b ON a.[pa-pt-no-woscd] = b.[pa-pt-no-woscd]
	AND A.[PA-DTL-DATE] >= B.[START_UNIT_DATE]
	AND A.[PA-DTL-DATE] <= B.[END_UNIT_DATE]
	AND a.[pa-ctl-paa-xfer-date] = b.[pa-ctl-paa-xfer-date] --AND b.[pa-unit-date] = a.[pa-dtl-unit-date]--DATEADD(DAY,-(DAY(DATEADD(MONTH, 1,a.[pa-dtl-date]))),DATEADD(MONTH,1,a.[pa-dtl-date]))
LEFT JOIN [Echo_Archive].dbo.[PatientDemographics] C ON A.[PA-PT-NO-WOSCD] = C.[PA-PT-NO-WOSCD]
LEFT JOIN DSH.DBO.DSH_INSURANCE_TABLE_W_REPORT_GROUPS AS RPTGRP
ON A.[PA-PT-NO-WOSCD] = RPTGRP.[PA-PT-NO-WOSCD]
	AND A.[PA-PT-NO-SCD-1] = RPTGRP.[PA-PT-NO-SCD]
WHERE a.[pa-dtl-type-ind] IN ('1', '2')
--AND  a.[pa-pt-no-woscd] = '1008126781'
--AND a.[pa-pt-no-woscd] = '1010586387'
GROUP BY a.[pa-pt-no-woscd],
	a.[pa-pt-no-scd-1],
	B.[PA-UNIT-NO],
	b.[pa-unit-date],
	A.[PA-DTL-UNIT-DATE],
	B.[PTACCT_TYPE],
	A.[PA-DTL-TYPE-IND],
	A.[PA-DTL-GL-NO],
	A.[PA-DTL-SVC-CD-WOSCD],
	A.[PA-DTL-SVC-CD-SCD],
	A.[PA-DTL-CDM-DESCRIPTION],
	c.[PA-UNIT-STS],
	RPTGRP.[REPORTING GROUP]

UNION

SELECT a.[pa-pt-no-woscd],
	a.[pa-pt-no-scd-1] AS 'PA-PT-NO-SCD',
	CAST(a.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(a.[pa-pt-no-scd-1] AS VARCHAR) AS 'PT-NO',
	B.[PA-UNIT-NO],
	b.[pa-unit-date],
	A.[PA-DTL-UNIT-DATE],
	B.[PTACCT_TYPE] AS 'TYPE',
	A.[PA-DTL-TYPE-IND],
	A.[PA-DTL-GL-NO],
	CAST(A.[PA-DTL-SVC-CD-WOSCD] AS VARCHAR) + CAST(A.[PA-DTL-SVC-CD-SCD] AS VARCHAR) AS 'PA-DTL-SVC-CD',
	A.[PA-DTL-CDM-DESCRIPTION],
	c.[PA-UNIT-STS],
    RPTGRP.[REPORTING GROUP],
	SUM(A.[PA-DTL-CHG-AMT]) AS 'TOT-PAYMENTS'

FROM [Echo_ACTIVE].dbo.[DetailInformation] a
INNER JOIN [Encounters_For_DSH] b ON a.[pa-pt-no-woscd] = b.[pa-pt-no-woscd]
	AND A.[PA-DTL-DATE] >= B.[START_UNIT_DATE]
	AND A.[PA-DTL-DATE] <= B.[END_UNIT_DATE]
	AND a.[pa-ctl-paa-xfer-date] = b.[pa-ctl-paa-xfer-date] --AND b.[pa-unit-date] = a.[pa-dtl-unit-date]--DATEADD(DAY,-(DAY(DATEADD(MONTH, 1,a.[pa-dtl-date]))),DATEADD(MONTH,1,a.[pa-dtl-date]))
LEFT JOIN [Echo_ACTIVE].dbo.[PatientDemographics] C ON A.[PA-PT-NO-WOSCD] = C.[PA-PT-NO-WOSCD]
LEFT JOIN DSH.DBO.DSH_INSURANCE_TABLE_W_REPORT_GROUPS AS RPTGRP
ON A.[PA-PT-NO-WOSCD] = RPTGRP.[PA-PT-NO-WOSCD]
	AND A.[PA-PT-NO-SCD-1] = RPTGRP.[PA-PT-NO-SCD]
WHERE a.[pa-dtl-type-ind] IN ('1', '2')
--AND a.[pa-pt-no-woscd] = '1010586387'
GROUP BY a.[pa-pt-no-woscd],
	a.[pa-pt-no-scd-1],
	B.[PA-UNIT-NO],
	b.[pa-unit-date],
	A.[PA-DTL-UNIT-DATE],
	B.[PTACCT_TYPE],
	A.[PA-DTL-TYPE-IND],
	A.[PA-DTL-GL-NO],
	A.[PA-DTL-SVC-CD-WOSCD],
	A.[PA-DTL-SVC-CD-SCD],
	A.[PA-DTL-CDM-DESCRIPTION],
	c.[PA-UNIT-STS],
    RPTGRP.[REPORTING GROUP]

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
	CAST(a.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(a.[pa-pt-no-scd-1] AS VARCHAR) AS 'PT-NO',
	B.[PA-UNIT-NO],
	b.[pa-unit-date],
	A.[PA-DTL-UNIT-DATE],
	B.[PTACCT_TYPE] AS 'TYPE',
	A.[PA-DTL-TYPE-IND],
	A.[PA-DTL-GL-NO],
	CAST(A.[PA-DTL-SVC-CD-WOSCD] AS VARCHAR) + CAST(A.[PA-DTL-SVC-CD-SCD] AS VARCHAR) AS 'PA-DTL-SVC-CD',
	A.[PA-DTL-CDM-DESCRIPTION],
	c.[PA-UNIT-STS],
    RPTGRP.[REPORTING GROUP],
	SUM(A.[PA-DTL-CHG-AMT]) AS 'TOT-PAYMENTS'
FROM [Echo_Archive].dbo.[DetailInformation] a
INNER JOIN [Encounters_For_DSH] b ON a.[pa-pt-no-woscd] = b.[pa-pt-no-woscd]
	AND b.[pa-unit-no] IS NULL
	AND a.[pa-ctl-paa-xfer-date] = b.[pa-ctl-paa-xfer-date] --DATEADD(DAY,-(DAY(DATEADD(MONTH, 1,a.[pa-dtl-date]))),DATEADD(MONTH,1,a.[pa-dtl-date]))
LEFT JOIN [Echo_Archive].dbo.[PatientDemographics] C ON A.[PA-PT-NO-WOSCD] = C.[PA-PT-NO-WOSCD]
LEFT JOIN DSH.DBO.DSH_INSURANCE_TABLE_W_REPORT_GROUPS AS RPTGRP
ON A.[PA-PT-NO-WOSCD] = RPTGRP.[PA-PT-NO-WOSCD]
	AND A.[PA-PT-NO-SCD-1] = RPTGRP.[PA-PT-NO-SCD]
WHERE a.[pa-dtl-type-ind] IN ('1', '2')
--AND a.[pa-pt-no-woscd] = '1010586387'
GROUP BY a.[pa-pt-no-woscd],
	a.[pa-pt-no-scd-1],
	B.[PA-UNIT-NO],
	b.[pa-unit-date],
	A.[PA-DTL-UNIT-DATE],
	B.[PTACCT_TYPE],
	A.[PA-DTL-TYPE-IND],
	A.[PA-DTL-GL-NO],
	A.[PA-DTL-SVC-CD-WOSCD],
	A.[PA-DTL-SVC-CD-SCD],
	A.[PA-DTL-CDM-DESCRIPTION],
	c.[PA-UNIT-STS],
    RPTGRP.[REPORTING GROUP]

UNION

SELECT a.[pa-pt-no-woscd],
	a.[pa-pt-no-scd-1] AS 'PA-PT-NO-SCD',
	CAST(a.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(a.[pa-pt-no-scd-1] AS VARCHAR) AS 'PT-NO',
	B.[PA-UNIT-NO],
	b.[pa-unit-date],
	A.[PA-DTL-UNIT-DATE],
	B.[PTACCT_TYPE] AS 'TYPE',
	A.[PA-DTL-TYPE-IND],
	A.[PA-DTL-GL-NO],
	CAST(A.[PA-DTL-SVC-CD-WOSCD] AS VARCHAR) + CAST(A.[PA-DTL-SVC-CD-SCD] AS VARCHAR) AS 'PA-DTL-SVC-CD',
	A.[PA-DTL-CDM-DESCRIPTION],
	c.[PA-UNIT-STS],
	D.[REPORTING GROUP],
	SUM(A.[PA-DTL-CHG-AMT]) AS 'TOT-PAYMENTS'

FROM [Echo_ACTIVE].dbo.[DetailInformation] a
INNER JOIN [Encounters_For_DSH] b ON a.[pa-pt-no-woscd] = b.[pa-pt-no-woscd]
	AND b.[pa-unit-no] IS NULL --DATEADD(DAY,-(DAY(DATEADD(MONTH, 1,a.[pa-dtl-date]))),DATEADD(MONTH,1,a.[pa-dtl-date]))
LEFT JOIN [Echo_ACTIVE].dbo.[PatientDemographics] C ON A.[PA-PT-NO-WOSCD] = C.[PA-PT-NO-WOSCD]
-- Get the reporting group for a patient
LEFT OUTER JOIN [dbo].[DSH_INSURANCE_TABLE_W_REPORT_GROUPS] AS D ON b.[PA-PT-NO-WOSCD] = D.[PA-PT-NO-WOSCD]
	AND A.[pa-pt-no-scd-1] = D.[PA-PT-NO-SCD]
WHERE a.[pa-dtl-type-ind] IN ('1', '2')
--AND a.[pa-pt-no-woscd] = '1010586387'
GROUP BY a.[pa-pt-no-woscd],
	a.[pa-pt-no-scd-1],
	B.[PA-UNIT-NO],
	b.[pa-unit-date],
	A.[PA-DTL-UNIT-DATE],
	B.[PTACCT_TYPE],
	A.[PA-DTL-TYPE-IND],
	A.[PA-DTL-GL-NO],
	A.[PA-DTL-SVC-CD-WOSCD],
	A.[PA-DTL-SVC-CD-SCD],
	A.[PA-DTL-CDM-DESCRIPTION],
	c.[PA-UNIT-STS],
	D.[REPORTING GROUP]
