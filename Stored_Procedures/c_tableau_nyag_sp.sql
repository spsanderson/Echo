USE [SMS]
GO
/****** Object:  StoredProcedure [dbo].[c_tableau_nyag_sp]    Script Date: 11/27/2024 8:40:54 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Create the stored procedure in the specified schema
ALTER PROCEDURE [dbo].[c_tableau_nyag_sp]
AS
SET ANSI_NULLS ON
SET ANSI_WARNINGS ON
SET QUOTED_IDENTIFIER ON

BEGIN
	SET NOCOUNT ON;
	/************************************************************************
	File: c_tableau_nyag_sp.sql

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
		c_tableau_nyag_*_tbl
		c_tableau_times_with_nyag_tbl

	Functions:
		None

	Authors: Steven P. Sanderson II, MPH
			 Casey Delaney

	Department: Revenue Cycle Management

	Purpose/Description:
		To build the tables necessary for the NY Attorney General Vendor
		Dashboard Report in Tableau

	Revision History:
	Date		Version		Description
	----		----		----
	2023-12-05	v1			Initial Creation
	2024-01-04	v2			Used FC information to get ASSIGNED dates
	2024-02-07	v3			Added NYAG inventory table
	2024-02-08	v4			Added FC to payments table
	2024-04-17	v5			Added logic for ins/patient payments
	2024-04-18	v7			Added logic for IP/OP info in base table
	2024-11-27	v8			Changed inventory from monthly to weekly
	************************************************************************/	
	
	DROP TABLE IF EXISTS dbo.c_tableau_nyag_base_tbl;
	DROP TABLE IF EXISTS dbo.c_tableau_nyag_stats_tbl;
	DROP TABLE IF EXISTS dbo.c_tableau_nyag_all_payments_tbl;
	DROP TABLE IF EXISTS dbo.c_tableau_nyag_payments_tbl;
	DROP TABLE IF EXISTS dbo.c_tableau_times_with_nyag_tbl;
	DROP TABLE IF EXISTS dbo.c_tableau_nyag_inventory_tbl;

	CREATE TABLE dbo.c_tableau_nyag_base_tbl
	(
		c_tableau_nyag_base_tblId INT IDENTITY(1, 1) NOT NULL PRIMARY KEY, -- primary key column
		pt_no VARCHAR(24),
		acct_type VARCHAR(24),
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
	
	
	-- Table to get pt rep numbers from echo active and archive with 'PATIENT REP' in the comment
	DROP TABLE IF EXISTS #PTRep_tbl;
	
	SELECT
		PTRep.pt_no,
		PTRep.pa_smart_date,
		PTRep.pt_rep,
		PTRep.acct_type
	INTO #PTRep_tbl
	FROM (
	SELECT
		(CAST([PA-PT-NO-WOSCD] AS VARCHAR) + CAST([PA-PT-NO-SCD-1] AS VARCHAR)) AS [pt_no]
		,LAG(CAST([PA-SMART-DATE] AS DATE),1) OVER (PARTITION BY [PA-PT-NO-WOSCD] ORDER BY CAST([PA-SMART-DATE] AS DATE)) AS [pa_smart_date]
		,SUBSTRING([PA-SMART-COMMENT], PATINDEX('%[0-9][0-9][0-9]%', [PA-SMART-COMMENT]), 3) AS [pt_rep]
		,[PA-ACCT-TYPE] as [acct_type]	
	FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Archive].[dbo].[AccountComments]
	WHERE [PA-SMART-COMMENT] like '%PATIENT REP%'
	
	UNION
	
	SELECT
		(CAST([PA-PT-NO-WOSCD] AS VARCHAR) + CAST([PA-PT-NO-SCD-1] AS VARCHAR)) AS [pt_no]
		,LAG(CAST([PA-SMART-DATE] AS DATE),1) OVER (PARTITION BY [PA-PT-NO-WOSCD] ORDER BY CAST([PA-SMART-DATE] AS DATE)) AS [pa_smart_date]
		,SUBSTRING([PA-SMART-COMMENT], PATINDEX('%[0-9][0-9][0-9]%', [PA-SMART-COMMENT]), 3) AS [pt_rep]
		,[PA-ACCT-TYPE] as [acct_type]	
	FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Active].[dbo].[AccountComments]
	WHERE [PA-SMART-COMMENT] LIKE '%PATIENT REP%'
	) AS PTRep;

	-- Table of the records to exclude; Drop the records if the only pt_rep on an account is 000
	DROP TABLE IF EXISTS #Exclude_tbl;
	
	SELECT
	    pt_no INTO #Exclude_tbl
	FROM
	    #PTRep_tbl
	GROUP BY
	    pt_no
	HAVING
	    COUNT(DISTINCT pt_rep) = 1
	    AND MAX(pt_rep) = '000';


	-- Drop excluded accounts from above from the first temp table created
	DELETE t1
	FROM #PTRep_tbl t1
	JOIN #Exclude_tbl t2 ON t1.pt_no = t2.pt_no;
	
	
	-- Drop the 000 pt_rep records from above
	DELETE FROM
	    #PTRep_tbl 
	WHERE
	    pt_rep NOT IN ('720',
		'721',
		'722',
		'723',
		'724',
		'730',
		'731',
		'732',
		'733',
		'734',
		'740',
		'741',
		'742',
		'743',
		'744',
		'750',
		'751',
		'752',
		'753',
		'754',
		'760',
		'770',
		'771',
		'772',
		'773',
		'774');


	-- Modify the PTRep table to add columns for pt_rep_description and system_process
	---- pt_rep_description: descriptions come from Build Outline Ver 20 in Cerner Manuals folder in RCA
	DROP TABLE IF EXISTS #PTRepFinal_tbl;
	
	SELECT
	    pt_no,
	    pa_smart_date,
	    pt_rep,
	    pt_rep_description = CASE
			WHEN pt_rep = '720' THEN 'NEW PLACEMENT'
			WHEN pt_rep = '721' THEN 'ASSIGNED'
			WHEN pt_rep = '722' THEN 'CLOSED'
			WHEN pt_rep = '723' THEN 'REASSIGNED'
			WHEN pt_rep = '724' THEN 'JUDGEMENT'
			WHEN pt_rep = '730' THEN 'NEW PLACEMENT'
			WHEN pt_rep = '731' THEN 'ASSIGNED'
			WHEN pt_rep = '732' THEN 'CLOSED'
			WHEN pt_rep = '733' THEN 'REASSIGNED'
			WHEN pt_rep = '734' THEN 'JUDGEMENT'
			WHEN pt_rep = '740' THEN 'NEW PLACEMENT'
			WHEN pt_rep = '741' THEN 'ASSIGNED'
			WHEN pt_rep = '742' THEN 'CLOSED'
			WHEN pt_rep = '743' THEN 'REASSIGNED'
			WHEN pt_rep = '744' THEN 'JUDGEMENT'
			WHEN pt_rep = '750' THEN 'NEW PLACEMENT'
			WHEN pt_rep = '751' THEN 'ASSIGNED'
			WHEN pt_rep = '752' THEN 'CLOSED'
			WHEN pt_rep = '753' THEN 'REASSIGNED'
			WHEN pt_rep = '754' THEN 'JUDGEMENT'
			WHEN pt_rep = '760' THEN 'NEW PLACEMENT'
			WHEN pt_rep = '770' THEN 'NEW PLACEMENT'
			WHEN pt_rep = '771' THEN 'ASSIGNED'
			WHEN pt_rep = '772' THEN 'CLOSED'
			WHEN pt_rep = '773' THEN 'REASSIGNED'
			WHEN pt_rep = '774' THEN 'JUDGEMENT'
	    END,
	    system_process = 'RPM',
		acct_type INTO #PTRepFinal_tbl
	FROM
	    #PTREp_tbl;


	-- Comment codes table (A)
	DROP TABLE IF EXISTS #CommentCodes_A_tbl;
	
	SELECT
		A.pt_no,
		A.pa_smart_date,
		A.pt_rep,
		A.pt_rep_description,
		A.svc_code,
		A.acct_type
	INTO #CommentCodes_A_tbl
	FROM (
		SELECT
			(CAST([PA-PT-NO-WOSCD] AS VARCHAR) + CAST([PA-PT-NO-SCD-1] AS VARCHAR) ) AS [pt_no],
			[pa_smart_date] = [PA-SMART-DATE],
			[pt_rep] = CASE 
				WHEN (CAST([PA-SMART-SVC-CD-WOSCD] AS VARCHAR) + CAST([PA-SMART-SVC-CD-SCD] AS VARCHAR)) IN ('3004','3012','3020','3038','3046','3053','3061','3079','3087','3095','3103','3111','3129','3137','3509','3517','3525') THEN '722'
			END,
			[pt_rep_description] = CASE 
				WHEN (CAST([PA-SMART-SVC-CD-WOSCD] AS VARCHAR) + CAST([PA-SMART-SVC-CD-SCD] AS VARCHAR)) IN ('3004','3012','3020','3038','3046','3053','3061','3079','3087','3095','3103','3111','3129','3137','3509','3517','3525') THEN 'CLOSED'
			END,
			(CAST([PA-SMART-SVC-CD-WOSCD] AS VARCHAR) + CAST([PA-SMART-SVC-CD-SCD] AS VARCHAR)) AS [svc_code],
			[PA-ACCT-TYPE] as [acct_type]
		FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Active].[dbo].[AccountComments]
		WHERE (CAST([PA-SMART-SVC-CD-WOSCD] AS VARCHAR) + CAST([PA-SMART-SVC-CD-SCD] AS VARCHAR)) IN ('3004','3012','3020','3038','3046','3053','3061','3079','3087','3095','3103','3111','3129','3137','3509','3517','3525')
	
		UNION
	
		SELECT
			(CAST([PA-PT-NO-WOSCD] AS VARCHAR) + CAST([PA-PT-NO-SCD-1] AS VARCHAR) ) AS [pt_no],
			[pa_smart_date] = [PA-SMART-DATE],
			[pt_rep] = CASE 
				WHEN (CAST([PA-SMART-SVC-CD-WOSCD] AS VARCHAR) + CAST([PA-SMART-SVC-CD-SCD] AS VARCHAR)) IN ('3004','3012','3020','3038','3046','3053','3061','3079','3087','3095','3103','3111','3129','3137','3509','3517','3525') THEN '722'
			END,
			[pt_rep_description] = CASE 
				WHEN (CAST([PA-SMART-SVC-CD-WOSCD] AS VARCHAR) + CAST([PA-SMART-SVC-CD-SCD] AS VARCHAR)) IN ('3004','3012','3020','3038','3046','3053','3061','3079','3087','3095','3103','3111','3129','3137','3509','3517','3525') THEN 'CLOSED'
			END,
			(CAST([PA-SMART-SVC-CD-WOSCD] AS VARCHAR) + CAST([PA-SMART-SVC-CD-SCD] AS VARCHAR)) AS [svc_code],
			[PA-ACCT-TYPE] as [acct_type]
		FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Archive].[dbo].[AccountComments]
		WHERE (CAST([PA-SMART-SVC-CD-WOSCD] AS VARCHAR) + CAST([PA-SMART-SVC-CD-SCD] AS VARCHAR)) IN ('3004','3012','3020','3038','3046','3053','3061','3079','3087','3095','3103','3111','3129','3137','3509','3517','3525')
	) AS A;


	-- Comments code table (B)
	DROP TABLE IF EXISTS #CommentCodes_B_tbl;
	
	CREATE TABLE #CommentCodes_B_tbl
	(
		service_code VARCHAR(24),
		system_process VARCHAR(128)
	);
	
	INSERT INTO #CommentCodes_B_tbl (service_code, system_process)
	VALUES 
	('3004', 'CLOSED NO $ DUE DOC SUBMITED'),
	('3012', 'PRESUMED SATISFIED CPLR211'),
	('3020', 'DEBT DISCHARGED IN BANKRUPTCY'),
	('3038', 'DECEASED - NO ESTATE'),
	('3046', 'LOW BALANCE OBLIGOR'),
	('3053', 'NO MONEY/DEBT DUE'),
	('3061', 'PAID IN FULL'),
	('3079', 'DECEASED NO ESTATE/RELATIVE'),
	('3087', 'DECEASED, ESTATE INSOLVENT'),
	('3095', 'SETTLED/COMPROMISED'),
	('3103', 'STATUTE OF LIMITATIONS EXPIRED'),
	('3111', 'UNABLE TO LOCATE OBLIGOR'),
	('3129', 'DECEASED - SLSC'),
	('3137', 'DECEASED - UNDER THRESHOLD'),
	('3509', 'RECALLED BY CLIENT'),
	('3517', 'REFERRED IN ERROR'),
	('3525', 'RETURNED TO CLIENT');


	-- Merge the two comments code tables
	DROP TABLE IF EXISTS #CommentCodesFinal_tbl;
	
	SELECT
	    CCA.pt_no,
		CCA.pa_smart_date,
		CCA.pt_rep,
		CCA.pt_rep_description,
		CCA.acct_type,
	    CCB.system_process INTO #CommentCodesFinal_tbl
	FROM
	    #CommentCodes_A_tbl AS CCA LEFT JOIN #CommentCodes_B_tbl AS CCB ON CCA.svc_code = CCB.service_code;


	-- Get the most recent PT Rep and the Last PT Rep Change
	DROP TABLE IF EXISTS #ALTRep_tbl;
	
	SELECT
		pt_no,
		pa_smart_date = [Last Date REP Changed],
		pt_rep = Pt_Representative,
		pt_rep_description = CASE
			WHEN Pt_Representative = '720' THEN 'NEW PLACEMENT'
			WHEN Pt_Representative = '721' THEN 'ASSIGNED'
			WHEN Pt_Representative = '722' THEN 'CLOSED'
			WHEN Pt_Representative = '723' THEN 'REASSIGNED'
			WHEN Pt_Representative = '724' THEN 'JUDGEMENT'
			WHEN Pt_Representative = '730' THEN 'NEW PLACEMENT'
			WHEN Pt_Representative = '731' THEN 'ASSIGNED'
			WHEN Pt_Representative = '732' THEN 'CLOSED'
			WHEN Pt_Representative = '733' THEN 'REASSIGNED'
			WHEN Pt_Representative = '734' THEN 'JUDGEMENT'
			WHEN Pt_Representative = '740' THEN 'NEW PLACEMENT'
			WHEN Pt_Representative = '741' THEN 'ASSIGNED'
			WHEN Pt_Representative = '742' THEN 'CLOSED'
			WHEN Pt_Representative = '743' THEN 'REASSIGNED'
			WHEN Pt_Representative = '744' THEN 'JUDGEMENT'
			WHEN Pt_Representative = '750' THEN 'NEW PLACEMENT'
			WHEN Pt_Representative = '751' THEN 'ASSIGNED'
			WHEN Pt_Representative = '752' THEN 'CLOSED'
			WHEN Pt_Representative = '753' THEN 'REASSIGNED'
			WHEN Pt_Representative = '754' THEN 'JUDGEMENT'
			WHEN Pt_Representative = '760' THEN 'NEW PLACEMENT'
			WHEN Pt_Representative = '770' THEN 'NEW PLACEMENT'
			WHEN Pt_Representative = '771' THEN 'ASSIGNED'
			WHEN Pt_Representative = '772' THEN 'CLOSED'
			WHEN Pt_Representative = '773' THEN 'REASSIGNED'
			WHEN Pt_Representative = '774' THEN 'JUDGEMENT'
			WHEN Pt_Representative = '   ' THEN 'NO REP ASSIGNED'
		END,
		system_process = 'RPM',
		acct_type
	INTO #ALTRep_tbl
	FROM SMS.DBO.Pt_Accounting_Reporting_ALT
	WHERE Pt_Representative IN ('720',
		'721',
		'722',
		'723',
		'724',
		'730',
		'731',
		'732',
		'733',
		'734',
		'740',
		'741',
		'742',
		'743',
		'744',
		'750',
		'751',
		'752',
		'753',
		'754',
		'760',
		'770',
		'771',
		'772',
		'773',
		'774',
		'   ')
		AND [Last Date REP Changed] IS NOT NULL
		AND (
			EXISTS (
				SELECT 1
				FROM #PTRepFinal_tbl AS Z
				WHERE Z.pt_no = Pt_No
			)
			OR EXISTS (
				SELECT 1
				FROM #CommentCodesFinal_tbl AS X
				WHERE X.pt_no = pt_no
			)
		);
	
	/* none of the above temp tables are chronologically ordered */

	DROP TABLE IF EXISTS #FC_1;

	SELECT fc.*
	INTO #FC_1
	FROM (
		SELECT
			CAST([PA-PT-NO-WOSCD] AS VARCHAR) + CAST([PA-PT-NO-SCD-1] AS VARCHAR) AS [pt_no],
			[PA-DTL-FC] AS [fc],
			CAST([PA-DTL-DATE] AS DATE) AS [fc_date],
			[PA-ACCT-TYPE] as [acct_type]
		FROM
			[ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Active].[dbo].[DetailInformation] AS a
		WHERE exists (
			SELECT 1
			FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Active].[dbo].[DetailInformation] AS z
			WHERE CAST(z.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(z.[PA-PT-NO-SCD-1] AS VARCHAR) = CAST(a.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(a.[PA-PT-NO-SCD-1] AS VARCHAR)
			and z.[pa-dtl-fc] in ('2','4','6','8')
		)
		GROUP BY 
			CAST([PA-PT-NO-WOSCD] AS VARCHAR) + CAST([PA-PT-NO-SCD-1] AS VARCHAR),
			[PA-DTL-FC],
			[PA-DTL-DATE],
			[PA-ACCT-TYPE]
	
		UNION ALL
	
		SELECT
			CAST([PA-PT-NO-WOSCD] AS VARCHAR) + CAST([PA-PT-NO-SCD-1] AS VARCHAR) AS [pt_no],
			[PA-DTL-FC] AS [fc],
			CAST([PA-DTL-DATE] AS DATE) AS [fc_date],
			[PA-ACCT-TYPE] as [acct_type]
		FROM
			[ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Active].[dbo].[DetailInformation] AS a
		WHERE exists (
			SELECT 1
			FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Archive].[dbo].[DetailInformation] AS z
			WHERE CAST(z.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(z.[PA-PT-NO-SCD-1] AS VARCHAR) = CAST(a.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(a.[PA-PT-NO-SCD-1] AS VARCHAR)
			and z.[pa-dtl-fc] in ('2','4','6','8')
		)
		GROUP BY  
			CAST([PA-PT-NO-WOSCD] AS VARCHAR) + CAST([PA-PT-NO-SCD-1] AS VARCHAR),
			[PA-DTL-FC],
			[PA-DTL-DATE],
			[PA-ACCT-TYPE]
	) AS fc;
	
	DROP TABLE IF EXISTS #FC_2;
	
	SELECT
		pt_no,
		pa_smart_date = fc_date,
		fc,
		pt_rep = CASE
			WHEN fc = '2' then '731'
			WHEN fc = '4' then '741'
			WHEN fc = '6' then '751'
			WHEN fc = '8' then '771'
			ELSE '720'
		END,
		pt_rep_description = CASE
			WHEN fc = '2' then 'ASSIGNED'
			WHEN fc = '4' then 'ASSIGNED'
			WHEN fc = '6' then 'ASSIGNED'
			WHEN fc = '8' then 'ASSIGNED'
			ELSE 'NEW PLACEMENT'
		END,		
		system_process = 'RPM',
		acct_type
	INTO #FC_2
	FROM
		#FC_1;

	-- Create a base table that gives the event number sequence
	DROP TABLE IF EXISTS #Base_tbl;
	
	SELECT
		A.pt_no,
		A.pa_smart_date,
		A.pt_rep,
		A.pt_rep_description,
		A.system_process,
		A.acct_type
	INTO #Base_tbl
	FROM (
		SELECT
			pt_no,
			pa_smart_date,
			pt_rep,
			pt_rep_description,
			system_process,
			acct_type
		FROM #PTRepFinal_tbl
	
		UNION ALL
	
		SELECT
			pt_no,
			pa_smart_date,
			pt_rep,
			pt_rep_description,
			system_process,
			acct_type
		FROM #CommentCodesFinal_tbl
	
		UNION ALL
	
		SELECT
			pt_no,
			pa_smart_date,
			pt_rep,
			pt_rep_description,
			system_process,
			acct_type
		FROM #ALTRep_tbl

		UNION ALL

		SELECT
			pt_no,
			pa_smart_date,
			pt_rep,
			pt_rep_description,
			system_process,
			acct_type
		FROM #FC_2
	) AS A;
	
	
	-- Make sequence table
	DROP TABLE IF EXISTS #SEQ_tbl;
	
	SELECT
		pt_no,
		CAST(pa_smart_date AS DATE) AS pa_smart_date,
		pt_rep,
		pt_rep_description,
		system_process,
		acct_type,
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
	
	SELECT pt_no INTO #ExcludeB_tbl
	FROM #SEQ_tbl
	GROUP BY pt_no
	HAVING
	    COUNT(DISTINCT pt_rep) = 1
	    AND (
	        MAX(pt_rep) = '000'
	        OR MAX(pt_rep) = '   '
	    );
	
	
	-- Drop exclusions again that may stem from getting pt_rep from ALT table
	DELETE T1
	FROM #SEQ_tbl T1
	JOIN #ExcludeB_tbl T2 on t1.pt_no = t2.pt_no;


	-- Make event Delete Flag as we do not want similar events on the same day to show
	-- For example we don't need to see both an acknowledgement and RPM action that occurred on the same day
	DROP TABLE IF EXISTS #DuplicateEvents_tbl;
	
	SELECT
		pt_no,
		pa_smart_date,
		pt_rep,
		pt_rep_description,
		system_process,
		acct_type,
		next_event_date,
		next_event,
		next_event_description,
		next_event_system_process,
		days_until_next_event,
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


	-- Put the data into the NYAG base table
	INSERT INTO dbo.c_tableau_nyag_base_tbl (
		pt_no,
		acct_type,
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
	SELECT
		pt_no,
		acct_type = CASE
						WHEN acct_type in ('IP','1','2','4','8')
							THEN 'IP' -- 1=IP; 2=A/R; 4=I/P BAD DEBT; 8=I/P HISTORIC
						ELSE 'OP' -- 0=OP; 6=OP BAD DEBT; 7=OP HISTORIC 
					END,
		pa_smart_date,
		pt_rep,
		pt_rep_description,
		system_process,
		event_number = ROW_NUMBER() OVER(
                     PARTITION BY PT_NO
                     ORDER BY PA_SMART_DATE, 
                     CASE WHEN next_event_date IS NULL THEN 1 ELSE 0 END, 
                     system_process
              ),
		next_event_date,
		next_event,
		next_event_description,
		next_event_system_process,
		days_until_next_event
	FROM #DuplicateEvents_tbl;

	/*
	----------

	Get the balance before and after an account is with NYAG
	
	----------
	*/
	
	-- Create a new table called 'c_tableau_times_with_nyag_tbl' in schema 'dbo'

	-- Create the table in the specified schema
	CREATE TABLE dbo.c_tableau_times_with_nyag_tbl (
		c_tableau_times_with_nyag_tblId INT IDENTITY(1, 1) NOT NULL PRIMARY KEY, -- primary key column
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
				[with_vendor_flag] = CASE WHEN A.pt_rep_description = 'ASSIGNED' THEN 1 ELSE 0 END,
				CAST(LAG(A.pt_rep) OVER(
					PARTITION BY A.pt_no
					ORDER BY A.event_number
					) AS VARCHAR) AS PriorActivityNumber
			FROM dbo.c_tableau_nyag_base_tbl A
			WHERE A.pt_rep IN ('721','722','731','732','741','742','751','752','771','772') -- 'ASSIGNED (WITH NYAG)', 'CLOSED (RETURNED)'
		) FA1
		WHERE FA1.pt_rep <> ISNULL(FA1.PriorActivityNumber, '')
	)

	INSERT INTO dbo.c_tableau_times_with_nyag_tbl (
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
		AND FA2.pt_rep IN ('722','732','742','752','772') -- 'CLOSED (RETURNED)'
	WHERE FA1.pt_rep IN ('721','731','741', '751','771')-- 'ASSIGNED (WITH NYAG)'
	ORDER BY FA1.pt_no, FA1.event_number;

	-- BALANCES BEFORE
	DROP TABLE IF EXISTS #ACCOUNT_BALANCE_BEFORE;
	
	SELECT
	    (CAST([PA-PT-NO-WOSCD] AS VARCHAR) + CAST([PA-PT-NO-SCD-1] AS VARCHAR)) AS pt_no,
	    SUM([PA-DTL-CHG-AMT]) AS balance_before,
	    M.pt_rep,
	    M.pt_rep_description,
	    M.event_number,
	    M.pa_smart_date AS [with_nyag] INTO #ACCOUNT_BALANCE_BEFORE
	FROM
	    [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Active].[dbo].[DetailInformation] D
	    INNER JOIN SMS.DBO.c_tableau_times_with_nyag_tbl AS M ON M.Pt_No = CAST(D.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(D.[PA-PT-NO-SCD-1] AS VARCHAR)
	    --INNER JOIN SMS.DBO.c_tableau_nyag_base_tbl AS M ON M.Pt_No = CAST(D.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(D.[PA-PT-NO-SCD-1] AS VARCHAR)
	WHERE
	    D.[PA-DTL-DATE] <= M.[pa_smart_date]
	    AND M.pt_rep_description = 'ASSIGNED'
	GROUP BY
		(CAST([PA-PT-NO-WOSCD] AS VARCHAR) + CAST([PA-PT-NO-SCD-1] AS VARCHAR)),
	    M.pt_rep,
	    M.pt_rep_description,
	    M.event_number,
	    M.pa_smart_date
	
	UNION
	
	SELECT
	    (CAST([PA-PT-NO-WOSCD] AS VARCHAR) + CAST([PA-PT-NO-SCD-1] AS VARCHAR)) AS pt_no,
	    SUM([PA-DTL-CHG-AMT]) AS balance_before,
	    M.pt_rep,
	    M.pt_rep_description,
	    M.event_number,
	    M.pa_smart_date AS [with_nyag]
	FROM
	    [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Archive].[dbo].[DetailInformation] D
	    INNER JOIN SMS.DBO.c_tableau_times_with_nyag_tbl AS M ON M.Pt_No = CAST(D.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(D.[PA-PT-NO-SCD-1] AS VARCHAR)
	    --INNER JOIN SMS.DBO.c_tableau_nyag_base_tbl AS M ON M.Pt_No = CAST(D.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(D.[PA-PT-NO-SCD-1] AS VARCHAR)
	WHERE
	    D.[PA-DTL-DATE] <= M.[pa_smart_date]
	    AND M.pt_rep_description = 'ASSIGNED'
	GROUP BY
	    (CAST([PA-PT-NO-WOSCD] AS VARCHAR) + CAST([PA-PT-NO-SCD-1] AS VARCHAR)),
	    M.pt_rep,
	    M.pt_rep_description,
	    M.event_number,
	    M.pa_smart_date


	-- BALANCES AFTER
	DROP TABLE IF EXISTS #ACCOUNT_BALANCE_AFTER;
	
	SELECT
	    (CAST([PA-PT-NO-WOSCD] AS VARCHAR) + CAST([PA-PT-NO-SCD-1] AS VARCHAR)) AS pt_no,
	    SUM([PA-DTL-CHG-AMT]) AS balance_after,
	    M.pt_rep,
	    M.pt_rep_description,
	    M.event_number,
	    M.pa_smart_date AS [returned_from_nyag] INTO #ACCOUNT_BALANCE_AFTER
	FROM
	    [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Active].[dbo].[DetailInformation] D
	    INNER JOIN SMS.DBO.c_tableau_times_with_nyag_tbl AS M ON M.Pt_No = CAST(D.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(D.[PA-PT-NO-SCD-1] AS VARCHAR)
	    --INNER JOIN SMS.DBO.c_tableau_nyag_base_tbl AS M ON M.Pt_No = CAST(D.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(D.[PA-PT-NO-SCD-1] AS VARCHAR)
	WHERE
	    D.[PA-DTL-DATE] <= M.[next_event_date]
	    AND M.next_event_description = 'CLOSED'
	GROUP BY
	    (CAST([PA-PT-NO-WOSCD] AS VARCHAR) + CAST([PA-PT-NO-SCD-1] AS VARCHAR)),
	    M.pt_rep,
	    M.pt_rep_description,
	    M.event_number,
	    M.pa_smart_date
	
	UNION
	
	SELECT
	    (CAST([PA-PT-NO-WOSCD] AS VARCHAR) + CAST([PA-PT-NO-SCD-1] AS VARCHAR)) AS pt_no,
	    SUM([PA-DTL-CHG-AMT]) AS balance_after,
	    M.pt_rep,
	    M.pt_rep_description,
	    M.event_number,
	    M.pa_smart_date AS [returned_from_nyag]
	FROM
	    [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Archive].[dbo].[DetailInformation] D
	    INNER JOIN SMS.DBO.c_tableau_times_with_nyag_tbl AS M ON M.Pt_No = CAST(D.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(D.[PA-PT-NO-SCD-1] AS VARCHAR)
	    --INNER JOIN SMS.DBO.c_tableau_nyag_base_tbl AS M ON M.Pt_No = CAST(D.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(D.[PA-PT-NO-SCD-1] AS VARCHAR)
	WHERE
	    D.[PA-DTL-DATE] <= M.[next_event_date]
	    AND M.next_event_description = 'CLOSED'
	GROUP BY
	    (CAST([PA-PT-NO-WOSCD] AS VARCHAR) + CAST([PA-PT-NO-SCD-1] AS VARCHAR)),
	    M.pt_rep,
	    M.pt_rep_description,
	    M.event_number,
	    M.pa_smart_date


	-- DROP DUPLICATE BEFORE RECORDS
	DROP TABLE IF EXISTS #TEMP_BEFORE_BAL;
	
	SELECT
	    pt_no,
	    pt_rep,
	    pt_rep_description,
	    with_nyag,
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
	
	SELECT
	    pt_no,
	    pt_rep,
	    pt_rep_description,
	    returned_from_nyag,
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


	-- Combine before and after balance temps
	DROP TABLE IF EXISTS #BALANCE;
	
	SELECT 
		A.pt_no,
		A.pt_rep,
		A.pt_rep_description,
		A.with_nyag,
		A.balance_before,
		B.returned_from_nyag,
		B.balance_after
	INTO #BALANCE
	FROM #TEMP_BEFORE_BAL AS A
    OUTER APPLY (
        SELECT TOP 1 B.returned_from_nyag,
            B.balance_after
        FROM #ACCOUNT_BALANCE_AFTER AS B
        WHERE B.pt_no = A.pt_no
            --AND B.event_number > A.event_number
        ORDER BY B.event_number
    ) AS B
	ORDER BY A.pt_no, A.event_number;


	/*
	Stats table
	*/
	CREATE TABLE dbo.c_tableau_nyag_stats_tbl(
		c_tableau_nyag_stats_tblId INT IDENTITY(1,1) NOT NULL PRIMARY KEY, -- primary key column
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
	
	INSERT INTO dbo.c_tableau_nyag_stats_tbl(
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
		(b.FC + ': ' + b.FC_Description) AS [financial_class],
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
	FROM SMS.DBO.c_tableau_nyag_base_tbl AS A
	INNER JOIN SMS.DBO.Pt_Accounting_Reporting_ALT AS B ON A.PT_NO = B.Pt_No
	LEFT JOIN SMS.DBO.c_tableau_insurance_tbl AS C ON B.Ins1_Cd = C.code
	LEFT JOIN #BALANCE AS BAL ON A.PT_NO = BAL.PT_NO
		AND A.pa_smart_date = BAL.with_nyag;


	/*
	All payments
	*/

	-- Create the table in the specified schema
	CREATE TABLE dbo.c_tableau_nyag_all_payments_tbl
	(
	       c_tableau_nyag_all_payments_tblId INT IDENTITY(1, 1) NOT NULL PRIMARY KEY, -- primary key column
	       pt_no VARCHAR(255) NOT NULL,
	       tot_pay_adj_amt MONEY,
	       pay_cd VARCHAR(255),
	       dtl_type_ind VARCHAR(255),
	       svc_date DATE,
	       post_date DATE,
	       fin_class VARCHAR(255),
		   payer_type VARCHAR(255)
	);
	
	INSERT INTO dbo.c_tableau_nyag_all_payments_tbl (pt_no, tot_pay_adj_amt, pay_cd, dtl_type_ind, svc_date, post_date, fin_class, payer_type)
		SELECT CAST([pa-pt-no-woscd] AS VARCHAR) + CAST([pa-pt-no-scd-1] AS VARCHAR) AS 'Pt_No',
		       [pa-dtl-chg-amt] AS [tot_pay_adj_amt],
		       [PA-DTL-SVC-CD-WOSCD] AS [pay_cd],
		       [PA-DTL-TYPE-IND] AS [dtl_type_ind],
		       CAST([PA-DTL-DATE] AS DATE) AS [svc_date],
		       CAST([pa-dtl-post-date] AS DATE) AS [post_date],
		       [pa-dtl-fc] AS [fin_class],
			   [payer_type] = CASE
								WHEN [pa-dtl-svc-cd-woscd] IN ('10275','10303','60215')
									THEN 'Patient'
								ELSE 'Insurance'
							END
		FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].Echo_Active.dbo.DetailInformation
		WHERE (
		              [pa-dtl-type-ind] = '1'
		              OR [pa-dtl-svc-cd-woscd] IN ('10275','10303','60320','60215','60110','61265')
		              )
		       AND EXISTS (
		              SELECT 1
		              FROM SMS.dbo.c_tableau_nyag_base_tbl AS Z
		              WHERE (CAST([pa-pt-no-woscd] AS VARCHAR) + CAST([pa-pt-no-scd-1] AS VARCHAR)) = Z.pt_no
		              )
		
		UNION ALL
		
		SELECT CAST([pa-pt-no-woscd] AS VARCHAR) + CAST([pa-pt-no-scd-1] AS VARCHAR) AS 'Pt_No',
		       [pa-dtl-chg-amt] AS [tot_pay_adj_amt],
		       [PA-DTL-SVC-CD-WOSCD] AS [pay_cd],
		       [PA-DTL-TYPE-IND] AS [dtl_type_ind],
		       CAST([PA-DTL-DATE] AS DATE) AS [svc_date],
		       CAST([pa-dtl-post-date] AS DATE) AS [post_date],
		       [pa-dtl-fc] AS [fin_class],
			   [payer_type] = CASE
								WHEN [pa-dtl-svc-cd-woscd] IN ('10275','10303','60215')
									THEN 'Patient'
								ELSE 'Insurance'
							END
		FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].Echo_Archive.dbo.DetailInformation
		WHERE (
		              [pa-dtl-type-ind] = '1'
		              OR [pa-dtl-svc-cd-woscd] IN ('10275','10303','60320','60215','60110','61265')
		              )
		       AND EXISTS (
		              SELECT 1
		              FROM SMS.dbo.c_tableau_nyag_base_tbl AS Z
		              WHERE (CAST([pa-pt-no-woscd] AS VARCHAR) + CAST([pa-pt-no-scd-1] AS VARCHAR)) = Z.pt_no
		              );
	
	
	/*
	Payments while account is with NYAG
	*/

	-- Make sure we are only getting the records of interest for where an account is with NYAG
	DROP TABLE IF EXISTS #WITH_NYAG_TBL
	SELECT *,
		[partion_number] = ROW_NUMBER() OVER (
			PARTITION BY pt_no ORDER BY pt_no,
				event_number
			)
	INTO #WITH_NYAG_TBL
	FROM dbo.c_tableau_nyag_base_tbl
	WHERE pt_rep_description = 'ASSIGNED';
	
	
	CREATE TABLE dbo.c_tableau_nyag_payments_tbl(
		c_tableau_nyag_payments_tblId INT IDENTITY(1,1) NOT NULL PRIMARY KEY, -- primary key column
		pt_no VARCHAR(24),
		nyag_payment DECIMAL(18,2),
		pay_cd VARCHAR(255),
		dtl_type_ind VARCHAR(255),
		svc_date DATE,
		post_date DATE,
		fc VARCHAR(255),
		payer_type VARCHAR(255)
	);
	
	INSERT INTO dbo.c_tableau_nyag_payments_tbl(
		pt_no,
		nyag_payment,
		pay_cd,
		dtl_type_ind,
		svc_date,
		post_date,
		fc,
		payer_type
		)

	SELECT M.PT_NO AS [pt_no],
	              M.[tot_pay_adj_amt] AS [nyag_payment],
	              M.pay_cd,
	              M.dtl_type_ind,
	              M.svc_date,
	              M.post_date,
				  M.fin_class,
				  M.payer_type
	       FROM dbo.c_tableau_nyag_all_payments_tbl M
	       LEFT JOIN #WITH_NYAG_TBL AS k ON m.pt_no = k.pt_no
	       WHERE (
	                     cast(m.post_date AS DATE) BETWEEN k.pa_smart_date
	                           AND k.next_event_date
	                     OR (
	                           cast(m.post_date AS DATE) >= k.pa_smart_date
	                           AND k.next_event_date IS NULL
	                           )
	                     );

	/*
	NYAG Inventory
	*/

	-- Create a new table called 'c_tableau_nyag_inventory_tbl' in schema 'dbo'
	
	-- Create the table in the specified schema
	DROP TABLE IF EXISTS #inventory;

	CREATE TABLE dbo.c_tableau_nyag_inventory_tbl (
		c_tableau_nyag_inventory_tblId INT IDENTITY(1, 1) NOT NULL PRIMARY KEY, -- primary key column
		inventory_date DATE,
		vendor_inventory INT
		);
	
	DECLARE @TODAY AS DATE;
	DECLARE @STARTDATE AS DATE;
	DECLARE @ENDDATE AS DATE;
	
	SET @TODAY = GETDATE();
	SET @STARTDATE = (SELECT EOMONTH(MIN(pa_smart_date)) FROM sms.dbo.c_tableau_times_with_nyag_tbl);
	SET @ENDDATE = (SELECT CONVERT(date,dateadd(d,-(day(getdate())),getdate()),106));
	
	DROP TABLE IF EXISTS #inventory;
	
	WITH dates AS (
	       SELECT @STARTDATE AS dte
	
	       UNION ALL
	
	       SELECT DATEADD(WEEK, 1, dte)
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
	              ) AS [vendor_inventory]
	INTO #inventory
	FROM dates AS A
	LEFT JOIN sms.dbo.c_tableau_times_with_nyag_tbl AS B ON B.pa_smart_date <= DATEADD(WEEK, 1, A.DTE)
	       AND ISNULL(B.next_event_date, GETDATE()) >= A.dte
	WHERE A.dte <= @ENDDATE
	GROUP BY A.dte
	ORDER BY A.dte
	OPTION (MAXRECURSION 0);
	
	-- Put the data into the NYAG inventory table
	INSERT INTO dbo.c_tableau_nyag_inventory_tbl (
		inventory_date,
		vendor_inventory
		)
		SELECT *
		FROM #inventory;

END;