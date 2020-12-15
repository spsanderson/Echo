USE [SMS]
GO

/*
***********************************************************************
File: sms_encounters_for_reporting_sp.sql

Input Parameters:
	none

Tables/Views:
	[ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_ACTIVE].dbo.PatientDemographics
	[ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_ACTIVE].dbo.unitizedaccounts
	[ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_ARCHIVE].dbo.PatientDemographics
	[ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_ARCHIVE].dbo.unitizedaccounts

Creates Table:
	dbo.Unit_Partitions

Functions:
	none	

Author: Steven P Sanderson II, MPH

Purpose/Description
	Create Encounters for reporting in SMS DB with linked server reference

Revision History:
Date		Version		Description
----		----		----
2020-11-15	v1			Initial Creation
***********************************************************************
*/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- Create a new stored procedure called 'sms_encounters_for_reporting_sp' in schema 'dbo'
-- Create the stored procedure in the specified schema
ALTER PROCEDURE dbo.c_sms_encounters_for_reporting_sp
AS
SET ANSI_NULLS ON
SET ANSI_WARNINGS ON
SET QUOTED_IDENTIFIER ON

BEGIN
	SET NOCOUNT ON;

	DECLARE @UNIT_START_DATE DATE;

	SET @UNIT_START_DATE = '2007-01-01';

	-- USE CTE to get units
	WITH CTE
	AS (
		SELECT A.[PA-PT-NO-woscd],
			A.[pa-pt-no-scd-1],
			b.[PA-UNIT-DATE],
			b.[PA-UNIT-NO],
			B.[PA-CTL-PAA-XFER-DATE],
			A.[PA-UNIT-STS]
		FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_ACTIVE].dbo.PatientDemographics a
		LEFT OUTER JOIN [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_ACTIVE].dbo.unitizedaccounts b ON a.[pa-pt-no-woscd] = b.[pa-pt-no-woscd]
			AND a.[pa-pt-no-scd] = b.[pa-pt-no-scd-1]
		WHERE (
				a.[pa-acct-type] IN ('0', '6', '7')
				AND b.[pa-unit-no] IS NOT NULL
				AND b.[pa-unit-date] >= @UNIT_START_DATE
				)
		
		UNION
		
		SELECT A.[PA-PT-NO-woscd],
			A.[pa-pt-no-scd-1],
			b.[PA-UNIT-DATE],
			b.[PA-UNIT-NO],
			B.[PA-CTL-PAA-XFER-DATE],
			A.[PA-UNIT-STS]
		FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_ARCHIVE].dbo.PatientDemographics a
		LEFT OUTER JOIN [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_ARCHIVE].dbo.unitizedaccounts b ON a.[pa-pt-no-woscd] = b.[pa-pt-no-woscd]
			AND a.[pa-pt-no-scd] = b.[pa-pt-no-scd-1]
		WHERE (
				a.[pa-acct-type] IN ('0', '6', '7')
				AND b.[pa-unit-no] IS NOT NULL
				AND b.[pa-unit-date] >= @UNIT_START_DATE
				)
		)
	-- RANK the units and place into #UNITS
	SELECT A.[PA-PT-NO-WOSCD],
		[PA-PT-NO-SCD-1],
		[PA-CTL-PAA-XFER-DATE],
		[PA-UNIT-DATE],
		[PA-UNIT-NO],
		RANK() OVER (
			PARTITION BY [pa-pt-no-woscd] ORDER BY [PA-unit-date] ASC
			) AS 'alt-pa-unit-no',
		[PA-UNIT-STS]
	INTO #UNITS
	FROM CTE AS A;

	-- Create a new table called 'Unit_Partitions' in schema 'dbo'
	-- Drop the table if it already exists
	IF OBJECT_ID('dbo.Unit_Partitions', 'U') IS NOT NULL
		DROP TABLE dbo.Unit_Partitions;

	-- Create the table in the specified schema
	CREATE TABLE dbo.Unit_Partitions (
		Unit_PartitionsID_PK INT IDENTITY(1, 1) NOT NULL PRIMARY KEY, -- primary key column
		[PA-PT-NO-WOSCD] NVARCHAR(50) NOT NULL,
		[PA-PT-NO-SCD] NVARCHAR(10) NOT NULL,
		[PA-CTL-PAA-XFER-DATE] DATETIME2,
		[START-UNIT-DATE] DATE,
		[END-UNIT-DATE] DATE,
		[PA-UNIT-NO] NVARCHAR(10) NULL,
		[PA-UNIT-STS] NVARCHAR(50) NULL
		);

	-- Insert rows into table 'TableName'
	INSERT INTO dbo.Unit_Partitions
	SELECT a.[pa-pt-no-woscd],
		a.[pa-pt-no-scd-1],
		A.[PA-CTL-PAA-XFER-DATE],
		isnull(DATEADD(DAY, 1, b.[PA-unit-date]), DATEADD(DAY, 1, EOMONTH(a.[PA-unit-date], - 1))) AS 'Start_Unit_Date',
		DATEADD(DAY, 0, a.[PA-unit-date]) AS 'End_Unit_Date',
		a.[pa-unit-no],
		A.[PA-UNIT-STS]
	FROM #UNITS AS A
	LEFT OUTER JOIN #UNITS AS b ON a.[pa-pt-no-woscd] = b.[pa-pt-no-woscd]
		AND b.[alt-pa-unit-no] = a.[alt-pa-unit-no] - 1

	-- DROP TALBE Statements
	DROP TABLE #UNITS;

	IF OBJECT_ID('dbo.Encounters_For_Reporting', 'U') IS NOT NULL
		TRUNCATE TABLE dbo.Encounters_For_Reporting
	ELSE
		CREATE TABLE dbo.Encounters_For_Reporting (
			[PK] INT IDENTITY(1, 1) PRIMARY KEY NOT NULL,
			[PA-PT-NO-WOSCD] DECIMAL(11, 0) NOT NULL,
			[PA-PT-NO-SCD] CHAR(1) NOT NULL,
			[PT_NO] VARCHAR(12) NOT NULL,
			[PA-UNIT-STS] VARCHAR(1) NULL,
			[FILE_TYPE] VARCHAR(2) NULL,
			[PA-CTL-PAA-XFER-DATE] DATETIME NULL,
			[pa-unit-no] DECIMAL(4, 0) NULL,
			[pa-med-rec-no] CHAR(12) NULL,
			[pa-pt-name] CHAR(25) NULL,
			[admit_date] DATETIME NULL,
			[dsch_date] DATETIME NULL,
			[pa-unit-date] DATETIME NULL,
			[start-unit-date] DATETIME NULL,
			[end-unit-date] DATETIME NULL,
			[pa-acct-type] CHAR(1) NULL,
			[1st_bl_date] DATETIME NULL,
			[balance] MONEY NULL,
			[pt_balance] MONEY NULL,
			[tot_chgs] MONEY NULL,
			[pa-bal-tot-pt-pay-amt] MONEY NULL,
			[ptacct_type] CHAR(3) NULL,
			[pa-fc] CHAR(1) NULL,
			[fc_description] CHAR(50) NULL,
			[pa-hosp-svc] CHAR(3) NULL,
			[pa-acct-sub-type] CHAR(1) NULL,
			[pa-pt-representative] CHAR(3) NULL,
			[pa-pay-scale] CHAR(1) NULL,
			[pa-cr-rating] CHAR(1) NULL,
			[pa-resp-cd] CHAR(1) NULL
			)

	INSERT INTO Encounters_For_Reporting (
		[PA-PT-NO-WOSCD],
		[PA-PT-NO-SCD],
		[PT_NO],
		[PA-UNIT-STS],
		[FILE_TYPE],
		[PA-CTL-PAA-XFER-DATE],
		[pa-unit-no],
		[pa-med-rec-no],
		[pa-pt-name],
		[admit_date],
		[dsch_date],
		[pa-unit-date],
		[start-unit-date],
		[end-unit-date],
		[pa-acct-type],
		[1st_bl_date],
		[balance],
		[pt_balance],
		[tot_chgs],
		[pa-bal-tot-pt-pay-amt],
		[ptacct_type],
		[pa-fc],
		[fc_description],
		[pa-hosp-svc],
		[pa-acct-sub-type],
		[pa-pt-representative],
		[pa-pay-scale],
		[pa-cr-rating],
		[pa-resp-cd]
		)
	SELECT a.[PA-PT-NO-WOSCD],
		a.[PA-PT-NO-SCD],
		CAST(a.[pa-pt-no-woscd] AS VARCHAR) + CAST(a.[pa-pt-no-scd] AS VARCHAR) AS 'Pt_No',
		a.[pa-unit-sts],
		CASE 
			WHEN a.[pa-acct-type] IN ('0', '7')
				THEN 'OP' --0=OP; 6=OP BAD DEBT; 7=OP HISTORIC
			WHEN a.[pa-acct-type] IN ('6')
				THEN 'OB'
			WHEN a.[pa-acct-type] IN ('4')
				THEN 'IB'
			WHEN a.[pa-acct-type] IN ('1')
				THEN 'IP'
			WHEN a.[pa-acct-type] IN ('2', '8')
				THEN 'AR'
			ELSE ''
			END AS 'File_Type',
		COALESCE(B.[PA-CTL-PAA-XFER-DATE], A.[PA-CTL-PAA-XFER-DATE]) AS 'PA-CTL-PAA-XFER-DATE',
		b.[PA-UNIT-NO],
		a.[pa-med-rec-no],
		a.[pa-pt-name],
		COALESCE(DATEADD(DAY, 1, EOMONTH(b.[pa-unit-date], - 1)), a.[pa-adm-date]) AS 'Admit_Date',
		CASE 
			WHEN a.[pa-acct-type] <> 1
				THEN COALESCE(b.[pa-unit-date], a.[pa-dsch-date], a.[pa-adm-date])
			ELSE a.[pa-dsch-date]
			END AS 'Dsch_Date',
		b.[pa-unit-date],
		m.[start-unit-date],
		m.[end-unit-date],
		a.[pa-acct-type],
		COALESCE(b.[pa-unit-op-first-ins-bl-date], a.[pa-final-bill-date], a.[pa-op-first-ins-bl-date]) AS '1st_Bl_Date',
		COALESCE((b.[pa-unit-ins1-bal] + b.[pa-unit-ins2-bal] + b.[pa-unit-ins3-bal] + b.[pa-unit-ins4-bal] + b.[pa-unit-pt-bal]), a.[pa-bal-acct-bal]) AS 'Balance',
		COALESCE(b.[pa-unit-pt-bal], a.[pa-bal-pt-bal]) AS 'Pt_Balance',
		COALESCE(b.[pa-unit-tot-chg-amt], a.[pa-bal-tot-chg-amt]) AS 'Tot_Chgs',
		a.[pa-bal-tot-pt-pay-amt],
		CASE 
			WHEN a.[pa-acct-type] IN ('0', '6', '7')
				THEN 'OP' --0=OP; 6=OP BAD DEBT; 7=OP HISTORIC
			WHEN a.[pa-acct-type] IN ('1', '2', '4', '8')
				THEN 'IP' --1=IP; 2=A/R; 4=I/P BAD DEBT; 8=I/P HISTORIC
			ELSE ''
			END AS 'PtAcct_Type',
		a.[pa-fc] AS 'FC',
		CASE 
			WHEN a.[pa-fc] = '1'
				THEN 'Bad Debt Medicaid Pending'
			WHEN a.[pa-fc] IN ('2', '6')
				THEN 'Bad Debt AG'
			WHEN a.[pa-fc] = '3'
				THEN 'MCS'
			WHEN a.[pa-fc] = '4'
				THEN 'Bad Debt AG Legal'
			WHEN a.[pa-fc] = '5'
				THEN 'Bad Debt POM'
			WHEN a.[pa-fc] = '8'
				THEN 'Bad Debt AG Exchange Plans'
			WHEN a.[pa-fc] = '9'
				THEN 'Kopp-Bad Debt'
			WHEN a.[pa-fc] = 'A'
				THEN 'Commercial'
			WHEN a.[pa-fc] = 'B'
				THEN 'Blue Cross'
			WHEN a.[pa-fc] = 'C'
				THEN 'Champus'
			WHEN a.[pa-fc] = 'D'
				THEN 'Medicaid'
			WHEN a.[pa-fc] = 'E'
				THEN 'Employee Health Svc'
			WHEN a.[pa-fc] = 'G'
				THEN 'Contract Accts'
			WHEN a.[pa-fc] = 'H'
				THEN 'Medicare HMO'
			WHEN a.[pa-fc] = 'I'
				THEN 'Balance After Ins'
			WHEN a.[pa-fc] = 'J'
				THEN 'Managed Care'
			WHEN a.[pa-fc] = 'K'
				THEN 'Pending Medicaid'
			WHEN a.[pa-fc] = 'M'
				THEN 'Medicare'
			WHEN a.[pa-fc] = 'N'
				THEN 'No-Fault'
			WHEN a.[pa-fc] = 'P'
				THEN 'Self Pay'
			WHEN a.[pa-fc] = 'R'
				THEN 'Aergo Commercial'
			WHEN a.[pa-fc] = 'T'
				THEN 'RTR WC NF'
			WHEN a.[pa-fc] = 'S'
				THEN 'Special Billing'
			WHEN a.[pa-fc] = 'U'
				THEN 'Medicaid Mgd Care'
			WHEN a.[pa-fc] = 'V'
				THEN 'First Source'
			WHEN a.[pa-fc] = 'W'
				THEN 'Workers Comp'
			WHEN a.[pa-fc] = 'X'
				THEN 'Control Accts'
			WHEN a.[pa-fc] = 'Y'
				THEN 'MCS'
			WHEN a.[pa-fc] = 'Z'
				THEN 'Unclaimed Credits'
			ELSE ''
			END AS 'FC_Description',
		a.[pa-hosp-svc],
		a.[pa-acct-sub-type] --D=Discharged; I=In House
		,
		a.[pa-pt-representative],
		a.[pa-pay-scale],
		a.[pa-cr-rating],
		a.[pa-resp-cd]
	FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Archive].dbo.PatientDemographics a
	LEFT OUTER JOIN [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Archive].dbo.[UnitizedAccounts] b ON a.[pa-pt-no-woscd] = b.[pa-pt-no-woscd]
		AND a.[pa-unit-sts] = 'U'
		AND a.[pa-ctl-paa-xfer-date] = b.[pa-ctl-paa-xfer-date]
	LEFT OUTER JOIN [Unit_Partitions] m ON b.[pa-pt-no-woscd] = m.[pa-pt-no-woscd]
		AND b.[pa-unit-date] >= m.[start-unit-date]
		AND b.[pa-unit-date] <= m.[end-unit-date]
	WHERE a.[pa-acct-sub-type] <> 'P'
	
	UNION
	
	SELECT a.[PA-PT-NO-WOSCD],
		a.[PA-PT-NO-SCD],
		CAST(a.[pa-pt-no-woscd] AS VARCHAR) + CAST(a.[pa-pt-no-scd] AS VARCHAR) AS 'Pt_No',
		a.[pa-unit-sts],
		CASE 
			WHEN a.[pa-acct-type] IN ('0', '7')
				THEN 'OP' --0=OP; 6=OP BAD DEBT; 7=OP HISTORIC
			WHEN a.[pa-acct-type] IN ('6')
				THEN 'OB'
			WHEN a.[pa-acct-type] IN ('4')
				THEN 'IB'
			WHEN a.[pa-acct-type] IN ('1')
				THEN 'IP'
			WHEN a.[pa-acct-type] IN ('2', '8')
				THEN 'AR'
			ELSE ''
			END AS 'File_Type',
		COALESCE(B.[PA-CTL-PAA-XFER-DATE], A.[PA-CTL-PAA-XFER-DATE]) AS 'PA-CTL-PAA-XFER-DATE',
		b.[PA-UNIT-NO],
		a.[pa-med-rec-no],
		a.[pa-pt-name],
		COALESCE(DATEADD(DAY, 1, EOMONTH(b.[pa-unit-date], - 1)), a.[pa-adm-date]) AS 'Admit_Date',
		CASE 
			WHEN a.[pa-acct-type] <> 1
				THEN COALESCE(b.[pa-unit-date], a.[pa-dsch-date], a.[pa-adm-date])
			ELSE a.[pa-dsch-date]
			END AS 'Dsch_Date',
		b.[pa-unit-date],
		m.[start-unit-date],
		m.[end-unit-date],
		a.[pa-acct-type],
		COALESCE(b.[pa-unit-op-first-ins-bl-date], a.[pa-final-bill-date], a.[pa-op-first-ins-bl-date]) AS '1st_Bl_Date',
		COALESCE((b.[pa-unit-ins1-bal] + b.[pa-unit-ins2-bal] + b.[pa-unit-ins3-bal] + b.[pa-unit-ins4-bal] + b.[pa-unit-pt-bal]), a.[pa-bal-acct-bal]) AS 'Balance',
		COALESCE(b.[pa-unit-pt-bal], a.[pa-bal-pt-bal]) AS 'Pt_Balance',
		COALESCE(b.[pa-unit-tot-chg-amt], a.[pa-bal-tot-chg-amt]) AS 'Tot_Chgs',
		a.[pa-bal-tot-pt-pay-amt],
		CASE 
			WHEN a.[pa-acct-type] IN ('0', '6', '7')
				THEN 'OP' --0=OP; 6=OP BAD DEBT; 7=OP HISTORIC
			WHEN a.[pa-acct-type] IN ('1', '2', '4', '8')
				THEN 'IP' --1=IP; 2=A/R; 4=I/P BAD DEBT; 8=I/P HISTORIC
			ELSE ''
			END AS 'PtAcct_Type',
		a.[pa-fc] AS 'FC',
		CASE 
			WHEN a.[pa-fc] = '1'
				THEN 'Bad Debt Medicaid Pending'
			WHEN a.[pa-fc] IN ('2', '6')
				THEN 'Bad Debt AG'
			WHEN a.[pa-fc] = '3'
				THEN 'MCS'
			WHEN a.[pa-fc] = '4'
				THEN 'Bad Debt AG Legal'
			WHEN a.[pa-fc] = '5'
				THEN 'Bad Debt POM'
			WHEN a.[pa-fc] = '8'
				THEN 'Bad Debt AG Exchange Plans'
			WHEN a.[pa-fc] = '9'
				THEN 'Kopp-Bad Debt'
			WHEN a.[pa-fc] = 'A'
				THEN 'Commercial'
			WHEN a.[pa-fc] = 'B'
				THEN 'Blue Cross'
			WHEN a.[pa-fc] = 'C'
				THEN 'Champus'
			WHEN a.[pa-fc] = 'D'
				THEN 'Medicaid'
			WHEN a.[pa-fc] = 'E'
				THEN 'Employee Health Svc'
			WHEN a.[pa-fc] = 'G'
				THEN 'Contract Accts'
			WHEN a.[pa-fc] = 'H'
				THEN 'Medicare HMO'
			WHEN a.[pa-fc] = 'I'
				THEN 'Balance After Ins'
			WHEN a.[pa-fc] = 'J'
				THEN 'Managed Care'
			WHEN a.[pa-fc] = 'K'
				THEN 'Pending Medicaid'
			WHEN a.[pa-fc] = 'M'
				THEN 'Medicare'
			WHEN a.[pa-fc] = 'N'
				THEN 'No-Fault'
			WHEN a.[pa-fc] = 'P'
				THEN 'Self Pay'
			WHEN a.[pa-fc] = 'R'
				THEN 'Aergo Commercial'
			WHEN a.[pa-fc] = 'T'
				THEN 'RTR WC NF'
			WHEN a.[pa-fc] = 'S'
				THEN 'Special Billing'
			WHEN a.[pa-fc] = 'U'
				THEN 'Medicaid Mgd Care'
			WHEN a.[pa-fc] = 'V'
				THEN 'First Source'
			WHEN a.[pa-fc] = 'W'
				THEN 'Workers Comp'
			WHEN a.[pa-fc] = 'X'
				THEN 'Control Accts'
			WHEN a.[pa-fc] = 'Y'
				THEN 'MCS'
			WHEN a.[pa-fc] = 'Z'
				THEN 'Unclaimed Credits'
			ELSE ''
			END AS 'FC_Description',
		a.[pa-hosp-svc],
		a.[pa-acct-sub-type] --D=Discharged; I=In House
		,
		a.[pa-pt-representative],
		a.[pa-pay-scale],
		a.[pa-cr-rating],
		a.[pa-resp-cd]
	FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Active].dbo.PatientDemographics a
	LEFT OUTER JOIN [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Active].dbo.[UnitizedAccounts] b ON a.[pa-pt-no-woscd] = b.[pa-pt-no-woscd]
		AND a.[pa-unit-sts] = 'U'
		AND a.[pa-ctl-paa-xfer-date] = b.[pa-ctl-paa-xfer-date]
	LEFT OUTER JOIN [Unit_Partitions] m ON b.[pa-pt-no-woscd] = m.[pa-pt-no-woscd]
		AND b.[pa-unit-date] >= m.[start-unit-date]
		AND b.[pa-unit-date] <= m.[end-unit-date]
	WHERE a.[pa-acct-sub-type] <> 'P';
END;
