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
CREATE PROCEDURE dbo.c_sms_encounters_for_reporting_sp
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
		Unit_PartitionsID_PK INT NOT NULL PRIMARY KEY, -- primary key column
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
END;

