USE [PARA]

/*
***********************************************************************
File: c_activity_code_productivity_sp.sql

Input Parameters:
	None

Tables/Views:
	[ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[ECHO_ACTIVE].[DBO].[ACCOUNTCOMMENTS]
    dbo.c_productivity_users_tbl

Creates Table/View:
	dbo.c_activity_code_productivity_tbl

Functions:
	None

Author: Steven P. Sanderson II, MPH

Department: Patient Financial Services

Purpose/Description
	This is part of the productivity report.  It creates a table that
    contains the data needed to create the activity code productivity.

Revision History:
Date		Version		Description
----		----		----
2023-03-28	v1			Initial Creation
***********************************************************************
*/

-- Create a new stored procedure called 'c_activity_code_productivity_sp' in schema 'dbo'
-- Drop the stored procedure if it already exists
IF EXISTS (
		SELECT *
		FROM INFORMATION_SCHEMA.ROUTINES
		WHERE SPECIFIC_SCHEMA = N'dbo'
			AND SPECIFIC_NAME = N'c_activity_code_productivity_sp'
		)
	DROP PROCEDURE dbo.c_activity_code_productivity_sp
GO

-- Create the stored procedure in the specified schema
CREATE PROCEDURE dbo.c_activity_code_productivity_sp
AS

DECLARE @BEGINDATE DATETIME
DECLARE @ENDDATE DATETIME
DECLARE @PRODREPORTDATE DATETIME
DECLARE @ThisDate DATETIME

SET @ThisDate = getdate()
SET @BEGINDATE = dateadd(wk, datediff(wk, 0, @ThisDate) - 1, - 1)
SET @ENDDATE = dateadd(wk, datediff(wk, 0, @ThisDate) - 1, 6)
SET @PRODREPORTDATE = @BEGINDATE - 1

-- drop the table if it already exists
DROP TABLE IF EXISTS dbo.c_activity_code_productivity_tbl

-- create the table
CREATE TABLE dbo.c_activity_code_productivity_tbl (
    [PA-PT-NO-WOSCD] VARCHAR(10) NULL,
    [PA-PT-NO-SCD-1] VARCHAR(10) NULL,
    [Pt_No] VARCHAR(20) NULL,
    [PA-CTL-PAA-XFER-DATE] DATETIME NULL,
    [PA-SMART-COUNTER] INT NULL,
    [SmartDate] VARCHAR(10) NULL,
    [PA-SMART-COMMENT] VARCHAR(100) NULL,
    [USER-ID] VARCHAR(6) NULL,
    [ACTIVITY_CODE] VARCHAR(5) NULL,
    [PA-SMART-SVC-CD-WOSCD] VARCHAR(10) NULL,
    [Unique_for_Join] VARCHAR(50) NULL,
)

-- insert data into the table
INSERT INTO dbo.c_activity_code_productivity_tbl (
    [PA-PT-NO-WOSCD],
    [PA-PT-NO-SCD-1],
    [Pt_No],
    [PA-CTL-PAA-XFER-DATE],
    [PA-SMART-COUNTER],
    [SmartDate],
    [PA-SMART-COMMENT],
    [USER-ID],
    [ACTIVITY_CODE],
    [PA-SMART-SVC-CD-WOSCD],    [Unique_for_Join]
)
    
SELECT [PA-PT-NO-WOSCD],
    [PA-PT-NO-SCD-1],
    CAST([PA-PT-NO-WOSCD] AS VARCHAR) + CAST([PA-PT-NO-SCD-1] AS VARCHAR) AS 'Pt_No',
    [PA-CTL-PAA-XFER-DATE],
    [PA-SMART-COUNTER],
    convert(VARCHAR, [PA-SMART-DATE], 101) AS 'SmartDate',
    [PA-SMART-COMMENT],
    SUBSTRING([PA-SMART-COMMENT], 6, 6) AS 'USER-ID',
    SUBSTRING([PA-SMART-COMMENT], 1, 5) AS 'ACTIVITY_CODE',
    [PA-SMART-SVC-CD-WOSCD],
    CAST([PA-PT-NO-WOSCD] AS VARCHAR) + CAST([PA-PT-NO-SCD-1] AS VARCHAR) + '_ _' + convert(VARCHAR, [PA-SMART-DATE], 101) + '_' + SUBSTRING([PA-SMART-COMMENT], 6, 6) AS 'Unique_for_Join'
--INTO #ACPRODUCTIVITY
FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[ECHO_ACTIVE].[DBO].[ACCOUNTCOMMENTS] F
RIGHT JOIN dbo.c_productivity_users_tbl M ON SUBSTRING([PA-SMART-COMMENT], 6, 6) = M.[User_ID]
WHERE [PA-SMART-DATE] BETWEEN @BEGINDATE
        AND @ENDDATE

GO

-- example to execute the stored procedure we just created
--EXECUTE dbo.c_activity_code_productivity_sp
--GO