USE [PARA]

/*
***********************************************************************
File: c_combined_productivity_sp.sql

Input Parameters:
	None

Tables/Views:
	dbo.c_activity_code_productivity_tbl
    dbo.c_trans_code_productivity_tbl

Creates Table/View:
	dbo.c_combined_productivity_tbl

Functions:
	None

Author: Steven P. Sanderson II, MPH

Department: Patient Financial Services

Purpose/Description
	This is part of the productivity report.  It creates a table that
    contains the combined activity code and transaction code data needed.

Revision History:
Date		Version		Description
----		----		----
2023-03-28	v1			Initial Creation
***********************************************************************
*/

-- Create a new stored procedure called 'c_combined_productivity_tbl_sp' in schema 'dbo'
-- Drop the stored procedure if it already exists
IF EXISTS (
		SELECT *
		FROM INFORMATION_SCHEMA.ROUTINES
		WHERE SPECIFIC_SCHEMA = N'dbo'
			AND SPECIFIC_NAME = N'c_combined_productivity_sp'
		)
	DROP PROCEDURE dbo.c_combined_productivity_sp
GO

-- Create the stored procedure in the specified schema
CREATE PROCEDURE dbo.c_combined_productivity_sp
AS

    -- DROP table if exists
    DROP TABLE IF EXISTS dbo.c_precombined_productivity_tbl

    -- Create table
    CREATE TABLE dbo.c_precombined_productivity_tbl (
        unique_for_join VARCHAR(50),
        pt_no VARCHAR(50)
    )

    INSERT INTO dbo.c_precombined_productivity_tbl (
        unique_for_join,
        pt_no
    )
    SELECT A.unique_for_join,
        A.pt_no
    FROM (
        SELECT AC.unique_for_join,
            AC.pt_no
        FROM dbo.c_activity_code_productivity_tbl AS AC

        UNION

        SELECT TC.unique_for_join,
            TC.pt_no
        FROM DBO.c_trans_code_productivity_tbl AS TC
    ) AS A

    -- Full combination
    -- DROP table if exists
	DROP TABLE IF EXISTS dbo.c_combined_productivity_tbl

    -- Create table
    CREATE TABLE dbo.c_combined_productivity_tbl (
        [UNIQUE_FOR_JOIN] VARCHAR(50),
        [PT_NO] VARCHAR(50),
        [UNIQUE_USER_ID] VARCHAR(50),
        [ACTIVITY_CODE_USER_ID] VARCHAR(50),
        [TRANSACTION_CODE_USER_ID] VARCHAR(50),
        [UNIQUE_ID] VARCHAR(50),
        [UNIQUE_CODE] VARCHAR(50),
        [UNIQUE_DATE] VARCHAR(50),
        [UNIQUE_PT_NO] VARCHAR(50),
        [AC_USER_ID] VARCHAR(50),
        [ACTIVITY_CODE_PT_NO] VARCHAR(50),
        [ACTIVITY_CODE] VARCHAR(50),
        [SMART_DATE] VARCHAR(50),
        [TC_USER_ID] VARCHAR(50),
        [TRANSACTION_CODE_PT_NO] VARCHAR(50),
        [UNIT] VARCHAR(50),
        [SERVICE_CODE] VARCHAR(50),
        [INS_PLAN] VARCHAR(50),
        [POSTED_AMT] VARCHAR(50),
        [POST_DATE] VARCHAR(50),
        [ENCOUNTER_NUMBER] VARCHAR(50)
    )

    INSERT INTO dbo.c_combined_productivity_tbl (
        [UNIQUE_FOR_JOIN],
        [PT_NO],
        [UNIQUE_USER_ID],
        [ACTIVITY_CODE_USER_ID],
        [TRANSACTION_CODE_USER_ID],
        [UNIQUE_ID],
        [UNIQUE_CODE],
        [UNIQUE_DATE],
        [UNIQUE_PT_NO],
        [AC_USER_ID],
        [ACTIVITY_CODE_PT_NO],
        [ACTIVITY_CODE],
        [SMART_DATE],
        [TC_USER_ID],
        [TRANSACTION_CODE_PT_NO],
        [UNIT],
        [SERVICE_CODE],
        [INS_PLAN],
        [POSTED_AMT],
        [POST_DATE],
        [ENCOUNTER_NUMBER]
    )
	--Creating a temp table to represent all transactions posted, combining Activity Codes and Transaction Codes
	SELECT M.[UNIQUE_FOR_JOIN],
		isnull(f.Pt_No, t.[Pt_No]) AS 'Pt_No',
		left(isnull(f.[USER-ID], t.[User_ID]), 6) AS 'Unique_User_ID',
		f.[USER-ID] AS 'Activity Code User ID',
		t.[User_ID] AS 'Transaction Code User ID',
		left(CONCAT (
				f.[USER-ID],
				t.[User_ID]
				), 6) + '_' + f.Pt_No + '_' + f.[ACTIVITY_CODE] + '_' + left(CONCAT (
				f.SmartDate,
				t.Post_Date
				), 10) AS 'Unique ID' --Unique ID for Activity Codes
		,
		SUBSTRING([PA-SMART-COMMENT], 6, 6) + '_' + CAST([PA-PT-NO-WOSCD] AS VARCHAR) + CAST([PA-PT-NO-SCD-1] AS VARCHAR) + '_' + convert(VARCHAR, f.SmartDate, 101) AS 'Unique Code',
		left(CONCAT (
				f.SmartDate,
				t.Post_Date
				), 10) AS 'Unique_Date',
		left(CONCAT (
				[USER-ID],
				t.[User_ID]
				), 6) + '_' + ISNULL(t.[Pt_No], f.Pt_No) + '_' + ISNULL(t.Unit, 'A') + '_' + left(CONCAT (
				SmartDate,
				Post_Date
				), 10) AS 'Unique_Pt_No' -- Unique for Transaction Codes
		,
		f.[USER-ID],
		f.Pt_No AS 'Activity Code Pt No',
		f.[ACTIVITY_CODE],
		f.SmartDate,
		t.[User_ID],
		t.[Pt_No] AS 'Transaction Code Pt No',
		t.Unit --pulling the Unit from the TCPRODUCTIVITY table
		,
		t.[Service Code],
		t.Ins_Plan,
		t.[Posted_Amt],
		t.Post_Date,
		t.[Pt_No]
	FROM dbo.c_precombined_productivity_tbl M
	FULL OUTER JOIN dbo.c_activity_code_productivity_tbl F ON M.[UNIQUE_FOR_JOIN] = F.Unique_for_Join
	FULL OUTER JOIN DBO.c_trans_code_productivity_tbl t ON M.[UNIQUE_FOR_JOIN] = t.[Unique_for_Join]
	RIGHT JOIN dbo.c_productivity_users_tbl z ON z.[User_ID] = isnull(f.[USER-ID], t.[User_ID]);

    UPDATE dbo.c_combined_productivity_tbl
	SET [Unique_Pt_No] = [Unique_Code]
	WHERE [Unique_Pt_No] IS NULL

GO

-- example to execute the stored procedure we just created
--EXECUTE dbo.c_combined_productivity_sp
--GO