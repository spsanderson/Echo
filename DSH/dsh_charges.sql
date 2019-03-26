USE [DSH];

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/*------------------------Create Unitized Charges Table-------------------------------------------------------------------------------*/
DROP TABLE IF EXISTS [2016_DSH_Charges] 
GO
	CREATE TABLE [2016_DSH_Charges] (
		[PA-PT-NO-WOSCD] VARCHAR(11) NOT NULL,
		[PA-PT-NO-SCD] CHAR(1) NOT NULL,
		[PT-NO] VARCHAR(50) NOT NULL,
		[PA-MED-REC-NO] VARCHAR(50) NOT NULL,
		[admit_date] DATETIME NULL,
		[dsch_date] DATETIME NULL,
		[PA-UNIT-NO] DECIMAL(4, 0) NULL,
		[unit-date] DATETIME NULL,
		[PA-DTL-UNIT-DATE] DATETIME NULL,
		[TYPE] CHAR(3) NULL,
		[PA-DTL-TYPE-IND] CHAR(1) NULL,
		[PA-DTL-GL-NO] CHAR(3) NULL,
		[PA-DTL-REV-CD] CHAR(9) NULL,
		[PA-DTL-CPT-CD] CHAR(9) NULL,
		[PA-DTL-SVC-CD] CHAR(9) NULL,
		[PA-DTL-CDM-DESCRIPTION] VARCHAR(50) NULL,
		[PA-UNIT-STS] CHAR(5) NULL,
		[TOT-BFW-ACCOUNT] MONEY NULL,
		[TOT-BFW-CHG] MONEY NULL,
		[TOT-CHG-QTY] DECIMAL(5, 0) NULL,
		[TOT-CHARGES] MONEY NULL,
		[TOT-PROF-FEES] MONEY NULL,
		[Sum_of_Chargesand_Prof_Fees] MONEY NULL,
		[REPORTING-GROUP] VARCHAR(100) NULL
		);

INSERT INTO [2016_DSH_Charges] (
	[PA-PT-NO-WOSCD],
	[PA-PT-NO-SCD],
	[PT-NO],
	[PA-MED-REC-NO],
	[admit_date],
	[dsch_date],
	[PA-UNIT-NO],
	[unit-date],
	[PA-DTL-UNIT-DATE],
	[TYPE],
	[PA-DTL-TYPE-IND],
	[PA-DTL-GL-NO],
	[PA-DTL-REV-CD],
	[PA-DTL-CPT-CD],
	[PA-DTL-SVC-CD],
	[PA-DTL-CDM-DESCRIPTION],
	[PA-UNIT-STS],
	[TOT-BFW-ACCOUNT],
	[TOT-BFW-CHG],
	[TOT-CHG-QTY],
	[TOT-CHARGES],
	[TOT-PROF-FEES],
	[Sum_of_Chargesand_Prof_Fees],
	[REPORTING-GROUP]
	)
    
SELECT a.[pa-pt-no-woscd],
	a.[pa-pt-no-scd-1] AS 'PA-PT-NO-SCD',
	CAST(a.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(a.[pa-pt-no-scd-1] AS VARCHAR) AS 'PT-NO',
	B.[pa-med-rec-no],
	B.[admit_date],
	B.[dsch_date],
	B.[PA-UNIT-NO],
	b.[pa-unit-date] AS 'UNIT-DATE',
	A.[PA-DTL-UNIT-DATE],
	B.[PTACCT_TYPE] AS 'TYPE',
	A.[PA-DTL-TYPE-IND],
	A.[PA-DTL-GL-NO],
	A.[PA-DTL-REV-CD],
	A.[PA-DTL-CPT-CD],
	CAST(A.[PA-DTL-SVC-CD-WOSCD] AS VARCHAR) + CAST(A.[PA-DTL-SVC-CD-SCD] AS VARCHAR) AS 'PA-DTL-SVC-CD',
	A.[PA-DTL-CDM-DESCRIPTION],
	c.[PA-UNIT-STS],
	C.[PA-BFW-ACCT-TOT] AS 'TOT-BFW-ACCOUNT',
	C.[PA-BFW-CHG-TOT] AS 'TOT-BFW-CHG',
	SUM(A.[PA-DTL-CHG-QTY]) AS 'TOT-CHG-QTY',
	SUM(A.[PA-DTL-CHG-AMT]) AS 'TOT-CHARGES',
	SUM(A.[PA-DTL-PROFESSIONAL-FEE]) AS 'TOT-PROF-FEES',
	SUM(A.[PA-DTL-CHG-AMT]) + SUM(A.[PA-DTL-PROFESSIONAL-FEE]) AS 'Sum_of_Chargesand_Prof_Fees',
	RPTGRP.[REPORTING GROUP]

FROM [Echo_Archive].dbo.[DetailInformation] a
INNER JOIN [Encounters_For_DSH] b ON a.[pa-pt-no-woscd] = b.[pa-pt-no-woscd]
	AND A.[PA-DTL-DATE] >= B.[START_UNIT_DATE]
	AND A.[PA-DTL-DATE] <= B.[END_UNIT_DATE]
	AND a.[pa-ctl-paa-xfer-date] = b.[pa-ctl-paa-xfer-date] --AND b.[pa-unit-date] = a.[pa-dtl-unit-date]--DATEADD(DAY,-(DAY(DATEADD(MONTH, 1,a.[pa-dtl-date]))),DATEADD(MONTH,1,a.[pa-dtl-date]))
LEFT JOIN [Echo_Archive].dbo.[PatientDemographics] C ON A.[PA-PT-NO-WOSCD] = C.[PA-PT-NO-WOSCD]
	AND a.[pa-ctl-paa-xfer-date] = c.[pa-ctl-paa-xfer-date]
LEFT JOIN [DSH].[dbo].[DSH_INSURANCE_TABLE_W_REPORT_GROUPS] AS RPTGRP
ON A.[PA-PT-NO-WOSCD] = RPTGRP.[PA-PT-NO-WOSCD]
	AND A.[PA-PT-NO-SCD-1] = RPTGRP.[PA-PT-NO-SCD]
		AND a.[pa-ctl-paa-xfer-date] = RPTGRP.[pa-ctl-paa-xfer-date]
	-- EDIT SPS 3-5-2019 -----
	AND B.[pa-unit-no] = RPTGRP.[pa-unit-no]
	AND B.[pa-unit-date] = RPTGRP.[pa-unit-date]
	-- END EDIT --------------
WHERE a.[pa-dtl-type-ind] IN ('7', '8', 'A', 'B')
--AND  a.[pa-pt-no-woscd] = '1010313424'
--AND a.[pa-pt-no-woscd] = '1010586387'
GROUP BY a.[pa-pt-no-woscd],
	a.[pa-pt-no-scd-1],
	B.[pa-med-rec-no],
	B.[admit_date],
	B.[dsch_date],
	B.[PA-UNIT-NO],
	b.[pa-unit-date],
	A.[PA-DTL-UNIT-DATE],
	B.[PTACCT_TYPE],
	A.[PA-DTL-TYPE-IND],
	A.[PA-DTL-GL-NO],
	A.[PA-DTL-REV-CD],
	A.[PA-DTL-CPT-CD],
	A.[PA-DTL-SVC-CD-WOSCD],
	A.[PA-DTL-SVC-CD-SCD],
	A.[PA-DTL-CDM-DESCRIPTION],
	c.[PA-UNIT-STS],
	c.[pa-bfw-acct-tot],
	c.[PA-BFW-CHG-TOT],
	RPTGRP.[REPORTING GROUP]

UNION

SELECT a.[pa-pt-no-woscd],
	a.[pa-pt-no-scd-1] AS 'PA-PT-NO-SCD',
	CAST(a.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(a.[pa-pt-no-scd-1] AS VARCHAR) AS 'PT-NO',
	B.[pa-med-rec-no],
	B.[admit_date],
	B.[dsch_date],
	B.[PA-UNIT-NO],
	b.[pa-unit-date] AS 'UNIT-DATE',
	A.[PA-DTL-UNIT-DATE],
	B.[PTACCT_TYPE] AS 'TYPE',
	A.[PA-DTL-TYPE-IND],
	A.[PA-DTL-GL-NO],
	A.[PA-DTL-REV-CD],
	A.[PA-DTL-CPT-CD],
	CAST(A.[PA-DTL-SVC-CD-WOSCD] AS VARCHAR) + CAST(A.[PA-DTL-SVC-CD-SCD] AS VARCHAR) AS 'PA-DTL-SVC-CD',
	A.[PA-DTL-CDM-DESCRIPTION],
	c.[PA-UNIT-STS],
	C.[PA-BFW-ACCT-TOT] AS 'TOT-BFW-ACCOUNT',
	c.[PA-BFW-CHG-TOT] AS 'TOT-BFW-CHG',
	SUM(A.[PA-DTL-CHG-QTY]) AS 'TOT-CHG-QTY',
	SUM(A.[PA-DTL-CHG-AMT]) AS 'TOT-CHARGES',
	SUM(A.[PA-DTL-PROFESSIONAL-FEE]) AS 'TOT-PROF-FESS',
	SUM(A.[PA-DTL-CHG-AMT]) + SUM(A.[PA-DTL-PROFESSIONAL-FEE]) AS 'Sum_of_Chargesand_Prof_Fees',
	RPTGRP.[REPORTING GROUP]

FROM [Echo_ACTIVE].dbo.[DetailInformation] a
INNER JOIN [Encounters_For_DSH] b ON a.[pa-pt-no-woscd] = b.[pa-pt-no-woscd]
	AND A.[PA-DTL-DATE] >= B.[START_UNIT_DATE]
	AND A.[PA-DTL-DATE] <= B.[END_UNIT_DATE]
	AND a.[pa-ctl-paa-xfer-date] = b.[pa-ctl-paa-xfer-date] --AND b.[pa-unit-date] = a.[pa-dtl-unit-date]--DATEADD(DAY,-(DAY(DATEADD(MONTH, 1,a.[pa-dtl-date]))),DATEADD(MONTH,1,a.[pa-dtl-date]))
LEFT JOIN [Echo_ACTIVE].dbo.[PatientDemographics] C ON A.[PA-PT-NO-WOSCD] = C.[PA-PT-NO-WOSCD]
AND a.[pa-ctl-paa-xfer-date] = c.[pa-ctl-paa-xfer-date]
LEFT JOIN [DSH].[dbo].[DSH_INSURANCE_TABLE_W_REPORT_GROUPS] AS RPTGRP
ON A.[PA-PT-NO-WOSCD] = RPTGRP.[PA-PT-NO-WOSCD]
	AND A.[PA-PT-NO-SCD-1] = RPTGRP.[PA-PT-NO-SCD]
	AND a.[pa-ctl-paa-xfer-date] = RPTGRP.[pa-ctl-paa-xfer-date]
	-- EDIT SPS 3-5-2019 -----
	AND B.[pa-unit-no] = RPTGRP.[pa-unit-no]
	AND B.[pa-unit-date] = RPTGRP.[pa-unit-date]
	-- END EDIT --------------
WHERE a.[pa-dtl-type-ind] IN ('7', '8', 'A', 'B')
--AND a.[pa-pt-no-woscd] = '1010586387'
GROUP BY a.[pa-pt-no-woscd],
	a.[pa-pt-no-scd-1],
	B.[pa-med-rec-no],
	B.[admit_date],
	B.[dsch_date],
	B.[PA-UNIT-NO],
	b.[pa-unit-date],
	A.[PA-DTL-UNIT-DATE],
	B.[PTACCT_TYPE],
	A.[PA-DTL-TYPE-IND],
	A.[PA-DTL-GL-NO],
	A.[PA-DTL-REV-CD],
	A.[PA-DTL-CPT-CD],
	A.[PA-DTL-SVC-CD-WOSCD],
	A.[PA-DTL-SVC-CD-SCD],
	A.[PA-DTL-CDM-DESCRIPTION],
	c.[PA-UNIT-STS],
	c.[pa-bfw-acct-tot],
	c.[PA-BFW-CHG-TOT],
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
	B.[pa-med-rec-no],
	B.[admit_date],
	B.[dsch_date],
	B.[PA-UNIT-NO],
	b.[pa-unit-date] AS 'UNIT-DATE',
	A.[PA-DTL-UNIT-DATE],
	B.[PTACCT_TYPE] AS 'TYPE',
	A.[PA-DTL-TYPE-IND],
	A.[PA-DTL-GL-NO],
	A.[PA-DTL-REV-CD],
	A.[PA-DTL-CPT-CD],
	CAST(A.[PA-DTL-SVC-CD-WOSCD] AS VARCHAR) + CAST(A.[PA-DTL-SVC-CD-SCD] AS VARCHAR) AS 'PA-DTL-SVC-CD',
	A.[PA-DTL-CDM-DESCRIPTION],
	c.[PA-UNIT-STS],
	C.[PA-BFW-ACCT-TOT] AS 'TOT-BFW-ACCOUNT',
	c.[PA-BFW-CHG-TOT] AS 'TOT-BFW-CHG',
	SUM(A.[PA-DTL-CHG-QTY]) AS 'TOT-CHG-QTY',
	SUM(A.[PA-DTL-CHG-AMT]) AS 'TOT-CHARGES',
	SUM(A.[PA-DTL-PROFESSIONAL-FEE]) AS 'TOT-PROF-FEES',
	SUM(A.[PA-DTL-CHG-AMT]) + SUM(A.[PA-DTL-PROFESSIONAL-FEE]) AS 'Sum_of_Chargesand_Prof_Fees',
	RPTGRP.[REPORTING GROUP]

FROM [Echo_Archive].dbo.[DetailInformation] a
INNER JOIN [Encounters_For_DSH] b ON a.[pa-pt-no-woscd] = b.[pa-pt-no-woscd]
	AND b.[pa-unit-no] IS NULL
	AND a.[pa-ctl-paa-xfer-date] = b.[pa-ctl-paa-xfer-date] --DATEADD(DAY,-(DAY(DATEADD(MONTH, 1,a.[pa-dtl-date]))),DATEADD(MONTH,1,a.[pa-dtl-date]))
LEFT JOIN [Echo_Archive].dbo.[PatientDemographics] C ON A.[PA-PT-NO-WOSCD] = C.[PA-PT-NO-WOSCD]
AND a.[pa-ctl-paa-xfer-date] = c.[pa-ctl-paa-xfer-date]
LEFT JOIN [DSH].[dbo].[DSH_INSURANCE_TABLE_W_REPORT_GROUPS] AS RPTGRP
ON A.[PA-PT-NO-WOSCD] = RPTGRP.[PA-PT-NO-WOSCD]
	AND A.[PA-PT-NO-SCD-1] = RPTGRP.[PA-PT-NO-SCD]
	AND a.[pa-ctl-paa-xfer-date] = RPTGRP.[pa-ctl-paa-xfer-date]
	-- EDIT SPS 3-5-2019 -----
	--AND B.[pa-unit-no] = RPTGRP.[pa-unit-no]
	--AND B.[pa-unit-date] = RPTGRP.[pa-unit-date]
	-- END EDIT --------------
WHERE a.[pa-dtl-type-ind] IN ('7', '8', 'A', 'B')
--AND a.[pa-pt-no-woscd] = '1010586387'
GROUP BY a.[pa-pt-no-woscd],
	a.[pa-pt-no-scd-1],
	B.[pa-med-rec-no],
	B.[admit_date],
	B.[dsch_date],
	B.[PA-UNIT-NO],
	b.[pa-unit-date],
	A.[PA-DTL-UNIT-DATE],
	B.[PTACCT_TYPE],
	A.[PA-DTL-TYPE-IND],
	A.[PA-DTL-GL-NO],
	A.[PA-DTL-REV-CD],
	A.[PA-DTL-CPT-CD],
	A.[PA-DTL-SVC-CD-WOSCD],
	A.[PA-DTL-SVC-CD-SCD],
	A.[PA-DTL-CDM-DESCRIPTION],
	c.[PA-UNIT-STS],
	c.[pa-bfw-acct-tot],
	c.[PA-BFW-CHG-TOT],
    RPTGRP.[REPORTING GROUP]

UNION

SELECT a.[pa-pt-no-woscd],
	a.[pa-pt-no-scd-1] AS 'PA-PT-NO-SCD',
	CAST(a.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(a.[pa-pt-no-scd-1] AS VARCHAR) AS 'PT-NO',
	B.[pa-med-rec-no],
	B.[admit_date],
	B.[dsch_date],
	B.[PA-UNIT-NO],
	b.[pa-unit-date] AS 'UNIT-DATE',
	A.[PA-DTL-UNIT-DATE],
	B.[PTACCT_TYPE] AS 'TYPE',
	A.[PA-DTL-TYPE-IND],
	A.[PA-DTL-GL-NO],
	A.[PA-DTL-REV-CD],
	A.[PA-DTL-CPT-CD],
	CAST(A.[PA-DTL-SVC-CD-WOSCD] AS VARCHAR) + CAST(A.[PA-DTL-SVC-CD-SCD] AS VARCHAR) AS 'PA-DTL-SVC-CD',
	A.[PA-DTL-CDM-DESCRIPTION],
	c.[PA-UNIT-STS],
	C.[PA-BFW-ACCT-TOT] AS 'TOT-BFW-ACCOUNT',
	C.[PA-BFW-CHG-TOT] AS 'TOT-BFW-CHG',
	SUM(A.[PA-DTL-CHG-QTY]) AS 'TOT-CHG-QTY',
	SUM(A.[PA-DTL-CHG-AMT]) AS 'TOT-CHARGES',
	SUM(A.[PA-DTL-PROFESSIONAL-FEE]) AS 'TOT-PROF-FEES',
	SUM(A.[PA-DTL-CHG-AMT]) + SUM(A.[PA-DTL-PROFESSIONAL-FEE]) AS 'Sum_of_Chargesand_Prof_Fees',
	 RPTGRP.[REPORTING GROUP]

FROM [Echo_ACTIVE].dbo.[DetailInformation] a
INNER JOIN [Encounters_For_DSH] b ON a.[pa-pt-no-woscd] = b.[pa-pt-no-woscd]
	AND b.[pa-unit-no] IS NULL --DATEADD(DAY,-(DAY(DATEADD(MONTH, 1,a.[pa-dtl-date]))),DATEADD(MONTH,1,a.[pa-dtl-date]))
	AND a.[pa-ctl-paa-xfer-date] = b.[pa-ctl-paa-xfer-date]
LEFT JOIN [Echo_ACTIVE].dbo.[PatientDemographics] C ON A.[PA-PT-NO-WOSCD] = C.[PA-PT-NO-WOSCD]
	AND a.[pa-ctl-paa-xfer-date] = c.[pa-ctl-paa-xfer-date]
LEFT JOIN [DSH].[dbo].[DSH_INSURANCE_TABLE_W_REPORT_GROUPS] AS RPTGRP
ON A.[PA-PT-NO-WOSCD] = RPTGRP.[PA-PT-NO-WOSCD]
	AND A.[PA-PT-NO-SCD-1] = RPTGRP.[PA-PT-NO-SCD]
	AND a.[pa-ctl-paa-xfer-date] = RPTGRP.[pa-ctl-paa-xfer-date]
	-- EDIT SPS 3-5-2019 -----
	--AND B.[pa-unit-no] = RPTGRP.[pa-unit-no]
	--AND B.[pa-unit-date] = RPTGRP.[pa-unit-date]
	-- END EDIT --------------
WHERE a.[pa-dtl-type-ind] IN ('7', '8', 'A', 'B')
--AND a.[pa-pt-no-woscd] = '1010586387'
GROUP BY a.[pa-pt-no-woscd],
	a.[pa-pt-no-scd-1],
	B.[pa-med-rec-no],
	B.[admit_date],
	B.[dsch_date],
	B.[PA-UNIT-NO],
	b.[pa-unit-date],
	A.[PA-DTL-UNIT-DATE],
	B.[PTACCT_TYPE],
	A.[PA-DTL-TYPE-IND],
	A.[PA-DTL-GL-NO],
	A.[PA-DTL-REV-CD],
	A.[PA-DTL-CPT-CD],
	A.[PA-DTL-SVC-CD-WOSCD],
	A.[PA-DTL-SVC-CD-SCD],
	A.[PA-DTL-CDM-DESCRIPTION],
	c.[PA-UNIT-STS],
	c.[pa-bfw-acct-tot],
	c.[PA-BFW-CHG-TOT],
    RPTGRP.[REPORTING GROUP]

UNION

/*********************ADD BALANCE FORWARD CHARGE RECORDS FOR SUPER AND NON-SUPER ACCOUNTS************************************************************************/
SELECT LEFT([PT_Number], (len([PT_Number]) - 1)) AS 'pa-pt-no-woscd',
	cast(RIGHT(LTRIM(RTRIM([PT_Number])), 1) AS DECIMAL(4, 0)) AS 'PA-PT-NO-SCD',
	[PT_Number] AS 'PT-NO',
	COALESCE(B.[pa-med-rec-no], C.[PA-MED-REC-NO]) AS 'PA-MED-REC-NO',
	A.[ADM_DT] AS 'admit_date',
	A.[DSCH_DT] AS 'dsch_date',
	A.[pa-unit-no],
	A.[unit-date],
	'' AS 'PA-DTL-UNIT-DATE',
	'IP' AS 'TYPE',
	A.[PA-DTL-TYPE-IND],
	'' AS 'PA-DTL-GL-NO',
	'' AS 'PA-DTL-REV-CD',
	'' AS 'PA-DTL-CPT-CD',
	A.[PA-DTL-SVC-CD],
	A.[PA-DTL-CDM-DESCRIPTION],
	'BFW' AS 'PA-UNIT-STS',
	coalesce(b.[pa-bfw-acct-tot], c.[pa-bfw-acct-tot]) AS 'TOT-BFW-ACCOUNT',
	coalesce(b.[pa-bfw-chg-tot], C.[PA-BFW-CHG-TOT]) AS 'TOT-BFW-CHG',
	SUM(A.[QTY]) AS 'TOT-CHG-QTY',
	SUM(A.[CHG_AMT]) AS 'TOT-CHARGES',
	'0' AS 'TOT-PROF-FEES',
	SUM(A.[CHG_AMT]) AS 'Sum_of_Chargesand_Prof_Fees', 
	    RPTGRP.[REPORTING GROUP]

FROM dbo.[2016_ALL_BFW_CHGS] a
LEFT OUTER JOIN [Echo_Archive].dbo.[PatientDemographics] b ON a.[PT_Number] = CAST(b.[pa-pt-no-woscd] AS VARCHAR) + CAST(b.[pa-pt-no-scd-1] AS VARCHAR)
LEFT OUTER JOIN [Echo_Active].dbo.[PatientDemographics] c ON a.[PT_Number] = CAST(c.[pa-pt-no-woscd] AS VARCHAR) + CAST(c.[pa-pt-no-scd-1] AS VARCHAR)
LEFT OUTER JOIN [DSH].[dbo].[DSH_INSURANCE_TABLE_W_REPORT_GROUPS] AS RPTGRP
ON A.[PT_Number] = CAST(RPTGRP.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(RPTGRP.[PA-PT-NO-SCD] AS VARCHAR)

	-- EDIT SPS 3-5-2019 -----
	--AND a.[pa-unit-no] = RPTGRP.[pa-unit-no]
	--AND a.[pa-unit-date] = RPTGRP.[pa-unit-date]
	-- END EDIT --------------

WHERE len([pt_number]) >= 1 --- Had to add this after I adjusted BFW files to include [pa-dtl-type-ind] which I need for identifying R&B charges.  Some how an extra line under pt_number was added to 2016_ALL_BFW_Chgs and was giving me errors when running this query 
GROUP BY a.[PT_Number],
	COALESCE(B.[pa-med-rec-no], C.[PA-MED-REC-NO]),
	A.[ADM_DT],
	A.[DSCH_DT],
	A.[pa-unit-no],
	A.[unit-date],
	A.[PA-DTL-TYPE-IND],
	a.[PA-DTL-SVC-CD], 
	a.[PA-DTL-CDM-DESCRIPTION],
	b.[pa-bfw-acct-tot],
	c.[pa-bfw-acct-tot],
	b.[pa-bfw-chg-tot],
	C.[PA-BFW-CHG-TOT],
    RPTGRP.[REPORTING GROUP]

	-- 340B INDICATOR TABLE --------------------------------
DROP TABLE IF EXISTS [DSH].[dbo].[2016_340B_INDICATOR]
GO

CREATE TABLE [DSH].[dbo].[2016_340B_INDICATOR] (
	 [PA-PT-NO-WOSCD] VARCHAR(50) NOT NULL
    , [PA-PT-NO-SCD] CHAR(1) NOT NULL
    , [PT-NO] VARCHAR(51) NOT NULL
	,[admit_date] DATETIME NULL
	,[dsch_date] DATETIME NULL
	, [PA-UNIT-NO] VARCHAR(50) NULL
	, [PA-DTL-SVC-CD] VARCHAR (50) NULL
	 ,[PA-DTL-CDM-DESCRIPTION] VARCHAR (50) NULL
	, [PA-DTL-UNIT-DATE] VARCHAR(50) NULL
	,[TYPE] VARCHAR (50) NULL
	,[340B-IND] INT NULL
	,[REPORTING-GROUP] VARCHAR (50) NULL
    ,[TOT-CHG-QTY] decimal
	--, [TOTAL-CHARGES] MONEY
	,[Total Charges including Prof Fees] MONEY
)
;

INSERT INTO [DSH].[dbo].[2016_340B_INDICATOR]

SELECT [PA-PT-NO-WOSCD]
, [PA-PT-NO-SCD]
, [PT-NO]
, [admit_date]
, [dsch_date]
, [PA-UNIT-NO]
, [PA-DTL-SVC-CD]
, [PA-DTL-CDM-DESCRIPTION]
--, CASE
--	WHEN [PA-UNIT-NO] IS NULL
--	THEN  NULL
--	ELSE CAST([PA-DTL-UNIT-DATE] AS DATE)
--  END AS [PA-DTL-UNIT-DATE]
, [PA-DTL-UNIT-DATE]
, [TYPE]
, CASE
	WHEN left([PA-DTL-SVC-CD],3) = '415'
		THEN 1
		ELSE 0
  END AS [340B-IND]
, [REPORTING-GROUP]
, [TOT-CHG-QTY]  
--,SUM([TOT-CHARGES]) AS [TOTAL-CHARGES]
,SUM([Sum_of_Chargesand_Prof_Fees]) as 'Total Chgs including Prof Fees'


FROM [DSH].[dbo].[2016_DSH_Charges]

WHERE left([PA-DTL-SVC-CD],3) = '415' 
AND [TYPE] = 'OP' 
 --AND [REPORTING-GROUP] IN (
 --      'PRIMARY MEDICAID',
 --      'PRIMARY MEDICAID MANAGED CARE',
 --      'MEDICAID FFS DUAL ELIGIBLE',
 --      'MEDICAID MANAGED CARE DUAL ELIGIBLE',
 --      'PRIMARY OUT OF STATE MEDICAID',
 --      'DUAL ELIGIBLE OUT OF STATE MEDICAID'
 --      )

GROUP BY  [PA-PT-NO-WOSCD]
, [PA-PT-NO-SCD]
, [PT-NO]
, [admit_date]
, [dsch_date]
, [PA-UNIT-NO]
, [PA-DTL-SVC-CD]
, [PA-DTL-CDM-DESCRIPTION]
, [PA-DTL-UNIT-DATE]
, [TYPE]
, [REPORTING-GROUP]
, [TOT-CHG-QTY]




