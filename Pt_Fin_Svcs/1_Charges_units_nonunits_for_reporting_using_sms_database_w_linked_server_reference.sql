/*
1_Charges_units_nonunits_for_reporting_using_sms_database_w_linked_server_reference.sql
*/

USE [SMS];

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


 

/*------------------------Create Unitized Charges Table-------------------------------------------------------------------------------*/

DROP TABLE IF EXISTS [SMS].DBO.[Charges_For_Reporting]
GO

CREATE TABLE [SMS].dbo.[Charges_For_Reporting] (
	[PA-PT-NO-WOSCD] VARCHAR(11) NOT NULL,
	[PA-PT-NO-SCD] CHAR(1) NOT NULL,
	[PA-UNIT-NO] DECIMAL(4, 0) NULL,
	[unit-date] DATETIME NULL,
	[PA-DTL-UNIT-DATE] DATETIME NULL,
	[TYPE] CHAR(3) NULL,
	[PA-DTL-TYPE-IND] CHAR(1) NULL,
	[PA-DTL-GL-NO] CHAR(3) NULL,
	[PA-DTL-REV-CD] CHAR(9) NULL,
	[PA-DTL-CPT-CD] CHAR(9) NULL,
	[pa-dtl-proc-cd-modf(1)] CHAR(2) NULL,
	[pa-dtl-proc-cd-modf(2)] CHAR(2) NULL,
	[pa-dtl-proc-cd-modf(3)] CHAR(2) NULL,
	[PA-DTL-SVC-CD] CHAR(9) NULL,
	[PA-DTL-CDM-DESCRIPTION] VARCHAR(30) NULL,
	[TOT-CHG-QTY] DECIMAL(5, 0) NULL,
	[TOT-CHARGES] MONEY NULL,
	[TOT-PROF-FEES] MONEY NULL
	);

INSERT INTO [SMS].dbo.[Charges_For_Reporting] (
	[PA-PT-NO-WOSCD],
	[PA-PT-NO-SCD],
	[PA-UNIT-NO],
	[unit-date],
	[PA-DTL-UNIT-DATE],
	[TYPE],
	[PA-DTL-TYPE-IND],
	[PA-DTL-GL-NO],
	[PA-DTL-REV-CD],
	[PA-DTL-CPT-CD],
	[PA-DTL-PROC-CD-MODF(1)],
	[PA-DTL-PROC-CD-MODF(2)],
	[PA-DTL-PROC-CD-MODF(3)],
	[PA-DTL-SVC-CD],
	[PA-DTL-CDM-DESCRIPTION],
	[TOT-CHG-QTY],
	[TOT-CHARGES],
	[TOT-PROF-FEES]
	)
--SELECT a.[pa-pt-no-woscd],
--a.[pa-pt-no-scd-1] AS 'PA-PT-NO-SCD',
--B.[PA-UNIT-NO],
--b.[pa-unit-date] as 'UNIT-DATE',
--A.[PA-DTL-UNIT-DATE],
--B.[PTACCT_TYPE] AS 'TYPE',
--A.[PA-DTL-TYPE-IND],
--A.[PA-DTL-GL-NO],
--A.[PA-DTL-REV-CD],
--A.[PA-DTL-CPT-CD],
--CAST(A.[PA-DTL-SVC-CD-WOSCD] AS VARCHAR) + CAST(A.[PA-DTL-SVC-CD-SCD] AS VARCHAR) AS 'PA-DTL-SVC-CD',
--A.[PA-DTL-CDM-DESCRIPTION],
--SUM(A.[PA-DTL-CHG-QTY]) AS 'TOT-CHG-QTY',
--SUM(A.[PA-DTL-CHG-AMT]) AS 'TOT-CHARGES',
--SUM(A.[PA-DTL-PROFESSIONAL-FEE]) AS 'TOT-PROF-FEES'
--FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Archive].dbo.[DetailInformation] a inner join dbo.[Encounters_For_Reporting] b
--ON a.[pa-pt-no-woscd]=b.[pa-pt-no-woscd] AND A.[PA-DTL-DATE] >= B.[START_UNIT_DATE] AND A.[PA-DTL-DATE] <= B.[END_UNIT_DATE] and a.[pa-ctl-paa-xfer-date]=b.[pa-ctl-paa-xfer-date]--AND b.[pa-unit-date] = a.[pa-dtl-unit-date]--DATEADD(DAY,-(DAY(DATEADD(MONTH, 1,a.[pa-dtl-date]))),DATEADD(MONTH,1,a.[pa-dtl-date]))
--WHERE a.[pa-dtl-type-ind] IN ('7','8','A','B')
----AND  a.[pa-pt-no-woscd] = '1010236261'
----AND a.[pa-pt-no-woscd] = '1010586387'
--GROUP BY a.[pa-pt-no-woscd], a.[pa-pt-no-scd-1],B.[PA-UNIT-NO],b.[pa-unit-date],A.[PA-DTL-UNIT-DATE],B.[PTACCT_TYPE],A.[PA-DTL-TYPE-IND],A.[PA-DTL-GL-NO],A.[PA-DTL-REV-CD],A.[PA-DTL-CPT-CD],A.[PA-DTL-SVC-CD-WOSCD],A.[PA-DTL-SVC-CD-SCD],A.[PA-DTL-CDM-DESCRIPTION]
--UNION
SELECT a.[pa-pt-no-woscd],
	a.[pa-pt-no-scd-1] AS 'PA-PT-NO-SCD',
	B.[PA-UNIT-NO],
	b.[pa-unit-date],
	A.[PA-DTL-UNIT-DATE],
	B.[PTACCT_TYPE] AS 'TYPE',
	A.[PA-DTL-TYPE-IND],
	A.[PA-DTL-GL-NO],
	A.[PA-DTL-REV-CD],
	A.[PA-DTL-CPT-CD],
	A.[PA-DTL-PROC-CD-MODF(1)],
	A.[PA-DTL-PROC-CD-MODF(2)],
	A.[PA-DTL-PROC-CD-MODF(3)],
	CAST(A.[PA-DTL-SVC-CD-WOSCD] AS VARCHAR) + CAST(A.[PA-DTL-SVC-CD-SCD] AS VARCHAR) AS 'PA-DTL-SVC-CD',
	A.[PA-DTL-CDM-DESCRIPTION],
	SUM(A.[PA-DTL-CHG-QTY]) AS 'TOT-CHG-QTY',
	SUM(A.[PA-DTL-CHG-AMT]) AS 'TOT-CHARGES',
	SUM(A.[PA-DTL-PROFESSIONAL-FEE]) AS 'TOT-PROF-FESS'
FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_ACTIVE].dbo.[DetailInformation] a
INNER JOIN dbo.[Encounters_For_Reporting] b ON a.[pa-pt-no-woscd] = b.[pa-pt-no-woscd]
	AND A.[PA-DTL-DATE] >= B.[START_UNIT_DATE]
	AND A.[PA-DTL-DATE] <= B.[END_UNIT_DATE]
	AND a.[pa-ctl-paa-xfer-date] = b.[pa-ctl-paa-xfer-date] --AND b.[pa-unit-date] = a.[pa-dtl-unit-date]--DATEADD(DAY,-(DAY(DATEADD(MONTH, 1,a.[pa-dtl-date]))),DATEADD(MONTH,1,a.[pa-dtl-date]))
WHERE a.[pa-dtl-type-ind] IN ('7', '8', 'A', 'B')
	AND A.[PA-DTL-DATE] > '2014-12-31 23:59:59.000'
--AND a.[pa-pt-no-woscd] = '1010586387'
GROUP BY a.[pa-pt-no-woscd],
	a.[pa-pt-no-scd-1],
	B.[PA-UNIT-NO],
	b.[pa-unit-date],
	A.[PA-DTL-UNIT-DATE],
	B.[PTACCT_TYPE],
	A.[PA-DTL-TYPE-IND],
	A.[PA-DTL-GL-NO],
	A.[PA-DTL-CPT-CD],
	A.[PA-DTL-PROC-CD-MODF(1)],
	A.[PA-DTL-PROC-CD-MODF(2)],
	A.[PA-DTL-PROC-CD-MODF(3)],
	A.[PA-DTL-REV-CD],
	A.[PA-DTL-SVC-CD-WOSCD],
	A.[PA-DTL-SVC-CD-SCD],
	A.[PA-DTL-CDM-DESCRIPTION]

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
	B.[PA-UNIT-NO],
	b.[pa-unit-date],
	A.[PA-DTL-UNIT-DATE],
	B.[PTACCT_TYPE] AS 'TYPE',
	A.[PA-DTL-TYPE-IND],
	A.[PA-DTL-GL-NO],
	A.[PA-DTL-REV-CD],
	A.[PA-DTL-CPT-CD],
	A.[PA-DTL-PROC-CD-MODF(1)],
	A.[PA-DTL-PROC-CD-MODF(2)],
	A.[PA-DTL-PROC-CD-MODF(3)],
	CAST(A.[PA-DTL-SVC-CD-WOSCD] AS VARCHAR) + CAST(A.[PA-DTL-SVC-CD-SCD] AS VARCHAR) AS 'PA-DTL-SVC-CD',
	A.[PA-DTL-CDM-DESCRIPTION],
	SUM(A.[PA-DTL-CHG-QTY]) AS 'TOT-CHG-QTY',
	SUM(A.[PA-DTL-CHG-AMT]) AS 'TOT-CHARGES',
	SUM(A.[PA-DTL-PROFESSIONAL-FEE]) AS 'TOT-PROF-FEES'
FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Archive].dbo.[DetailInformation] a
INNER JOIN dbo.[Encounters_For_Reporting] b ON a.[pa-pt-no-woscd] = b.[pa-pt-no-woscd]
	AND b.[pa-unit-no] IS NULL
	AND a.[pa-ctl-paa-xfer-date] = b.[pa-ctl-paa-xfer-date] --DATEADD(DAY,-(DAY(DATEADD(MONTH, 1,a.[pa-dtl-date]))),DATEADD(MONTH,1,a.[pa-dtl-date]))
WHERE a.[pa-dtl-type-ind] IN ('7', '8', 'A', 'B')
	AND A.[PA-DTL-DATE] > '2014-12-31 23:59:59.000'
--AND a.[pa-pt-no-woscd] = '1010586387'
GROUP BY a.[pa-pt-no-woscd],
	a.[pa-pt-no-scd-1],
	B.[PA-UNIT-NO],
	b.[pa-unit-date],
	A.[PA-DTL-UNIT-DATE],
	B.[PTACCT_TYPE],
	A.[PA-DTL-TYPE-IND],
	A.[PA-DTL-GL-NO],
	A.[PA-DTL-CPT-CD],
	A.[PA-DTL-PROC-CD-MODF(1)],
	A.[PA-DTL-PROC-CD-MODF(2)],
	A.[PA-DTL-PROC-CD-MODF(3)],
	A.[PA-DTL-REV-CD],
	A.[PA-DTL-SVC-CD-WOSCD],
	A.[PA-DTL-SVC-CD-SCD],
	A.[PA-DTL-CDM-DESCRIPTION]

UNION

SELECT a.[pa-pt-no-woscd],
	a.[pa-pt-no-scd-1] AS 'PA-PT-NO-SCD',
	B.[PA-UNIT-NO],
	b.[pa-unit-date],
	A.[PA-DTL-UNIT-DATE],
	B.[PTACCT_TYPE] AS 'TYPE',
	A.[PA-DTL-TYPE-IND],
	A.[PA-DTL-GL-NO],
	A.[PA-DTL-REV-CD],
	A.[PA-DTL-CPT-CD],
	A.[PA-DTL-PROC-CD-MODF(1)],
	A.[PA-DTL-PROC-CD-MODF(2)],
	A.[PA-DTL-PROC-CD-MODF(3)],
	CAST(A.[PA-DTL-SVC-CD-WOSCD] AS VARCHAR) + CAST(A.[PA-DTL-SVC-CD-SCD] AS VARCHAR) AS 'PA-DTL-SVC-CD',
	A.[PA-DTL-CDM-DESCRIPTION],
	SUM(A.[PA-DTL-CHG-QTY]) AS 'TOT-CHG-QTY',
	SUM(A.[PA-DTL-CHG-AMT]) AS 'TOT-CHARGES',
	SUM(A.[PA-DTL-PROFESSIONAL-FEE]) AS 'TOT-PROF-FEES'
FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_ACTIVE].dbo.[DetailInformation] a
INNER JOIN dbo.[Encounters_For_Reporting] b ON a.[pa-pt-no-woscd] = b.[pa-pt-no-woscd]
	AND b.[pa-unit-no] IS NULL --DATEADD(DAY,-(DAY(DATEADD(MONTH, 1,a.[pa-dtl-date]))),DATEADD(MONTH,1,a.[pa-dtl-date]))
WHERE a.[pa-dtl-type-ind] IN ('7', '8', 'A', 'B')
	AND A.[PA-DTL-DATE] > '2014-12-31 23:59:59.000'
--AND a.[pa-pt-no-woscd] = '1010586387'
GROUP BY a.[pa-pt-no-woscd],
	a.[pa-pt-no-scd-1],
	B.[PA-UNIT-NO],
	b.[pa-unit-date],
	A.[PA-DTL-UNIT-DATE],
	B.[PTACCT_TYPE],
	A.[PA-DTL-TYPE-IND],
	A.[PA-DTL-GL-NO],
	A.[PA-DTL-CPT-CD],
	A.[PA-DTL-PROC-CD-MODF(1)],
	A.[PA-DTL-PROC-CD-MODF(2)],
	A.[PA-DTL-PROC-CD-MODF(3)],
	A.[PA-DTL-REV-CD],
	A.[PA-DTL-SVC-CD-WOSCD],
	A.[PA-DTL-SVC-CD-SCD],
	A.[PA-DTL-CDM-DESCRIPTION]
	----------------------------------------------------------------------------------------------------------------------------------------------------
	/*----Create Temp Table Unitized Bad Debts----------------------------------------*/
	-- IF OBJECT_ID('tempdb.dbo.#BD_UNIT_REFERRAL_AMTS','U') IS NOT NULL
	-- DROP TABLE #BD_UNIT_REFERRAL_AMTS;
	-- GO
	-- CREATE TABLE #BD_UNIT_REFERRAL_AMTS
	--(
	--[PA-PT-NO] CHAR(12) NOT NULL,
	--[PA-ACCT-TYPE] CHAR(1) NULL,
	--[PA-SMART-DATE] DATETIME NULL,
	--[BD-AMT] MONEY NULL,
	--[BD-UNIT-XFR] VARCHAR(6) null,
	--[RANK] VARCHAR(3) NULL,
	--);
	--INSERT INTO #BD_UNIT_REFERRAL_AMTS([PA-PT-NO],[PA-ACCT-TYPE],[PA-SMART-DATE],[BD-AMT],[BD-UNIT-XFR],[RANK])
	--SELECT CAST(a.[PA-PT-NO-WOSCD] as varchar) + CAST(a.[PA-PT-NO-SCD-1] as varchar) as 'PA-PT-NO'
	--      ,a.[PA-ACCT-TYPE]
	--      ,a.[PA-SMART-DATE]
	--       ,CASE
	--       WHEN CHARINDEX('-',[pa-smart-comment])<>'0' THEN  (-1 * CONVERT(money,REPLACE(REPLACE(LTRIM(RTRIM(Right(a.[pa-smart-comment],charindex(' ',REVERSE(a.[pa-smart-comment]))-1))),',',''),'-','')) )
	--       ELSE CONVERT(money,REPLACE(LTRIM(RTRIM(Right(a.[pa-smart-comment],charindex(' ',REVERSE(a.[pa-smart-comment]))-1))),',',''),1)
	--       END as 'BD-Amt',
	--       CASE
	--       WHEN CAST(SUBSTRING(a.[pa-smart-comment],16,8) as varchar) like '[0-1][0-9]/[0-3][0-9]/[0-1][0-9]'
	--       --ISDATE((SUBSTRING(a.[pa-smart-comment],16,2) + SUBSTRING(a.[pa-smart-comment],19,2) + SUBSTRING(a.[pa-smart-comment],22,2)))=1
	--       THEN (SUBSTRING(a.[pa-smart-comment],16,2) + SUBSTRING(a.[pa-smart-comment],19,2) + SUBSTRING(a.[pa-smart-comment],22,2))
	--       ELSE ''
	--       END  as 'BD-Unit-Xfr',
	--       --(SUBSTRING(a.[pa-smart-comment],16,2) + SUBSTRING(a.[pa-smart-comment],19,2) + SUBSTRING(a.[pa-smart-comment],22,2))
	--       RANK() OVER (PARTITION BY a.[pa-pt-no-woscd] ORDER BY a.[pa-smart-date] asc) as 'Rank'
	--       --,ISDATE((SUBSTRING(a.[pa-smart-comment],16,2) + SUBSTRING(a.[pa-smart-comment],19,2) + SUBSTRING(a.[pa-smart-comment],22,2)))
	--  FROM [Echo_Active].[dbo].[AccountComments] a left outer join [Echo_Active].[dbo].[PatientDemographics] b
	--  ON a.[pa-pt-no-woscd]=b.[pa-pt-no-woscd]
	--  WHERE a.[pa-smart-comment] LIKE 'BD UNIT %'
	--  AND SUBSTRING([pa-smart-comment],13,2) <> '00'
	--  AND CAST(SUBSTRING(a.[pa-smart-comment],16,8) as varchar) like '[0-1][0-9]/[0-3][0-9]/[0-1][0-9]'
	--  AND b.[pa-unit-sts]='U'
	--  UNION
	-- SELECT CAST(a.[PA-PT-NO-WOSCD] as varchar) + CAST(a.[PA-PT-NO-SCD-1] as varchar) as 'PA-PT-NO'
	--      ,a.[PA-ACCT-TYPE]
	--      ,a.[PA-SMART-DATE]
	--       ,CASE
	--       WHEN CHARINDEX('-',[pa-smart-comment])<>'0' THEN  (-1 * CONVERT(money,REPLACE(REPLACE(LTRIM(RTRIM(Right(a.[pa-smart-comment],charindex(' ',REVERSE(a.[pa-smart-comment]))-1))),',',''),'-','')) )
	--       ELSE CONVERT(money,REPLACE(LTRIM(RTRIM(Right(a.[pa-smart-comment],charindex(' ',REVERSE(a.[pa-smart-comment]))-1))),',',''),1)
	--       END as 'BD-Amt',
	--       CASE
	--       WHEN CAST(SUBSTRING(a.[pa-smart-comment],16,8) as varchar) like '[0-1][0-9]/[0-3][0-9]/[0-1][0-9]'
	--       --ISDATE((SUBSTRING(a.[pa-smart-comment],16,2) + SUBSTRING(a.[pa-smart-comment],19,2) + SUBSTRING(a.[pa-smart-comment],22,2)))=1
	--       THEN (SUBSTRING(a.[pa-smart-comment],16,2) + SUBSTRING(a.[pa-smart-comment],19,2) + SUBSTRING(a.[pa-smart-comment],22,2))
	--       ELSE ''
	--       END  as 'BD-Unit-Xfr',
	--       --(SUBSTRING(a.[pa-smart-comment],16,2) + SUBSTRING(a.[pa-smart-comment],19,2) + SUBSTRING(a.[pa-smart-comment],22,2))
	--       RANK() OVER (PARTITION BY a.[pa-pt-no-woscd] ORDER BY a.[pa-smart-date] asc) as 'Rank'
	--       --,ISDATE((SUBSTRING(a.[pa-smart-comment],16,2) + SUBSTRING(a.[pa-smart-comment],19,2) + SUBSTRING(a.[pa-smart-comment],22,2)))
	--  FROM [Echo_Archive].[dbo].[AccountComments] a left outer join [Echo_Archive].[dbo].[PatientDemographics] b
	--  ON a.[pa-pt-no-woscd]=b.[pa-pt-no-woscd]
	--  WHERE (a.[pa-smart-comment] LIKE 'XFER%TO BD'
	--  OR a.[pa-smart-comment] LIKE 'BD UNIT %')
	--  AND SUBSTRING([pa-smart-comment],13,2) <> '00'
	--  AND CAST(SUBSTRING(a.[pa-smart-comment],16,8) as varchar) like '[0-1][0-9]/[0-3][0-9]/[0-1][0-9]'
	--  AND b.[pa-unit-sts]='U'
	--  ORDER BY [pa-pt-no]
	----------------------------------------------------------------------------------------------------------------------------------------------------
	/*-----------Create Temp Table Non-Unitized Bad Debt Referrals--------------------*/
	-- IF OBJECT_ID('tempdb.dbo.#BD_REFERRAL_AMTS','U') IS NOT NULL
	-- DROP TABLE #BD_REFERRAL_AMTS;
	-- GO
	-- CREATE TABLE #BD_REFERRAL_AMTS
	--(
	--[PA-PT-NO] CHAR(12) NOT NULL,
	--[PA-ACCT-TYPE] CHAR(1) NULL,
	--[PA-SMART-DATE] DATETIME NULL,
	--[BD-AMT] VARCHAR(15) NULL,
	--[RANK] VARCHAR(1) NULL,
	--);
	--INSERT INTO #BD_REFERRAL_AMTS([PA-PT-NO],[PA-ACCT-TYPE],[PA-SMART-DATE],[BD-AMT],[RANK])
	--SELECT CAST(a.[PA-PT-NO-WOSCD] as varchar) + CAST(a.[PA-PT-NO-SCD-1] as varchar) as 'PA-PT-NO'
	--      ,a.[PA-ACCT-TYPE]
	--      ,a.[PA-SMART-DATE]
	--       , LTRIM(RTRIM(Right(a.[pa-smart-comment],charindex(' ',REVERSE(a.[pa-smart-comment]))-1))) as 'BD-Amt'
	--       ,RANK() OVER (PARTITION BY a.[pa-pt-no-woscd] ORDER BY a.[pa-smart-date] asc) as 'Rank'
	--  FROM [Echo_Active].[dbo].[AccountComments] a left outer join [Echo_Active].[dbo].[PatientDemographics] b
	--  ON a.[pa-pt-no-woscd]=b.[pa-pt-no-woscd]
	--  WHERE a.[pa-smart-comment] LIKE 'XFER ACCT FC%'
	--  --AND SUBSTRING([pa-smart-comment],13,2) <> '00'
	--  --AND CAST(SUBSTRING(a.[pa-smart-comment],16,8) as varchar) like '[0-1][0-9]/[0-3][0-9]/[0-1][0-9]'
	--  AND b.[pa-unit-sts] <> 'U'
	--  UNION
	-- SELECT CAST(a.[PA-PT-NO-WOSCD] as varchar) + CAST(a.[PA-PT-NO-SCD-1] as varchar) as 'PA-PT-NO'
	--      ,a.[PA-ACCT-TYPE]
	--      ,a.[PA-SMART-DATE]
	--       , LTRIM(RTRIM(Right(a.[pa-smart-comment],charindex(' ',REVERSE(a.[pa-smart-comment]))-1))) as 'BD-Amt'
	--       ,RANK() OVER (PARTITION BY a.[pa-pt-no-woscd] ORDER BY a.[pa-smart-date] asc) as 'Rank'
	--  FROM [Echo_Archive].[dbo].[AccountComments] a left outer join [Echo_Archive].[dbo].[PatientDemographics] b
	--  ON a.[pa-pt-no-woscd]=b.[pa-pt-no-woscd]
	--  WHERE a.[pa-smart-comment] LIKE 'XFER ACCT FC%'
	--  --AND SUBSTRING([pa-smart-comment],13,2) <> '00'
	-- -- AND CAST(SUBSTRING(a.[pa-smart-comment],16,8) as varchar) like '[0-1][0-9]/[0-3][0-9]/[0-1][0-9]'
	--  AND b.[pa-unit-sts] <> 'U'
	--  ORDER BY [pa-pt-no]
	/*------------------------Create Unitized Pt BD Recovery Table-------------------------------------------------------------------------------*/
	-- IF OBJECT_ID('tempdb.dbo.#Unitized_Pt_Recoveries','U') IS NOT NULL
	-- DROP TABLE #Unitized_Pt_Recoveries;
	-- GO
	-- CREATE TABLE #Unitized_Pt_Recoveries
	--(
	--[PA-PT-NO] VARCHAR(12) NOT NULL,
	--[UNIT-DATE] DATETIME null,
	--[TOT-PT-RECOVERIES] MONEY NULL
	--);
	--INSERT INTO #Unitized_Pt_Recoveries ([PA-PT-NO],[UNIT-DATE],[TOT-PT-RECOVERIES])
	--SELECT CAST(a.[pa-pt-no-woscd] as varchar) +CAST(a.[pa-pt-no-scd-1] as varchar) as 'PA-PT-NO',
	--b.[pa-unit-date],
	--SUM(a.[pa-dtl-chg-amt]) as 'Tot-Pt-Recoveries'
	--FROM [Echo_Archive].dbo.[DetailInformation] a inner join [Echo_Archive].dbo.[UnitizedAccounts] b
	--ON a.[pa-pt-no-woscd]=b.[pa-pt-no-woscd] AND b.[pa-unit-date] = a.[pa-dtl-unit-date]--DATEADD(DAY,-(DAY(DATEADD(MONTH, 1,a.[pa-dtl-date]))),DATEADD(MONTH,1,a.[pa-dtl-date]))
	--WHERE ((a.[pa-dtl-svc-cd-woscd] IN ('10275','10202')
	--OR a.[pa-dtl-svc-cd-woscd] IN ('60320','60215') and a.[pa-dtl-ins-co-cd]='')
	--AND a.[pa-dtl-fc] IN ('0','1','2','3','4','5','6','7','8','9'))
	----AND a.[pa-pt-no-woscd]='1004750392'
	-- GROUP BY a.[pa-pt-no-woscd], a.[pa-pt-no-scd-1], b.[pa-unit-date]
	-- UNION
	-- SELECT CAST(a.[pa-pt-no-woscd] as varchar) +CAST(a.[pa-pt-no-scd-1] as varchar) as 'PA-PT-NO',
	--b.[pa-unit-date],
	--SUM(a.[pa-dtl-chg-amt]) as 'Tot_Pt_Recoveries'
	--FROM [Echo_Active].dbo.[DetailInformation] a inner join [Echo_Active].dbo.[UnitizedAccounts] b
	--ON a.[pa-pt-no-woscd]=b.[pa-pt-no-woscd] AND b.[pa-unit-date] = a.[pa-dtl-unit-date]--DATEADD(DAY,-(DAY(DATEADD(MONTH, 1,a.[pa-dtl-date]))),DATEADD(MONTH,1,a.[pa-dtl-date]))
	--WHERE ((a.[pa-dtl-svc-cd-woscd] IN ('10275','10202')
	--OR a.[pa-dtl-svc-cd-woscd] IN ('60320','60215') and a.[pa-dtl-ins-co-cd]='')
	--AND a.[pa-dtl-fc] IN ('0','1','2','3','4','5','6','7','8','9'))
	-- GROUP BY a.[pa-pt-no-woscd], a.[pa-pt-no-scd-1], b.[pa-unit-date]
	----------------------------------------------------------------------------------------------------------------------------------------------------
	/*----------Create Non-Unitized Pt Recoveries Table---------------------------*/
	-- IF OBJECT_ID('tempdb.dbo.#NonUnit_Pt_Recoveries','U') IS NOT NULL
	-- DROP TABLE #NonUnit_Pt_Recoveries;
	-- GO
	-- CREATE TABLE #NonUnit_Pt_Recoveries
	--(
	--[PA-PT-NO] VARCHAR(12) NOT NULL,
	--[DSCH-DATE] DATETIME null,
	--[TOT-PT-RECOVERIES] MONEY NULL
	--);
	--INSERT INTO #NonUnit_Pt_Recoveries ([PA-PT-NO],[DSCH-DATE],[TOT-PT-RECOVERIES])
	--SELECT CAST(a.[pa-pt-no-woscd] as varchar) +CAST(a.[pa-pt-no-scd-1] as varchar) as 'PA-PT-NO',
	--b.[pa-dsch-date],
	--SUM(a.[pa-dtl-chg-amt]) as 'Tot-Pt-Recoveries'
	--FROM [Echo_Archive].dbo.[DetailInformation] a inner join [Echo_Archive].dbo.[PatientDemographics] b
	--ON a.[pa-pt-no-woscd]=b.[pa-pt-no-woscd] AND b.[pa-unit-sts]<>'U'--DATEADD(DAY,-(DAY(DATEADD(MONTH, 1,a.[pa-dtl-date]))),DATEADD(MONTH,1,a.[pa-dtl-date]))
	--WHERE ((a.[pa-dtl-svc-cd-woscd] IN ('10275','10202')
	--OR a.[pa-dtl-svc-cd-woscd] IN ('60320','60215') and a.[pa-dtl-ins-co-cd]='')
	--AND a.[pa-dtl-fc] IN ('0','1','2','3','4','5','6','7','8','9'))
	-- GROUP BY a.[pa-pt-no-woscd], a.[pa-pt-no-scd-1], b.[pa-dsch-date]
	-- UNION
	-- SELECT CAST(a.[pa-pt-no-woscd] as varchar) +CAST(a.[pa-pt-no-scd-1] as varchar) as 'PA-PT-NO',
	--b.[pa-dsch-date],
	--SUM(a.[pa-dtl-chg-amt]) as 'Tot_Pt_Recoveries'
	--FROM [Echo_Active].dbo.[DetailInformation] a inner join [Echo_Active].dbo.[PatientDemographics] b
	--ON a.[pa-pt-no-woscd]=b.[pa-pt-no-woscd] AND b.[pa-unit-sts] <> 'U'---DATEADD(DAY,-(DAY(DATEADD(MONTH, 1,a.[pa-dtl-date]))),DATEADD(MONTH,1,a.[pa-dtl-date]))
	--WHERE ((a.[pa-dtl-svc-cd-woscd] IN ('10275','10202')
	--OR a.[pa-dtl-svc-cd-woscd] IN ('60320','60215') and a.[pa-dtl-ins-co-cd]='')
	--AND a.[pa-dtl-fc] IN ('0','1','2','3','4','5','6','7','8','9'))
	-- GROUP BY a.[pa-pt-no-woscd], a.[pa-pt-no-scd-1], b.[pa-dsch-date]
	----------------------------------------------------------------------------------------------------------------------------------------------------
	/*----------Create Non-Unitized Non-Pt Recoveries Table---------------------------*/
	-- IF OBJECT_ID('tempdb.dbo.#NonUnit_NonPt_Recoveries','U') IS NOT NULL
	-- DROP TABLE #NonUnit_NonPt_Recoveries;
	-- GO
	-- CREATE TABLE #NonUnit_NonPt_Recoveries
	--(
	--[PA-PT-NO] VARCHAR(12) NOT NULL,
	--[DSCH-DATE] DATETIME null,
	--[TOT-NONPT-RECOVERIES] MONEY NULL
	--);
	--INSERT INTO #NonUnit_NonPt_Recoveries ([PA-PT-NO],[DSCH-DATE],[TOT-NONPT-RECOVERIES])
	--SELECT CAST(a.[pa-pt-no-woscd] as varchar) +CAST(a.[pa-pt-no-scd-1] as varchar) as 'PA-PT-NO',
	--b.[pa-dsch-date],
	--SUM(a.[pa-dtl-chg-amt]) as 'Tot-NonPt-Recoveries'
	--FROM [Echo_Archive].dbo.[DetailInformation] a inner join [Echo_Archive].dbo.[PatientDemographics] b
	--ON a.[pa-pt-no-woscd]=b.[pa-pt-no-woscd] AND b.[pa-unit-sts]<>'U'--DATEADD(DAY,-(DAY(DATEADD(MONTH, 1,a.[pa-dtl-date]))),DATEADD(MONTH,1,a.[pa-dtl-date]))
	--WHERE (a.[pa-dtl-type-ind]='1' AND a.[pa-dtl-svc-cd-woscd] NOT IN ('10275','10202') AND a.[pa-dtl-fc] IN ('0','1','2','3','4','5','6','7','8','9'))
	--OR (a.[pa-dtl-svc-cd-woscd] IN ('60320','60215') and a.[pa-dtl-ins-co-cd]<>'' AND a.[pa-dtl-fc] IN ('0','1','2','3','4','5','6','7','8','9'))
	-- GROUP BY a.[pa-pt-no-woscd], a.[pa-pt-no-scd-1], b.[pa-dsch-date]
	-- UNION
	-- SELECT CAST(a.[pa-pt-no-woscd] as varchar) +CAST(a.[pa-pt-no-scd-1] as varchar) as 'PA-PT-NO',
	--b.[pa-dsch-date],
	--SUM(a.[pa-dtl-chg-amt]) as 'Tot-NonPt-Recoveries'
	--FROM [Echo_Active].dbo.[DetailInformation] a inner join [Echo_Active].dbo.[PatientDemographics] b
	--ON a.[pa-pt-no-woscd]=b.[pa-pt-no-woscd] AND b.[pa-unit-sts] <> 'U'---DATEADD(DAY,-(DAY(DATEADD(MONTH, 1,a.[pa-dtl-date]))),DATEADD(MONTH,1,a.[pa-dtl-date]))
	--WHERE (a.[pa-dtl-type-ind]='1' AND a.[pa-dtl-svc-cd-woscd] NOT IN ('10275','10202') AND a.[pa-dtl-fc] IN ('0','1','2','3','4','5','6','7','8','9'))
	--OR (a.[pa-dtl-svc-cd-woscd] IN ('60320','60215') and a.[pa-dtl-ins-co-cd]<>'' AND a.[pa-dtl-fc] IN ('0','1','2','3','4','5','6','7','8','9'))
	-- GROUP BY a.[pa-pt-no-woscd], a.[pa-pt-no-scd-1], b.[pa-dsch-date]
	----------------------------------------------------------------------------------------------------------------------------------------------------
	/*------------------------Create Unitized Non Pt BD Recovery Table-------------------------------------------------------------------------------*/
	-- IF OBJECT_ID('tempdb.dbo.#Unitized_NonPt_Recoveries','U') IS NOT NULL
	-- DROP TABLE #Unitized_NonPt_Recoveries;
	-- GO
	-- CREATE TABLE #Unitized_NonPt_Recoveries
	--(
	--[PA-PT-NO] VARCHAR(12) NOT NULL,
	--[UNIT-DATE] DATETIME null,
	--[TOT-NONPT-RECOVERIES] MONEY NULL
	--);
	--INSERT INTO #Unitized_NonPt_Recoveries ([PA-PT-NO],[UNIT-DATE],[TOT-NONPT-RECOVERIES])
	--SELECT CAST(a.[pa-pt-no-woscd] as varchar) +CAST(a.[pa-pt-no-scd-1] as varchar) as 'PA-PT-NO',
	--b.[pa-unit-date],
	--SUM(a.[pa-dtl-chg-amt]) as 'Tot-NonPt-Recoveries'
	--FROM [Echo_Archive].dbo.[DetailInformation] a inner join [Echo_Archive].dbo.[UnitizedAccounts] b
	--ON a.[pa-pt-no-woscd]=b.[pa-pt-no-woscd] AND b.[pa-unit-date] = a.[pa-dtl-unit-date]--DATEADD(DAY,-(DAY(DATEADD(MONTH, 1,a.[pa-dtl-date]))),DATEADD(MONTH,1,a.[pa-dtl-date]))
	--WHERE (a.[pa-dtl-type-ind]='1' AND a.[pa-dtl-svc-cd-woscd] NOT IN ('10275','10202') AND a.[pa-dtl-fc] IN ('0','1','2','3','4','5','6','7','8','9'))
	--OR (a.[pa-dtl-svc-cd-woscd] IN ('60320','60215') and a.[pa-dtl-ins-co-cd]<>'' AND a.[pa-dtl-fc] IN ('0','1','2','3','4','5','6','7','8','9'))
	-- GROUP BY a.[pa-pt-no-woscd], a.[pa-pt-no-scd-1], b.[pa-unit-date]
	-- UNION
	-- SELECT CAST(a.[pa-pt-no-woscd] as varchar) +CAST(a.[pa-pt-no-scd-1] as varchar) as 'PA-PT-NO',
	--b.[pa-unit-date],
	--SUM(a.[pa-dtl-chg-amt]) as 'Tot-NonPt-Recoveries'
	--FROM [Echo_Active].dbo.[DetailInformation] a inner join [Echo_Active].dbo.[UnitizedAccounts] b
	--ON a.[pa-pt-no-woscd]=b.[pa-pt-no-woscd] AND b.[pa-unit-date] = a.[pa-dtl-unit-date]--DATEADD(DAY,-(DAY(DATEADD(MONTH, 1,a.[pa-dtl-date]))),DATEADD(MONTH,1,a.[pa-dtl-date]))
	--WHERE (a.[pa-dtl-type-ind]='1' AND a.[pa-dtl-svc-cd-woscd] NOT IN ('10275','10202') AND a.[pa-dtl-fc] IN ('0','1','2','3','4','5','6','7','8','9'))
	--OR (a.[pa-dtl-svc-cd-woscd] IN ('60320','60215') and a.[pa-dtl-ins-co-cd]<>'' AND a.[pa-dtl-fc] IN ('0','1','2','3','4','5','6','7','8','9'))
	-- GROUP BY a.[pa-pt-no-woscd], a.[pa-pt-no-scd-1], b.[pa-unit-date]
	----------------------------------------------------------------------------------------------------------------------------------------------------
	-- SELECT a.[pa-pt-no],
	-- A.[PA-MED-REC-NO],
	-- A.[PA-HOSP-SVC],
	-- a.[unit-date],
	-- a.[dsch-date],
	-- --a.[pa-bal-tot-pt-pay-amt],
	-- a.[pa-bal-pt-bal] as 'Patient_Balance',
	-- a.[pa-acct-bd-xfr-date],
	----COALESCE(e.[pa-smart-date],d.[pa-smart-date]) as 'BD_Referral_Date',
	--a.[pa-fc],
	----a.[pa-bal-posted-since-xfr-bd],
	--isnull(b.[tot-payments],0) as 'Unitized_Payments',
	--isnull(c.[tot-payments],0) as 'NonUnit_Payments'
	----isnull(bb.[tot-pt-recoveries],0) as 'Unitized_Recoveries',
	----isnull(cc.[tot-pt-recoveries],0) as 'NonUnit_Recoveries',
	----COALESCE(e.[bd-amt],isnull(d.[bd-amt],0)) as 'Bad_Debt_Bal_Referred',
	----isnull(g.[tot-nonpt-recoveries],0) as 'Unitized_NonPt_Recoveries',
	----isnull(f.[tot-nonpt-recoveries],0) as 'NonUnit_NonPt_Recoveries'
	-- FROM #Pts_By_Dsch_Date a left outer join #Unitized_Payments b  
	-- ON a.[pa-pt-no]=b.[pa-pt-no] and a.[unit-date]=b.[unit-date]
	-- left outer join #NonUnit_Payments c
	-- ON a.[pa-pt-no]=c.[pa-pt-no]
	-- --left outer join #Unitized_Pt_Recoveries bb
	-- --ON a.[pa-pt-no]=bb.[pa-pt-no] AND a.[unit-date]=bb.[unit-date]
	-- --left outer join #NonUnit_Pt_Recoveries cc
	-- --ON a.[pa-pt-no]=cc.[pa-pt-no]
	-- --left outer join #BD_REFERRAL_AMTS d
	-- --ON a.[pa-pt-no]=d.[pa-pt-no]
	-- --left outer join #BD_UNIT_REFERRAL_AMTS e
	-- --ON a.[pa-pt-no]=e.[pa-pt-no] and a.[unit-string]=e.[bd-unit-xfr]
	-- --left outer join #NonUnit_NonPt_Recoveries f
	-- --ON a.[pa-pt-no]=f.[pa-pt-no]
	-- --left outer join #Unitized_NonPt_Recoveries g
	-- --ON a.[pa-pt-no]=g.[pa-pt-no] and a.[unit-date]=g.[unit-date]
	-- -- WHERE a.[dsch-date] > '2010-12-31 00:00:00.000'
	-- -- AND a.[pa-hosp-svc] IN ('ORT','NBS')
	-- -- AND (a.[pa-bal-pt-bal]<> '0.00'
	-- --OR (b.[tot-pt-payments] is not null or b.[tot-pt-payments] <> '0')
	-- --OR (c.[tot-pt-payments] is not null or c.[tot-pt-payments] <> '0')
	-- ----or (e.[bd-amt]<>'0' or e.[bd-amt] is not null)
	-- ----or (d.[bd-amt]<>'0' or d.[bd-amt] is not null))
	--WHERE a.[pa-hosp-svc] IN ('MON','PON','RDO','TIP','PSP')
	--GROUP BY a.[pa-pt-no],
	--A.[PA-MED-REC-NO],
	--A.[PA-HOSP-SVC],
	-- a.[unit-date],
	-- a.[dsch-date],
	-- --a.[pa-bal-tot-pt-pay-amt],
	-- a.[pa-bal-pt-bal],
	-- a.[pa-acct-bd-xfr-date],
	---- e.[pa-smart-date],
	---- d.[pa-smart-date],
	--a.[pa-fc],
	--b.[tot-payments],
	--c.[tot-payments]
	----bb.[tot-pt-recoveries],
	----cc.[tot-pt-recoveries],
	----e.[bd-amt],
	----d.[bd-amt],
	----g.[tot-nonpt-recoveries],
	----f.[tot-nonpt-recoveries]
	----ORDER BY a.[pa-pt-no]
	----SELECT * 
	----FROM dbo.#NonUnit_NonPt_Recoveries
