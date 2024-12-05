USE [SMS]
GO
/****** Object:  StoredProcedure [dbo].[c_tableau_medco_sp]    Script Date: 11/27/2024 8:38:45 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Create the stored procedure in the specified schema
ALTER PROCEDURE [dbo].[c_tableau_medco_sp]
AS
SET ANSI_NULLS ON
SET ANSI_WARNINGS ON
SET QUOTED_IDENTIFIER ON

-- If the c_tableau_medco_base_tbl table does not exist, then begin procedure
-- make sure the other tables are dropped if they exist, which at this point
-- they should not.

BEGIN
	SET NOCOUNT ON;
	/************************************************************************
	File: c_tableau_medco_sp.sql

	Input Parameters:
		None

	Tables/Views:
		echo_active.dbo.accountcomments
		echo_archive.dbo.accountcomments
		echo_active.dbo.detailinformation
		echo_archive.dbo.detailinformation
		sms.dbo.pt_accounting_reporting_alt
		sms.dbo.c_tableau_insurance_tbl
		
	Creates Table/View:
		c_tableau_medco_*_tbl

	Functions:
		None

	Author: Steven P. Sanderson II, MPH
			Mayur Shah

	Department: Revenue Cycle Management

	Purpose/Description
		To build the tables necessary for the Medco Vendor Dashbaord Report in 
		Tableau

	Revision History:
	Date		Version		Description
	----		----		----
	2023-11-21	v1			Initial Creation
	2023-12-11	v2			Added an outer apply to the balance after section
							this can prevent multiple rows from returning if
							they exist and will return only the first one.
	2023-12-15	v3			Change the way payments are collected to ensure
							we only read in ddata for accounts that went to
							medco.  This will prevent us from getting payments
							that are not relevant to the report.
							Changed the way payments are calculated when with
							medco and returned from medco.  This resulted in
							an extra $1 million in payments.
	2023-12-22 v4			Update del_flag logic in #DuplicateEvents_tbl
							Update before and after vendor balance logic
	2024-11-27	v5			Changed inventory from monthly to weekly
	************************************************************************/

	-- Create the table in the specified schema
	DROP TABLE IF EXISTS dbo.c_tableau_medco_base_tbl;
	DROP TABLE IF EXISTS dbo.c_tableau_medco_stats_tbl;
	DROP TABLE IF EXISTS dbo.c_tableau_medco_payments_tbl;

	CREATE TABLE dbo.c_tableau_medco_base_tbl
	(
		c_tableau_medco_base_tblId INT IDENTITY(1, 1) NOT NULL PRIMARY KEY, -- primary key column
		pt_no VARCHAR(24),
		pa_smart_date DATE,
		pt_rep VARCHAR(3),
		pt_rep_description VARCHAR(255),
		system_process VARCHAR(255),
		event_number INT,
		next_event_date DATE,
		next_event VARCHAR(3),
		next_event_description VARCHAR(255),
		next_event_system_process VARCHAR(255),
		days_until_next_event INT
	);

	-- Get pt rep numbers
	DROP TABLE IF EXISTS #PTRep_tbl;

	SELECT A.pt_no,
		A.pa_smart_date,
		A.pt_rep
	INTO #PTRep_tbl
	FROM (
	SELECT (CAST([pa-pt-no-woscd] AS VARCHAR) + CAST([pa-pt-no-scd-1] AS VARCHAR)) AS [pt_no]
		,LAG(CAST([PA-SMART-DATE] AS DATE),1) OVER (PARTITION BY [PA-PT-NO-WOSCD] ORDER BY CAST([PA-SMART-DATE] AS DATE)) AS [pa_smart_date]
		,SUBSTRING([PA-SMART-COMMENT], PATINDEX('%[0-9][0-9][0-9]%', [PA-SMART-COMMENT]), 3) AS [pt_rep]
	FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].echo_archive.dbo.accountcomments
	WHERE [pa-smart-comment] like '%PATIENT REP%'

	UNION

	SELECT (CAST([pa-pt-no-woscd] AS VARCHAR) + CAST([pa-pt-no-scd-1] AS VARCHAR)) AS [pt_no]
		,LAG(CAST([PA-SMART-DATE] AS DATE),1) OVER (PARTITION BY [PA-PT-NO-WOSCD] ORDER BY CAST([PA-SMART-DATE] AS DATE)) AS [pa_smart_date]
		,SUBSTRING([PA-SMART-COMMENT], PATINDEX('%[0-9][0-9][0-9]%', [PA-SMART-COMMENT]), 3) AS [pt_rep]
	FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].echo_active.dbo.accountcomments
	WHERE [PA-SMART-COMMENT] LIKE '%PATIENT REP%'
	) AS A;

	-- Drop the records if the only pt_rep on an account is 000
	-- Make a table of the records to exclude
	DROP TABLE IF EXISTS #Exclude_tbl;
	SELECT pt_no
	INTO #Exclude_tbl
	FROM #PTRep_tbl
	GROUP BY pt_no
	HAVING COUNT(DISTINCT pt_rep) = 1
		AND MAX(pt_rep) = '000';

	-- Drop excluded Accounts
	DELETE t1
	FROM #PTRep_tbl t1
	JOIN #Exclude_tbl t2 ON t1.pt_no = t2.pt_no;

	-- Drop the 000 pt_rep records from above
	DELETE
	FROM #PTRep_tbl 
	WHERE pt_rep NOT IN ('590','591','592','593');

	-- Modify the PTRep table to add columns for pt_rep_description and system_process
	DROP TABLE IF EXISTS #PTRepFinal_tbl;
	SELECT pt_no,
		pa_smart_date,
		pt_rep,
		pt_rep_description = CASE
		WHEN pt_rep = '590'
			THEN 'PREPARING TO SEND'
		WHEN pt_rep = '591'
			THEN 'WITH MEDCO'
		WHEN pt_rep = '592'
			THEN 'RETURNED'
		WHEN pt_rep = '593'
			THEN 'PREPARING TO SEND'
		END,
		system_process = 'RPM'
	INTO #PTRepFinal_tbl
	FROM #PTREp_tbl;

	-- Make comment codes table
	
	DECLARE @SysTable Table(
	Comment_Code VARCHAR(255),
	System_Process VARCHAR (MAX)
)

	INSERT INTO @SysTable
	VALUES
	('38035895', 'REQ VENDOR TO RETURN OTHER'),
	('38035903', 'REQ VENDOR TO RETURN FOR JOC'),
	('7005', 'MEDCO CLOSED NO VARIANCE'),
	('7013', 'MEDCO CLOSED'),
	('6932', 'MEDCO CLOSED - PT RESP'),
	('6908', 'MEDCO ACKNOWLEDGEMENT - CLIENT REQ RETURN FOR JOC'),
	('6916', 'MEDCO ACKNOWLEDGEMENT - CLIENT REQ RETURN OTHER'),
	('6999', 'ACCOUNT PLACED WITH MEDCO'),
	('6957', 'MEDCO IDENTIFIED VARIANCE'),
	('6973', 'ACCOUNT MANUALLY ASSIGNED TO MEDCO'),
	('6924', 'MEDCO REQUESTING JOC'),
	('6890', 'ACCOUNT REASSIGNED TO MEDCO')


	DROP TABLE IF EXISTS #CommentCodes_tbl;

	SELECT A.pt_no,
		A.pa_smart_date,
		A.pt_rep,
		A.pt_rep_description,
		A.system_process
	INTO #CommentCodes_tbl
	FROM (
		SELECT (CAST([PA-PT-NO-WOSCD] AS VARCHAR) + CAST([PA-PT-NO-SCD-1] AS VARCHAR) ) AS [pt_no],
			[pa_smart_date] = [pa-smart-date],
			[pt_rep] = CASE 
				WHEN (CAST([PA-SMART-SVC-CD-WOSCD] AS VARCHAR) + CAST([PA-SMART-SVC-CD-SCD] AS VARCHAR)) IN ('38035895','38035903','7005','7013','6908','6916','6932','6924') THEN '592'
				WHEN (CAST([PA-SMART-SVC-CD-WOSCD] AS VARCHAR) + CAST([PA-SMART-SVC-CD-SCD] AS VARCHAR)) IN ('6999','6957') THEN '591'
				WHEN (CAST([PA-SMART-SVC-CD-WOSCD] AS VARCHAR) + CAST([PA-SMART-SVC-CD-SCD] AS VARCHAR)) IN ('6973','6890') THEN '593'
				END,
			[pt_rep_description] = CASE 
				WHEN (CAST([PA-SMART-SVC-CD-WOSCD] AS VARCHAR) + CAST([PA-SMART-SVC-CD-SCD] AS VARCHAR)) IN ('38035895','38035903','7005','7013','6908','6932','6916','6924') THEN 'RETURNED'
				WHEN (CAST([PA-SMART-SVC-CD-WOSCD] AS VARCHAR) + CAST([PA-SMART-SVC-CD-SCD] AS VARCHAR)) IN ('6999','6957') THEN 'WITH MEDCO'
				WHEN (CAST([PA-SMART-SVC-CD-WOSCD] AS VARCHAR) + CAST([PA-SMART-SVC-CD-SCD] AS VARCHAR)) IN ('6973','6890') THEN 'PREPARING TO SEND'
				END,
			s.[system_process]
		FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Active].[dbo].[AccountComments]
		left join @SysTable as s on (CAST([PA-SMART-SVC-CD-WOSCD] AS VARCHAR) + CAST([PA-SMART-SVC-CD-SCD] AS VARCHAR)) = s.Comment_Code
		WHERE (cast([PA-SMART-SVC-CD-WOSCD] as varchar) + cast([pa-smart-svc-cd-scd] as varchar)) IN ('38035895', '38035903','6999','6973','7005','6932','6957','7013','6908','6916','6924','6890')

		UNION

		SELECT (CAST([PA-PT-NO-WOSCD] AS VARCHAR) + CAST([PA-PT-NO-SCD-1] AS VARCHAR) ) AS [pt_no],
			[pa_smart_date] = [pa-smart-date],
			[pt_rep] = CASE 
				WHEN (CAST([PA-SMART-SVC-CD-WOSCD] AS VARCHAR) + CAST([PA-SMART-SVC-CD-SCD] AS VARCHAR)) IN ('38035895','38035903','7005','7013','6908','6932','6916','6924') THEN '592'
				WHEN (CAST([PA-SMART-SVC-CD-WOSCD] AS VARCHAR) + CAST([PA-SMART-SVC-CD-SCD] AS VARCHAR)) IN ('6999','6957') THEN '591'
				WHEN (CAST([PA-SMART-SVC-CD-WOSCD] AS VARCHAR) + CAST([PA-SMART-SVC-CD-SCD] AS VARCHAR)) IN ('6973','6890') THEN '593'
				END,
			[pt_rep_description] = CASE 
				WHEN (CAST([PA-SMART-SVC-CD-WOSCD] AS VARCHAR) + CAST([PA-SMART-SVC-CD-SCD] AS VARCHAR)) IN ('38035895','38035903','7005','7013','6908','6932','6916','6924') THEN 'RETURNED'
				WHEN (CAST([PA-SMART-SVC-CD-WOSCD] AS VARCHAR) + CAST([PA-SMART-SVC-CD-SCD] AS VARCHAR)) IN ('6999','6957') THEN 'WITH MEDCO'
				WHEN (CAST([PA-SMART-SVC-CD-WOSCD] AS VARCHAR) + CAST([PA-SMART-SVC-CD-SCD] AS VARCHAR)) IN ('6973','6890') THEN 'PREPARING TO SEND'
				END,
			s.[system_process]
		FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Archive].[dbo].[AccountComments]
		left join @SysTable as s on (CAST([PA-SMART-SVC-CD-WOSCD] AS VARCHAR) + CAST([PA-SMART-SVC-CD-SCD] AS VARCHAR)) = s.Comment_Code
		WHERE (cast([PA-SMART-SVC-CD-WOSCD] as varchar) + cast([pa-smart-svc-cd-scd] as varchar)) IN ('38035895', '38035903','6999','6973','7005','6932','6957','7013','6908','6916','6924','6890')
	) AS A;

	-- Get the most recent PT Rep and Last PT_Rep Change
	DROP TABLE IF EXISTS #ALTRep_tbl;

	SELECT pt_no,
		pa_smart_date = [Last Date REP Changed],
		pt_rep = Pt_Representative,
		pt_rep_description = CASE
			WHEN Pt_Representative = '590'
				THEN 'PREPARING TO SEND'
			WHEN Pt_Representative = '591'
				THEN 'WITH MEDCO'
			WHEN Pt_Representative = '592'
				THEN 'RETURNED'
			WHEN Pt_Representative = '593'
				THEN 'PREPARING TO SEND'
			WHEN Pt_Representative = '   '
				THEN 'NO REP ASSIGNED'
			END,
		system_process = 'RPM'
	INTO #ALTRep_tbl
	FROM SMS.DBO.Pt_Accounting_Reporting_ALT
	WHERE Pt_Representative IN ('590','591','592','593','   ')
		AND [Last Date REP Changed] IS NOT NULL
		AND (
			EXISTS (
				SELECT 1
				FROM #PTRepFinal_tbl AS Z
				WHERE Z.pt_no = Pt_No
			)
			OR EXISTS (
				SELECT 1
				FROM #CommentCodes_tbl AS X
				WHERE X.pt_no = pt_no
			)
		);

	-- Create a base table that gives the event number sequence
	DROP TABLE IF EXISTS #Base_tbl;

	SELECT A.pt_no,
		A.pa_smart_date,
		A.pt_rep,
		A.pt_rep_description,
		A.system_process
	INTO #Base_tbl
	FROM (
		SELECT pt_no,
			pa_smart_date,
			pt_rep,
			pt_rep_description,
			system_process
		FROM #PTRepFinal_tbl

		UNION ALL

		SELECT pt_no,
			pa_smart_date,
			pt_rep,
			pt_rep_description,
			system_process
		FROM #CommentCodes_tbl

		UNION ALL

		SELECT pt_no,
			pa_smart_date,
			pt_rep,
			pt_rep_description,
			system_process
		FROM #ALTRep_tbl
	) AS A;

	-- Make sequence table
	DROP TABLE IF EXISTS #SEQ_tbl;

	SELECT pt_no,
		CAST(pa_smart_date AS date) AS pa_smart_date,
		pt_rep,
		pt_rep_description,
		system_process,
		next_event = LEAD(pt_rep) OVER(PARTITION BY pt_no ORDER BY pa_smart_date),
		next_event_description = LEAD(pt_rep_description) OVER(PARTITION BY pt_no ORDER BY pa_smart_date),
		next_event_system_process = LEAD(system_process) OVER(PARTITION BY pt_no ORDER BY pa_smart_date),
		next_event_date = CAST(LEAD(pa_smart_date) OVER(PARTITION BY pt_no ORDER BY pa_smart_date) AS date),
		days_until_next_event = DATEDIFF(DAY, pa_smart_date, LEAD(pa_smart_date) OVER(PARTITION BY pt_no ORDER BY pa_smart_date))
	INTO #SEQ_tbl
	FROM #Base_tbl;

	-- Drop the records if the only pt_rep on an account is 000
	-- Make a table of the records to exclude
	DROP TABLE IF EXISTS #ExcludeB_tbl;
	SELECT pt_no
	INTO #ExcludeB_tbl
	FROM #SEQ_tbl
	GROUP BY pt_no
	HAVING COUNT(DISTINCT pt_rep) = 1
		AND (
			MAX(pt_rep) = '000'
			OR MAX(pt_rep) = '   '
			);

	-- DROP EXCLUSIONS AGAIN that may stem from getting pt_rep from ALT table
	DELETE T1
	FROM #SEQ_tbl T1
	JOIN #ExcludeB_tbl T2 on t1.pt_no = t2.pt_no;

	-- Make event Delete Flag as we do not want similar events on the same day to show
	-- For example we don't need to see both an acknowledgement and RPM action that occurred
	-- on the same day
	DROP TABLE IF EXISTS #DuplicateEvents_tbl;

	SELECT pt_no,
		pa_smart_date,
		pt_rep,
		pt_rep_description,
		system_process,
		next_event_date,
		next_event,
		next_event_description,
		next_event_system_process,
		days_until_next_event,
		--[del_flag] = CASE
		--	WHEN pa_smart_date = next_event_date
		--		AND pt_rep = next_event
		--		AND pt_rep_description = next_event_description
		--		THEN 1
		--	ELSE 0
		--	END
		[del_flag] = CASE
			WHEN pa_smart_date = next_event_date
				AND pt_rep = next_event
				AND pt_rep_description = next_event_description
				AND (
					system_process = next_event_system_process
					OR (
						system_process != next_event_system_process
						and system_process = 'RPM'
					)
				)
				THEN 1
			ELSE 0
			END
	INTO #DuplicateEvents_tbl
	FROM #SEQ_tbl;

	DELETE
	FROM #DuplicateEvents_tbl
	WHERE del_flag = 1;

	INSERT INTO dbo.c_tableau_medco_base_tbl (
		pt_no,
		pa_smart_date,
		pt_rep,
		pt_rep_description,
		system_process,
		event_number,
		next_event_date,
		next_event,
		next_event_description,
		next_event_system_process,
		days_until_next_event
	)
	SELECT pt_no,
		pa_smart_date,
		pt_rep,
		pt_rep_description,
		system_process,
		event_number = ROW_NUMBER() OVER(
			PARTITION BY PT_NO
			ORDER BY PA_SMART_DATE, SYSTEM_PROCESS
		),
		next_event_date,
		next_event,
		next_event_description,
		next_event_system_process,
		days_until_next_event
	FROM #DuplicateEvents_tbl

	/*
	----------

	Get the balance before and after an account is with medco
	
	----------
	*/

	-- Create a new table called 'c_tableau_times_with_medco_tbl' in schema 'dbo'
	-- Drop the table if it already exists
	IF OBJECT_ID('dbo.c_tableau_times_with_medco_tbl', 'U') IS NOT NULL
		DROP TABLE dbo.c_tableau_times_with_medco_tbl;

	-- Create the table in the specified schema
	CREATE TABLE dbo.c_tableau_times_with_medco_tbl (
		c_tableau_times_with_medco_tblId INT IDENTITY(1, 1) NOT NULL PRIMARY KEY, -- primary key column
		pt_no VARCHAR(255),
		pa_smart_date DATE,
		pt_rep VARCHAR(255),
		pt_rep_description VARCHAR(255),
		system_process VARCHAR(255),
		event_number INT,
		next_event_date DATE,
		next_event VARCHAR(255),
		next_event_description VARCHAR(255),
		with_vendor_number INT,
		times_with_vendor INT,
		days_with_vendor INT
		);

	-- Get the times with vendor table
	WITH CTE_FilteredActivity AS (
		SELECT
			FA1.*,
			ROW_NUMBER() OVER(
				PARTITION BY FA1.pt_no
				ORDER BY FA1.event_number
				) AS RowNum
		FROM (
			SELECT
				A.pt_no,
				A.pa_smart_date,
				A.pt_rep,
				A.pt_rep_description,
				A.system_process,
				A.event_number,
				[with_vendor_flag] = CASE WHEN A.pt_rep_description = 'WITH MEDCO' THEN 1 ELSE 0 END,
				CAST(LAG(A.pt_rep) OVER(
					PARTITION BY A.pt_no
					ORDER BY A.event_number
					) AS VARCHAR) AS PriorActivityNumber
			FROM dbo.c_tableau_medco_base_tbl A
			WHERE A.pt_rep IN ('591', '592') -- 'WITH VENDOR', 'RETURNED'
		) FA1
		WHERE FA1.pt_rep <> ISNULL(FA1.PriorActivityNumber, '')
	)

	INSERT INTO dbo.c_tableau_times_with_medco_tbl (
		pt_no,
		pa_smart_date,
		pt_rep,
		pt_rep_description,
		system_process,
		event_number,
		next_event_date,
		next_event,
		next_event_description,
		with_vendor_number,
		times_with_vendor,
		days_with_vendor
		)
	SELECT
		FA1.pt_no,
		FA1.pa_smart_date,
		FA1.pt_rep, 
		FA1.pt_rep_description,
		FA1.system_process,
		FA1.event_number,
		[next_event_date] = FA2.pa_smart_date,
		[next_event] = FA2.pt_rep, 
		[next_event_description] = FA2.pt_rep_description,
		[with_vendor_number] = SUM(FA1.with_vendor_flag) OVER(
				PARTITION BY FA1.pt_no
				ORDER BY FA1.pa_smart_date
			),
		[times_with_vendor] = SUM(FA1.with_vendor_flag) OVER(PARTITION BY FA1.pt_no),
		[days_with_vendor] = DATEDIFF(day, FA1.pa_smart_date, ISNULL(FA2.pa_smart_date, GETDATE()))
	FROM CTE_FilteredActivity FA1
	LEFT JOIN CTE_FilteredActivity FA2
		ON FA2.pt_no = FA1.pt_no
		AND FA2.RowNum = FA1.RowNum + 1
		AND FA2.pt_rep = '592' -- 'RETURNED'
	WHERE FA1.pt_rep = '591' -- 'WITH VENDOR'
	ORDER BY FA1.pt_no, FA1.event_number;

	-- Now get the balances since we have the dates to compute them by
	-- BALANCES BEFORE AND AFTER
	DROP TABLE IF EXISTS #ACCOUNT_BALANCE_BEFORE;
	SELECT (CAST([pa-pt-no-woscd] AS VARCHAR) + CAST([pa-pt-no-scd-1] AS VARCHAR)) AS 'pt_no', 
		SUM([PA-DTL-CHG-AMT]) AS 'balance_before',
		M.pt_rep,
		M.pt_rep_description,
		M.event_number,
		M.pa_smart_date AS [with_medco]
	INTO #ACCOUNT_BALANCE_BEFORE
	FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Active].[dbo].[DetailInformation] D
	INNER JOIN dbo.c_tableau_times_with_medco_tbl AS M ON M.pt_no = CAST(D.[pa-pt-no-woscd] AS VARCHAR) + CAST(D.[pa-pt-no-scd-1] AS VARCHAR)
	--INNER JOIN DBO.c_tableau_medco_base_tbl AS M ON M.Pt_No = CAST(D.[pa-pt-no-woscd] AS VARCHAR) + CAST(D.[pa-pt-no-scd-1] AS VARCHAR)
	WHERE D.[PA-DTL-DATE] <= M.[pa_smart_date]
		AND M.pt_rep_description = 'WITH medco'
	GROUP BY (CAST([pa-pt-no-woscd] AS VARCHAR) + CAST([pa-pt-no-scd-1] AS VARCHAR)), 
		M.pt_rep,
		M.pt_rep_description,
		M.event_number,
		M.pa_smart_date
	UNION
	SELECT (CAST([pa-pt-no-woscd] AS VARCHAR) + CAST([pa-pt-no-scd-1] AS VARCHAR)) AS 'pt_no', 
		SUM([PA-DTL-CHG-AMT]) AS 'balance_before',
		M.pt_rep,
		M.pt_rep_description,
		M.event_number,
		M.pa_smart_date AS [with_medco]
	FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Archive].[dbo].[DetailInformation] D
	INNER JOIN dbo.c_tableau_times_with_medco_tbl AS M ON M.pt_no = CAST(D.[pa-pt-no-woscd] AS VARCHAR) + CAST(D.[pa-pt-no-scd-1] AS VARCHAR)
	--INNER JOIN DBO.c_tableau_medco_base_tbl AS M ON M.Pt_No = CAST(D.[pa-pt-no-woscd] AS VARCHAR) + CAST(D.[pa-pt-no-scd-1] AS VARCHAR)
	WHERE D.[PA-DTL-DATE] <= M.[pa_smart_date]
		AND M.pt_rep_description = 'WITH medco'
	GROUP BY (CAST([pa-pt-no-woscd] AS VARCHAR) + CAST([pa-pt-no-scd-1] AS VARCHAR)), 
		M.pt_rep,
		M.pt_rep_description,
		M.event_number,
		M.pa_smart_date;

	-- Balance After return from vendor
	DROP TABLE IF EXISTS #ACCOUNT_BALANCE_AFTER;
	SELECT (CAST([pa-pt-no-woscd] AS VARCHAR) + CAST([pa-pt-no-scd-1] AS VARCHAR)) AS 'pt_no', 
		SUM([PA-DTL-CHG-AMT]) AS 'balance_after',
		M.pt_rep,
		M.pt_rep_description,
		M.event_number,
		M.pa_smart_date AS [returned_from_medco]
	INTO #ACCOUNT_BALANCE_AFTER
	FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Active].[dbo].[DetailInformation] D
	INNER JOIN dbo.c_tableau_times_with_medco_tbl AS M ON M.pt_no = CAST(D.[pa-pt-no-woscd] AS VARCHAR) + CAST(D.[pa-pt-no-scd-1] AS VARCHAR)
	--INNER JOIN DBO.c_tableau_medco_base_tbl AS M ON M.Pt_No = CAST(D.[pa-pt-no-woscd] AS VARCHAR) + CAST(D.[pa-pt-no-scd-1] AS VARCHAR)
	WHERE D.[PA-DTL-DATE] <= M.[next_event_date]
		AND M.next_event_description = 'RETURNED'
	GROUP BY (CAST([pa-pt-no-woscd] AS VARCHAR) + CAST([pa-pt-no-scd-1] AS VARCHAR)), 
		M.pt_rep,
		M.pt_rep_description,
		M.event_number,
		M.pa_smart_date
	UNION
	SELECT (CAST([pa-pt-no-woscd] AS VARCHAR) + CAST([pa-pt-no-scd-1] AS VARCHAR)) AS 'pt_no', 
		SUM([PA-DTL-CHG-AMT]) AS 'balance_after',
		M.pt_rep,
		M.pt_rep_description,
		M.event_number,
		M.pa_smart_date AS [returned_from_medco]
	FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Archive].[dbo].[DetailInformation] D
	INNER JOIN dbo.c_tableau_times_with_medco_tbl AS M ON M.pt_no = CAST(D.[pa-pt-no-woscd] AS VARCHAR) + CAST(D.[pa-pt-no-scd-1] AS VARCHAR)
	--INNER JOIN DBO.c_tableau_medco_base_tbl AS M ON M.Pt_No = CAST(D.[pa-pt-no-woscd] AS VARCHAR) + CAST(D.[pa-pt-no-scd-1] AS VARCHAR)
	WHERE D.[PA-DTL-DATE] <= M.[next_event_date]
		AND M.next_event_description = 'RETURNED'
	GROUP BY (CAST([pa-pt-no-woscd] AS VARCHAR) + CAST([pa-pt-no-scd-1] AS VARCHAR)), 
		M.pt_rep,
		M.pt_rep_description,
		M.event_number,
		M.pa_smart_date;

	-- DROP DUPLICATE BEFORE RECORDS
	DROP TABLE IF EXISTS #TEMP_BEFORE_BAL;
	SELECT pt_no,
		pt_rep,
		pt_rep_description,
		with_medco,
		event_number,
		balance_before,
		[dupe_flag] = ROW_NUMBER() OVER(
			PARTITION BY pt_no, 
				pt_rep, 
				pt_rep_description, 
				balance_before 
			ORDER BY event_number
		)
	INTO #TEMP_BEFORE_BAL
	FROM #ACCOUNT_BALANCE_BEFORE;

	DELETE
	FROM #TEMP_BEFORE_BAL
	WHERE dupe_flag != 1;

	-- DROP DUPLICATE AFTER RECORDS
	DROP TABLE IF EXISTS #TEMP_AFTER_BAL;
	SELECT pt_no,
		pt_rep,
		pt_rep_description,
		returned_from_medco,
		event_number,
		balance_after,
		[dupe_flag] = ROW_NUMBER() OVER(
			PARTITION BY pt_no, 
				pt_rep, 
				pt_rep_description, 
				balance_after
			ORDER BY event_number
		)
	INTO #TEMP_AFTER_BAL
	FROM #ACCOUNT_BALANCE_AFTER;

	DELETE
	FROM #TEMP_AFTER_BAL
	WHERE dupe_flag != 1;

	DROP TABLE IF EXISTS #BALANCE;
    SELECT A.pt_no,
        A.pt_rep,
        A.pt_rep_description,
        A.with_medco,
        A.balance_before,
        B.returned_from_medco,
        B.balance_after
    INTO #BALANCE
    FROM #TEMP_BEFORE_BAL AS A
    OUTER APPLY (
        SELECT TOP 1 B.returned_from_medco,
            B.balance_after
        FROM #ACCOUNT_BALANCE_AFTER AS B
        WHERE B.pt_no = A.pt_no
            --AND B.event_number > A.event_number
        ORDER BY B.event_number
    ) AS B
    ORDER BY A.pt_no, A.event_number

	/*
	Stats table
	*/
	CREATE TABLE dbo.c_tableau_medco_stats_tbl(
		c_tableau_medco_stats_tblId INT IDENTITY(1,1) NOT NULL PRIMARY KEY, -- primary key column
		mrn VARCHAR(24),
		pt_no VARCHAR(24),
		insurance_code VARCHAR(24),
		payer_organization VARCHAR(255),
		product_class VARCHAR(255),
		expected_payment DECIMAL(18,2),
		financial_class VARCHAR(255),
		ins_balance DECIMAL(18,2),
		pt_balance DECIMAL(18,2),
		tot_pay_amt DECIMAL(18,2),
		acct_balance DECIMAL(18,2),
		admit_date DATE,
		dsch_date DATE,
		event_date DATE,
		pt_rep_description VARCHAR(255),
		event_number INT,
		system_process VARCHAR(255),
		next_event_description VARCHAR(255),
		next_event_date DATE,
		days_until_next_event INT,
		next_event_system_process VARCHAR(255),
		balance_before DECIMAL(18,2),
		balance_after DECIMAL(18,2)
	);

	INSERT INTO dbo.c_tableau_medco_stats_tbl(
		mrn,
		pt_no,
		insurance_code,
		payer_organization,
		product_class,
		expected_payment,
		financial_class,
		ins_balance,
		pt_balance,
		tot_pay_amt,
		acct_balance,
		admit_date,
		dsch_date,
		event_date,
		pt_rep_description,
		event_number,
		system_process,
		next_event_description,
		next_event_date,
		days_until_next_event,
		next_event_system_process,
		balance_before,
		balance_after
		)
	SELECT B.MRN AS [mrn],	
		A.pt_no,
		B.Ins1_Cd AS [insurance_code],
		c.payer_organization,
		c.product_class,
		b.Expected_Payment AS [expected_payment],
		b.fc AS [financial_class],
		b.Ins_Balance AS [ins_balance],
		b.Pt_Balance AS [pt_balance],
		B.Tot_Pay_Amt AS [tot_pay_amt],
		B.Balance AS [acct_balance],
		CAST(B.Admit_Date AS date) AS [admit_date],
		CAST(B.dsch_date AS date) AS [dsch_date],
		A.pa_smart_date AS [event_date],
		A.pt_rep_description,
		A.event_number,
		A.system_process,
		A.next_event_description,
		A.next_event_date,
		A.days_until_next_event,
		A.next_event_system_process,
		BAL.balance_before,
		BAL.balance_after
	FROM DBO.c_tableau_medco_base_tbl AS A
	INNER JOIN SMS.DBO.Pt_Accounting_Reporting_ALT AS B ON A.PT_NO = B.Pt_No
	LEFT JOIN SMS.DBO.c_tableau_insurance_tbl AS C ON B.Ins1_Cd = C.code
	LEFT JOIN #BALANCE AS BAL ON A.PT_NO = BAL.PT_NO 
		AND A.pa_smart_date = BAL.with_medco

	/*
	Payments while account is with medco
	*/
	IF OBJECT_ID('dbo.c_tableau_medco_all_payments_tbl', 'U') IS NOT NULL
	DROP TABLE dbo.c_tableau_medco_all_payments_tbl;
	-- Create the table in the specified schema
	CREATE TABLE dbo.c_tableau_medco_all_payments_tbl
	(
			c_tableau_medco_all_payments_tblId INT IDENTITY(1, 1) NOT NULL PRIMARY KEY, -- primary key column
			pt_no VARCHAR(255) NOT NULL,
			tot_pay_adj_amt MONEY,
			pay_cd VARCHAR(255),
			dtl_type_ind VARCHAR(255),
			svc_date DATE,
			post_date DATE,
			fin_class VARCHAR(255)
	);

	INSERT INTO dbo.c_tableau_medco_all_payments_tbl (
		pt_no,
		tot_pay_adj_amt,
		pay_cd,
		dtl_type_ind,
		svc_date,
		post_date,
		fin_class
		)
	SELECT CAST([pa-pt-no-woscd] AS VARCHAR) + CAST([pa-pt-no-scd-1] AS VARCHAR) AS 'Pt_No',
		[pa-dtl-chg-amt] AS [tot_pay_adj_amt],
		[PA-DTL-SVC-CD-WOSCD] AS [pay_cd],
		[PA-DTL-TYPE-IND] AS [dtl_type_ind],
		CAST([PA-DTL-DATE] AS DATE) AS [svc_date],
		CAST([pa-dtl-post-date] AS DATE) AS [post_date],
		[pa-dtl-fc] AS [fin_class]
	FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].Echo_Active.dbo.DetailInformation
	WHERE (
			[pa-dtl-type-ind] = '1'
			OR [pa-dtl-svc-cd-woscd] IN ('60320', '60215', '60110', '61265')
			)
		AND CAST([PA-DTL-SVC-CD-WOSCD] AS VARCHAR) + CAST([PA-DTL-SVC-CD-SCD] AS VARCHAR) NOT IN ('102764', '102756', '103044', '103036', '102756', '102756', '102756', '102756', '102756', '102756', '102756', '102756', '102756', '102756', '102764', '102764', '103036', '103044')
		AND EXISTS (
			SELECT 1
			FROM SMS.dbo.c_tableau_medco_base_tbl AS Z
			WHERE (CAST([pa-pt-no-woscd] AS VARCHAR) + CAST([pa-pt-no-scd-1] AS VARCHAR)) = Z.pt_no
			)

	UNION ALL

	SELECT CAST([pa-pt-no-woscd] AS VARCHAR) + CAST([pa-pt-no-scd-1] AS VARCHAR) AS 'Pt_No',
		[pa-dtl-chg-amt] AS [tot_pay_adj_amt],
		[PA-DTL-SVC-CD-WOSCD] AS [pay_cd],
		[PA-DTL-TYPE-IND] AS [dtl_type_ind],
		CAST([PA-DTL-DATE] AS DATE) AS [svc_date],
		CAST([pa-dtl-post-date] AS DATE) AS [post_date],
		[pa-dtl-fc] AS [fin_class]
	FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].Echo_Archive.dbo.DetailInformation
	WHERE (
			[pa-dtl-type-ind] = '1'
			OR [pa-dtl-svc-cd-woscd] IN ('60320', '60215', '60110', '61265')
			)
		AND CAST([PA-DTL-SVC-CD-WOSCD] AS VARCHAR) + CAST([PA-DTL-SVC-CD-SCD] AS VARCHAR) NOT IN ('102764', '102756', '103044', '103036', '102756', '102756', '102756', '102756', '102756', '102756', '102756', '102756', '102756', '102756', '102764', '102764', '103036', '103044')
		AND EXISTS (
			SELECT 1
			FROM SMS.dbo.c_tableau_medco_base_tbl AS Z
			WHERE (CAST([pa-pt-no-woscd] AS VARCHAR) + CAST([pa-pt-no-scd-1] AS VARCHAR)) = Z.pt_no
			);



	-- Make sure we are only getting the records of interest for where an account is with medco
	DROP TABLE IF EXISTS #WITH_medco_TBL
		SELECT *,
			[partion_number] = ROW_NUMBER() OVER (
				PARTITION BY pt_no ORDER BY pt_no,
					event_number
				)
		INTO #WITH_medco_TBL
		FROM dbo.c_tableau_medco_base_tbl
		WHERE pt_rep_description = 'WITH MEDCO';

    CREATE TABLE dbo.c_tableau_medco_payments_tbl(
		c_tableau_medco_payments_tblId INT IDENTITY(1,1) NOT NULL PRIMARY KEY, -- primary key column
		pt_no VARCHAR(24),
		medco_payment DECIMAL(18,2),
		pay_cd VARCHAR(255),
		dtl_type_ind VARCHAR(255),
		svc_date DATE,
		post_date DATE,
		fc VARCHAR(255)
	);

	INSERT INTO dbo.c_tableau_medco_payments_tbl(
		pt_no,
		medco_payment,
		pay_cd,
		dtl_type_ind,
		svc_date,
		post_date,
		fc
		)
	SELECT M.PT_NO AS [pt_no],
              M.[tot_pay_adj_amt] AS [medco_payment],
              M.pay_cd,
              M.dtl_type_ind,
              M.svc_date,
              M.post_date,
			  M.fin_class
       FROM dbo.c_tableau_medco_all_payments_tbl M
       LEFT JOIN #WITH_medco_TBL AS k ON m.pt_no = k.pt_no
       WHERE (
                     cast(m.[svc_date] AS DATE) BETWEEN k.pa_smart_date
                           AND k.next_event_date
                     OR (
                           cast(m.[svc_date] AS DATE) >= k.pa_smart_date
                           AND k.next_event_date IS NULL
                           )
                     )

	IF OBJECT_ID('dbo.c_tableau_medco_inventory_tbl', 'U') IS NOT NULL
		DROP TABLE dbo.c_tableau_medco_inventory_tbl;


	CREATE TABLE dbo.c_tableau_medco_inventory_tbl (
		c_tableau_medco_inventory_tblId INT IDENTITY(1, 1) NOT NULL PRIMARY KEY, -- primary key column
		inventory_date DATE,
		vendor_inventory INT
		);

	DECLARE @TODAY AS DATE;
	DECLARE @STARTDATE AS DATE;
	DECLARE @ENDDATE AS DATE;

	SET @TODAY = GETDATE();
	SET @STARTDATE = (SELECT EOMONTH(MIN(pa_smart_date)) FROM sms.dbo.c_tableau_times_with_medco_tbl);
	SET @ENDDATE = (SELECT EOMONTH(MAX(pa_smart_date)) FROM sms.dbo.c_tableau_times_with_medco_tbl);

	WITH dates AS (
		SELECT @STARTDATE AS dte

		UNION ALL

		SELECT DATEADD(WEEK, 1, dte)
		FROM dates
		WHERE dte < @ENDDATE
	)

	INSERT INTO dbo.c_tableau_medco_inventory_tbl (
		inventory_date,
		vendor_inventory
	)
	SELECT inventory_date = A.dte,
		vendor_inventory = 
			SUM	(
				CASE
                     WHEN B.pa_smart_date <= A.DTE
                           AND ISNULL(B.next_event_date, GETDATE()) >= A.DTE
                           THEN 1
                     ELSE 0
                     END
              )
	FROM dates AS A
	LEFT JOIN sms.dbo.c_tableau_times_with_medco_tbl AS B ON B.pa_smart_date <= DATEADD(WEEK, 1, A.DTE)
       AND ISNULL(B.next_event_date, GETDATE()) >= A.dte
	WHERE A.dte <= @ENDDATE
	GROUP BY A.dte
	ORDER BY A.dte
	OPTION (MAXRECURSION 0);

END;