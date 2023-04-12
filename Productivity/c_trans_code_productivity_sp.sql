USE [PARA]

/*
***********************************************************************
File: c_trans_code_productivity_sp.sql

Input Parameters:
	None

Tables/Views:
	swarm.dbo.oamcomb
    dbo.c_productivity_users_tbl

Creates Table/View:
	dbo.c_trans_code_productivity_tbl

Functions:
	None

Author: Steven P. Sanderson II, MPH

Department: Patient Financial Services

Purpose/Description
	This is part of the productivity report.  It creates a table that
    contains the data needed to create the transaction code productivity
    report.

Revision History:
Date		Version		Description
----		----		----
2023-03-28	v1			Initial Creation
***********************************************************************
*/

-- Create a new stored procedure called 'c_trans_code_productivity_sp' in schema 'dbo'
-- Drop the stored procedure if it already exists
IF EXISTS (
		SELECT *
		FROM INFORMATION_SCHEMA.ROUTINES
		WHERE SPECIFIC_SCHEMA = N'dbo'
			AND SPECIFIC_NAME = N'c_trans_code_productivity_sp'
		)
	DROP PROCEDURE dbo.c_trans_code_productivity_sp
GO

-- Create the stored procedure in the specified schema
CREATE PROCEDURE dbo.c_trans_code_productivity_sp
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
DROP TABLE IF EXISTS dbo.c_trans_code_productivity_tbl

-- create the table
CREATE TABLE dbo.c_trans_code_productivity_tbl (
    [PA_File] VARCHAR(10),
    [Batch_No] VARCHAR(10),
    [Pt_No] VARCHAR(25),
    [Unit] VARCHAR(10),
    [Pt_Name] VARCHAR(50),
    [Svc_Date] DATE,
    [Service Code] VARCHAR(12),
    [Posted_Amt] MONEY,
    [Pt_Type] VARCHAR(12),
    [FC] VARCHAR(12),
    [User_ID] VARCHAR(12),
    [User_Batch_ID] VARCHAR(12),
    [Tran_Type_1] VARCHAR(12),
    [Tran_Type_2] VARCHAR(12),
    [Ins_Plan] VARCHAR(12),
    [Post_Date] VARCHAR(12),
    [Unique_for_Join] VARCHAR(100)
)

-- insert data into the table
INSERT INTO dbo.c_trans_code_productivity_tbl (
    [PA_File],
    [Batch_No],
    [Pt_No],
    [Unit],
    [Pt_Name],
    [Svc_Date],
    [Service Code],
    [Posted_Amt],
    [Pt_Type],
    [FC],
    [User_ID],
    [User_Batch_ID],
    [Tran_Type_1],
    [Tran_Type_2],
    [Ins_Plan],
    [Post_Date],
    [Unique_for_Join]
)
SELECT [PA_File],
	[Batch_No],
	[Encounter Number],
	CASE 
		WHEN t.[Unit] = ''
			THEN 'A'
		ELSE T.[Unit]
		END AS 'Unit',
	t.[Pt_Name],
	[Svc_Date],
	[Service Code],
	[Posted_Amt],
	t.[Pt_Type],
	t.[FC],
	t.[User_ID],
	[User_Batch_ID],
	[Tran_Type_1],
	[Tran_Type_2],
	[Ins_Plan],
	convert(VARCHAR, [Post_Date], 101) AS [Post_Date],
	[Encounter Number] + '_' + t.[Unit] + '_' + convert(VARCHAR, [Post_Date], 101) + '_' + t.[User_ID] AS 'Unique for Join'
FROM [SWARM].[DBO].[OAMCOMB ] T
INNER JOIN dbo.c_productivity_users_tbl M ON t.[User_ID] = M.[User_ID]
WHERE [POST_DATE] BETWEEN @BEGINDATE
		AND @ENDDATE
GO

-- example to execute the stored procedure we just created
--EXECUTE dbo.c_trans_code_productivity_sp
--GO