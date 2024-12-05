USE [SMS]

-- Create a new stored procedure called 'c_tableau_rirv_tracker_sp' in schema 'dbo'
-- Drop the stored procedure if it already exists
IF EXISTS (
SELECT *
	FROM INFORMATION_SCHEMA.ROUTINES
	WHERE SPECIFIC_SCHEMA = N'dbo'
	AND SPECIFIC_NAME = N'c_tableau_rirv_tracker_sp'
)
DROP PROCEDURE dbo.c_tableau_rirv_tracker_sp
GO
-- Create the stored procedure in the specified schema
CREATE PROCEDURE dbo.c_tableau_rirv_tracker_sp
AS
SET ANSI_NULLS ON
SET ANSI_WARNINGS ON
SET QUOTED_IDENTIFIER ON

BEGIN
	SET NOCOUNT ON;
	/************************************************************************
	File: c_tableau_rirv_tracker_sp.sql

	Input Parameters:
		None

	Tables/Views:
		sms.dbo.c_tableau_revenue_integrity_times_with_tbl
		sms.dbo.Pt_Accounting_Reporting_ALT
		sms.dbo.c_tableau_revenue_integrity_payments_tbl
		[ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Active].[dbo].[AccountComments]
		[ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Archive].[dbo].[AccountComments]
		sms.dbo.Activity_Codes_with_Svc_Codes
		sms.dbo.Denied_Encounter_Details
		
	Creates Table/View:
		c_tableau_rirv_tracker_tbl

	Functions:
		None

	Authors: Casey Delaney

	Department: Revenue Cycle Management

	Purpose/Description:
		To build the table necessary for the RIRV Revenue Integrity Tracker

	Revision History:
	Date		Version		Description
	----		----		----
	2024-09-26	v1			Initial Creation
	************************************************************************/

	DROP TABLE IF EXISTS dbo.c_tableau_rirv_tracker_tbl;	

	-- #tracker_accounts: all accounts in the RIRV Tracker
	DROP TABLE IF EXISTS #tracker_accounts;
	SELECT DISTINCT pt_no
	INTO #tracker_accounts
	FROM sms.dbo.c_tableau_revenue_integrity_times_with_tbl
	WHERE pa_smart_date >= '2024-01-01';
	
	
	-- #alt: ALT table data
	DROP TABLE IF EXISTS #alt;
	SELECT DISTINCT
		Pt_No,
		MRN,
		Pt_Name,
		Acct_Type,
		Pt_Type,
		Pt_Type_Desc,
		Hosp_Svc,
		Hosp_Svc_Description,
		Ins1_Cd,
		Ins1_Desc,
		Ins1_Balance,
		payer_organization,
		product_class,
		Admit_Date,
		Dsch_Date,
		Unit_No,
		Unit_Date,
		Tot_Chgs,
		Expected_Payment,
		Tot_Pay_Amt,
		Balance,
		SP_RunDateTime
	INTO #alt
	FROM
		sms.dbo.Pt_Accounting_Reporting_ALT as ALT
	WHERE
		EXISTS (
			select 1
			from #tracker_accounts as b
			where ALT.Pt_No = b.Pt_No
		)
		AND (Unit_No is null OR Unit_No != '0'); -- ensures no open units are pulled

	
	 /* Check for duplicate accounts in #alts */
	
	--SELECT
	--	a.Pt_No,
	--	a.Admit_Date,
	--	a.Dsch_Date,
	--	a.Unit_No,
	--	a.Unit_Date
	--FROM
	--	#alt as a
	--	INNER JOIN (
	--		SELECT pt_no
	--		FROM #alt as b
	--		GROUP BY Pt_No
	--		HAVING COUNT(pt_no) > 1
	--	) as c
	--		ON a.Pt_No = c.pt_no
	--ORDER BY
	--	a.Pt_No,
	--	a.Admit_Date;
	
	
	-- #rev_int_info: necessary information from the Revenue Integrity times with table for referral and resolution data
	DROP TABLE IF EXISTS #rev_int_info;
	WITH CTE AS (
		SELECT DISTINCT
			pt_no,
			pa_smart_date as 'current_referred_date',
			comment_type as 'referred_comment',
			performed_by as 'referred_user',
			performed_by_dept as 'referred_dept',
			next_event_date as 'resolved_date',
			next_event as 'resolved_comment',
			next_performed_by as 'resolved_user',
			next_performed_by_dept as 'resolved_dept',
			with_revenue_integrity_number,
			ROW_NUMBER() OVER(PARTITION BY pt_no ORDER BY pa_smart_date, comment_type, performed_by, performed_by_dept,
										next_event_date, next_event, next_performed_by, next_performed_by_dept, with_revenue_integrity_number) as 'row_num'
		FROM
			sms.dbo.c_tableau_revenue_integrity_times_with_tbl as REV
		WHERE
			EXISTS (
				select 1
				from #tracker_accounts as c
				where REV.pt_no = c.Pt_No
			)
	)
	SELECT
		pt_no,
		current_referred_date,
		referred_comment,
		referred_user,
		referred_dept,
		resolved_date,
		resolved_comment,
		resolved_user,
		resolved_dept,
		with_revenue_integrity_number
	INTO #rev_int_info
	FROM
		CTE
	WHERE
		with_revenue_integrity_number = row_num; -- ensures that only the latest referral is pulled in if an account has been referred multiple times
	
	
	-- #joins: Joining ALT, Revenue Integrity, and Payment info
	DROP TABLE IF EXISTS #joins;
	SELECT
		a.*,
		b.current_referred_date,
		b.referred_comment,
		b.referred_user,
		b.referred_dept,
		b.resolved_date,
		--resolved_year_month = CAST(YEAR(b.resolved_date) as VARCHAR) + '-' + CAST(MONTH(b.resolved_date) as VARCHAR),
		b.resolved_comment,
		b.resolved_user,
		b.resolved_dept,
		b.with_revenue_integrity_number,
		c.revenue_integrity_payments,
		payment_indicator = CASE
							WHEN c.revenue_integrity_payments < 0
							THEN 'Payment'
							WHEN c.revenue_integrity_payments > 0
							THEN 'Retraction'
							WHEN c.revenue_integrity_payments IS NULL AND a.Ins1_Balance != 0
							THEN 'Pending'
							ELSE 'No Pay'
							END
	INTO #joins
	FROM
		#alt as a
		LEFT JOIN #rev_int_info as b
			ON a.Pt_No = b.pt_no
		LEFT JOIN (
			SELECT
				pt_no,
				ins_plan,
				SUM(revenue_integrity_payment) as 'revenue_integrity_payments'
			FROM
				sms.dbo.c_tableau_revenue_integrity_payments_tbl
			GROUP BY
				pt_no,
				ins_plan
		) as c
			ON a.Pt_No = c.pt_no
				AND a.Ins1_Cd = c.ins_plan;
	
	
	-- #echo_comments: Account comments for all accounts in the tracker
	DROP TABLE IF EXISTS #echo_comments;
	SELECT
		(CAST(ACTIVE.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(ACTIVE.[PA-PT-NO-SCD-1] AS VARCHAR)) as 'pt_no',
		(CAST(ACTIVE.[PA-SMART-SVC-CD-WOSCD] AS VARCHAR) + CAST(ACTIVE.[PA-SMART-SVC-CD-SCD] AS VARCHAR)) as 'scv_cd',
		ACTIVE.[PA-SMART-SEG-CREATE-DATE] as 'post_date',
		ACTIVE.[PA-SMART-COMMENT] as 'comment'
	INTO #echo_comments
	FROM
		[ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Active].[dbo].[AccountComments] as ACTIVE
	WHERE
		EXISTS (
			select 1
			from #tracker_accounts as b
			where (CAST(ACTIVE.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(ACTIVE.[PA-PT-NO-SCD-1] AS VARCHAR)) = b.Pt_No
		)
	
	UNION
	
	SELECT
		(CAST(ARCHIVE.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(ARCHIVE.[PA-PT-NO-SCD-1] AS VARCHAR)) as 'pt_no',
		(CAST(ARCHIVE.[PA-SMART-SVC-CD-WOSCD] AS VARCHAR) + CAST(ARCHIVE.[PA-SMART-SVC-CD-SCD] AS VARCHAR)) as 'scv_cd',
		ARCHIVE.[PA-SMART-SEG-CREATE-DATE] as 'post_date',
		ARCHIVE.[PA-SMART-COMMENT] as 'comment'
	FROM
		[ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Archive].[dbo].[AccountComments] as ARCHIVE
	WHERE
		EXISTS (
			select 1
			from #tracker_accounts as b
			where (CAST(ARCHIVE.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(ARCHIVE.[PA-PT-NO-SCD-1] AS VARCHAR)) = b.Pt_No
		);
	
	
	-- #next_activity: Adding the next activity code that's placed after Revenue Integrity resolves an account
	DROP TABLE IF EXISTS #next_activity;
	SELECT
		a.Pt_No,
		oa.next_activity_code,
		oa.next_activity_code_desc,
		oa.next_activity_code_post_date,
		oa.next_activity_code_comment
	INTO #next_activity
	FROM
		#joins as a
	OUTER APPLY (
		SELECT TOP 1
			y.[ACTIVITY CD] as 'next_activity_code',
			y.[7M CMNT] as 'next_activity_code_desc',
			x.post_date as 'next_activity_code_post_date',
			x.comment as 'next_activity_code_comment'
		FROM
			#echo_comments as x
			LEFT JOIN sms.dbo.Activity_Codes_with_Svc_Codes as y
				ON SUBSTRING(x.comment,1,4) = y.[ACTIVITY CD]
		WHERE
			SUBSTRING(x.comment,5,1) = ' '
			AND y.[ACTIVITY CD] IS NOT NULL
			AND y.[7M CMNT] IS NOT NULL
			AND x.post_date > a.resolved_date
			AND x.pt_no = a.Pt_No
		GROUP BY
			x.pt_no,
			x.post_date,
			x.comment,
			y.[ACTIVITY CD],
			y.[7M CMNT]
	) as oa;
	
	
	-- #joins2: joining the next activity data for each account and the total hard denial amount
	DROP TABLE IF EXISTS #joins2;
	SELECT
		a.*,
		b.next_activity_code,
		b.next_activity_code_desc,
		b.next_activity_code_post_date,
		b.next_activity_code_comment,
		c.hard_denial_amt
	INTO #joins2
	FROM
		#joins as a
		LEFT JOIN #next_activity as b
			ON a.Pt_No = b.pt_no
		LEFT JOIN (
			SELECT
				[PA-PT-NO],
				sum([PA-DTL-CHGS]) as 'hard_denial_amt'
			FROM
				sms.dbo.Denied_Encounter_Details
			GROUP BY
				[PA-PT-NO]
		) as c
			ON a.Pt_No = c.[PA-PT-NO];
	

	-- Create and populate dbo.c_tableau_rirv_tracker_tbl
	CREATE TABLE dbo.c_tableau_rirv_tracker_tbl (
		pk INT IDENTITY(1, 1) NOT NULL PRIMARY KEY,
		Pt_No VARCHAR(255),
		MRN VARCHAR(255),
		Pt_Name VARCHAR(255),
		Acct_Type VARCHAR(255),
		Pt_Type VARCHAR(255),
		Pt_Type_Desc VARCHAR(255),
		Hosp_Svc VARCHAR(255),
		Hosp_Svc_Description VARCHAR(255),
		Ins1_Cd VARCHAR(255),
		Ins1_Desc VARCHAR(255),
		Ins1_Balance MONEY,
		payer_organization VARCHAR(255),
		product_class VARCHAR(255),
		Admit_Date DATETIME,
		Dsch_Date DATETIME,
		Unit_No VARCHAR(255),
		Unit_Date DATETIME,
		Tot_Chgs MONEY,
		Expected_Payment MONEY,
		Tot_Pay_Amt MONEY,
		Balance MONEY,
		SP_RunDateTime DATETIME,
		current_referred_date DATE,
		referred_comment VARCHAR(255),
		referred_user VARCHAR(255),
		referred_dept VARCHAR(255),
		resolved_date DATE,
		resolved_comment VARCHAR(255),
		resolved_user VARCHAR(255),
		resolved_dept VARCHAR(255),				
		with_revenue_integrity_number INT,
		revenue_integrity_payments MONEY,
		payment_indicator VARCHAR(255),
		next_activity_code VARCHAR(255),
		next_activity_code_desc VARCHAR(255),
		next_activity_code_post_date DATETIME,
		next_activity_code_comment VARCHAR(255),
		hard_denial_amt MONEY
		);

	INSERT INTO dbo.c_tableau_rirv_tracker_tbl (
		Pt_No,
		MRN,
		Pt_Name,
		Acct_Type,
		Pt_Type,
		Pt_Type_Desc,
		Hosp_Svc,
		Hosp_Svc_Description,
		Ins1_Cd,
		Ins1_Desc,
		Ins1_Balance,
		payer_organization,
		product_class,
		Admit_Date,
		Dsch_Date,
		Unit_No,
		Unit_Date,
		Tot_Chgs,
		Expected_Payment,
		Tot_Pay_Amt,
		Balance,
		SP_RunDateTime,
		current_referred_date,
		referred_comment,
		referred_user,
		referred_dept,
		resolved_date,
		resolved_comment,
		resolved_user,
		resolved_dept,
		with_revenue_integrity_number,
		revenue_integrity_payments,
		payment_indicator,
		next_activity_code,
		next_activity_code_desc,
		next_activity_code_post_date,
		next_activity_code_comment,
		hard_denial_amt
		)
	SELECT DISTINCT
		*
	FROM
		#joins2;


END;