/*
***********************************************************************
File: productive_capacity_query.sql

Input Parameters:
	None

Tables/Views:
	SMS.dbo.c_remit_most_recent_Carc_Rarc_Combined_tbl
	Swarm.dbo.CW_DTL_productivity
	SWARM.DBO.OAMCOMB
	ECHO_ACTIVE.DBO.COLLECTORWORKSTATION

Creates Table:
	#MOST_RECENT_CARC_RARC_TBL
	#PRODUCTIVITY_TBL
	#OAM_TBL
	#CARC_RARC_PRODUCTIVITY_TBL
	#BASE_POP_TBL
	#COLLECTOR_WORKSTATION_PTNO_TBL
	#PRE_TILE_TBL
	#TILED_TBL
	#STRATIFICATION_TBL
	#FINAL_TBL


Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description:
	This script processes productivity and payment data to generate reports
	on accounts worked by collectors.

Revision History:
Date		Version		Description
----		----		----
2025-06-20	v1			Initial Creation
***********************************************************************
*/

DROP TABLE IF EXISTS #MOST_RECENT_CARC_RARC_TBL;
-- Get most recent CARC/RARC data for the year 2023
-- This table is used to join with productivity data
SELECT DISTINCT PT_NO,
	INS_CD,
	UNIT_NO,
	CHECK_EFT_DATE,
	DATE_OF_SERVICE,
	SERVICE_DATE_THROUGH,
	PAYER_NAME,
	REMARKCODECOMBINED,
	REMARKDESCCOMBINED,
	COMBINED_REMIT_ADJUSTMENT_GROUP_AND_REASON_CODE,
	COMBINED_REMIT_ADJUSTMENT_REASON_DESCRIPTION,
	COMBINED_LINE_ADJUSTMENT_GROUP_AND_REASON_CODE,
	COMBINED_LINE_ADJUSTMENT_REASON_DESCRIPTION,
	CARCCATEGORYCOMBINED,
	CARCSUBCATEGORYCOMBINED
INTO #MOST_RECENT_CARC_RARC_TBL
FROM SMS.dbo.c_remit_most_recent_Carc_Rarc_Combined_tbl
WHERE CHECK_EFT_DATE >= '2023-01-01';

DROP TABLE IF EXISTS #PRODUCTIVITY_TBL;
-- Get productivity data for specific collectors and the most recent report date
-- This table is used to join with CARC/RARC data
SELECT DISTINCT [REPORT DATE],
	[SUPERVISOR ID],
	[SUPERVISOR NAME],
	[RESPONSIBLE COLLECTOR],
	[RC NAME],
	[WORKLIST],
	[WORKLIST NAME],
	[SEQ NO],
	[PATIENT NO],
	[PATIENT NAME],
	[PYR ID],
	[GUAR NO],
	[MED REC NO],
	[FOL AMT],
	[LAST BILL DATE],
	[LAST PAY DATE],
	[RPM/VOF LINE],
	[FOL LVL],
	[FOL TYP],
	[FILE],
	[SVC FAC ID],
	[UNIT NO],
	[UNIT DATE],
	[ERRORS]
INTO #PRODUCTIVITY_TBL
FROM [Swarm].[dbo].[CW_DTL_productivity]
WHERE (
		[RESPONSIBLE COLLECTOR] IN ('nmurro', 'pdinoi', 'abenso')
		OR [Supervisor ID] IN ('nmurro', 'pdinoi', 'abenso')
		)
	AND [Report Date] = (
		SELECT Max([Report Date])
		FROM [swarm].[dbo].[CW_DTL_productivity]
		);

DROP TABLE IF EXISTS #OAM_TBL;
-- Get OAM data for the current week
-- This table is used to join with productivity data
SELECT *
INTO #OAM_TBL
FROM SWARM.DBO.[OAMCOMB ] 
WHERE [Post_Date] >= DATEADD(wk, DATEDIFF(wk, 0, GETDATE()), 0);

DROP TABLE IF EXISTS #CARC_RARC_PRODUCTIVITY_TBL;
-- Join CARC/RARC data with productivity data
-- This table combines the most recent CARC/RARC data with productivity data
SELECT A.PT_NO,
	A.INS_CD,
	A.UNIT_NO,
	A.CHECK_EFT_DATE,
	COUNTDISTINCT_DATE_OF_SERVICE = COUNT(DISTINCT A.DATE_OF_SERVICE),
	CONCAT_DATE_OF_SERVICE = STUFF(
	(
		SELECT ', ' + CAST(Z.DATE_OF_SERVICE AS VARCHAR) AS [text()]
		FROM #MOST_RECENT_CARC_RARC_TBL AS Z
		WHERE Z.PT_NO = A.PT_NO
			AND ISNULL(CAST(Z.UNIT_NO AS varchar), '') = ISNULL(CAST(Z.UNIT_NO AS varchar), '')
			AND Z.INS_CD = A.INS_CD
		ORDER BY Z.PT_NO, ISNULL(CAST(Z.UNIT_NO AS VARCHAR), ''), Z.INS_CD
		FOR XML PATH (''), TYPE
	).value('text()[1]','nvarchar(max)'), 1, 1, ''),
	A.PAYER_NAME,
	A.REMARKCODECOMBINED,
	A.REMARKDESCCOMBINED,
	A.COMBINED_REMIT_ADJUSTMENT_GROUP_AND_REASON_CODE,
	A.COMBINED_REMIT_ADJUSTMENT_REASON_DESCRIPTION,
	A.COMBINED_LINE_ADJUSTMENT_GROUP_AND_REASON_CODE,
	A.COMBINED_LINE_ADJUSTMENT_REASON_DESCRIPTION,
	A.CARCCATEGORYCOMBINED,
	A.CARCSUBCATEGORYCOMBINED,
	B.[Report Date],
	B.[Supervisor ID],
	B.[Supervisor Name],
	B.[RESPONSIBLE COLLECTOR],
	B.[RC Name],
	B.WORKLIST,
	B.[WORKLIST NAME],
	B.[Seq No],
	B.[PATIENT NO],
	B.[PATIENT NAME],
	B.[Pyr ID],
	B.[GUAR NO],
	B.[MED REC NO],
	B.[Fol AMT],
	B.[LAST BILL DATE],
	B.[LAST PAY DATE],
	B.[RPM/VOF Line],
	B.[FOL LVL],
	B.[FOL TYP],
	B.[FILE],
	B.[SVC FAC ID],
	B.[Unit No],
	B.[Unit Date],
	B.ERRORS
INTO #CARC_RARC_PRODUCTIVITY_TBL
FROM #MOST_RECENT_CARC_RARC_TBL AS A
RIGHT JOIN #PRODUCTIVITY_TBL AS B ON A.PT_NO = B.[PATIENT NO]
	AND ISNULL(CAST(A.UNIT_NO AS varchar), '') = ISNULL(CAST(B.[Unit No] AS varchar), '')
	AND A.INS_CD = B.[Pyr ID]
GROUP BY A.PT_NO,
	A.INS_CD,
	A.UNIT_NO,
	A.CHECK_EFT_DATE,
	A.PAYER_NAME,
	A.REMARKCODECOMBINED,
	A.REMARKDESCCOMBINED,
	A.COMBINED_REMIT_ADJUSTMENT_GROUP_AND_REASON_CODE,
	A.COMBINED_REMIT_ADJUSTMENT_REASON_DESCRIPTION,
	A.COMBINED_LINE_ADJUSTMENT_GROUP_AND_REASON_CODE,
	A.COMBINED_LINE_ADJUSTMENT_REASON_DESCRIPTION,
	A.CARCCATEGORYCOMBINED,
	A.CARCSUBCATEGORYCOMBINED,
	B.[Report Date],
	B.[Supervisor ID],
	B.[Supervisor Name],
	B.[RESPONSIBLE COLLECTOR],
	B.[RC Name],
	B.WORKLIST,
	B.[WORKLIST NAME],
	B.[Seq No],
	B.[PATIENT NO],
	B.[PATIENT NAME],
	B.[Pyr ID],
	B.[GUAR NO],
	B.[MED REC NO],
	B.[Fol AMT],
	B.[LAST BILL DATE],
	B.[LAST PAY DATE],
	B.[RPM/VOF Line],
	B.[FOL LVL],
	B.[FOL TYP],
	B.[FILE],
	B.[SVC FAC ID],
	B.[Unit No],
	B.[Unit Date],
	B.ERRORS
;

-- JOIN DATA TO THE OAM_TBL
DROP TABLE IF EXISTS #BASE_POP_TBL;
-- Create a base table that combines CARC/RARC productivity data with OAM data
-- This table is used to prepare data for further processing
SELECT *,
	[ACCOUNT WORKED-TRANSACTION] = DATEDIFF(DAY, B.POST_DATE, GETDATE())
INTO #BASE_POP_TBL
FROM #CARC_RARC_PRODUCTIVITY_TBL AS A
LEFT JOIN #OAM_TBL AS B ON A.[PATIENT NO] = B.[Encounter Number]
	AND A.[RESPONSIBLE COLLECTOR] = B.[User_ID]
	AND ISNULL(CAST(A.[Unit No] AS varchar), '') = ISNULL(CAST(B.Unit AS varchar), '');

-- GET PT NUMBER FROM COLLECTORWORKSTATION
DROP TABLE IF EXISTS #COLLECTOR_WORKSTATION_PTNO_TBL;
-- This table is used to get patient numbers from the COLLECTORWORKSTATION table
-- It combines patient numbers from two columns into one
SELECT [PT_NUM] = CAST([collectorworkstation].[PA-PT-NO-WOSCD] as [varchar]) + CAST([collectorworkstation].[PA-PT-NO-SCD-1] AS [varchar]),
	*
INTO #COLLECTOR_WORKSTATION_PTNO_TBL
FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].ECHO_ACTIVE.DBO.COLLECTORWORKSTATION;

DROP TABLE IF EXISTS #PRE_TILE_TBL;
-- Prepare a table for tiling by joining the base population table with collector workstation data
-- This table is used to assign tile numbers based on the amount owed
SELECT L.*,
	R.*
INTO #PRE_TILE_TBL
FROM #BASE_POP_TBL AS L
LEFT JOIN #COLLECTOR_WORKSTATION_PTNO_TBL AS R ON L.[PATIENT NO] = R.PT_NUM
	AND ISNULL(L.[Unit Date], '') = ISNULL(R.[PA-CWI-UNIT-DATE], '')
	AND L.WORKLIST = R.[PA-CWI-LAST-WKLST-ID];

DROP TABLE IF EXISTS #TILED_TBL;
-- Assign tile numbers based on the amount owed
-- This table is used to categorize accounts into different tiles for reporting
SELECT *,
	TILE_NUM = CASE
		WHEN [FOL AMT] <= 0
			THEN 1
		WHEN [Fol AMT] > 0
			AND [FOL AMT] < 3000
			THEN 2
		WHEN [FOL AMT] >= 3000
			AND [FOL AMT] < 5000
			THEN 3
		WHEN [FOL AMT] >= 5000
			AND [FOL AMT] < 25000
			THEN 4
		WHEN [FOL AMT] >= 25000
			THEN 5
		END
INTO #TILED_TBL
FROM #PRE_TILE_TBL;

DROP TABLE IF EXISTS #STRATIFICATION_TBL;
-- Create a stratification table that categorizes accounts based on tile numbers and work status
-- This table is used to generate reports on accounts worked by collectors
SELECT PT_NO,
	INS_CD,
	UNIT_NO,
	CHECK_EFT_DATE,
	COUNTDISTINCT_DATE_OF_SERVICE,
	CONCAT_DATE_OF_SERVICE,
	PAYER_NAME,
	RemarkCodeCombined,
	RemarkDescCombined,
	Combined_Remit_Adjustment_Group_and_Reason_code,
	Combined_Remit_Adjustment_Reason_Description,
	Combined_Line_Adjustment_Group_and_Reason_code,
	Combined_Line_Adjustment_Reason_Description,
	CarcCategoryCombined,
	[Report Date],
	[Supervisor ID],
	[Supervisor Name],
	[RESPONSIBLE COLLECTOR],
	[RC Name],
	WORKLIST,
	[WORKLIST NAME],
	[Seq No],
	[PATIENT NO],
	[PATIENT NAME],
	[Pyr ID],
--	[GUAR NO],
	[MED REC NO],
	[Fol AMT],
	[LAST BILL DATE],
	[LAST PAY DATE],
--	[RPM/VOF Line],
	[FOL LVL],
--	[FOL TYP],
	[FILE],
--	[SVC FAC ID],
	[Unit No],
	[Unit Date],
	ERRORS,
	PA_File,
	Batch_No,
	[Encounter Number],
	Unit,
	Pt_Name,
	Svc_Date,
	[Service Code],
	Posted_Amt,
	Pt_Type,
	FC,	
	[USER_ID],
	User_Batch_ID,
	Tran_Type_1,
	Tran_Type_2,
	Ins_Plan,
	Post_Date,
	[ACCOUNT WORKED-TRANSACTION],
	[PA-CWI-LAST-CMPLT-FOL-DATE],
	[PA-CWI-LAST-ACTV-DATE],
	[PA-CWI-LAST-ACTV-CD],
	[PA-CWI-LAST-ACTV-CMPLT-IND],
	[PA-CWI-LAST-ACTV-COLL-ID],
	TILE_NUM,
--	TILE_SEQUENCE_NUMBER = ROW_NUMBER() OVER(PARTITION BY TILE_NUM ORDER BY [Fol AMT]),
	DAYS_SINCE_LAST_WORKED = CASE
		WHEN DATEDIFF(DAY, POST_DATE, GETDATE()) < DATEDIFF(DAY, [PA-CWI-LAST-CMPLT-FOL-DATE], GETDATE())
			THEN DATEDIFF(DAY, POST_DATE, GETDATE())
		ELSE DATEDIFF(DAY, [PA-CWI-LAST-CMPLT-FOL-DATE], GETDATE())
		END,
	STRATIFICATION = CASE
		WHEN TILE_NUM = 1
			THEN 'CREDIT'
		WHEN TILE_NUM = 2
			THEN '$0 - $3K'
		WHEN TILE_NUM = 3
			THEN '$3K - $5K'
		WHEN TILE_NUM = 4
			THEN '$5K - $25K'
		WHEN TILE_NUM = 5
			THEN '$25K+'
		ELSE NULL
		END,
	WORKED_THIS_WEEK = CASE
		WHEN (
			CASE WHEN DATEDIFF(DAY, POST_DATE, GETDATE()) < DATEDIFF(DAY, [PA-CWI-LAST-CMPLT-FOL-DATE], GETDATE())
				THEN DATEDIFF(DAY, POST_DATE, GETDATE())
			ELSE DATEDIFF(DAY, [PA-CWI-LAST-CMPLT-FOL-DATE], GETDATE())
			END
		) < 5
			THEN 'WORKED THIS WEEK'
		WHEN [ACCOUNT WORKED-TRANSACTION] < 5
			THEN 'WORKED THIS WEEK-TRANSACTION'
		ELSE 'UNWORKED ACCOUNT'
		END
INTO #STRATIFICATION_TBL
FROM #TILED_TBL
ORDER BY [Supervisor ID],
	[RESPONSIBLE COLLECTOR],
	[Fol AMT] DESC;

-- GET ACCTS THAT ARE WORKED ON A REP WORKLIST IN 21 DAYS OR LESS
-- AND UNION ALL TO THOSE ACCOUNTS NOT ON A REP WORKLIST
DROP TABLE IF EXISTS #FINAL_TBL;
-- This table combines the stratification data with additional fields and categorizes accounts
-- based on whether they are worked or unworked
WITH REP_TWENTYONE_TBL AS (
	SELECT *
	FROM #STRATIFICATION_TBL
	WHERE LEFT([WORKLIST NAME], 3) = 'REP'
	AND CAST([PA-CWI-LAST-CMPLT-FOL-DATE] AS DATE) < DATEADD(DAY, -21, CAST(GETDATE() AS DATE))

	UNION ALL

	SELECT *
	FROM #STRATIFICATION_TBL AS Z
	WHERE LEFT(Z.[WORKLIST NAME], 3) != 'REP'
)

-- CREATE FINAL TABLE
SELECT Unit_No = LTRIM(RTRIM(A.Unit_No)),
	Check_EFT_Date = LTRIM(RTRIM(A.Check_EFT_Date)),
	COUNTDISTINCT_DATE_OF_SERVICE = LTRIM(RTRIM(A.COUNTDISTINCT_DATE_OF_SERVICE)),
	CONCAT_DATE_OF_SERVICE = LTRIM(RTRIM(A.CONCAT_DATE_OF_SERVICE)),
	Payer_Name = LTRIM(RTRIM(A.Payer_Name)),
	RemarkCodeCombined = LTRIM(RTRIM(A.RemarkCodeCombined)),
	RemarkDescCombined = LTRIM(RTRIM(A.RemarkDescCombined)),
	Combined_Remit_Adjustment_Group_and_Reason_code = LTRIM(RTRIM(A.Combined_Remit_Adjustment_Group_and_Reason_code)),
	Combined_Remit_Adjustment_Reason_Description = LTRIM(RTRIM(A.Combined_Remit_Adjustment_Reason_Description)),
	Combined_Line_Adjustment_Group_and_Reason_code = LTRIM(RTRIM(A.Combined_Line_Adjustment_Group_and_Reason_code)),
	Combined_Line_Adjustment_Reason_Description = LTRIM(RTRIM(A.Combined_Line_Adjustment_Reason_Description)),
	[Report Date] = LTRIM(RTRIM(A.[Report Date])),
	[Supervisor ID] = LTRIM(RTRIM(A.[Supervisor ID])),
	[Supervisor Name] = LTRIM(RTRIM(A.[Supervisor Name])),
	[RESPONSIBLE COLLECTOR] = LTRIM(RTRIM(A.[RESPONSIBLE COLLECTOR])),
	[RC Name] = LTRIM(RTRIM(A.[RC Name])),
	WORKLIST = LTRIM(RTRIM(A.WORKLIST)),
	[WORKLIST NAME] = LTRIM(RTRIM(A.[WORKLIST NAME])),
	[Seq No] = LTRIM(RTRIM(A.[Seq No])),
	[PATIENT NO] = LTRIM(RTRIM(A.[PATIENT NO])),
	[PATIENT NAME] = LTRIM(RTRIM(A.[PATIENT NAME])),
	[Pyr ID] = LTRIM(RTRIM(A.[Pyr ID])),
	[MED REC NO] = LTRIM(RTRIM(A.[MED REC NO])),
	[Fol AMT] = LTRIM(RTRIM(A.[Fol AMT])),
	[LAST BILL DATE] = LTRIM(RTRIM(A.[LAST BILL DATE])),
	[LAST PAY DATE] = LTRIM(RTRIM(A.[LAST PAY DATE])),
	[FOL LVL] = LTRIM(RTRIM(A.[FOL LVL])),
	[FILE] = LTRIM(RTRIM(A.[FILE])),
	[Unit No] = LTRIM(RTRIM(A.[Unit No])),
	[Unit Date] = LTRIM(RTRIM(A.[Unit Date])),
	ERRORS = LTRIM(RTRIM(A.ERRORS)),
	PA_File = LTRIM(RTRIM(A.PA_File)),
	[Encounter Number] = LTRIM(RTRIM(A.[Encounter Number])),
	Unit = LTRIM(RTRIM(A.Unit)),
	Svc_Date = LTRIM(RTRIM(A.Svc_Date)),
	[Service Code] = LTRIM(RTRIM(A.[Service Code])),
	Posted_Amt = LTRIM(RTRIM(A.Posted_Amt)),
	FC = LTRIM(RTRIM(A.FC)),
	[User_ID] = LTRIM(RTRIM(A.[User_ID])),
	Ins_Plan = LTRIM(RTRIM(A.Ins_Plan)),
	Post_Date = LTRIM(RTRIM(A.Post_Date)),
	[ACCOUNT WORKED-TRANSACTION] = LTRIM(RTRIM(A.[ACCOUNT WORKED-TRANSACTION])),
	[PA-CWI-LAST-CMPLT-FOL-DATE] = LTRIM(RTRIM(A.[PA-CWI-LAST-CMPLT-FOL-DATE])),
	[PA-CWI-LAST-ACTV-DATE] = LTRIM(RTRIM(A.[PA-CWI-LAST-ACTV-DATE])),
	[PA-CWI-LAST-ACTV-CD] = LTRIM(RTRIM(A.[PA-CWI-LAST-ACTV-CD])),
	[PA-CWI-LAST-ACTV-CMPLT-IND] = LTRIM(RTRIM(A.[PA-CWI-LAST-ACTV-CMPLT-IND])),
	[PA-CWI-LAST-ACTV-COLL-ID] = LTRIM(RTRIM(A.[PA-CWI-LAST-ACTV-COLL-ID])),
	TILE_NUM = LTRIM(RTRIM(A.TILE_NUM)),
	DAYS_SINCE_LAST_WORKED = LTRIM(RTRIM(A.DAYS_SINCE_LAST_WORKED)),
	STRATIFICATION = LTRIM(RTRIM(A.STRATIFICATION)),
	A.WORKED_THIS_WEEK,
	WORKED_VS_UNWORKED = CASE
		WHEN LEFT(WORKED_THIS_WEEK, 4) = 'WORK'
			THEN 'WORKED'
		ELSE 'UNWORKED'
		END,
	[UNIQUE_NO] = CASE
		WHEN [Unit No] IS NULL
			THEN [PATIENT NO]
		ELSE CAST([PATIENT NO] AS varchar) + CAST([UNIT NO] AS varchar)
		END,
	REP_NUMBER_WORKLIST = CASE
		WHEN [WORKLIST NAME] LIKE '%REP%'
			THEN 'REP NUMBER WORKLIST'
		ELSE 'TRADITIONAL WORKLIST'
		END,
	[TIMESTAMP] = CAST(GETDATE() AS DATE)
INTO #FINAL_TBL
FROM REP_TWENTYONE_TBL AS A;

-- Now that we have the final table, we want to check if the current date is Monday,
-- and if so, we will select the data from the final table and insert it into a reporting table
-- that captures the beginning inventory of accounts to be worked for the week.
-- This is useful for tracking productivity over time.
IF DATENAME(WEEKDAY, GETDATE()) = 'Monday'
	BEGIN
	-- Insert beginning inventory into the reporting table
	-- use all the fields from the final table
	SELECT DISTINCT [Report Date],
		[PATIENT NO],
		[UNIT NO],
		UNIQUE_NO,
		[Supervisor ID],
		[Supervisor Name],
		[RESPONSIBLE COLLECTOR],
		[RC Name],
		WORKLIST,
		[WORKLIST NAME],
		REP_NUMBER_WORKLIST,
		[PATIENT NAME],
		[MED REC NO],
		[Pyr ID],
		STRATIFICATION,
		[Fol AMT],
		[LAST BILL DATE],
		[LAST PAY DATE],
		[FOL LVL],
		[FILE],
		[Unit Date],
		ERRORS,
		PA_File,
		[ACCOUNT WORKED-TRANSACTION],
		[PA-CWI-LAST-CMPLT-FOL-DATE],
		[PA-CWI-LAST-ACTV-DATE],
		[PA-CWI-LAST-ACTV-CD],
		[PA-CWI-LAST-ACTV-CMPLT-IND],
		[PA-CWI-LAST-ACTV-COLL-ID],
		WORKED_THIS_WEEK,
		DAYS_SINCE_LAST_WORKED,
		WORKED_VS_UNWORKED,
		Check_EFT_Date,
		COUNTDISTINCT_DATE_OF_SERVICE,
		CONCAT_DATE_OF_SERVICE,
		Payer_Name,
		Combined_Remit_Adjustment_Group_and_Reason_code,
		Combined_Remit_Adjustment_Reason_Description,
		Combined_Line_Adjustment_Group_and_Reason_code,
		Combined_Line_Adjustment_Reason_Description,
		[Seq No],
		[TIMESTAMP]
	--INTO #MONDAY_INVENTORY_TBL
	INTO [SMS].[dbo].[c_productive_capacity_beginning_inventory_tbl]
	FROM #FINAL_TBL
END
ELSE BEGIN
	/*
	If it's not Monday, we want to select everything from the final table and place it into a reporting table.
	This reporting table will capture the accounts that are either:
		- worked
		- unworked or 
		- missing from the Monday inventory table SMS.dbo.c_productive_capacity_beginning_inventory_tbl
	
	This allows us to compare the current day's data with the previous. Further, we only want to capture
	records that have changed in status from the Monday inventory. This means we will only select records if
	the following conditions are met:
		- The account is worked today but unworked in SMS.dbo.c_productive_capacity_beginning_inventory_tbl
		- The account is unworked today but worked in SMS.dbo.c_productive_capacity_beginning_inventory_tbl
		- The account is not in the Monday inventory table, this would denote a new account that has been added
		- The account no longer shows up but was in the Monday inventory table, this would denote an account that has been removed.

	The data is going to go into a table called: SMS.dbo.c_productive_capacity_weekly_activity_tbl.

	When the code runs we should make sure that we do not insert a record into SMS.dbo.c_productive_capacity_weekly_activity_tbl
	if it will have the the same values in all columns as the previous run except for the TIMESTAMP column.
	This is because we want to capture changes in the data, and if the data is the same as the previous run,
	it means there are no changes to report. We will use the TIMESTAMP column to determine if the record has changed.
	We will select all the same columns as in the final table.
	*/
	
	SELECT DISTINCT A.[Report Date],
		A.[PATIENT NO],
		A.[UNIT NO],
		A.[UNIQUE_NO],
		A.[Supervisor ID],
		A.[Supervisor Name],
		A.[RESPONSIBLE COLLECTOR],
		A.[RC Name],
		A.[WORKLIST],
		A.[WORKLIST NAME],
		A.[REP_NUMBER_WORKLIST],
		A.[PATIENT NAME],
		A.[MED REC NO],
		A.[Pyr ID],
		A.[STRATIFICATION],
		A.[Fol AMT],
		A.[LAST BILL DATE],
		A.[LAST PAY DATE],
		A.[FOL LVL],
		A.[FILE],
		A.[Unit Date],
		A.[ERRORS],
		A.[PA_File],
		A.[ACCOUNT WORKED-TRANSACTION],
		A.[PA-CWI-LAST-CMPLT-FOL-DATE],
		A.[PA-CWI-LAST-ACTV-DATE],
		A.[PA-CWI-LAST-ACTV-CD],
		A.[PA-CWI-LAST-ACTV-CMPLT-IND],
		A.[PA-CWI-LAST-ACTV-COLL-ID],
		A.[WORKED_THIS_WEEK],
		A.[DAYS_SINCE_LAST_WORKED],
		A.[WORKED_VS_UNWORKED],
		A.[Check_EFT_Date],
		A.[COUNTDISTINCT_DATE_OF_SERVICE],
		A.[CONCAT_DATE_OF_SERVICE],
		A.[Payer_Name],
		A.[Combined_Remit_Adjustment_Group_and_Reason_code],
		A.[Combined_Remit_Adjustment_Reason_Description],
		A.[Combined_Line_Adjustment_Group_and_Reason_code],
		A.[Combined_Line_Adjustment_Reason_Description],
		A.[Seq No],
		A.[TIMESTAMP]
	INTO SMS.dbo.c_productive_capacity_weekly_activity_tbl
	FROM #FINAL_TBL AS A
	-- We will only select records that have changed in status from the Monday inventory table
	-- Select records that are either:
	-- 1. Worked today but unworked in the Monday inventory table
	WHERE EXISTS (
		SELECT 1
		FROM [SMS].[dbo].[c_productive_capacity_beginning_inventory_tbl] AS B
		WHERE A.UNIQUE_NO = B.UNIQUE_NO
			AND A.WORKED_THIS_WEEK LIKE 'WORKED%'
			AND B.WORKED_THIS_WEEK NOT LIKE 'WORKED%'
	)
	-- 2. Unworked today but worked in the Monday inventory table
	OR EXISTS (
		SELECT 1
		FROM [SMS].[dbo].[c_productive_capacity_beginning_inventory_tbl] AS B
		WHERE A.UNIQUE_NO = B.UNIQUE_NO
			AND A.WORKED_THIS_WEEK NOT LIKE 'WORKED%'
			AND B.WORKED_THIS_WEEK LIKE 'WORKED%'
	)
	-- 3. Not in the Monday inventory table
	OR NOT EXISTS (
		SELECT 1
		FROM [SMS].[dbo].[c_productive_capacity_beginning_inventory_tbl] AS B
		WHERE A.UNIQUE_NO = B.UNIQUE_NO
	)
	-- 4. No longer shows up but was in the Monday inventory table
	OR NOT EXISTS (
		SELECT 1
		FROM [SMS].[dbo].[c_productive_capacity_beginning_inventory_tbl] AS B
		WHERE A.UNIQUE_NO = B.UNIQUE_NO
			AND B.WORKED_THIS_WEEK LIKE 'WORKED%'
	)
	-- Ensure we do not insert a record if it has the same values in all columns as the previous run
	AND NOT EXISTS (
		SELECT 1
		FROM [SMS].[dbo].[c_productive_capacity_weekly_activity_tbl] AS C
		WHERE A.UNIQUE_NO = C.UNIQUE_NO
			AND A.[PATIENT NO] = C.[PATIENT NO]
			AND A.[UNIT NO] = C.[UNIT NO]
			AND A.[UNIQUE_NO] = C.[UNIQUE_NO]
			AND A.[Supervisor ID] = C.[Supervisor ID]
			AND A.[Supervisor Name] = C.[Supervisor Name]
			AND A.[RESPONSIBLE COLLECTOR] = C.[RESPONSIBLE COLLECTOR]
			AND A.[RC Name] = C.[RC Name]
			AND A.[WORKLIST] = C.[WORKLIST]
			AND A.[WORKLIST NAME] = C.[WORKLIST NAME]
			AND A.[REP_NUMBER_WORKLIST] = C.[REP_NUMBER_WORKLIST]
			AND A.[PATIENT NAME] = C.[PATIENT NAME]
			AND A.[MED REC NO] = C.[MED REC NO]
			AND A.[Pyr ID] = C.[Pyr ID]
			AND A.[STRATIFICATION] = C.[STRATIFICATION]
			AND A.[Fol AMT] = C.[Fol AMT]
			AND A.[LAST BILL DATE] = C.[LAST BILL DATE]
			AND A.[LAST PAY DATE] = C.[LAST PAY DATE]
			AND A.[FOL LVL] = C.[FOL LVL]
			AND A.[FILE] = C.[FILE]
			AND A.[Unit Date] = C.[Unit Date]
			AND A.[ERRORS] = C.[ERRORS]
			AND A.[PA_File] = C.[PA_File]
			AND A.[ACCOUNT WORKED-TRANSACTION] = C.[ACCOUNT WORKED-TRANSACTION]
			AND A.[PA-CWI-LAST-CMPLT-FOL-DATE] = C.[PA-CWI-LAST-CMPLT-FOL-DATE]
			AND A.[PA-CWI-LAST-ACTV-DATE] = C.[PA-CWI-LAST-ACTV-DATE]
			AND A.[PA-CWI-LAST-ACTV-CD] = C.[PA-CWI-LAST-ACTV-CD]
			AND A.[PA-CWI-LAST-ACTV-CMPLT-IND] = C.[PA-CWI-LAST-ACTV-CMPLT-IND]
			AND A.[PA-CWI-LAST-ACTV-COLL-ID] = C.[PA-CWI-LAST-ACTV-COLL-ID]
			AND A.[WORKED_THIS_WEEK] = C.[WORKED_THIS_WEEK]
			AND A.[DAYS_SINCE_LAST_WORKED] = C.[DAYS_SINCE_LAST_WORKED]
			AND A.[WORKED_VS_UNWORKED] = C.[WORKED_VS_UNWORKED]
			AND A.[Check_EFT_Date] = C.[Check_EFT_Date]
			AND A.[COUNTDISTINCT_DATE_OF_SERVICE] = C.[COUNTDISTINCT_DATE_OF_SERVICE]
			AND A.[CONCAT_DATE_OF_SERVICE] = C.[CONCAT_DATE_OF_SERVICE]
			AND A.[Payer_Name] = C.[Payer_Name]
			AND A.[Combined_Remit_Adjustment_Group_and_Reason_code] = C.[Combined_Remit_Adjustment_Group_and_Reason_code]
			AND A.[Combined_Remit_Adjustment_Reason_Description] = C.[Combined_Remit_Adjustment_Reason_Description]
			AND A.[Combined_Line_Adjustment_Group_and_Reason_code] = C.[Combined_Line_Adjustment_Group_and_Reason_code]
			AND A.[Combined_Line_Adjustment_Reason_Description] = C.[Combined_Line_Adjustment_Reason_Description]
			AND A.[Seq No] = C.[Seq No]
	);
END;
