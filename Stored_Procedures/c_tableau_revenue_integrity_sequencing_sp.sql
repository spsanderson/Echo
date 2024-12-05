USE [SMS]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/************************************************************************
File: c_tableau_revenue_integrity_sequencing_sp.sql

Input Parameters:
	None

Tables/Views:
	c_tableau_revenue_integrity_dashboard_tbl

Creates Table/View:
	c_tableau_revenue_integrity_base_tbl
	c_tableau_revenue_integrity_times_with_tbl

Functions:
	None

Author: Steven P. Sanderson II, MPH

Department: Revenue Cycle Management

Purpose/Description
	To build the tables necessary for the Revenue Integrity (Variance) Dashbaord Report in 
	Tableau

Revision History:
Date		Version		Description
----		----		----
2024-04-18	v1			Initial Creation
2024-06-10	v2			Updated [with_revenue_integrity_flag] to get an accurate 'times_with' metric
2024-06-17	v3			Added inventory table
2024-07-25	v4			Changed RIRE activity_type to WITH REV INTEGRITY
						Changed RIAW activity_type to CLOSED
************************************************************************/

ALTER PROCEDURE dbo.c_tableau_revenue_integrity_sequencing_sp
AS
BEGIN
	-- Drop existing tables if they exist
	DROP TABLE IF EXISTS sms.dbo.c_tableau_revenue_integrity_base_tbl;
    DROP TABLE IF EXISTS sms.dbo.c_tableau_revenue_integrity_times_with_tbl;
    DROP TABLE IF EXISTS #DuplicateEvents_tbl;
	DROP TABLE IF EXISTS sms.dbo.c_tableau_revenue_integrity_inventory_tbl;
	DROP TABLE IF EXISTS sms.dbo.c_tableau_revenue_integrity_payments_tbl;

		-- Get data for base sequence table
		WITH cte
		AS (
			-- Select relevant columns and assign a description to letter_type
			SELECT A.pt_no,
				A.pa_ctl_paa_xfer_date,
				A.pa_smart_comment,
				A.pa_smart_date,
				A.letter_type,
				[letter_type_description] = CASE 
					WHEN letter_type IN ('RIRI')
						THEN 'RESOLVED'
					WHEN pa_smart_svc_cd_woscd IN ('3803594')
						THEN 'RESOLVED'
					WHEN letter_type IN ('RIUI')
						THEN 'RESOLVED - SENT IN ERROR'
					WHEN pa_smart_svc_cd_woscd IN ('3803595')
						THEN 'RESOLVED - SENT IN ERROR'
					WHEN letter_type IN ('RIRV')
						THEN 'REFERRED'
					WHEN pa_smart_svc_cd_woscd IN ('3803593')
						THEN 'REFERRED'
					WHEN letter_type IN ('RIRE')
						THEN 'EXPERIMENTAL DENIAL'
					WHEN pa_smart_svc_cd_woscd IN ('3803601')
						THEN 'EXPERIMENTAL DENIAL'
					WHEN letter_type IN ('RIAS')
						THEN 'APPEAL SENT'
					WHEN pa_smart_svc_cd_woscd IN ('3850034')
						THEN 'APPEAL SENT'
					WHEN letter_type IN ('RINA')
						THEN 'CANNOT APPEAL'
					WHEN pa_smart_svc_cd_woscd IN ('3850033')
						THEN 'CANNOT APPEAL'
					WHEN letter_type IN ('RIRF')
						THEN 'INSURANCE REFUND'
					WHEN pa_smart_svc_cd_woscd IN ('3858022')
						THEN 'INSURANCE REFUND'
					WHEN letter_type IN ('RIAW')
						THEN 'APPEAL WRITTEN'
					END,
				A.user_id_dirty,
				[letter_group] = CASE 
					WHEN letter_type = 'SYSTEM'
						THEN 2
					ELSE 1
					END,
				[activity_type] = CASE 
					WHEN letter_type IN ('RIRI')
						THEN 'CLOSED'
					WHEN pa_smart_svc_cd_woscd IN ('3803594')
						THEN 'CLOSED'
					WHEN letter_type IN ('RIUI')
						THEN 'CLOSED'
					WHEN pa_smart_svc_cd_woscd IN ('3803595')
						THEN 'CLOSED'
					WHEN letter_type IN ('RIRV')
						THEN 'WITH REV INTEGRITY'
					WHEN pa_smart_svc_cd_woscd IN ('3803593')
						THEN 'WITH REV INTEGRITY'
					WHEN letter_type IN ('RIRE')
						THEN 'WITH REV INTEGRITY'
					WHEN pa_smart_svc_cd_woscd IN ('3803601')
						THEN 'WITH REV INTEGRITY'
					WHEN letter_type IN ('RIAS')
						THEN 'CLOSED'
					WHEN pa_smart_svc_cd_woscd IN ('3850034')
						THEN 'CLOSED'
					WHEN letter_type IN ('RINA')
						THEN 'CLOSED'
					WHEN pa_smart_svc_cd_woscd IN ('3850033')
						THEN 'CLOSED'
					WHEN letter_type IN ('RIRF')
						THEN 'WITH REV INTEGRITY'
					WHEN pa_smart_svc_cd_woscd IN ('3858022')
						THEN 'WITH REV INTEGRITY'
					WHEN letter_type IN ('RIAW')
						THEN 'CLOSED'
					END,
				[event_no] = ROW_NUMBER() OVER (
					PARTITION BY A.pt_no ORDER BY A.pa_smart_date,
						A.letter_type
					)
			FROM SMS.DBO.c_tableau_revenue_integrity_dashboard_tbl AS A
			)
		-- Select relevant columns and calculate days_until_next_event and del_flag
		SELECT A.pt_no,
			A.pa_ctl_paa_xfer_date,
			A.pa_smart_comment,
			A.pa_smart_date,
			A.letter_type,
			A.letter_type_description,
			A.user_id_dirty,
			A.letter_group,
			A.activity_type,
			B.pa_smart_comment AS next_smart_comment,
			B.pa_smart_date AS next_comment_date,
			B.letter_type AS next_letter_type,
			B.letter_type_description AS next_letter_type_description,
			B.user_id_dirty AS next_user_id_dirty,
			B.letter_group AS next_letter_group,
			B.activity_type AS next_activity_type,
			[days_until_next_event] = DATEDIFF(DAY, a.pa_smart_date, b.pa_smart_date),
			[del_flag] = CASE 
				WHEN a.pa_smart_date = b.pa_smart_date
					AND a.letter_type = b.letter_type
					AND A.letter_type_description = B.letter_type_description
					AND (
						a.letter_group = b.letter_group
						OR (
							a.letter_group != b.letter_group
							AND a.letter_type = 'SYSTEM'
							)
						)
					-- ACTIVITY CODE BLOCK IS THE SAME AS PREVIOUS ACTIVITY CODE BLOCK
					OR (
						-- LETTER_TYPE_DESCRIPTION IS THE SAME
						A.letter_type_description = LAG(A.letter_type_description, 2) OVER(PARTITION BY A.PT_NO ORDER BY A.PA_SMART_DATE)
						-- LETTER_TYPE_DESCRIPTION IS EQUAL
						AND A.event_no > LAG(A.EVENT_NO, 2) OVER(PARTITION BY A.PT_NO ORDER BY A.PA_SMART_DATE)
						AND A.letter_type = LAG(A.letter_type, 2) OVER(PARTITION BY A.PT_NO ORDER BY A.PA_SMART_DATE)
						AND A.letter_group = LAG(A.letter_group, 2) OVER(PARTITION BY A.PT_NO ORDER BY A.PA_SMART_DATE)
					)
					THEN 1
				ELSE 0
				END
		INTO #DuplicateEvents_tbl
		FROM cte AS A
		LEFT JOIN cte AS B ON A.pt_no = B.pt_no
			AND A.event_no = B.event_no - 1;

	-- Delete duplicate events with del_flag = 1
	DELETE
	FROM #DuplicateEvents_tbl
	WHERE del_flag = 1;

	-- Create Base sequencing table and insert records
	CREATE TABLE sms.dbo.c_tableau_revenue_integrity_base_tbl (
		c_tableau_kopp_base_tblId INT IDENTITY(1, 1) NOT NULL PRIMARY KEY, -- primary key column
		pt_no VARCHAR(24),
		pa_ctl_paa_xfer_date DATE,
		pa_smart_date DATE,
		pa_smart_comment VARCHAR(100),
		comment_type VARCHAR(20),
		comment_description VARCHAR(30),
		performed_by VARCHAR(30),
		performed_by_dept VARCHAR(100),
		comment_group INT,
		event_status VARCHAR(30),
		event_number INT,
		next_comment_date DATE,
		next_smart_comment VARCHAR(100),
		next_comment_type VARCHAR(20),
		next_comment_description VARCHAR(30),
		next_performed_by VARCHAR(30),
		next_performed_by_dept VARCHAR(100),
		next_comment_group INT,
		next_event_status VARCHAR(30),
		days_until_next_event INT
		);

	-- Insert data into the Base sequencing table
	INSERT INTO sms.dbo.c_tableau_revenue_integrity_base_tbl (
		pt_no,
		pa_ctl_paa_xfer_date,
		pa_smart_date,
		pa_smart_comment,
		comment_type,
		comment_description,
		performed_by,
		performed_by_dept,
		comment_group,
		event_status,
		event_number,
		next_comment_date,
		next_smart_comment,
		next_comment_type,
		next_comment_description,
		next_performed_by,
		next_performed_by_dept,
		next_comment_group,
		next_event_status,
		days_until_next_event
		)
	SELECT pt_no,
		pa_ctl_paa_xfer_date,
		pa_smart_date,
		pa_smart_comment,
		[comment_type] = letter_type,
		[comment_description] = letter_type_description,
		[performed_by] = user_id_dirty,
		[performed_by_dept] = B.USER_DEPT,
		[comment_group] = letter_group,
		[event_status] = A.activity_type,
		[event_number] = ROW_NUMBER() OVER (
			PARTITION BY PT_NO ORDER BY PA_SMART_DATE,
				CASE 
					WHEN NEXT_COMMENT_DATE IS NULL
						THEN 1
					ELSE 0
					END,
				LETTER_GROUP
			),
		next_comment_date,
		next_smart_comment,
		[next_comment_type] = next_letter_type,
		[next_comment_description] = next_letter_type_description,
		[next_performed_by] = next_user_id_dirty,
		[next_performed_by_dept] = c.USER_DEPT,
		[next_comment_group] = next_letter_group,
		[next_event_status] = next_activity_type,
		days_until_next_event
	FROM #DuplicateEvents_tbl AS A
	LEFT JOIN SMS.DBO.revenue_cycle_employee_listing AS B ON A.user_id_dirty = B.[USER_ID]
	LEFT JOIN SMS.DBO.revenue_cycle_employee_listing AS C ON A.next_user_id_dirty = C.[USER_ID];

	-- Create table for times with revenue integrity
	CREATE TABLE sms.dbo.c_tableau_revenue_integrity_times_with_tbl (
		pt_no VARCHAR(24),
		pa_smart_date DATE,
		comment_type VARCHAR(20),
		comment_description VARCHAR(30),
		performed_by VARCHAR(30),
		performed_by_dept VARCHAR(100),
		event_status VARCHAR(30),
		event_number INT,
		next_event_date DATE,
		next_event VARCHAR(20),
		next_event_description VARCHAR(30),
		next_performed_by VARCHAR(30),
		next_performed_by_dept VARCHAR(100),
		next_event_status VARCHAR(30),
		with_revenue_integrity_number INT,
		days_with_revenue_integrity INT
		);

	-- Get the times with revenue integrity data
	WITH CTE_FilteredActivity
	AS (
		SELECT FA1.*,
			ROW_NUMBER() OVER (
				PARTITION BY FA1.pt_no ORDER BY FA1.event_number
				) AS RowNum
		FROM (
			SELECT A.pt_no,
				A.pa_smart_date,
				A.comment_type,
				A.comment_description,
				A.performed_by,
				A.performed_by_dept,
				A.event_status,
				A.event_number,
				[with_revenue_integrity_flag] = CASE 
					WHEN A.event_status = 'WITH REV INTEGRITY'--'OPEN'
						THEN 1
					ELSE 0
					END,
				CAST(LAG(A.comment_type) OVER (
						PARTITION BY A.pt_no ORDER BY A.event_number
						) AS VARCHAR) AS PriorActivity
			FROM sms.dbo.c_tableau_revenue_integrity_base_tbl A
			WHERE A.event_status IN ('WITH REV INTEGRITY', 'CLOSED')
				AND A.comment_group = 1
			) FA1
		WHERE FA1.event_status <> ISNULL(FA1.PriorActivity, '')
		)
	-- Insert data into the times with revenue integrity table
	INSERT INTO sms.dbo.c_tableau_revenue_integrity_times_with_tbl (
		pt_no,
		pa_smart_date,
		comment_type,
		comment_description,
		performed_by,
		performed_by_dept,
		event_status,
		event_number,
		next_event_date,
		next_event,
		next_event_description,
		next_performed_by,
		next_performed_by_dept,
		next_event_status,
		with_revenue_integrity_number,
		days_with_revenue_integrity
		)
	SELECT FA1.pt_no,
		FA1.pa_smart_date,
		FA1.comment_type,
		FA1.comment_description,
		FA1.performed_by,
		FA1.performed_by_dept,
		FA1.event_status,
		FA1.event_number,
		[next_event_date] = FA2.pa_smart_date,
		[next_event] = FA2.comment_type,
		[next_event_description] = FA2.comment_description,
		[next_performed_by] = FA2.performed_by,
		[next_performed_by_dept] = FA2.performed_by_dept,
		[next_event_status] = FA2.event_status,
		[with_revenue_integrity_number] = SUM(FA1.with_revenue_integrity_flag) OVER (PARTITION BY FA1.pt_no),
		[days_with_revenue_integrity] = DATEDIFF(DAY, FA1.pa_smart_date, ISNULL(FA2.pa_smart_date, GETDATE()))
	FROM CTE_FilteredActivity AS FA1
	LEFT JOIN CTE_FilteredActivity AS FA2 ON FA2.pt_no = FA1.pt_no
		AND FA2.RowNum = FA1.RowNum + 1
		AND FA2.event_status = 'CLOSED'
	WHERE FA1.event_status = 'WITH REV INTEGRITY'
	ORDER BY FA1.pt_no,
		FA1.event_number;


	/*
	Rev Integrity Inventory
	*/

	-- Create a new table called 'c_tableau_revenue_integrity_inventory_tbl' in schema 'dbo'
	
	-- Create the table in the specified schema
	CREATE TABLE dbo.c_tableau_revenue_integrity_inventory_tbl (
		c_tableau_rev_integrity_inventory_tblId INT IDENTITY(1, 1) NOT NULL PRIMARY KEY, -- primary key column
		inventory_date DATE,
		rev_integrity_inventory INT
		);
	
	DECLARE @TODAY AS DATE;
	DECLARE @STARTDATE AS DATE;
	DECLARE @ENDDATE AS DATE;
	
	SET @TODAY = GETDATE();
	SET @STARTDATE = (SELECT EOMONTH(MIN(pa_smart_date)) FROM sms.dbo.c_tableau_revenue_integrity_times_with_tbl);
	SET @ENDDATE = (SELECT CONVERT(date,dateadd(d,-(day(getdate())),getdate()),106));
	
	DROP TABLE IF EXISTS #inventory;
	
	WITH dates AS (
		SELECT @STARTDATE AS dte
	
		UNION ALL
	
		SELECT EOMONTH(DATEADD(MONTH, 1, dte))
		FROM dates
		WHERE dte < @ENDDATE
	)
	
	SELECT A.dte AS [inventory_date],
		SUM(
			CASE
				WHEN B.pa_smart_date <= A.DTE
				AND ISNULL(B.next_event_date, GETDATE()) >= A.DTE
					THEN 1
				ELSE 0
				END
			) AS rev_integrity_inventory
	INTO #inventory
	FROM dates AS A
	LEFT JOIN sms.dbo.c_tableau_revenue_integrity_times_with_tbl AS B ON B.pa_smart_date <= DATEADD(MONTH, 1, A.DTE)
		AND ISNULL(B.next_event_date, GETDATE()) >= A.dte
	WHERE A.dte <= @ENDDATE
	GROUP BY A.dte
	ORDER BY A.dte
	OPTION (MAXRECURSION 0);
	
	-- Put the data into the Rev Integrity inventory table
	INSERT INTO dbo.c_tableau_revenue_integrity_inventory_tbl (
		inventory_date,
		rev_integrity_inventory
		)
		SELECT *
		FROM #inventory;

	-- GET ALL PAYMENTS FROM CLOSURE TO NEXT REFERRAL IF REFERRED OR SINCE CLOSURE WITH NO NEXT REFERRAL
	DROP TABLE IF EXISTS #WITH_RI_TBL
	SELECT pt_no,
		event_status,
		pa_smart_date,
		[next_comment_date] = LEAD(next_comment_date, 1) OVER(
			PARTITION BY PT_NO
			ORDER BY PA_SMART_DATE
			)
	INTO #WITH_RI_TBL
	FROM dbo.c_tableau_revenue_integrity_base_tbl
	WHERE event_status = 'CLOSED'
		AND comment_type != 'SYSTEM';

	CREATE TABLE dbo.c_tableau_revenue_integrity_payments_tbl(
		c_tableau_revenue_integrity_payments_tblId INT IDENTITY(1, 1) NOT NULL PRIMARY KEY,
		pt_no VARCHAR(24),
		revenue_integrity_payment DECIMAL(18,2),
		pay_cd VARCHAR(255),
		dtl_type_ind VARCHAR(255),
		ins_plan VARCHAR(10),
		post_date DATE
	);

	INSERT INTO dbo.c_tableau_revenue_integrity_payments_tbl(
		pt_no,
		revenue_integrity_payment,
		pay_cd,
		dtl_type_ind,
		ins_plan,
		post_date
	)
	SELECT M.PT_NO AS [pt_no],
              M.[pa_dtl_chg_amt] AS [revenue_integrity_payment],
              M.pa_dtl_svc_cd,
              M.pa_dtl_type_ind,
			  m.pa_ins_plan,
              M.pa_dtl_post_date
       FROM dbo.c_tableau_revenue_integrity_dashboard_payments_tbl M
       LEFT JOIN #WITH_RI_TBL AS k ON m.pt_no = k.pt_no
       WHERE (
                     cast(m.[pa_dtl_post_date] AS DATE) BETWEEN k.pa_smart_date
                           AND k.next_comment_date
                     OR (
                           cast(m.[pa_dtl_post_date] AS DATE) >= k.pa_smart_date
                           AND k.next_comment_date IS NULL
                           )
                     )
			AND M.pa_dtl_type_ind = '1';
END;
