USE [SMS]
GO
/****** Object:  StoredProcedure [dbo].[c_tableau_revenue_integrity_dashboard_sp]    Script Date: 10/6/2023 11:19:12 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
***********************************************************************
File: c_tableau_revenue_integrity_dashboard_sp.sql

Input Parameters:
	None

Tables/Views:
	[ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].echo_active.dbo.accountcomments
    [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].echo_archive.dbo.accountcomments
    [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].echo_active.dbo.detailinformation
    [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].echo_archive.dbo.detailinformation
	dbo.revenue_cycle_employee_listing

Creates Table/View:
	c_tableau_revenue_integrity_dashboard_tbl
    c_tableau_revenue_integrity_dashboard_payments_tbl

Functions:
	None

Author: Steven P. Sanderson II, MPH

Department: Patient Financial Services

Purpose/Description
	To create a view that will be used to create a Tableau dashboard for the
    Revenue Integrity and Retention Unit.

Revision History:
Date		Version		Description
----		----		----
2024-04-11	v1			Initial Creation
***********************************************************************
*/

ALTER PROCEDURE dbo.c_tableau_revenue_integrity_dashboard_sp
AS
-- Step 1: Make outcomes letters/comments table if it does not exist, otherwise insert new records
IF OBJECT_ID('dbo.c_tableau_revenue_integrity_dashboard_tbl', 'U') IS NULL
BEGIN
	-- Create the table if it doesn't exist
	CREATE TABLE dbo.c_tableau_revenue_integrity_dashboard_tbl (
		-- Define the table columns
		pt_no VARCHAR(20),
		pa_pt_no_woscd VARCHAR(10),
		pa_pt_no_scd_1 VARCHAR(10),
		pa_ctl_paa_xfer_date SMALLDATETIME,
		pa_smart_comment VARCHAR(100),
		pa_smart_date DATE,
		letter_type VARCHAR(10),
		user_id_dirty VARCHAR(10),
		pa_smart_svc_cd_woscd VARCHAR(10),
		pa_smart_svc_cd_scd VARCHAR(10),
		report_run_datetime SMALLDATETIME
		);

	DECLARE @START DATE;

	SET @START = '2023-03-01';

	INSERT INTO dbo.c_tableau_revenue_integrity_dashboard_tbl (
		pt_no,
		pa_pt_no_woscd,
		pa_pt_no_scd_1,
		pa_ctl_paa_xfer_date,
		pa_smart_comment,
		pa_smart_date,
		letter_type,
		user_id_dirty,
		pa_smart_svc_cd_woscd,
		pa_smart_svc_cd_scd,
		report_run_datetime
		)
	SELECT [PT_NO] = CAST(A.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(A.[PA-PT-NO-SCD-1] AS VARCHAR),
		[PA-PT-NO-WOSCD],
		[PA-PT-NO-SCD-1],
		[pa-ctl-paa-xfer-date],
		[PA-SMART-COMMENT],
		[PA-SMART-DATE],
		[pa_smart_comment] = CASE
			WHEN A.[PA-SMART-SVC-CD-WOSCD] = '0'
				THEN SUBSTRING([PA-SMART-COMMENT], 1, 4)
			ELSE 'SYSTEM'
			END,
		[USER-ID-DIRTY] = CASE
			WHEN A.[PA-SMART-SVC-CD-WOSCD] = '0' 
				THEN SUBSTRING([PA-SMART-COMMENT], 6, 6)
			ELSE 'SYSTEM'
			END,
		[PA-SMART-SVC-CD-WOSCD],
		[PA-SMART-SVC-CD-SCD],
		CAST(GETDATE() AS SMALLDATETIME) AS [REPORT-RUN-DATETIME]
	FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].echo_active.dbo.accountcomments AS A
	LEFT JOIN dbo.revenue_cycle_employee_listing AS B ON CAST(SUBSTRING(A.[PA-SMART-COMMENT], 6, 6) AS VARCHAR) = CAST(B.[USER_ID] AS VARCHAR)
	WHERE (
		(
			A.[pa-smart-comment] like 'RI__ [A-Z][A-Z][A-Z][A-Z][A-Z]%'
			AND SUBSTRING(A.[pa-smart-comment], 1, 5) IN (
				'RIRV ', 'RIUI ', 'RIRI ','RIRE ','RIRF ', 'RIAW ','RIAS ','RINA '
				)
		)
			OR (
				A.[PA-SMART-SVC-CD-WOSCD] IN ('3803594', '3803593', '3803595','3803601','3858022','3850034','3850033')
				AND A.[PA-SMART-SVC-CD-SCD] IN ('5','7','2','8','1','4','6')
				)
		)
		AND A.[PA-SMART-IND] = 'C'
		AND A.[PA-SMART-DATE] >= @START
	
	UNION ALL
		 
	SELECT [PT_NO] = CAST(A.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(A.[PA-PT-NO-SCD-1] AS VARCHAR),
		[PA-PT-NO-WOSCD],
		[PA-PT-NO-SCD-1],
		[pa-ctl-paa-xfer-date],
		[PA-SMART-COMMENT],
		[PA-SMART-DATE],
		[LETTER-TYPE] = CASE
			WHEN A.[PA-SMART-SVC-CD-WOSCD] = '0'
				THEN SUBSTRING([PA-SMART-COMMENT], 1, 4)
			ELSE 'SYSTEM'
			END,
		[USER-ID-DIRTY] = CASE
			WHEN A.[PA-SMART-SVC-CD-WOSCD] = '0' 
				THEN SUBSTRING([PA-SMART-COMMENT], 6, 6)
			ELSE 'SYSTEM'
			END,
		[PA-SMART-SVC-CD-WOSCD],
		[PA-SMART-SVC-CD-SCD],
		CAST(GETDATE() AS SMALLDATETIME) AS [REPORT-RUN-DATETIME]
	FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].echo_archive.dbo.accountcomments AS A
	LEFT JOIN dbo.revenue_cycle_employee_listing AS B ON CAST(SUBSTRING(A.[PA-SMART-COMMENT], 6, 6) AS VARCHAR) = CAST(B.[USER_ID] AS VARCHAR)
	WHERE (
		(
			A.[pa-smart-comment] like 'RI__ [A-Z][A-Z][A-Z][A-Z][A-Z]%'
			AND SUBSTRING(A.[pa-smart-comment], 1, 5) IN (
				'RIRV ', 'RIUI ', 'RIRI ','RIRE ','RIRF ', 'RIAW ','RIAS ','RINA '
				)
		)
			OR (
				A.[PA-SMART-SVC-CD-WOSCD] IN ('3803594', '3803593', '3803595','3803601','3858022','3850034','3850033')
				AND A.[PA-SMART-SVC-CD-SCD] IN ('5','7','2','8','1','4','6')
				)
		)
		AND A.[PA-SMART-IND] = 'C'
		AND A.[PA-SMART-DATE] >= @START;

		-- Remove any records that have a user_id_dirty that is not a valid user_id
		DELETE
		FROM SMS.DBO.c_tableau_revenue_integrity_dashboard_tbl
		WHERE user_id_dirty in (
			'COMPLT',
			'FOLDER',
			'MAILED',
			'PROCES',
			'REVIEW'
		)
END
ELSE BEGIN
	DECLARE @STARTDATE DATE;

	SET @STARTDATE = (SELECT MAX(pa_smart_date) FROM dbo.c_tableau_revenue_integrity_dashboard_tbl);

	INSERT INTO dbo.c_tableau_revenue_integrity_dashboard_tbl (
		pt_no,
		pa_pt_no_woscd,
		pa_pt_no_scd_1,
		pa_ctl_paa_xfer_date,
		pa_smart_comment,
		pa_smart_date,
		letter_type,
		user_id_dirty,
		pa_smart_svc_cd_woscd,
		pa_smart_svc_cd_scd,
		report_run_datetime
		)
	SELECT [PT_NO] = CAST(A.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(A.[PA-PT-NO-SCD-1] AS VARCHAR),
		[PA-PT-NO-WOSCD],
		[PA-PT-NO-SCD-1],
		[pa-ctl-paa-xfer-date],
		[PA-SMART-COMMENT],
		[PA-SMART-DATE],
		[pa_smart_comment] = CASE
			WHEN A.[PA-SMART-SVC-CD-WOSCD] = '0'
				THEN SUBSTRING([PA-SMART-COMMENT], 1, 4)
			ELSE 'SYSTEM'
			END,
		[USER-ID-DIRTY] = CASE
			WHEN A.[PA-SMART-SVC-CD-WOSCD] = '0' 
				THEN SUBSTRING([PA-SMART-COMMENT], 6, 6)
			ELSE 'SYSTEM'
			END,
		[PA-SMART-SVC-CD-WOSCD],
		[PA-SMART-SVC-CD-SCD],
		CAST(GETDATE() AS SMALLDATETIME) AS [REPORT-RUN-DATETIME]
	FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].echo_active.dbo.accountcomments AS A
	LEFT JOIN dbo.revenue_cycle_employee_listing AS B ON CAST(SUBSTRING(A.[PA-SMART-COMMENT], 6, 6) AS VARCHAR) = CAST(B.[USER_ID] AS VARCHAR)
	WHERE (
		(
			A.[pa-smart-comment] like 'RI__ [A-Z][A-Z][A-Z][A-Z][A-Z]%'
			AND SUBSTRING(A.[pa-smart-comment], 1, 5) IN (
				'RIRV ', 'RIUI ', 'RIRI ', 'RIRE ','RIRF ', 'RIAW ','RIAS ','RINA '
				)
		)
			OR (
				A.[PA-SMART-SVC-CD-WOSCD] IN ('3803594', '3803593', '3803595','3803601','3858022','3850034','3850033')
				AND A.[PA-SMART-SVC-CD-SCD] IN ('5','7','2','8','1','4','6')
				)
		)
		AND A.[PA-SMART-IND] = 'C'
		AND A.[PA-SMART-DATE] >= @START
	
	UNION ALL
		 
	SELECT [PT_NO] = CAST(A.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(A.[PA-PT-NO-SCD-1] AS VARCHAR),
		[PA-PT-NO-WOSCD],
		[PA-PT-NO-SCD-1],
		[pa-ctl-paa-xfer-date],
		[PA-SMART-COMMENT],
		[PA-SMART-DATE],
		[LETTER-TYPE] = CASE
			WHEN A.[PA-SMART-SVC-CD-WOSCD] = '0'
				THEN SUBSTRING([PA-SMART-COMMENT], 1, 4)
			ELSE 'SYSTEM'
			END,
		[USER-ID-DIRTY] = CASE
			WHEN A.[PA-SMART-SVC-CD-WOSCD] = '0' 
				THEN SUBSTRING([PA-SMART-COMMENT], 6, 6)
			ELSE 'SYSTEM'
			END,
		[PA-SMART-SVC-CD-WOSCD],
		[PA-SMART-SVC-CD-SCD],
		CAST(GETDATE() AS SMALLDATETIME) AS [REPORT-RUN-DATETIME]
	FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].echo_archive.dbo.accountcomments AS A
	LEFT JOIN dbo.revenue_cycle_employee_listing AS B ON CAST(SUBSTRING(A.[PA-SMART-COMMENT], 6, 6) AS VARCHAR) = CAST(B.[USER_ID] AS VARCHAR)
	WHERE (
		(
			A.[pa-smart-comment] like 'RI__ [A-Z][A-Z][A-Z][A-Z][A-Z]%'
			AND SUBSTRING(A.[pa-smart-comment], 1, 5) IN (
				'RIRV ', 'RIUI ', 'RIRI ', 'RIRE ','RIRF ', 'RIAW ','RIAS ','RINA '
				)
		)
			OR (
				A.[PA-SMART-SVC-CD-WOSCD] IN ('3803594', '3803593', '3803595','3803601','3858022','3850034','3850033')
				AND A.[PA-SMART-SVC-CD-SCD] IN ('5','7','2','8','1','4','6')
				)
		)
		AND A.[PA-SMART-IND] = 'C'
		AND A.[PA-SMART-DATE] >= @START

		-- Remove any records that have a user_id_dirty that is not a valid user_id
		DELETE
		FROM SMS.DBO.c_tableau_revenue_integrity_dashboard_tbl
		WHERE user_id_dirty in (
			'COMPLT',
			'FOLDER',
			'MAILED',
			'PROCES',
			'REVIEW'
		)
END;

-- Step 2: Make outcomes payments table if it does not exist, otherwise insert new records
DROP TABLE IF EXISTS SMS.DBO.c_tableau_revenue_integrity_dashboard_payments_tbl;
BEGIN
	CREATE TABLE dbo.c_tableau_revenue_integrity_dashboard_payments_tbl (
		pt_no VARCHAR(20),
		pa_ctl_paa_xfer_date SMALLDATETIME,
		pa_unit_no VARCHAR(20),
		pa_unit_date SMALLDATETIME,
		pa_dtl_type_ind VARCHAR(20),
		pa_dtl_svc_cd VARCHAR(20),
		pa_tx_type VARCHAR(200),
		pa_dtl_cdm_description VARCHAR(100),
		pa_dtl_post_date DATE,
		pa_dtl_chg_amt MONEY,
		pa_ins_plan VARCHAR(10),
		report_run_datetime SMALLDATETIME
		);

	INSERT INTO dbo.c_tableau_revenue_integrity_dashboard_payments_tbl (
		pt_no,
		pa_ctl_paa_xfer_date,
		pa_unit_no,
		pa_unit_date,
		pa_dtl_type_ind,
		pa_dtl_svc_cd,
		pa_tx_type,
		pa_dtl_cdm_description,
		pa_dtl_post_date,
		pa_dtl_chg_amt,
		pa_ins_plan,
		report_run_datetime
		)
	SELECT pt_no,
		PA_CTL_PAA_XFER_DATE,
		Unit_No,
		Unit_Date,
		DTL_Type_Ind,
		SVC_CD,
		Transaction_Type,
		CDM_DESCRIPTION,
		[pa-dtl-post-date],
		[pa-dtl-chg-amt],
		Ins_Plan, 
		[report_run_datetime] = CAST(GETDATE() AS smalldatetime)
	FROM sms.dbo.Payments_Adjustments_For_Reporting AS PMTS
	WHERE EXISTS (
		SELECT 1
		FROM SMS.dbo.c_tableau_revenue_integrity_dashboard_tbl AS Z
		WHERE Z.pt_no = PMTS.PT_NO
		AND Z.pa_ctl_paa_xfer_date = PMTS.PA_CTL_PAA_XFER_DATE
	)
END;
