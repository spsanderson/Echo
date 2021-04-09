USE [SMS]
GO

/*
***********************************************************************
File: sms_charges_for_reporting_sp.sql

Input Parameters:
	None

Tables/Views:
	[ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_ACTIVE].dbo.[DetailInformation]
    [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Archive].dbo.[DetailInformation]
	dbo.[Encounters_For_Reporting]

Creates Table:
	dbo.Charges_For_Reporting

Functions:
	none	

Author: Steven P Sanderson II, MPH

Purpose/Description
	Create table Charges for Reprting 

Revision History:
Date		Version		Description
----		----		----
2020-12-17	v1			Initial Creation
***********************************************************************
*/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE dbo.c_sms_charges_for_reporting_sp
AS
SET ANSI_NULLS ON
SET ANSI_WARNINGS ON
SET QUOTED_IDENTIFIER ON

BEGIN
	SET NOCOUNT ON;

	-- If table exists TRUNCATE else Create then INSERT
	IF OBJECT_ID('dbo.Charges_For_Reporting', 'U') IS NOT NULL
		TRUNCATE TABLE dbo.Charges_For_Reporting
	ELSE
		CREATE TABLE dbo.[Charges_For_Reporting] (
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

	INSERT INTO dbo.[Charges_For_Reporting] (
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
		AND A.[PA-DTL-DATE] >= B.[START-UNIT-DATE]
		AND A.[PA-DTL-DATE] <= B.[END-UNIT-DATE]
		AND a.[pa-ctl-paa-xfer-date] = b.[pa-ctl-paa-xfer-date]
	WHERE a.[pa-dtl-type-ind] IN ('7', '8', 'A', 'B')
		AND A.[PA-DTL-DATE] > '2014-12-31 23:59:59.000'
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
	FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Archive].dbo.[DetailInformation] a
	INNER JOIN dbo.[Encounters_For_Reporting] b ON a.[pa-pt-no-woscd] = b.[pa-pt-no-woscd]
		AND b.[pa-unit-no] IS NULL
		AND a.[pa-ctl-paa-xfer-date] = b.[pa-ctl-paa-xfer-date]
	WHERE a.[pa-dtl-type-ind] IN ('7', '8', 'A', 'B')
		AND A.[PA-DTL-DATE] > '2014-12-31 23:59:59.000'
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
		AND b.[pa-unit-no] IS NULL
	WHERE a.[pa-dtl-type-ind] IN ('7', '8', 'A', 'B')
		AND A.[PA-DTL-DATE] > '2014-12-31 23:59:59.000'
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
END
