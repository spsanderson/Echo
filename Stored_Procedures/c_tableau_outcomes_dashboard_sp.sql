USE [SMS]
GO
/****** Object:  StoredProcedure [dbo].[c_tableau_outcomes_dashboard_sp]    Script Date: 10/6/2023 11:19:12 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
***********************************************************************
File: c_tableau_outcomes_dashboard_sp.sql

Input Parameters:
	None

Tables/Views:
	[ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].echo_active.dbo.accountcomments
    [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].echo_archive.dbo.accountcomments
    [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].echo_active.dbo.detailinformation
    [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].echo_archive.dbo.detailinformation

Creates Table/View:
	c_tableau_outcomes_dashboard_letters_tbl
    c_tableau_outcomes_dashboard_payments_tbl

Functions:
	None

Author: Steven P. Sanderson II, MPH

Department: Patient Financial Services

Purpose/Description
	To create a view that will be used to create a Tableau dashboard for the
    Outcomes team.

Revision History:
Date		Version		Description
----		----		----
2023-06-09	v1			Initial Creation
2023-06-14	v2			Update from dev testing
2023-06-26	v3			Add more JOC Codes per Chris
2023-10-06	v4			Fix substring logic to add a space. Example: 'JREF' should be 'JREF '
2023-10-19	v5			Add in unit date and archive date for joins to ALT
***********************************************************************
*/

ALTER PROCEDURE dbo.c_tableau_outcomes_dashboard_sp
AS
-- Step 1: Make outcomes letters/comments table if it does not exist, otherwise insert new records
IF OBJECT_ID('dbo.c_tableau_outcomes_dashboard_letters_tbl', 'U') IS NULL
BEGIN
	-- Create the table if it doesn't exist
	CREATE TABLE dbo.c_tableau_outcomes_dashboard_letters_tbl (
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

	SET @START = '2021-01-01';

	INSERT INTO dbo.c_tableau_outcomes_dashboard_letters_tbl (
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
		[LETTER-TYPE] = SUBSTRING([PA-SMART-COMMENT], 1, 4),
		[USER-ID-DIRTY] = SUBSTRING([PA-SMART-COMMENT], 6, 6),
		[PA-SMART-SVC-CD-WOSCD],
		[PA-SMART-SVC-CD-SCD],
		CAST(GETDATE() AS SMALLDATETIME) AS [REPORT-RUN-DATETIME]    
	FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].echo_active.dbo.accountcomments AS A
	LEFT JOIN dbo.revenue_cycle_employee_listing AS B ON CAST(SUBSTRING(A.[PA-SMART-COMMENT], 6, 6) AS VARCHAR) = CAST(B.[USER_ID] AS VARCHAR)
	WHERE SUBSTRING(A.[pa-smart-comment], 1, 5) IN (
		-- Appeals
		'APP2 ', 'APPC ', 'APPL ', 'APPS ', 'CMSA ', 'PCUR ', 'RPPA ', 'RTPA ',
		-- Contacted Insurance
		'CIFB ', 'CILM ', 'CINS ', 'ICBR ', 'ICCR ', 'ICIR ', 'ICNR ', 'ICOR ', 'ICRB ', 'ICRC ', 'INST ', 'IBSI ', 'ICPP ', 'ICPR ',
		-- JOC
		'PJOC ', 'RJOC ', 'PAAU ', 'JADD ', 'JAPP ', 'JATH ', 'JCPT ', 'JCRT ', 'JDRG ', 'JEMR ', 'JIMP ', 'JMOD ', 'JMRC ', 'JNBN ', 'JNPI ', 'JOBS ', 'JOCC ', 'JOCD ', 'JPAY ', 'JPHA ', 'JPST ', 'JRAD ', 'JREV ', 'JRTL ', 'JSCH ', 'JSTL ', 'JSVC ', 'RTRJ ', 'JREF ',
		-- Letter
		'L130 ', 'L131 ', 'L132 ', 'L133 ', 'L135 ', 'L136 ', 'L137 ', 'L138 ', 'L139 ', 'L140 ', 'L142 ', 'L143 ', 'L144 ', 'L145 ', 'L146 ', 'L147 ', 'L148 ', 'L149 ', 'LSTI ', 'SLTP ',
		-- Medical Record/UR
		'MRRH ','MRUR ','MRRI ','MRRS ',
		-- OTHER
		'UMVA ','WCCT '
		)
		AND A.[PA-SMART-DATE] >= @START
	
	UNION ALL
		 
	SELECT [PT_NO] = CAST(A.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(A.[PA-PT-NO-SCD-1] AS VARCHAR),
		[PA-PT-NO-WOSCD],
		[PA-PT-NO-SCD-1],
		[pa-ctl-paa-xfer-date],
		[PA-SMART-COMMENT],
		[PA-SMART-DATE],
		[LETTER-TYPE] = SUBSTRING([PA-SMART-COMMENT], 1, 4),
		[USER-ID-DIRTY] = SUBSTRING([PA-SMART-COMMENT], 6, 6),
		[PA-SMART-SVC-CD-WOSCD],
		[PA-SMART-SVC-CD-SCD],
		CAST(GETDATE() AS SMALLDATETIME) AS [REPORT-RUN-DATETIME]     
	FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].echo_archive.dbo.accountcomments AS A
	LEFT JOIN dbo.revenue_cycle_employee_listing AS B ON CAST(SUBSTRING(A.[PA-SMART-COMMENT], 6, 6) AS VARCHAR) = CAST(B.[USER_ID] AS VARCHAR)
	WHERE SUBSTRING(A.[pa-smart-comment], 1, 5) IN (
		-- Appeals
		'APP2 ', 'APPC ', 'APPL ', 'APPS ', 'CMSA ', 'PCUR ', 'RPPA ', 'RTPA ',
		-- Contacted Insurance
		'CIFB ', 'CILM ', 'CINS ', 'ICBR ', 'ICCR ', 'ICIR ', 'ICNR ', 'ICOR ', 'ICRB ', 'ICRC ', 'INST ', 'IBSI ', 'ICPP ', 'ICPR ',
		-- JOC
		'PJOC ', 'RJOC ', 'PAAU ', 'JADD ', 'JAPP ', 'JATH ', 'JCPT ', 'JCRT ', 'JDRG ', 'JEMR ', 'JIMP ', 'JMOD ', 'JMRC ', 'JNBN ', 'JNPI ', 'JOBS ', 'JOCC ', 'JOCD ', 'JPAY ', 'JPHA ', 'JPST ', 'JRAD ', 'JREV ', 'JRTL ', 'JSCH ', 'JSTL ', 'JSVC ', 'RTRJ ', 'JREF ',
		-- Letter
		'L130 ', 'L131 ', 'L132 ', 'L133 ', 'L135 ', 'L136 ', 'L137 ', 'L138 ', 'L139 ', 'L140 ', 'L142 ', 'L143 ', 'L144 ', 'L145 ', 'L146 ', 'L147 ', 'L148 ', 'L149 ', 'LSTI ', 'SLTP ',
		-- Medical Record/UR
		'MRRH ','MRUR ','MRRI ','MRRS ',
		-- OTHER
		'UMVA ','WCCT '
		)
		AND A.[PA-SMART-DATE] >= @START
END
ELSE BEGIN
	DECLARE @STARTDATE DATE;

	SET @STARTDATE = (SELECT MAX(pa_smart_date) FROM dbo.c_tableau_outcomes_dashboard_letters_tbl);

	INSERT INTO dbo.c_tableau_outcomes_dashboard_letters_tbl (
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
		[LETTER-TYPE] = SUBSTRING([PA-SMART-COMMENT], 1, 4),
		[USER-ID-DIRTY] = SUBSTRING([PA-SMART-COMMENT], 6, 6),
		[PA-SMART-SVC-CD-WOSCD],
		[PA-SMART-SVC-CD-SCD],
		CAST(GETDATE() AS SMALLDATETIME) AS [REPORT-RUN-DATETIME]      
	FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].echo_active.dbo.accountcomments AS A
	LEFT JOIN dbo.revenue_cycle_employee_listing AS B ON CAST(SUBSTRING(A.[PA-SMART-COMMENT], 6, 6) AS VARCHAR) = CAST(B.[USER_ID] AS VARCHAR)
	WHERE SUBSTRING(A.[pa-smart-comment], 1, 5) IN (
		-- Appeals
		'APP2 ', 'APPC ', 'APPL ', 'APPS ', 'CMSA ', 'PCUR ', 'RPPA ', 'RTPA ',
		-- Contacted Insurance
		'CIFB ', 'CILM ', 'CINS ', 'ICBR ', 'ICCR ', 'ICIR ', 'ICNR ', 'ICOR ', 'ICRB ', 'ICRC ', 'INST ', 'IBSI ', 'ICPP ', 'ICPR ',
		-- JOC
		'PJOC ', 'RJOC ', 'PAAU ', 'JADD ', 'JAPP ', 'JATH ', 'JCPT ', 'JCRT ', 'JDRG ', 'JEMR ', 'JIMP ', 'JMOD ', 'JMRC ', 'JNBN ', 'JNPI ', 'JOBS ', 'JOCC ', 'JOCD ', 'JPAY ', 'JPHA ', 'JPST ', 'JRAD ', 'JREV ', 'JRTL ', 'JSCH ', 'JSTL ', 'JSVC ', 'RTRJ ', 'JREF ',
		-- Letter
		'L130 ', 'L131 ', 'L132 ', 'L133 ', 'L135 ', 'L136 ', 'L137 ', 'L138 ', 'L139 ', 'L140 ', 'L142 ', 'L143 ', 'L144 ', 'L145 ', 'L146 ', 'L147 ', 'L148 ', 'L149 ', 'LSTI ', 'SLTP ',
		-- Medical Record/UR
		'MRRH ','MRUR ','MRRI ','MRRS ',
		-- OTHER
		'UMVA ','WCCT '
		)
		AND A.[PA-SMART-DATE] >= @STARTDATE
	
	UNION ALL
		
	SELECT [PT_NO] = CAST(A.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(A.[PA-PT-NO-SCD-1] AS VARCHAR),
		[PA-PT-NO-WOSCD],
		[PA-PT-NO-SCD-1],
		[pa-ctl-paa-xfer-date],
		[PA-SMART-COMMENT],
		[PA-SMART-DATE],
		[LETTER-TYPE] = SUBSTRING([PA-SMART-COMMENT], 1, 4),
		[USER-ID-DIRTY] = SUBSTRING([PA-SMART-COMMENT], 6, 6),
		[PA-SMART-SVC-CD-WOSCD],
		[PA-SMART-SVC-CD-SCD],
		CAST(GETDATE() AS SMALLDATETIME) AS [REPORT-RUN-DATETIME]    
	FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].echo_archive.dbo.accountcomments AS A
	LEFT JOIN dbo.revenue_cycle_employee_listing AS B ON CAST(SUBSTRING(A.[PA-SMART-COMMENT], 6, 6) AS VARCHAR) = CAST(B.[USER_ID] AS VARCHAR)
	WHERE SUBSTRING(A.[pa-smart-comment], 1, 5) IN (
		-- Appeals
		'APP2 ', 'APPC ', 'APPL ', 'APPS ', 'CMSA ', 'PCUR ', 'RPPA ', 'RTPA ',
		-- Contacted Insurance
		'CIFB ', 'CILM ', 'CINS ', 'ICBR ', 'ICCR ', 'ICIR ', 'ICNR ', 'ICOR ', 'ICRB ', 'ICRC ', 'INST ', 'IBSI ', 'ICPP ', 'ICPR ',
		-- JOC
		'PJOC ', 'RJOC ', 'PAAU ', 'JADD ', 'JAPP ', 'JATH ', 'JCPT ', 'JCRT ', 'JDRG ', 'JEMR ', 'JIMP ', 'JMOD ', 'JMRC ', 'JNBN ', 'JNPI ', 'JOBS ', 'JOCC ', 'JOCD ', 'JPAY ', 'JPHA ', 'JPST ', 'JRAD ', 'JREV ', 'JRTL ', 'JSCH ', 'JSTL ', 'JSVC ', 'RTRJ ', 'JREF ',
		-- Letter
		'L130 ', 'L131 ', 'L132 ', 'L133 ', 'L135 ', 'L136 ', 'L137 ', 'L138 ', 'L139 ', 'L140 ', 'L142 ', 'L143 ', 'L144 ', 'L145 ', 'L146 ', 'L147 ', 'L148 ', 'L149 ', 'LSTI ', 'SLTP ',
		-- Medical Record/UR
		'MRRH ','MRUR ','MRRI ','MRRS ',
		-- OTHER
		'UMVA ','WCCT '
		)
		AND A.[PA-SMART-DATE] >= @STARTDATE
END;

-- Step 2: Make outcomes payments table if it does not exist, otherwise insert new records
IF OBJECT_ID('dbo.c_tableau_outcomes_dashboard_payments_tbl') IS NULL
BEGIN
	CREATE TABLE dbo.c_tableau_outcomes_dashboard_payments_tbl (
		pt_no VARCHAR(20),
		pa_pt_no_woscd VARCHAR(20),
		pa_pt_no_scd_1 VARCHAR(20),
		pa_ctl_paa_xfer_date SMALLDATETIME,
		pa_unit_date SMALLDATETIME,
		pa_dtl_type_ind VARCHAR(20),
		pa_dtl_svc_cd_woscd VARCHAR(20),
		pa_dtl_svc_cd_scd VARCHAR(20),
		pa_dtl_technical_desc VARCHAR(100),
		pa_dtl_cdm_description VARCHAR(100),
		pa_dtl_post_date DATE,
		pa_dtl_chg_amt MONEY,
		pa_ins_plan VARCHAR(10),
		report_run_datetime SMALLDATETIME
		);

	DECLARE @START_PMTS DATE;

	SET @START_PMTS = '2021-01-01';

	INSERT INTO dbo.c_tableau_outcomes_dashboard_payments_tbl (
		pt_no,
		pa_pt_no_woscd,
		pa_pt_no_scd_1,
		pa_ctl_paa_xfer_date,
		pa_unit_date,
		pa_dtl_type_ind,
		pa_dtl_svc_cd_woscd,
		pa_dtl_svc_cd_scd,
		pa_dtl_technical_desc,
		pa_dtl_cdm_description,
		pa_dtl_post_date,
		pa_dtl_chg_amt,
		pa_ins_plan,
		report_run_datetime
		)    
	SELECT [PT-NO] = CAST([PA-PT-NO-WOSCD] AS VARCHAR) + CAST([PA-PT-NO-SCD-1] AS VARCHAR),
        [PA-PT-NO-WOSCD],
	    [PA-PT-NO-SCD-1],
		[PA-CTL-PAA-XFER-DATE],
		[PA-DTL-UNIT-DATE],
		[PA-DTL-TYPE-IND],
		[PA-DTL-SVC-CD-WOSCD],
		[PA-DTL-SVC-CD-SCD],
		[PA-DTL-TECHNICAL-DESC],
		[PA-DTL-CDM-DESCRIPTION],
		CAST([PA-DTL-POST-DATE] AS DATE) AS [PA-DTL-POST-DATE],
		[PA-DTL-CHG-AMT],
		[PA-INS-PLAN] = CASE            
		    WHEN LEN(ltrim(rtrim([pa-dtl-ins-plan-no]))) = '1'                
				THEN CAST(CAST(LTRIM(RTRIM([pa-dtl-ins-co-cd])) AS VARCHAR) + CONVERT(VARCHAR(1), 0) + CAST(LTRIM(RTRIM([pa-dtl-ins-plan-no])) AS VARCHAR) AS VARCHAR)            
			WHEN LEN(LTRIM(RTRIM([pa-dtl-ins-plan-no]))) = '2'                
				THEN CAST(CAST(LTRIM(RTRIM([pa-dtl-ins-co-cd])) AS VARCHAR) + CAST(LTRIM(RTRIM([pa-dtl-ins-plan-no])) AS VARCHAR) AS VARCHAR)            
		END,
		CAST(GETDATE() AS SMALLDATETIME) AS [REPORT-RUN-DATETIME]       
	FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].echo_active.dbo.detailinformation    
	WHERE (
			        [PA-DTL-TYPE-IND] = '1'        
			OR [PA-DTL-SVC-CD-WOSCD] IN ('60320', '60215')    
			)        
		AND [PA-DTL-POST-DATE] >= @START_PMTS
	
	UNION ALL
		
		   
	SELECT [PT-NO] = CAST([PA-PT-NO-WOSCD] AS VARCHAR) + CAST([PA-PT-NO-SCD-1] AS VARCHAR),
        [PA-PT-NO-WOSCD],
	    [PA-PT-NO-SCD-1],
		[PA-CTL-PAA-XFER-DATE],
		[PA-DTL-UNIT-DATE],
		[PA-DTL-TYPE-IND],
		[PA-DTL-SVC-CD-WOSCD],
		[PA-DTL-SVC-CD-SCD],
		[PA-DTL-TECHNICAL-DESC],
		[PA-DTL-CDM-DESCRIPTION],
		CAST([PA-DTL-POST-DATE] AS DATE) AS [PA-DTL-POST-DATE],
		[PA-DTL-CHG-AMT],
		[PA-INS-PLAN] = CASE            
		    WHEN LEN(ltrim(rtrim([pa-dtl-ins-plan-no]))) = '1'                
				THEN CAST(CAST(LTRIM(RTRIM([pa-dtl-ins-co-cd])) AS VARCHAR) + CONVERT(VARCHAR(1), 0) + CAST(LTRIM(RTRIM([pa-dtl-ins-plan-no])) AS VARCHAR) AS VARCHAR)            
			WHEN LEN(LTRIM(RTRIM([pa-dtl-ins-plan-no]))) = '2'                
				THEN CAST(CAST(LTRIM(RTRIM([pa-dtl-ins-co-cd])) AS VARCHAR) + CAST(LTRIM(RTRIM([pa-dtl-ins-plan-no])) AS VARCHAR) AS VARCHAR)            
		END,
		CAST(GETDATE() AS SMALLDATETIME) AS [REPORT-RUN-DATETIME]        
	FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].echo_archive.dbo.detailinformation    
	WHERE (
			        [PA-DTL-TYPE-IND] = '1'        
			OR [PA-DTL-SVC-CD-WOSCD] IN ('60320', '60215')    
			)        
		AND [PA-DTL-POST-DATE] >= @START_PMTS
END
ELSE BEGIN
	DECLARE @STARTDATE_PMTS DATE;

	SET @STARTDATE_PMTS = (SELECT MAX(pa_dtl_post_date) FROM dbo.c_tableau_outcomes_dashboard_payments_tbl);

	INSERT INTO dbo.c_tableau_outcomes_dashboard_payments_tbl (
		pt_no,
		pa_pt_no_woscd,
		pa_pt_no_scd_1,
		pa_ctl_paa_xfer_date,
		pa_unit_date,
		pa_dtl_type_ind,
		pa_dtl_svc_cd_woscd,
		pa_dtl_svc_cd_scd,
		pa_dtl_technical_desc,
		pa_dtl_cdm_description,
		pa_dtl_post_date,
		pa_dtl_chg_amt,
		pa_ins_plan,
		report_run_datetime
		)    
	SELECT [PT-NO] = CAST([PA-PT-NO-WOSCD] AS VARCHAR) + CAST([PA-PT-NO-SCD-1] AS VARCHAR),
        [PA-PT-NO-WOSCD],
	    [PA-PT-NO-SCD-1],
		[PA-CTL-PAA-XFER-DATE],
		[PA-DTL-UNIT-DATE],
		[PA-DTL-TYPE-IND],
		[PA-DTL-SVC-CD-WOSCD],
		[PA-DTL-SVC-CD-SCD],
		[PA-DTL-TECHNICAL-DESC],
		[PA-DTL-CDM-DESCRIPTION],
		CAST([PA-DTL-POST-DATE] AS DATE) AS [PA-DTL-POST-DATE],
		[PA-DTL-CHG-AMT],
		[PA-INS-PLAN] = CASE            
		    WHEN LEN(ltrim(rtrim([pa-dtl-ins-plan-no]))) = '1'                
				THEN CAST(CAST(LTRIM(RTRIM([pa-dtl-ins-co-cd])) AS VARCHAR) + CONVERT(VARCHAR(1), 0) + CAST(LTRIM(RTRIM([pa-dtl-ins-plan-no])) AS VARCHAR) AS VARCHAR)            
			WHEN LEN(LTRIM(RTRIM([pa-dtl-ins-plan-no]))) = '2'                
				THEN CAST(CAST(LTRIM(RTRIM([pa-dtl-ins-co-cd])) AS VARCHAR) + CAST(LTRIM(RTRIM([pa-dtl-ins-plan-no])) AS VARCHAR) AS VARCHAR)            
		END,
		CAST(GETDATE() AS SMALLDATETIME) AS [REPORT-RUN-DATETIME]       
	FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].echo_active.dbo.detailinformation    
	WHERE (
			        [PA-DTL-TYPE-IND] = '1'        
			OR [PA-DTL-SVC-CD-WOSCD] IN ('60320', '60215')    
			)        
		AND [PA-DTL-POST-DATE] >= @STARTDATE_PMTS
	
	UNION ALL

	SELECT [PT-NO] = CAST([PA-PT-NO-WOSCD] AS VARCHAR) + CAST([PA-PT-NO-SCD-1] AS VARCHAR),
        [PA-PT-NO-WOSCD],
	    [PA-PT-NO-SCD-1],
		[PA-CTL-PAA-XFER-DATE],
		[PA-DTL-UNIT-DATE],
		[PA-DTL-TYPE-IND],
		[PA-DTL-SVC-CD-WOSCD],
		[PA-DTL-SVC-CD-SCD],
		[PA-DTL-TECHNICAL-DESC],
		[PA-DTL-CDM-DESCRIPTION],
		CAST([PA-DTL-POST-DATE] AS DATE) AS [PA-DTL-POST-DATE],
		[PA-DTL-CHG-AMT],
		[PA-INS-PLAN] = CASE            
		    WHEN LEN(ltrim(rtrim([pa-dtl-ins-plan-no]))) = '1'                
				THEN CAST(CAST(LTRIM(RTRIM([pa-dtl-ins-co-cd])) AS VARCHAR) + CONVERT(VARCHAR(1), 0) + CAST(LTRIM(RTRIM([pa-dtl-ins-plan-no])) AS VARCHAR) AS VARCHAR)            
			WHEN LEN(LTRIM(RTRIM([pa-dtl-ins-plan-no]))) = '2'                
				THEN CAST(CAST(LTRIM(RTRIM([pa-dtl-ins-co-cd])) AS VARCHAR) + CAST(LTRIM(RTRIM([pa-dtl-ins-plan-no])) AS VARCHAR) AS VARCHAR)            
		END,
		CAST(GETDATE() AS SMALLDATETIME) AS [REPORT-RUN-DATETIME]         
	FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].echo_archive.dbo.detailinformation    
	WHERE (
			        [PA-DTL-TYPE-IND] = '1'        
			OR [PA-DTL-SVC-CD-WOSCD] IN ('60320', '60215')    
			)        
		AND [PA-DTL-POST-DATE] >= @STARTDATE_PMTS
END;
