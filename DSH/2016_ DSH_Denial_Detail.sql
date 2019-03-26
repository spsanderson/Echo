USE [DSH];

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/*------------------------Create Unitized Charges Table-------------------------------------------------------------------------------*/
DROP TABLE IF EXISTS [2016_DSH_Denials_Detail] GO

	CREATE TABLE [2016_DSH_Denials_Detail] (
		[PA-PT-NO-WOSCD] VARCHAR(11) NOT NULL,
		[PA-PT-NO-SCD] CHAR(1) NOT NULL,
		[PT-NO] VARCHAR(50) NOT NULL,
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
		[TOT-PROF-FEES] MONEY NULL
		);

INSERT INTO [2016_DSH_Denials_Detail] (
	[PA-PT-NO-WOSCD],
	[PA-PT-NO-SCD],
	[PT-NO],
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
	[TOT-PROF-FEES]
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
	A.[PA-DTL-REV-CD],
	A.[PA-DTL-CPT-CD],
	CAST(A.[PA-DTL-SVC-CD-WOSCD] AS VARCHAR) + CAST(A.[PA-DTL-SVC-CD-SCD] AS VARCHAR) AS 'PA-DTL-SVC-CD',
	A.[PA-DTL-CDM-DESCRIPTION],
	c.[PA-UNIT-STS],
	C.[PA-BFW-ACCT-TOT] AS 'TOT-BFW-ACCOUNT',
	C.[PA-BFW-CHG-TOT] AS 'TOT-BFW-CHG',
	SUM(A.[PA-DTL-CHG-QTY]) AS 'TOT-CHG-QTY',
	SUM(A.[PA-DTL-CHG-AMT]) AS 'TOT-CHARGES',
	SUM(A.[PA-DTL-PROFESSIONAL-FEE]) AS 'TOT-PROF-FEES'
FROM [Echo_Archive].dbo.[DetailInformation] a
INNER JOIN [Encounters_For_DSH] b ON a.[pa-pt-no-woscd] = b.[pa-pt-no-woscd]
	AND A.[PA-DTL-unit-DATE] = B.[pa-unit-date]
	AND a.[pa-ctl-paa-xfer-date] = b.[pa-ctl-paa-xfer-date] --AND b.[pa-unit-date] = a.[pa-dtl-unit-date]--DATEADD(DAY,-(DAY(DATEADD(MONTH, 1,a.[pa-dtl-date]))),DATEADD(MONTH,1,a.[pa-dtl-date]))
LEFT JOIN [Echo_Archive].dbo.[PatientDemographics] C ON A.[PA-PT-NO-WOSCD] = C.[PA-PT-NO-WOSCD]
WHERE --a.[pa-dtl-type-ind] IN ('7','8','A','B')
	--AND a.[pa-pt-no-woscd] = '1010586387'
	a.[pa-dtl-svc-cd-woscd] IN ('21141', '21145', '23750', '23754', '29101') --('21141','21142','21901','21905','23752','23754','29701','29705','21143','21144','21145','21146','21147','21148','21810','22750','23302','23303',--Rev Integrity Denial Codes
	--'20375','20525','21130','21140','21742','21910','21915','22210','2220','22626','22330','22636','23756','23840','24109','29101','23750','29001','29101')
GROUP BY a.[pa-pt-no-woscd],
	a.[pa-pt-no-scd-1],
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
	c.[PA-BFW-CHG-TOT]

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
	A.[PA-DTL-REV-CD],
	A.[PA-DTL-CPT-CD],
	CAST(A.[PA-DTL-SVC-CD-WOSCD] AS VARCHAR) + CAST(A.[PA-DTL-SVC-CD-SCD] AS VARCHAR) AS 'PA-DTL-SVC-CD',
	A.[PA-DTL-CDM-DESCRIPTION],
	c.[PA-UNIT-STS],
	C.[PA-BFW-ACCT-TOT] AS 'TOT-BFW-ACCOUNT',
	c.[PA-BFW-CHG-TOT] AS 'TOT-BFW-CHG',
	SUM(A.[PA-DTL-CHG-QTY]) AS 'TOT-CHG-QTY',
	SUM(A.[PA-DTL-CHG-AMT]) AS 'TOT-CHARGES',
	SUM(A.[PA-DTL-PROFESSIONAL-FEE]) AS 'TOT-PROF-FESS'
FROM [Echo_ACTIVE].dbo.[DetailInformation] a
INNER JOIN [Encounters_For_DSH] b ON a.[pa-pt-no-woscd] = b.[pa-pt-no-woscd]
	AND A.[PA-DTL-unit-DATE] = B.[pa-unit-date]
	AND a.[pa-ctl-paa-xfer-date] = b.[pa-ctl-paa-xfer-date] --AND b.[pa-unit-date] = a.[pa-dtl-unit-date]--DATEADD(DAY,-(DAY(DATEADD(MONTH, 1,a.[pa-dtl-date]))),DATEADD(MONTH,1,a.[pa-dtl-date]))
LEFT JOIN [Echo_Active].dbo.[PatientDemographics] C ON A.[PA-PT-NO-WOSCD] = C.[PA-PT-NO-WOSCD]
WHERE --a.[pa-dtl-type-ind] IN ('7','8','A','B')
	--AND a.[pa-pt-no-woscd] = '1010586387'
	a.[pa-dtl-svc-cd-woscd] IN ('21141', '21145', '23750', '23754', '29101') --('21141','21142','21901','21905','23752','23754','29701','29705','21143','21144','21145','21146','21147','21148','21810','22750','23302','23303',--Rev Integrity Denial Codes
	--'20375','20525','21130','21140','21742','21910','21915','22210','2220','22626','22330','22636','23756','23840','24109','29101','23750','29001','29101')
GROUP BY a.[pa-pt-no-woscd],
	a.[pa-pt-no-scd-1],
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
	c.[PA-BFW-CHG-TOT]

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
	A.[PA-DTL-REV-CD],
	A.[PA-DTL-CPT-CD],
	CAST(A.[PA-DTL-SVC-CD-WOSCD] AS VARCHAR) + CAST(A.[PA-DTL-SVC-CD-SCD] AS VARCHAR) AS 'PA-DTL-SVC-CD',
	A.[PA-DTL-CDM-DESCRIPTION],
	c.[PA-UNIT-STS],
	C.[PA-BFW-ACCT-TOT] AS 'TOT-BFW-ACCOUNT',
	c.[PA-BFW-CHG-TOT] AS 'TOT-BFW-CHG',
	SUM(A.[PA-DTL-CHG-QTY]) AS 'TOT-CHG-QTY',
	SUM(A.[PA-DTL-CHG-AMT]) AS 'TOT-CHARGES',
	SUM(A.[PA-DTL-PROFESSIONAL-FEE]) AS 'TOT-PROF-FEES'
FROM [Echo_Archive].dbo.[DetailInformation] a
INNER JOIN [Encounters_For_DSH] b ON a.[pa-pt-no-woscd] = b.[pa-pt-no-woscd]
	AND b.[pa-unit-no] IS NULL
	AND a.[pa-ctl-paa-xfer-date] = b.[pa-ctl-paa-xfer-date] --DATEADD(DAY,-(DAY(DATEADD(MONTH, 1,a.[pa-dtl-date]))),DATEADD(MONTH,1,a.[pa-dtl-date]))
LEFT JOIN [Echo_Archive].dbo.[PatientDemographics] C ON A.[PA-PT-NO-WOSCD] = C.[PA-PT-NO-WOSCD]
WHERE --a.[pa-dtl-type-ind] IN ('7','8','A','B')
	--AND a.[pa-pt-no-woscd] = '1010586387'
	a.[pa-dtl-svc-cd-woscd] IN ('21141', '21145', '23750', '23754', '29101') --('21141','21142','21901','21905','23752','23754','29701','29705','21143','21144','21145','21146','21147','21148','21810','22750','23302','23303',--Rev Integrity Denial Codes
	--'20375','20525','21130','21140','21742','21910','21915','22210','2220','22626','22330','22636','23756','23840','24109','29101','23750','29001','29101')
GROUP BY a.[pa-pt-no-woscd],
	a.[pa-pt-no-scd-1],
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
	c.[PA-BFW-CHG-TOT]

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
	A.[PA-DTL-REV-CD],
	A.[PA-DTL-CPT-CD],
	CAST(A.[PA-DTL-SVC-CD-WOSCD] AS VARCHAR) + CAST(A.[PA-DTL-SVC-CD-SCD] AS VARCHAR) AS 'PA-DTL-SVC-CD',
	A.[PA-DTL-CDM-DESCRIPTION],
	c.[PA-UNIT-STS],
	C.[PA-BFW-ACCT-TOT] AS 'TOT-BFW-ACCOUNT',
	C.[PA-BFW-CHG-TOT] AS 'TOT-BFW-CHG',
	SUM(A.[PA-DTL-CHG-QTY]) AS 'TOT-CHG-QTY',
	SUM(A.[PA-DTL-CHG-AMT]) AS 'TOT-CHARGES',
	SUM(A.[PA-DTL-PROFESSIONAL-FEE]) AS 'TOT-PROF-FEES'
FROM [Echo_ACTIVE].dbo.[DetailInformation] a
INNER JOIN [Encounters_For_DSH] b ON a.[pa-pt-no-woscd] = b.[pa-pt-no-woscd]
	AND b.[pa-unit-no] IS NULL --DATEADD(DAY,-(DAY(DATEADD(MONTH, 1,a.[pa-dtl-date]))),DATEADD(MONTH,1,a.[pa-dtl-date]))
LEFT JOIN [Echo_ACTIVE].dbo.[PatientDemographics] C ON A.[PA-PT-NO-WOSCD] = C.[PA-PT-NO-WOSCD]
WHERE --a.[pa-dtl-type-ind] IN ('7','8','A','B')
	--AND a.[pa-pt-no-woscd] = '1010586387'
	a.[pa-dtl-svc-cd-woscd] IN ('21141', '21145', '23750', '23754', '29101') --('21141','21142','21901','21905','23752','23754','29701','29705','21143','21144','21145','21146','21147','21148','21810','22750','23302','23303',--Rev Integrity Denial Codes
	--'20375','20525','21130','21140','21742','21910','21915','22210','2220','22626','22330','22636','23756','23840','24109','29101','23750','29001','29101')
GROUP BY a.[pa-pt-no-woscd],
	a.[pa-pt-no-scd-1],
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
	c.[PA-BFW-CHG-TOT]

SELECT *
FROM [2016_DSH_Denials_Detail]
ORDER BY [pt-no],
	[pa-unit-no]
