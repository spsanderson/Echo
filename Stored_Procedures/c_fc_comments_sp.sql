USE [SMS]
GO 

SET QUOTED_IDENTIFIER ON
GO  

CREATE PROCEDURE dbo.c_fc_comments_sp
AS 

SET NOCOUNT ON;

/*
***********************************************************************
File: c_fc_comments_sp.sql

Input Parameters:
	None

Tables/Views:
	[ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Active].[dbo].[accountcomments]
	[ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Archive].[dbo].[accountcomments]

Creates Table/View:
	dbo.c_fc_comments_tbl

Functions:
	NONE

Author: Steven P. Sanderson II, MPH

Department: Patient Financial Services

Purpose/Description
Creates a table that contains the financial class change history for patients.

Revision History:
Date		Version		Description
----		----		----
2024-03-14	v1			Initial Creation
2024-03-22	v2			Added a check to see if the table exists and if 
						it does, it will only insert records that are 
						newer than the last record in the table. No longer
						checking Archive table for records for yesterday.	
***********************************************************************
*/

IF NOT EXISTS (
		SELECT TOP 1 *
		FROM SYSOBJECTS
		WHERE name = 'c_fc_comments_tbl'
			AND xtype = 'U'
		)
BEGIN
	CREATE TABLE dbo.c_fc_comments_tbl (
		[pa_pt_no_woscd] VARCHAR(50),
		[pa_pt_no_scd1] VARCHAR(50),
		[pt_no] VARCHAR(50),
		[svc_date] DATE,
		[post_date] DATE,
		[pa_smart_comment] VARCHAR(50),
		[fc] VARCHAR(50),
		[fc_class] VARCHAR(50),
		[fc_group] VARCHAR(50),
		[comment_yr] INT,
		[comment_month] INT,
		[comment_wk] INT
		)

	DECLARE @FC_TBL AS TABLE (
		fc_code VARCHAR(50),
		fc VARCHAR(5)
	)
	INSERT INTO @FC_TBL (fc_code, fc)
	VALUES ('FIN. CLASS     1', '1'),
		('FIN. CLASS     2', '2'),
		('FIN. CLASS     3', '3'),
		('FIN. CLASS     4', '4'),
		('FIN. CLASS     5', '5'),
		('FIN. CLASS     6', '6'),
		('FIN. CLASS     7', '7'),
		('FIN. CLASS     8', '8'),
		('FIN. CLASS     9', '9'),
		('FIN. CLASS     A', 'A'),
		('FIN. CLASS     B', 'B'),
		('FIN. CLASS     C', 'C'),
		('FIN. CLASS     D', 'D'),
		('FIN. CLASS     E', 'E'),
		('FIN. CLASS     F', 'F'),
		('FIN. CLASS     G', 'G'),
		('FIN. CLASS     H', 'H'),
		('FIN. CLASS     I', 'I'),
		('FIN. CLASS     J', 'J'),
		('FIN. CLASS     K', 'K'),
		('FIN. CLASS     L', 'L'),
		('FIN. CLASS     M', 'M'),
		('FIN. CLASS     N', 'N'),
		('FIN. CLASS     O', 'O'),
		('FIN. CLASS     P', 'P'),
		('FIN. CLASS     Q', 'Q'),
		('FIN. CLASS     R', 'R'),
		('FIN. CLASS     S', 'S'),
		('FIN. CLASS     T', 'T'),
		('FIN. CLASS     U', 'U'),
		('FIN. CLASS     V', 'V'),
		('FIN. CLASS     W', 'W'),
		('FIN. CLASS     X', 'X'),
		('FIN. CLASS     Y', 'Y'),
		('FIN. CLASS     Z', 'Z'),
		('FIN. CLASS     0', '0');

	INSERT INTO dbo.c_fc_comments_tbl ([pa_pt_no_woscd], [pa_pt_no_scd1], [pt_no], [svc_date], [post_date], [pa_smart_comment], [fc], [fc_class], [fc_group], [comment_yr], [comment_month], [comment_wk])
	SELECT [pa_pt_no_woscd] = [pa-pt-no-woscd],
		[pa_pt_no_scd1] = [pa-pt-no-scd-1],
		[pt_no] = cast([pa-pt-no-woscd] AS VARCHAR) + cast([pa-pt-no-scd-1] AS VARCHAR),
		[svc_date] = cast([pa-smart-date] as date),
		[post_date] = cast([pa-smart-seg-create-date] as date),
		[pa_smart_comment] = [pa-smart-comment],
		[fc] = b.fc,
		[fc_class] = C.[Financial Class],
		[fc_group] = C.[FC Grouped],
		[comment_yr] = datepart(year, [pa-smart-date]),
		[comment_month] = datepart(month, [pa-smart-date]),
		[comment_wk] = datepart(week, [pa-smart-date])
	FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Active].[dbo].[accountcomments] AS A
	INNER JOIN @FC_TBL AS B ON A.[pa-smart-comment] = B.fc_code
	LEFT JOIN SMS.DBO.FC AS C ON B.fc = C.FC

	UNION ALL

	SELECT [pa_pt_no_woscd] = [pa-pt-no-woscd],
		[pa_pt_no_scd1] = [pa-pt-no-scd-1],
		[pt_no] = cast([pa-pt-no-woscd] AS VARCHAR) + cast([pa-pt-no-scd-1] AS VARCHAR),
		[svc_date] = cast([pa-smart-date] as date),
		[post_date] = cast([pa-smart-seg-create-date] as date),
		[pa_smart_comment] = [pa-smart-comment],
		[fc] = b.fc,
		[fc_class] = C.[Financial Class],
		[fc_group] = C.[FC Grouped],
		[comment_yr] = datepart(year, [pa-smart-date]),
		[comment_month] = datepart(month, [pa-smart-date]),
		[comment_wk] = datepart(week, [pa-smart-date])
	FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Archive].[dbo].[accountcomments] AS A
	INNER JOIN @FC_TBL AS B ON A.[pa-smart-comment] = B.fc_code
	LEFT JOIN SMS.DBO.FC AS C ON B.fc = C.FC
END
ELSE BEGIN
	
	DECLARE @START AS DATE;
	SET @START = DATEADD(DAY, -1, GETDATE());

	DECLARE @FC_TBL_B AS TABLE (
		fc_code VARCHAR(50),
		fc VARCHAR(5)
	)
	INSERT INTO @FC_TBL_B (fc_code, fc)
	VALUES ('FIN. CLASS     1', '1'),
		('FIN. CLASS     2', '2'),
		('FIN. CLASS     3', '3'),
		('FIN. CLASS     4', '4'),
		('FIN. CLASS     5', '5'),
		('FIN. CLASS     6', '6'),
		('FIN. CLASS     7', '7'),
		('FIN. CLASS     8', '8'),
		('FIN. CLASS     9', '9'),
		('FIN. CLASS     A', 'A'),
		('FIN. CLASS     B', 'B'),
		('FIN. CLASS     C', 'C'),
		('FIN. CLASS     D', 'D'),
		('FIN. CLASS     E', 'E'),
		('FIN. CLASS     F', 'F'),
		('FIN. CLASS     G', 'G'),
		('FIN. CLASS     H', 'H'),
		('FIN. CLASS     I', 'I'),
		('FIN. CLASS     J', 'J'),
		('FIN. CLASS     K', 'K'),
		('FIN. CLASS     L', 'L'),
		('FIN. CLASS     M', 'M'),
		('FIN. CLASS     N', 'N'),
		('FIN. CLASS     O', 'O'),
		('FIN. CLASS     P', 'P'),
		('FIN. CLASS     Q', 'Q'),
		('FIN. CLASS     R', 'R'),
		('FIN. CLASS     S', 'S'),
		('FIN. CLASS     T', 'T'),
		('FIN. CLASS     U', 'U'),
		('FIN. CLASS     V', 'V'),
		('FIN. CLASS     W', 'W'),
		('FIN. CLASS     X', 'X'),
		('FIN. CLASS     Y', 'Y'),
		('FIN. CLASS     Z', 'Z'),
		('FIN. CLASS     0', '0');

	INSERT INTO dbo.c_fc_comments_tbl ([pa_pt_no_woscd], [pa_pt_no_scd1], [pt_no], [svc_date], [post_date], [pa_smart_comment], [fc], [fc_class], [fc_group], [comment_yr], [comment_month], [comment_wk])
	SELECT [pa_pt_no_woscd] = [pa-pt-no-woscd],
		[pa_pt_no_scd1] = [pa-pt-no-scd-1],
		[pt_no] = cast([pa-pt-no-woscd] AS VARCHAR) + cast([pa-pt-no-scd-1] AS VARCHAR),
		[svc_date] = cast([pa-smart-date] as date),
		[post_date] = cast([pa-smart-seg-create-date] as date),
		[pa_smart_comment] = [pa-smart-comment],
		[fc] = b.fc,
		[fc_class] = C.[Financial Class],
		[fc_group] = C.[FC Grouped],
		[comment_yr] = datepart(year, [pa-smart-date]),
		[comment_month] = datepart(month, [pa-smart-date]),
		[comment_wk] = datepart(week, [pa-smart-date])
	FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Active].[dbo].[accountcomments] AS A
	INNER JOIN @FC_TBL_B AS B ON A.[pa-smart-comment] = B.fc_code
	LEFT JOIN SMS.DBO.FC AS C ON B.fc = C.FC
	WHERE A.[PA-SMART-SEG-CREATE-DATE] >= @START

	--UNION ALL

	--SELECT [pa_pt_no_woscd] = [pa-pt-no-woscd],
	--	[pa_pt_no_scd1] = [pa-pt-no-scd-1],
	--	[pt_no] = cast([pa-pt-no-woscd] AS VARCHAR) + cast([pa-pt-no-scd-1] AS VARCHAR),
	--	[svc_date] = cast([pa-smart-date] as date),
	--	[post_date] = cast([pa-smart-seg-create-date] as date),
	--	[pa_smart_comment] = [pa-smart-comment],
	--	[fc] = b.fc,
	--	[fc_class] = C.[Financial Class],
	--	[fc_group] = C.[FC Grouped],
	--	[comment_yr] = datepart(year, [pa-smart-date]),
	--	[comment_month] = datepart(month, [pa-smart-date]),
	--	[comment_wk] = datepart(week, [pa-smart-date])
	--FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Archive].[dbo].[accountcomments] AS A
	--INNER JOIN @FC_TBL_B AS B ON A.[pa-smart-comment] = B.fc_code
	--LEFT JOIN SMS.DBO.FC AS C ON B.fc = C.FC
	--WHERE A.[PA-SMART-SEG-CREATE-DATE] >= @START
END