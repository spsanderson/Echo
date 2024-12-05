/*
***********************************************************************
File: c_pt_rep_change_sp.sql

Input Parameters:
	None

Tables/Views:
	[ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].echo_active.dbo.accountcomments
    [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].echo_archive.dbo.accountcomments

Creates Table/View:
	SMS.dbo.c_pt_rep_change_tbl

Functions:
	None

Author: Steven P. Sanderson II, MPH

Department: Patient Financial Services

Purpose/Description
	Get the payscales applied to a patient's account and the dates they were applied.

Revision History:
Date		Version		Description
----		----		----
2024-12-05	v1			Initial Creation
***********************************************************************
*/

-- Create a new stored procedure called 'c_pt_rep_change_sp' in schema 'dbo'
-- Drop the stored procedure if it already exists
-- Step 1: Check if the table exists
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_SCHEMA = 'dbo'
      AND TABLE_NAME = 'c_pt_rep_change_tbl'
      AND TABLE_CATALOG = 'SMS'
)
BEGIN
    -- Table does not exist, create and populate it

    -- Create the table
    CREATE TABLE SMS.dbo.c_pt_rep_change_tbl (
        pt_no NVARCHAR(50),
        pa_smart_comment NVARCHAR(255),
        pt_rep_removed NVARCHAR(3),
        date_rep_removed DATE,
        acct_type NVARCHAR(50),
        ip_op_ind NVARCHAR(2),
        rep_type NVARCHAR(50),
        track_id INT
    );

    -- Define the common table expression (CTE)
    WITH CTE_AccountComments AS (
        SELECT 
            (CAST([PA-PT-NO-WOSCD] AS VARCHAR) + CAST([PA-PT-NO-SCD-1] AS VARCHAR)) AS pt_no,
            [PA-SMART-COMMENT] AS pa_smart_comment,
            CASE 
                WHEN PATINDEX('%[0-9][0-9][0-9]%', [PA-SMART-COMMENT]) > 0 
                THEN SUBSTRING([PA-SMART-COMMENT], PATINDEX('%[0-9][0-9][0-9]%', [PA-SMART-COMMENT]), 3) 
                ELSE NULL 
            END AS pt_rep_removed,
            CAST([PA-SMART-DATE] AS DATE) AS date_rep_removed,
            [PA-ACCT-TYPE] AS acct_type,
            CASE
                WHEN [PA-ACCT-TYPE] IN ('0','6','7') THEN 'OP'
                ELSE 'IP'
            END AS ip_op_ind,
            CASE
                WHEN [PA-SMART-COMMENT] LIKE 'PATIENT REP.  [0-9][0-9][0-9]%DUE TO SUB POL%' AND ISNUMERIC(RIGHT([PA-SMART-COMMENT], 5)) = 1 THEN CAST(RIGHT([PA-SMART-COMMENT], 5) AS INT)
                ELSE 'Manually Triggered'
            END AS rep_type,
            CASE
                WHEN [PA-SMART-COMMENT] LIKE 'PATIENT REP.  [0-9][0-9][0-9]%DUE TO SUB POL%' THEN TRY_CAST(RIGHT([PA-SMART-COMMENT], 5) AS INT)
                ELSE NULL
            END AS track_id
        FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Active].[dbo].[AccountComments]
        WHERE (
            [PA-SMART-COMMENT] LIKE 'PATIENT REP.  [0-9][0-9][0-9]%DUE TO SUB POL%'
            OR [PA-SMART-COMMENT] LIKE 'PATIENT REP%DUE TO 18M%'
        )
        UNION ALL
        SELECT 
            (CAST([PA-PT-NO-WOSCD] AS VARCHAR) + CAST([PA-PT-NO-SCD-1] AS VARCHAR)) AS pt_no,
            [PA-SMART-COMMENT] AS pa_smart_comment,
            SUBSTRING([PA-SMART-COMMENT], PATINDEX('%[0-9][0-9][0-9]%', [PA-SMART-COMMENT]), 3) AS pt_rep_removed,
            CAST([PA-SMART-DATE] AS DATE) AS date_rep_removed,
            [PA-ACCT-TYPE] AS acct_type,
            CASE
                WHEN [PA-ACCT-TYPE] IN ('0','6','7') THEN 'OP'
                ELSE 'IP'
            END AS ip_op_ind,
            CASE
                WHEN [PA-SMART-COMMENT] LIKE 'PATIENT REP.  [0-9][0-9][0-9]%DUE TO SUB POL%' THEN 'RPM Triggered'
                ELSE 'Manually Triggered'
            END AS rep_type,
            CASE
                WHEN [PA-SMART-COMMENT] LIKE 'PATIENT REP.  [0-9][0-9][0-9]%DUE TO SUB POL%' THEN TRY_CAST(RIGHT([PA-SMART-COMMENT], 5) AS INT)
                ELSE NULL
            END AS track_id
        FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Archive].[dbo].[AccountComments]
        WHERE (
            [PA-SMART-COMMENT] LIKE 'PATIENT REP.  [0-9][0-9][0-9]%DUE TO SUB POL%'
            OR [PA-SMART-COMMENT] LIKE 'PATIENT REP%DUE TO 18M%'
        )
    )

    -- Populate the table without the date filter
    INSERT INTO SMS.dbo.c_pt_rep_change_tbl (
        pt_no,
        pa_smart_comment,
        pt_rep_removed,
        date_rep_removed,
        acct_type,
        ip_op_ind,
        rep_type,
        track_id
    )
    SELECT 
        pt_no,
        pa_smart_comment,
        pt_rep_removed,
        date_rep_removed,
        acct_type,
        ip_op_ind,
        rep_type,
        track_id
    FROM CTE_AccountComments;

    -- Create indexes on all columns
    CREATE NONCLUSTERED INDEX IX_pt_no ON SMS.dbo.c_pt_rep_change_tbl (pt_no);
    CREATE NONCLUSTERED INDEX IX_date_rep_removed ON SMS.dbo.c_pt_rep_change_tbl (date_rep_removed);
    CREATE NONCLUSTERED INDEX IX_acct_type ON SMS.dbo.c_pt_rep_change_tbl (acct_type);
    CREATE NONCLUSTERED INDEX IX_ip_op_ind ON SMS.dbo.c_pt_rep_change_tbl (ip_op_ind);
END
ELSE
BEGIN
    -- Table exists, update it

    -- Use MERGE to update the table with the date filter
    MERGE SMS.dbo.c_pt_rep_change_tbl AS target
    USING (
        SELECT 
            pt_no,
            pa_smart_comment,
            pt_rep_removed,
            date_rep_removed,
            acct_type,
            ip_op_ind,
            rep_type,
            track_id
        FROM CTE_AccountComments
        WHERE date_rep_removed >= DATEADD(DAY, -1, CAST(GETDATE() AS DATE))
    ) AS source
    ON target.pt_no = source.pt_no
    AND target.date_rep_removed = source.date_rep_removed
    AND target.acct_type = source.acct_type
    WHEN MATCHED THEN
        UPDATE SET 
            target.pa_smart_comment = source.pa_smart_comment,
            target.pt_rep_removed = source.pt_rep_removed,
            target.date_rep_removed = source.date_rep_removed,
            target.acct_type = source.acct_type,
            target.ip_op_ind = source.ip_op_ind,
            target.rep_type = source.rep_type,
            target.track_id = source.track_id
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (pt_no, pa_smart_comment, pt_rep_removed, date_rep_removed, acct_type, ip_op_ind, rep_type, track_id)
        VALUES (source.pt_no, source.pa_smart_comment, source.pt_rep_removed, source.date_rep_removed, source.acct_type, source.ip_op_ind, source.rep_type, source.track_id);
END;