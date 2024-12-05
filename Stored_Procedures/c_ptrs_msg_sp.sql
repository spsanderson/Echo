USE [SMS]
GO 

SET QUOTED_IDENTIFIER ON
GO  

CREATE PROCEDURE dbo.c_ptrs_msg_sp
AS 

SET NOCOUNT ON;

/*
***********************************************************************
File: c_ptrs_msg_sp.sql

Input Parameters:
	None

Tables/Views:
	[ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Active].[dbo].[accountcomments]
	[ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Archive].[dbo].[accountcomments]

Creates Table/View:
	dbo.c_ptrs_msg_tbl

Functions:
	NONE

Author: Steven P. Sanderson II, MPH

Department: Patient Financial Services

Purpose/Description
Creates a table that contains the dunning message history for patients.

Revision History:
Date		Version		Description
----		----		----
2024-03-25	v1			Initial Creation	
***********************************************************************
*/

IF NOT EXISTS (
		SELECT TOP 1 *
		FROM SYSOBJECTS
		WHERE name = 'c_ptrs_msg_tbl'
			AND xtype = 'U'
		)
BEGIN
	CREATE TABLE dbo.c_ptrs_msg_tbl (
		[pa_pt_no_woscd] VARCHAR(50),
		[pa_pt_no_scd1] VARCHAR(50),
		[pt_no] VARCHAR(50),
		[svc_date] DATE,
		[post_date] DATE,
		[archive_date] DATE,
		[message_number] INT
		)

	INSERT INTO dbo.c_ptrs_msg_tbl (
		[pa_pt_no_woscd],
		[pa_pt_no_scd1],
		[pt_no],
		[svc_date],
		[post_date],
		[archive_date],
		[message_number]
		)
	SELECT [pt_no] = cast([pa-pt-no-woscd] AS VARCHAR) + cast([pa-pt-no-scd-1] AS VARCHAR),
		[smart_comment] = [pa-smart-comment],
		[post_date] = [pa-smart-seg-create-date],
		[svc_date] = [pa-smart-date],
		[archive_date] = [pa-ctl-paa-xfer-date],
		[message_number] = ROW_NUMBER() OVER (
			PARTITION BY [PA-PT-NO-WOSCD],
			[PA-PT-NO-SCD-1] ORDER BY [PA-SMART-DATE]
			)
	FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].echo_active.dbo.accountcomments
	WHERE left([pa-smart-comment], 12) = 'MESSAGE PTRS'

    UNION ALL

	SELECT [pt_no] = cast([pa-pt-no-woscd] AS VARCHAR) + cast([pa-pt-no-scd-1] AS VARCHAR),
		[smart_comment] = [pa-smart-comment],
		[post_date] = [pa-smart-seg-create-date],
		[svc_date] = [pa-smart-date],
		[archive_date] = [pa-ctl-paa-xfer-date],
		[message_number] = ROW_NUMBER() OVER (
			PARTITION BY [PA-PT-NO-WOSCD],
			[PA-PT-NO-SCD-1] ORDER BY [PA-SMART-DATE]
			)
	FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].echo_archive.dbo.accountcomments
	WHERE left([pa-smart-comment], 12) = 'MESSAGE PTRS'

END
ELSE BEGIN
    INSERT INTO dbo.c_ptrs_msg_tbl (
        [pa_pt_no_woscd],
        [pa_pt_no_scd1],
        [pt_no],
        [svc_date],
        [post_date],
        [archive_date],
        [message_number]
        )
    SELECT [pt_no] = cast([pa-pt-no-woscd] AS VARCHAR) + cast([pa-pt-no-scd-1] AS VARCHAR),
        [smart_comment] = [pa-smart-comment],
        [post_date] = [pa-smart-seg-create-date],
        [svc_date] = [pa-smart-date],
        [archive_date] = [pa-ctl-paa-xfer-date],
        [message_number] = ROW_NUMBER() OVER (
            PARTITION BY [PA-PT-NO-WOSCD],
            [PA-PT-NO-SCD-1] ORDER BY [PA-SMART-DATE]
            )
    FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].echo_active.dbo.accountcomments
    WHERE left([pa-smart-comment], 12) = 'MESSAGE PTRS'
        AND [pa-smart-seg-create-date] > (SELECT MAX([post_date]) FROM dbo.c_ptrs_msg_tbl)

    UNION ALL

	SELECT [pt_no] = cast([pa-pt-no-woscd] AS VARCHAR) + cast([pa-pt-no-scd-1] AS VARCHAR),
		[smart_comment] = [pa-smart-comment],
		[post_date] = [pa-smart-seg-create-date],
		[svc_date] = [pa-smart-date],
		[archive_date] = [pa-ctl-paa-xfer-date],
		[message_number] = ROW_NUMBER() OVER (
			PARTITION BY [PA-PT-NO-WOSCD],
			[PA-PT-NO-SCD-1] ORDER BY [PA-SMART-DATE]
			)
	FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].echo_archive.dbo.accountcomments
	WHERE left([pa-smart-comment], 12) = 'MESSAGE PTRS'
        AND [pa-smart-seg-create-date] > (SELECT MAX([post_date]) FROM dbo.c_ptrs_msg_tbl)
END

