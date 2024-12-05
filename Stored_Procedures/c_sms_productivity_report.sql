USE [SMS]
GO
/****** Object:  StoredProcedure [dbo].[c_sms_productivity_report]    Script Date: 10/21/2024 9:32:36 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[c_sms_productivity_report]
AS
SET ANSI_NULLS ON
SET ANSI_WARNINGS ON
SET QUOTED_IDENTIFIER ON

BEGIN
	SET NOCOUNT ON;
/************************************************************************
File: Productivity_DB.sql

Input Parameters:
	None

Tables/Views:
	swarm.dbo.CW_DTL_productivity c

Creates Table/View:
	c_productivity_*

Functions:
	None

Author: Steven P. Sanderson II, MPH
		Mayur Shah
		Casey Delaney

Department: Patient Financial Services

Purpose/Description
	To build the tables necessary for the Productivity Report in Tableau

Revision History:
Date		Version		Description
----		----		----
2023-05-17	v1			Initial Creation
2023-06-16	v2			Added create table statements and coerced all to varchar
2023-10-16	v3			Add service code description to combined table
2024-02-26	v4			Added payer org table
2024-05-02	v5			Added activity code and service code logic
************************************************************************/

DECLARE @BEGINDATE DATETIME
DECLARE @ENDDATE DATETIME
DECLARE @PRODREPORTDATE DATETIME
DECLARE @ThisDate DATETIME

--DECLARE @PRIORCWREPORTDATE DATETIME
SET @ThisDate = getdate()
SET @BEGINDATE = dateadd(wk, datediff(wk, 0, @ThisDate) - 1, - 1)
SET @ENDDATE = dateadd(wk, datediff(wk, 0, @ThisDate) - 1, 5)
SET @PRODREPORTDATE = @BEGINDATE - 1

--SET @PRIORCWREPORTDATE = @PRODREPORTDATE - 7
------------------------------------------------------Drop Table to identify staff in the Business Office------------------------------------------------------
DROP TABLE IF EXISTS #USERS
CREATE TABLE #USERS ([user_id] VARCHAR(128), [USER_NAME] VARCHAR(128), user_dept VARCHAR(128));

INSERT INTO #USERS ([user_id],[USER_NAME], user_dept)
	SELECT [user_id],
		[USER_NAME],
		[user_dept]
	--INTO #USERS
	FROM dbo.revenue_cycle_employee_listing
	WHERE [USER_ID] IS NOT NULL
	AND CAST(USER_DEPT AS VARCHAR(255)) NOT IN ('Administrative Assistant',
    'Analyst Team',
    'Associate Director',
    'Director',
    'Director Patient Financial Svcs',
    'Manager, Cash Management',
    'Manager, Rev Cycle Operations',
    'Sr Manager, Billing',
    'Sr Manager, Denials & Appeals');

------------------------------------------------------Drop Table to identify accounts currently on staff's Worklists------------------------------------------------------
--DATA TABLE: COLLECTOR WORKLIST INVENTORY
DROP TABLE IF EXISTS #COLLECTORWORKLIST
CREATE TABLE #COLLECTORWORKLIST (
	[Report Date] DATE,
	[IfAcctNewOldOff] VARCHAR(128),
	[Supervisor ID] VARCHAR(128),
	[Supervisor Name] VARCHAR(128),
	[RESPONSIBLE COLLECTOR] VARCHAR(128),
	[RC Name] VARCHAR(128),
	[WORKLIST] VARCHAR(128),
	[WORKLIST NAME] VARCHAR(128),
	[Seq No] VARCHAR(128),
	[PATIENT NO] VARCHAR(128),
	[PATIENT NAME] VARCHAR(128),
	[Pyr ID] VARCHAR(128),
	[GUAR NO] VARCHAR(128),
	[MED REC NO] VARCHAR(128),
	[Fol AMT] VARCHAR(128),
	[LAST BILL DATE] DATE,
	[LAST PAY DATE] DATE,
	[RPM/VOF Line] VARCHAR(128),
	[FOL LVL] VARCHAR(128),
	[FOL TYP] VARCHAR(128),
	[FILE] VARCHAR(128),
	[SVC FAC ID] VARCHAR(128),
	[Unit No] varchar(128),
	[Unit Date] DATETIME2,
	[USER_ID] VARCHAR(128),
	[USER_NAME] VARCHAR(128),
	[USER_DEPT] VARCHAR(128)
);

INSERT INTO #COLLECTORWORKLIST (
	[Report Date],
	[IfAcctNewOldOff],
	[Supervisor ID],
	[Supervisor Name],
	[RESPONSIBLE COLLECTOR],
	[RC Name],
	[WORKLIST],
	[WORKLIST NAME],
	[Seq No],
	[PATIENT NO],
	[PATIENT NAME],
	[Pyr ID],
	[GUAR NO],
	[MED REC NO],
	[Fol AMT],
	[LAST BILL DATE],
	[LAST PAY DATE],
	[RPM/VOF Line],
	[FOL LVL],
	[FOL TYP],
	[FILE],
	[SVC FAC ID],
	[Unit No],
	[Unit Date],
	[USER_ID],
	[USER_NAME],
	[USER_DEPT]
)
SELECT [Report Date],
		[IfAcctNewOldOff],
		[Supervisor ID],
		[Supervisor Name],
		[RESPONSIBLE COLLECTOR],
		[RC Name],
		[WORKLIST],
		[WORKLIST NAME],
		[Seq No],
		[PATIENT NO],
		[PATIENT NAME],
		[Pyr ID],
		[GUAR NO],
		[MED REC NO],
		[Fol AMT],
		[LAST BILL DATE],
		[LAST PAY DATE],
		[RPM/VOF Line],
		[FOL LVL],
		[FOL TYP],
		[FILE],
		[SVC FAC ID],
		ISNULL(CAST([Unit No] AS VARCHAR), 'A') AS 'UNIT NO',
		[Unit Date],
		[USER_ID],
		[USER_NAME],
		[USER_DEPT]
	--INTO #CollectorWorklist
	FROM swarm.dbo.CW_DTL_productivity c
	RIGHT JOIN #USERS z ON CAST(c.[RESPONSIBLE COLLECTOR] AS VARCHAR) = CAST(z.[User_ID] AS VARCHAR)
	WHERE c.[Report Date] = @PRODREPORTDATE;

-- Create table of all activity codes posted by users in the business office
DROP TABLE IF EXISTS #ACPRODUCTIVITY
CREATE TABLE #ACPRODUCTIVITY (
	[PA-PT-NO-WOSCD] VARCHAR(128),
	[PA-PT-NO-SCD-1] VARCHAR(128),
	[Pt_No] VARCHAR(128),
	[PA-CTL-PAA-XFER-DATE] DATETIME2,
	[PA-SMART-COUNTER] VARCHAR(128),
	[SmartDate] DATE,
	[PA-SMART-COMMENT] VARCHAR(128),
	[USER-ID] VARCHAR(128),
	[ACTIVITY_CODE] VARCHAR(128),
	[PA-SMART-SVC-CD-WOSCD] VARCHAR(128),
	[Unique_for_Join] VARCHAR(128)
);

INSERT INTO #ACPRODUCTIVITY (
	[PA-PT-NO-WOSCD],
	[PA-PT-NO-SCD-1],
	[Pt_No],
	[PA-CTL-PAA-XFER-DATE],
	[PA-SMART-COUNTER],
	[SmartDate],
	[PA-SMART-COMMENT],
	[USER-ID],
	[ACTIVITY_CODE],
	[PA-SMART-SVC-CD-WOSCD],
	[Unique_for_Join]
)
	SELECT [PA-PT-NO-WOSCD],
		[PA-PT-NO-SCD-1],
		CAST([PA-PT-NO-WOSCD] AS VARCHAR) + CAST([PA-PT-NO-SCD-1] AS VARCHAR) AS 'Pt_No',
		[PA-CTL-PAA-XFER-DATE],
		[PA-SMART-COUNTER],
		convert(VARCHAR, [PA-SMART-DATE], 101) AS 'SmartDate',
		[PA-SMART-COMMENT],
		SUBSTRING([PA-SMART-COMMENT], 6, 6) AS 'USER-ID',
		SUBSTRING([PA-SMART-COMMENT], 1, 5) AS 'ACTIVITY_CODE',
		[PA-SMART-SVC-CD-WOSCD],
		CAST([PA-PT-NO-WOSCD] AS VARCHAR) + CAST([PA-PT-NO-SCD-1] AS VARCHAR) + '_ _' + convert(VARCHAR, [PA-SMART-DATE], 101) + '_' + SUBSTRING([PA-SMART-COMMENT], 6, 6) AS 'Unique_for_Join'
	--INTO #ACPRODUCTIVITY
	FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Active].[dbo].[AccountComments] F
	RIGHT JOIN #USERS M ON CAST(SUBSTRING([PA-SMART-COMMENT], 6, 6) AS VARCHAR) = CAST(M.[User_ID] AS VARCHAR)
	WHERE [PA-SMART-DATE] BETWEEN @BEGINDATE
			AND @ENDDATE;

------------------------------------------------------Drop Table to isolate Transaction codes used by staff------------------------------------------------------
--DATA TABLE: USED TO DETERMINE WHAT TRANSACTION CODES WERE PLACED. OUTPUT IN #COMBINEDTABLE
DROP TABLE IF EXISTS #TCPRODUCTIVITY --Creating a temp table of all Transaction codes posted by Users in the Business office
CREATE TABLE #TCPRODUCTIVITY (
	[PA_File] VARCHAR(128),
	[Batch_No] VARCHAR(128),
	[Encounter Number] VARCHAR(128),
	[Unit] VARCHAR(128),
	[Pt_Name] VARCHAR(128),
	[Svc_Date] DATETIME2,
	[Service Code] VARCHAR(128),
	[Posted_Amt] VARCHAR(128),
	[Pt_Type] VARCHAR(128),
	[FC] VARCHAR(128),
	[User_ID] VARCHAR(128),
	[User_Batch_ID] VARCHAR(128),
	[Tran_Type_1] VARCHAR(128),
	[Tran_Type_2] VARCHAR(128),
	[Ins_Plan] VARCHAR(128),
	[Post_Date] VARCHAR(128),
	[Unique_for_Join] VARCHAR(128)
);

INSERT INTO #TCPRODUCTIVITY (
	[PA_File],
	[Batch_No],
	[Encounter Number],
	[Unit],
	[Pt_Name],
	[Svc_Date],
	[Service Code],
	[Posted_Amt],
	[Pt_Type],
	[FC],
	[User_ID],
	[User_Batch_ID],
	[Tran_Type_1],
	[Tran_Type_2],
	[Ins_Plan],
	[Post_Date],
	[Unique_for_Join]
)
	SELECT [PA_File],
		[Batch_No],
		[Encounter Number],
		isnull(t.[Unit], 'A') AS 'Unit',
		t.[Pt_Name],
		[Svc_Date],
		[Service Code],
		[Posted_Amt],
		t.[Pt_Type],
		t.[FC],
		t.[User_ID],
		[User_Batch_ID],
		[Tran_Type_1],
		[Tran_Type_2],
		[Ins_Plan],
		convert(VARCHAR, [Post_Date], 101) AS [Post_Date],
		CAST([Encounter Number] AS VARCHAR) + '_' + CAST(t.[Unit] AS VARCHAR) + '_' + convert(VARCHAR, [Post_Date], 101) + '_' + CAST(t.[User_ID] AS VARCHAR) AS 'Unique for Join'
	--INTO #TCPRODUCTIVITY
	FROM [SWARM].[DBO].[OAMCOMB ] T
	RIGHT JOIN #USERS M ON CAST(t.[User_ID] AS VARCHAR) = M.[User_ID]
	WHERE [POST_DATE] BETWEEN @BEGINDATE
			AND @ENDDATE;

UPDATE #TCPRODUCTIVITY
SET Unit = 'A'
WHERE Unit = '';

------------------------------------------------------Drop table to be used when combining Activity Code and Transaction code tables------------------------------------------------------
--DATA TABLE: COMBINE ACTIVITY CODE AND TRANSACTION CODE DATA BEFORE COMBINING EVERYTHING IN #COMBINEDTABLE. ENCOUNTERED ISSUES COMBINING THEM DIRECTLY INTO #COMBINED TABLE, MADE IT A TWO STEP PROCESS
DROP TABLE IF EXISTS #PRECOMBINE --Creating a temp table for step 1 of combining the TC/AC tables
CREATE TABLE #PRECOMBINE (
	[UNIQUE FOR JOIN] VARCHAR(128),
	[PTNUM] VARCHAR(128),
	[USERID] VARCHAR(128),
	[TCUNIT] VARCHAR(128)
);

INSERT INTO #PRECOMBINE (
	[UNIQUE FOR JOIN],
	[PTNUM],
	[USERID],
	[TCUNIT]
)
	SELECT Unique_for_Join AS 'UNIQUE FOR JOIN',
		Pt_No AS 'PTNUM',
		[USER-ID] AS 'USERID',
		NULL AS 'TCUNIT'
	--INTO #PRECOMBINE
	FROM #ACPRODUCTIVITY
	
	UNION
	
	SELECT [Unique_for_Join] AS 'UNIQUE FOR JOIN',
		[Encounter Number] AS 'PTNUM',
		[User_ID] AS 'USERID',
		Unit AS 'TCUNIT'
	FROM #TCPRODUCTIVITY;

------------------------------------------------------Drop table to combine Activity Code table and Transaction Code table------------------------------------------------------
--DATA TABLE: COMBINING ACTIVITY CODES AND TRANSACTION CODES. 
DROP TABLE IF EXISTS #COMBINEDTABLE --Creating a temp table to represent all transactions posted, combining Activity Codes and Transaction Codes
CREATE TABLE #COMBINEDTABLE (
	[UNIQUE FOR JOIN] VARCHAR(128),
	[PT_NO] VARCHAR(128),
	[UNIQUE_USER_ID] VARCHAR(128),
	[FOL AMT] VARCHAR(128),
	[FOL UP UNIT #] VARCHAR(128),
	[UNIT DATE] VARCHAR(128),
	[DEPT] VARCHAR(128),
	[ACTIVITY CODE USER ID] VARCHAR(128),
	[TRANSACTION CODE USER ID] VARCHAR(128),
	[UNIQUE ID] VARCHAR(128),
	[UNIQUE CODE] VARCHAR(128),
	[UNIQUE_DATE] VARCHAR(128),
	[UNIQUE_PT_NO] VARCHAR(255),
	[USER-ID] VARCHAR(128),
	[ACTIVITY CODE PT NO] VARCHAR(128),
	[ACTIVITY_CODE] VARCHAR(128),
	[SMARTDATE] VARCHAR(128),
	[USER_ID] VARCHAR(128),
	[TRANSACTION CODE PT NO] VARCHAR(128),
	[UNIT] VARCHAR(128),
	[SERVICE CODE] VARCHAR(128),
	[INS_PLAN] VARCHAR(128),
	[POSTED_AMT] VARCHAR(128),
	[POST_DATE] VARCHAR(128),
	[ENCOUNTER NUMBER] VARCHAR(128)
);

INSERT INTO #COMBINEDTABLE (
	[UNIQUE FOR JOIN],
	[PT_NO],
	[UNIQUE_USER_ID],
	[FOL AMT],
	[FOL UP UNIT #],
	[UNIT DATE],
	[DEPT],
	[ACTIVITY CODE USER ID],
	[TRANSACTION CODE USER ID],
	[UNIQUE ID],
	[UNIQUE CODE],
	[UNIQUE_DATE],
	[UNIQUE_PT_NO],
	[USER-ID],
	[ACTIVITY CODE PT NO],
	[ACTIVITY_CODE],
	[SMARTDATE],
	[USER_ID],
	[TRANSACTION CODE PT NO],
	[UNIT],
	[SERVICE CODE],
	[INS_PLAN],
	[POSTED_AMT],
	[POST_DATE],
	[ENCOUNTER NUMBER]
)
	SELECT DISTINCT M.[UNIQUE FOR JOIN],
		isnull(f.Pt_No, t.[Encounter Number]) AS 'Pt_No',
		left(isnull(f.[USER-ID], t.[User_ID]), 6) AS 'Unique_User_ID',
		c.[Fol AMT],
		isnull(cast(c.[Unit No] AS VARCHAR), 'A') AS 'Fol Up Unit #',
		Cast(c.[Unit Date] AS VARCHAR) AS 'Unit Date',
		z.USER_DEPT AS 'DEPT',
		f.[USER-ID] AS 'Activity Code User ID',
		t.[User_ID] AS 'Transaction Code User ID',
		left(CONCAT (
				f.[USER-ID],
				t.[User_ID]
				), 6) + '_' + f.Pt_No + '_' + f.[ACTIVITY_CODE] + '_' + left(CONCAT (
				f.SmartDate,
				t.Post_Date
				), 10) AS 'Unique ID', --Unique ID for Activity Codes
		SUBSTRING([PA-SMART-COMMENT], 6, 6) + '_' + CAST([PA-PT-NO-WOSCD] AS VARCHAR) + CAST([PA-PT-NO-SCD-1] AS VARCHAR) + '_' + convert(VARCHAR, f.SmartDate, 101) AS 'Unique Code',
		left(CONCAT (
				f.SmartDate,
				t.Post_Date
				), 10) AS 'Unique_Date',
		isnull(left(CONCAT (
					[USER-ID],
					t.[User_ID]
					), 6) + '_' + ISNULL(t.[Encounter Number], f.Pt_No) + '_' + ISNULL(t.Unit, 'A') + '_' + left(CONCAT (
					SmartDate,
					Post_Date
					), 10), SUBSTRING([PA-SMART-COMMENT], 6, 6) + '_' + CAST([PA-PT-NO-WOSCD] AS VARCHAR) + CAST([PA-PT-NO-SCD-1] AS VARCHAR) + '_' + convert(VARCHAR, f.SmartDate, 101)) AS 'Unique_Pt_No', -- Unique for Transaction Codes
		f.[USER-ID],
		f.Pt_No AS 'Activity Code Pt No',
		f.[ACTIVITY_CODE],
		f.SmartDate,
		t.[User_ID],
		t.[Encounter Number] AS 'Transaction Code Pt No',
		ISNULL(t.Unit, isnull(cast(c.[Unit No] AS VARCHAR), 'A')) AS 'UNIT', --pulling the Unit from the TCPRODUCTIVITY table
		t.[Service Code],
		t.Ins_Plan,
		t.[Posted_Amt],
		t.Post_Date,
		t.[Encounter Number]
	--INTO #CombinedTable
	FROM #PRECOMBINE M
	FULL OUTER JOIN #ACPRODUCTIVITY F ON M.[UNIQUE FOR JOIN] = F.Unique_for_Join
	FULL OUTER JOIN #TCPRODUCTIVITY t ON M.[UNIQUE FOR JOIN] = t.Unique_for_Join
		AND M.TCUNIT = T.Unit
	FULL OUTER JOIN #USERS z ON z.[User_ID] = isnull(f.[USER-ID], t.[User_ID])
	LEFT JOIN #CollectorWorklist c ON m.PTNUM = c.[PATIENT NO]
		AND CAST(COALESCE(M.TCUNIT, C.[Unit No]) AS VARCHAR) = CAST(C.[Unit No] AS VARCHAR);

------------------------------------------------------Create a table to determine how many transactions occured per account------------------------------------------------------
--DATA TABLE: IDENTIFYING HOW MANY TRANSACTIONS ON THE SAME ACCT/SAME DAY/SAME USER. WILL BE USED TO COUNT DISTINCT ACCTS WORKED
DROP TABLE IF EXISTS #TRANSACTIONCODESUMMARY --Creating a temp table to count of Multiple Transactions on Same Acct, on the same day, per user
CREATE TABLE #TRANSACTIONCODESUMMARY (
	[USER] VARCHAR(128),
	[DEPT] VARCHAR(128),
	[Fol AMT] VARCHAR(128),
	[Unique_Date] VARCHAR(128),
	[pt_no] VARCHAR(128),
	[Unit] VARCHAR(128),
	[Transactions per Acct] VARCHAR(128),
	[Unique_Pt_No] VARCHAR(128)
);

INSERT INTO #TRANSACTIONCODESUMMARY (
	[USER],
	[DEPT],
	[Fol AMT],
	[Unique_Date],
	[pt_no],
	[Unit],
	[Transactions per Acct],
	[Unique_Pt_No]
)
	SELECT Unique_User_ID AS 'USER',
		DEPT,
		[Fol AMT],
		Unique_Date,
		s.pt_no,
		s.Unit,
		count(Unique_Pt_No) AS 'Transactions per Acct',
		Unique_Pt_No
	--INTO #TRANSACTIONCODESUMMARY
	FROM #CombinedTable s
	RIGHT JOIN #USERS m ON s.Unique_User_ID = m.[User_ID]
	GROUP BY [Unique_Pt_No],
		DEPT,
		[Fol AMT],
		Unique_User_ID,
		Unique_Date,
		Pt_No,
		s.Unit;
	--ORDER BY COUNT([Unique_Pt_No]) DESC;

------------------------------------------------------Drop Table to identify how many accounts a staff member worked daily------------------------------------------------------
--SUMMARY TABLE: SUMMARIZES THE ACCOUNTS WORKED DAILY PER STAFF MEMBER
DROP TABLE IF EXISTS #ACCOUNTSWORKEDSUMMARYDAILY -- Creating a temp table to determine how many accounts were worked on a given day per user
CREATE TABLE #ACCOUNTSWORKEDSUMMARYDAILY (
	[TSUSER] VARCHAR(128),
	[TSUSERDEPT] VARCHAR(128),
	[TSDATE] VARCHAR(128),
	[AvgFolAMTDLY] VARCHAR(128),
	[TotFolAMTDLY] VARCHAR(128),
	[TSACCTSWORKED] VARCHAR(128)
);

INSERT INTO #ACCOUNTSWORKEDSUMMARYDAILY (
	[TSUSER],
	[TSUSERDEPT],
	[TSDATE],
	[AvgFolAMTDLY],
	[TotFolAMTDLY],
	[TSACCTSWORKED]
)
	SELECT [USER] AS 'TSUSER',
		m.USER_DEPT AS 'TSUSERDEPT',
		Unique_Date AS 'TSDATE',
		CAST(ROUND(SUM(CAST([Fol AMT] AS MONEY)) / COUNT(UNIQUE_PT_NO), 2) AS MONEY) AS 'AvgFolAMTDLY',
		--(cast(round((sum(CAST([Fol AMT] AS MONEY))) / COUNT(Unique_Pt_No)), 2) AS MONEY)) AS 'AvgFolAMTDLY',
		cast(round(sum(CAST([Fol AMT] AS MONEY)), 2) AS MONEY) AS 'TotFolAMTDLY',
		COUNT(Unique_Pt_No) AS 'TSACCTSWORKED'
	--INTO #ACCOUNTSWORKEDSUMMARYDAILY
	FROM #TRANSACTIONCODESUMMARY s
	RIGHT JOIN #USERS m ON s.[USER] = m.[User_ID]
	WHERE [user] IS NOT NULL
	GROUP BY Unique_Date,
		[USER],
		m.USER_DEPT;
	--ORDER BY COUNT(Unique_Pt_No) DESC;

--APPEND #TIMESTUDY TABLE TO THE #ACCOUNTSWORKEDSUMMARYDAILY TABLE SO THERE IS ALWAYS A BENCHMARCK IN THE OUTPUT
DROP TABLE IF EXISTS #TIMESTUDY
	CREATE TABLE #TIMESTUDY (
		TSUSER [NVARCHAR](50) NOT NULL,
		TSUSERDEPT [NVARCHAR](50) NOT NULL,
		TSDATE [DATETIME],
		AvgFolAMTDLY [NVARCHAR](50) NULL,
		TotFolAMTDLY [NVARCHAR](50) NULL,
		TSACCTSWORKED [INT] NOT NULL
		);

INSERT INTO #TIMESTUDY (
	[TSUSER],
	TSUSERDEPT,
	TSDATE,
	TSACCTSWORKED
	)
-- question on 10 and 20 minutes per account. Why do they exist?
VALUES (
	'10 MINUTES PER ACCT',
	'TIME STUDY',
	(@BEGINDATE + 1),
	42
	),
	(
	'10 MINUTES PER ACCT',
	'TIME STUDY',
	(@BEGINDATE + 2),
	42
	),
	(
	'10 MINUTES PER ACCT',
	'TIME STUDY',
	(@BEGINDATE + 3),
	42
	),
	(
	'10 MINUTES PER ACCT',
	'TIME STUDY',
	(@BEGINDATE + 4),
	42
	),
	(
	'10 MINUTES PER ACCT',
	'TIME STUDY',
	(@BEGINDATE + 5),
	42
	),
	(
	'15 MINUTES PER ACCT',
	'TIME STUDY',
	(@BEGINDATE + 1),
	28
	),
	(
	'15 MINUTES PER ACCT',
	'TIME STUDY',
	(@BEGINDATE + 2),
	28
	),
	(
	'15 MINUTES PER ACCT',
	'TIME STUDY',
	(@BEGINDATE + 3),
	28
	),
	(
	'15 MINUTES PER ACCT',
	'TIME STUDY',
	(@BEGINDATE + 4),
	28
	),
	(
	'15 MINUTES PER ACCT',
	'TIME STUDY',
	(@BEGINDATE + 5),
	28
	),
	(
	'20 MINUTES PER ACCT',
	'TIME STUDY',
	(@BEGINDATE + 1),
	21
	),
	(
	'20 MINUTES PER ACCT',
	'TIME STUDY',
	(@BEGINDATE + 2),
	21
	),
	(
	'20 MINUTES PER ACCT',
	'TIME STUDY',
	(@BEGINDATE + 3),
	21
	),
	(
	'20 MINUTES PER ACCT',
	'TIME STUDY',
	(@BEGINDATE + 4),
	21
	),
	(
	'20 MINUTES PER ACCT',
	'TIME STUDY',
	(@BEGINDATE + 5),
	21
	),
	(
	'30 MINUTES PER ACCT',
	'TIME STUDY',
	(@BEGINDATE + 1),
	14
	),
	(
	'30 MINUTES PER ACCT',
	'TIME STUDY',
	(@BEGINDATE + 2),
	14
	),
	(
	'30 MINUTES PER ACCT',
	'TIME STUDY',
	(@BEGINDATE + 3),
	14
	),
	(
	'30 MINUTES PER ACCT',
	'TIME STUDY',
	(@BEGINDATE + 4),
	14
	),
	(
	'30 MINUTES PER ACCT',
	'TIME STUDY',
	(@BEGINDATE + 5),
	14
	),
	(
	'45 MINUTES PER ACCT',
	'TIME STUDY',
	(@BEGINDATE + 1),
	9
	),
	(
	'45 MINUTES PER ACCT',
	'TIME STUDY',
	(@BEGINDATE + 2),
	9
	),
	(
	'45 MINUTES PER ACCT',
	'TIME STUDY',
	(@BEGINDATE + 3),
	9
	),
	(
	'45 MINUTES PER ACCT',
	'TIME STUDY',
	(@BEGINDATE + 4),
	9
	),
	(
	'45 MINUTES PER ACCT',
	'TIME STUDY',
	(@BEGINDATE + 5),
	9
	),
	(
	'60 MINUTES PER ACCT',
	'TIME STUDY',
	(@BEGINDATE + 1),
	7
	),
	(
	'60 MINUTES PER ACCT',
	'TIME STUDY',
	(@BEGINDATE + 2),
	7
	),
	(
	'60 MINUTES PER ACCT',
	'TIME STUDY',
	(@BEGINDATE + 3),
	7
	),
	(
	'60 MINUTES PER ACCT',
	'TIME STUDY',
	(@BEGINDATE + 4),
	7
	),
	(
	'60 MINUTES PER ACCT',
	'TIME STUDY',
	(@BEGINDATE + 5),
	7
	);

------------------------------------------------------Drop Table to identify how many accounts a staff member worked in a week------------------------------------------------------
--SUMMARY TABLE: THIS TABLE SUMMARIZES THE ACCOUNTS WORKED WEEKLY PER USER
DROP TABLE IF EXISTS #ACCOUNTSWORKEDSUMMARYWEEKLY --Creating a temp table to determine how many accounts were worked throughout the week per user
CREATE TABLE #ACCOUNTSWORKEDSUMMARYWEEKLY (
	[TSUSER] [NVARCHAR](50) NULL,
	[Avg Fol AMT WKLY] [MONEY] NULL,
	[Tot Fol AMT WKLY] [MONEY] NULL,
	[ACCTS WORKED] [INT] NOT NULL
	);

INSERT INTO #ACCOUNTSWORKEDSUMMARYWEEKLY(
	TSUSER,
	[Avg Fol AMT WKLY],
	[Tot Fol AMT WKLY],
	[ACCTS WORKED]
)
	SELECT TSUSER,
		cast(round((sum(CAST(TotFolAMTDLY AS MONEY)) / sum(CAST(TSACCTSWORKED AS INT))), 2) AS MONEY) AS 'Avg Fol AMT WKLY',
		sum(CAST(TotFolAMTDLY AS MONEY)) AS 'Tot Fol AMT WKLY',
		sum(CAST(TSACCTSWORKED AS INT)) AS 'ACCTS WORKED'
	--INTO #ACCOUNTSWORKEDSUMMARYWEEKLY
	FROM #ACCOUNTSWORKEDSUMMARYDAILY
	GROUP BY TSUSER;

------------------------------------------------------Drop table to determine how many old accounts were on a staff member's worklist per week------------------------------------------------------
--DATA/SUMMARY TABLE: THIS TABLE DETERMINES HOW MANY OLD ACCOUNTS PER WEEK ON THE STAFF'S WORKLISTS
DROP TABLE IF EXISTS #CollectorWorklistOld -- Creating a temp table to determine the number of Old accounts in their worklist
CREATE TABLE #CollectorWorklistOld (
	[RESPONSIBLE COLLECTOR] [NVARCHAR](50) NULL,
	[Count of Old] [INT] NULL,
	[Report Date2] [NVARCHAR](50) NULL
	);

INSERT INTO #CollectorWorklistOld(
	[RESPONSIBLE COLLECTOR],
	[Count of Old],
	[Report Date2]
)
	SELECT [RESPONSIBLE COLLECTOR],
		COUNT(IfAcctNewOldOff) AS 'Count of Old',
		left(convert(VARCHAR, [Report Date], 101), 10) AS 'Report Date2'
	--INTO #CollectorWorklistOld
	FROM #CollectorWorklist
	WHERE IfAcctNewOldOff IN ('Old')
	GROUP BY [RESPONSIBLE COLLECTOR],
		[Report Date]
	ORDER BY COUNT(IfAcctNewOldOff) DESC;

------------------------------------------------------Drop table to determine how many accounts came off a staff member's worklist per week------------------------------------------------------
--DATA/SUMMARY TABLE: THIS TABLE DETERMINES HOW MANY RESOLVED ACCOUNTS PER WEEK ON THE STAFF'S WORKLISTS
DROP TABLE IF EXISTS #CollectorWorklistOff -- Creating a temp table to determine the number of accounts that came off their worklist within this week
CREATE TABLE #CollectorWorklistOff (
	[RESPONSIBLE COLLECTOR] [NVARCHAR](50) NULL,
	[Count of Off] [INT] NULL,
	[Report Date2] [NVARCHAR](50) NULL
	);

INSERT INTO #COLLECTORWORKLISTOFF(
	[RESPONSIBLE COLLECTOR],
	[Count of Off],
	[Report Date2]
)
	SELECT [RESPONSIBLE COLLECTOR],
		COUNT(IfAcctNewOldOff) AS 'Count of Off',
		left(convert(VARCHAR, [Report Date], 101), 10) AS 'Report Date2'
	--INTO #CollectorWorklistOff
	FROM #CollectorWorklist
	WHERE IfAcctNewOldOff IN ('Off')
	GROUP BY [RESPONSIBLE COLLECTOR],
		[Report Date]
	ORDER BY COUNT(IfAcctNewOldOff) DESC;

------------------------------------------------------Drop table to determine how many new accounts came on a staff member's worklist per week------------------------------------------------------
--DATA/SUMMARY TABLE: THIS TABLE DETERMINES HOW MANY NEW ACCOUNTS PER WEEK ON THE STAFF'S WORKLISTS
DROP TABLE IF EXISTS #CollectorWorklistNew -- Creating a temp table to determine the number of accounts that were added their worklist within this week
CREATE TABLE #COLLECTORWORKLISTNEW (
	[RESPONSIBLE COLLECTOR] [NVARCHAR](50) NULL,
	[Count of New] [INT] NULL,
	[Report Date2] [NVARCHAR](50) NULL
	);

INSERT INTO #COLLECTORWORKLISTNEW(
	[RESPONSIBLE COLLECTOR],
	[Count of New],
	[Report Date2]
)
	SELECT [RESPONSIBLE COLLECTOR],
		COUNT(IfAcctNewOldOff) AS 'Count of New',
		left(convert(VARCHAR, [Report Date], 101), 10) AS 'Report Date2'
	--INTO #CollectorWorklistNew
	FROM #CollectorWorklist
	WHERE IfAcctNewOldOff IN ('New')
	GROUP BY [RESPONSIBLE COLLECTOR],
		[Report Date]
	ORDER BY COUNT(IfAcctNewOldOff) DESC;

------------------------------------------------------Drop table to determine how many accounts are aging off the staff's worklists per week------------------------------------------------------	
--DATA TABLE: THIS TABLE DETERMINES HOW MANY ACCOUNTS AGED OUT TO 910/MEDCO
DROP TABLE IF EXISTS #AccountsAgingOffWorklistsDATA -- Creating a temp table to determine the number of accounts that came off their worklist within this week
CREATE TABLE #AccountsAgingOffWorklistsDATA (
	Pt_Representative [NVARCHAR](50) NULL,
	Pt_No [NVARCHAR](50) NULL,
	[User_ID] [NVARCHAR](50) NULL,
	[USER_DEPT] [NVARCHAR](50) NULL,
	[Fol AMT] [MONEY] NULL,
	[Last Date REP Changed] [NVARCHAR](50) NULL,
	[Week_of_Aging] [NVARCHAR](50) NULL
	);

INSERT INTO #AccountsAgingOffWorklistsDATA(
	Pt_Representative,
	Pt_No,
	[User_ID],
	[USER_DEPT],
	[Fol AMT],
	[Last Date REP Changed],
	[Week_of_Aging]
)	
SELECT DISTINCT Pt_Representative,
		Pt_No,
		b.[User_ID],
		b.USER_DEPT,
		b.[Fol AMT],
		[Last Date REP Changed],
		@begindate AS 'Week_of_Aging'
	--INTO #AccountsAgingOffWorklistsDATA
	FROM sms.dbo.Pt_Accounting_Reporting_ALT_for_Tableau a
	RIGHT JOIN #COLLECTORWORKLIST b ON a.Pt_No = b.[PATIENT NO]
	WHERE Pt_Representative IN ('910', '591')
		AND [Last Date REP Changed] BETWEEN @PRODREPORTDATE
			AND @ENDDATE;

--SUMMARY TABLE: THIS TABLE DETERMINES HOW MANY ACCOUNTS AGED OUT TO 910/MEDCO, EXCLUDING ACCOUNTS THAT AGED WITH $.01(ZERO BALANCE)
DROP TABLE IF EXISTS #AccountsAgingOffWorklists -- Creating a temp table to determine the number of accounts that came off their worklist within this week
CREATE TABLE #AccountsAgingOffWorklists (
	Pt_Representative [NVARCHAR](50) NULL,
	[USER_DEPT] [NVARCHAR](50) NULL,
	[User_ID] [NVARCHAR](50) NULL,
	[Week_of_Aging] [NVARCHAR](50) NULL,
	[Count Aged Off Worklists] [INT] NULL,
	[Tot Fol AMT AGED] [MONEY] NULL
	);

INSERT INTO #AccountsAgingOffWorklists(
	Pt_Representative,
	[USER_DEPT],
	[User_ID],
	[Week_of_Aging],
	[Count Aged Off Worklists],
	[Tot Fol AMT AGED]
)
	SELECT Pt_Representative,
		USER_DEPT,
		[User_ID],
		@begindate AS 'Week_of_Aging',
		COUNT(Pt_Representative) AS 'Count Aged Off Worklists',
		sum([Fol AMT]) AS 'Tot Fol AMT AGED'
	--INTO #AccountsAgingOffWorklists
	FROM #AccountsAgingOffWorklistsDATA
	WHERE Pt_Representative IN ('910', '591')
		AND [User_ID] IS NOT NULL
		AND [Fol AMT] != 0.01
	GROUP BY Pt_Representative,
		USER_DEPT,
		[User_ID];

------------------------------------------------------CREATED DROP TABLE TO BE USED IN FINAL OUTPUT FOR SUM OF AGED ACCTS------------------------------------------------------
--DATA/SUMMARY TABLE: THIS TABLE IS USED TO DETERMINE HOW MANY ACCTS AGED TO 910/MEDCO FOR THE UNIT
DROP TABLE IF EXISTS #UnitAcctsAged
CREATE TABLE #UnitAcctsAged (
	[USER_DEPT] NVARCHAR(50) NULL,
	[Week_of_Aging] NVARCHAR(50) NULL,
	[SUM OF AGED ACCTS] INT NULL
	);

INSERT INTO #UnitAcctsAged(
	[USER_DEPT],
	[Week_of_Aging],
	[SUM OF AGED ACCTS]
)
	SELECT USER_DEPT,
		Week_of_Aging,
		sum([Count Aged Off Worklists]) AS 'SUM OF AGED ACCTS'
	--INTO #UnitAcctsAged
	FROM #AccountsAgingOffWorklists
	GROUP BY USER_DEPT,
		Week_of_Aging;

------------------------------------------------------Drop table to combine data from Old Accts/Off Accts/New Accts/Accts Worked/Accts worked with 20% Increase------------------------------------------------------
--SUMMARY TABLE: THIS TABLE IS THE OVERALL USER WEEKLY SUMMARY OF HOW MANY ACCTS WERE WORKED/HOW MANY ACCTS ARE IN A STAFF MEMBER'S INVENTORY/HOW MANY ACCTS ARE AGED TO 910.MEDCO
DROP TABLE IF EXISTS #CollectorSummary --Creating a final Output summary to show how many acounts a user worked in a week compared to the accounts in their worklists
CREATE TABLE #CollectorSummary (
	[RESPONSIBLE COLLECTOR] NVARCHAR(50) NULL,
	[USER_DEPT] NVARCHAR(50) NULL,
	[Week Of] NVARCHAR(50) NULL,
	[Old] INT NULL,
	[Off] INT NULL,
	[New] INT NULL,
	[ACCTS Worked] INT NULL,
	[Accts Worked w. 20% Increase] INT NULL,
	[SUM_OF_AGED_ACCTS] INT NULL
	);

INSERT INTO #CollectorSummary(
	[RESPONSIBLE COLLECTOR],
	[USER_DEPT],
	[Week Of],
	[Old],
	[Off],
	[New],
	[ACCTS Worked],
	[Accts Worked w. 20% Increase],
	[SUM_OF_AGED_ACCTS]
)
SELECT left(CONCAT (
				c.[responsible collector],
				s.TSUSER
				), 6) AS 'RESPONSIBLE COLLECTOR',
		z.USER_DEPT,
		@BEGINDATE AS 'Week Of',
		isnull(C.[Count of Old], 0) AS 'Old',
		isnull(M.[Count of Off], 0) AS 'Off',
		isnull(F.[Count of New], 0) AS 'New',
		isnull(s.[ACCTS WORKED], 0) AS 'ACCTS Worked',
		cast(round(isnull(s.[ACCTS WORKED], 0) * 1.2, 0) AS INT) AS 'Accts Worked w. 20% Increase',
		isnull(sum(x.[Count Aged Off Worklists]), 0) AS 'SUM_OF_AGED_ACCTS'
	--INTO #CollectorSummary
	FROM #USERS z
	LEFT JOIN #CollectorWorklistOld C ON z.[User_ID] = c.[RESPONSIBLE COLLECTOR]
	LEFT JOIN #CollectorWorklistNew F ON z.[User_ID] = F.[RESPONSIBLE COLLECTOR]
	LEFT JOIN #CollectorWorklistOff M ON z.[User_ID] = M.[RESPONSIBLE COLLECTOR]
	FULL OUTER JOIN #ACCOUNTSWORKEDSUMMARYWEEKLY S ON z.[User_ID] = S.TSUSER
	LEFT JOIN #AccountsAgingOffWorklists x ON x.[User_ID] = z.[User_ID]
	GROUP BY left(CONCAT (
				c.[responsible collector],
				s.TSUSER
				), 6),
		z.USER_DEPT,
		[Count of Old],
		[Count of Off],
		[Count of New],
		[ACCTS WORKED]
	
	UNION
	
	SELECT left(CONCAT (
				c.[responsible collector],
				s.TSUSER
				), 6) AS 'RESPONSIBLE COLLECTOR',
		z.USER_DEPT,
		@BEGINDATE AS 'Week Of',
		isnull(C.[Count of Old], 0) AS 'Old',
		isnull(M.[Count of Off], 0) AS 'Off',
		isnull(F.[Count of New], 0) AS 'New',
		isnull(s.[ACCTS WORKED], 0) AS 'ACCTS Worked',
		cast(round(isnull(s.[ACCTS WORKED], 0) * 1.2, 0) AS INT) AS 'Accts Worked w. 20% Increase',
		isnull(sum(x.[Count Aged Off Worklists]), 0) AS 'SUM_OF_AGED_ACCTS'
	FROM #USERS z
	LEFT JOIN #CollectorWorklistOld C ON z.[User_ID] = c.[RESPONSIBLE COLLECTOR]
	LEFT JOIN #CollectorWorklistNew F ON z.[User_ID] = F.[RESPONSIBLE COLLECTOR]
	LEFT JOIN #CollectorWorklistOff M ON z.[User_ID] = M.[RESPONSIBLE COLLECTOR]
	FULL OUTER JOIN #ACCOUNTSWORKEDSUMMARYWEEKLY S ON z.[User_ID] = S.TSUSER
	LEFT JOIN #AccountsAgingOffWorklists x ON x.[User_ID] = z.[User_ID]
	GROUP BY left(CONCAT (
				c.[responsible collector],
				s.TSUSER
				), 6),
		z.USER_DEPT,
		[Count of Old],
		[Count of Off],
		[Count of New],
		[ACCTS WORKED];

------------------------------------------------------Drop table to combine data from Old Accts/Off Accts/New Accts/Accts Worked/Accts worked with 20% Increase UNIT Summary------------------------------------------------------
--SUMMARY TABLE: THIS TABLE IS THE OVERALL UNIT WEEKLY SUMMARY OF HOW MANY ACCTS WERE WORKED/HOW MANY ACCTS ARE IN A STAFF MEMBER'S INVENTORY/HOW MANY ACCTS ARE AGED TO 910.MEDCO
DROP TABLE IF EXISTS #UNITSUMMARY -- Creating a temp table to determine the number of accounts that were added their worklist within this week
CREATE TABLE #UNITSUMMARY (
	[USER_DEPT] NVARCHAR(50) NULL,
	[Week Of] NVARCHAR(50) NULL,
	[SUM_OF_OLD] INT NULL,
	[SUM_OF_OFF] INT NULL,
	[SUM_OF_NEW] INT NULL,
	[SUM_OF_ACCTS_WORKED] INT NULL,
	[SUM_OF_ACCTS_WORKED_W.20%_INCREASE] INT NULL,
	[SUM_OF_AGED_ACCTS] INT NULL
	);

INSERT INTO #UNITSUMMARY(
	[USER_DEPT],
	[Week Of],
	[SUM_OF_OLD],
	[SUM_OF_OFF],
	[SUM_OF_NEW],
	[SUM_OF_ACCTS_WORKED],
	[SUM_OF_ACCTS_WORKED_W.20%_INCREASE],
	[SUM_OF_AGED_ACCTS]
)
	SELECT #CollectorSummary.USER_DEPT,
		[Week Of],
		SUM(Old) AS 'SUM_OF_OLD',
		SUM([Off]) AS 'SUM_OF_OFF',
		SUM(New) AS 'SUM_OF_NEW',
		SUM([ACCTS WORKED]) AS 'SUM_OF_ACCTS_WORKED',
		SUM([Accts Worked w. 20% Increase]) AS 'SUM_OF_ACCTS_WORKED_W.20%_INCREASE',
		isnull(#UnitAcctsAged.[SUM OF AGED ACCTS], 0) AS 'SUM_OF_AGED_ACCTS'
	--INTO #UNITSUMMARY
	FROM #CollectorSummary
	LEFT JOIN #UnitAcctsAged ON #CollectorSummary.USER_DEPT = #UnitAcctsAged.USER_DEPT
	GROUP BY #CollectorSummary.USER_DEPT,
		[Week Of],
		#UnitAcctsAged.[SUM OF AGED ACCTS]
	ORDER BY #CollectorSummary.USER_DEPT DESC;




------------------------------------------------------First Output from Combined Table------------------------------------------------------
--SELECT [Pt_NO]
--      ,[Unit_NO]
     
--      ,count(distinct [Payer_Claim_Control_Number]) as 'ClaimCount'
--  into #claimcount   
--  FROM [SMS].[dbo].[EMSEE_Claim_No]
--  group by [Pt_NO]
--      ,[Unit_NO]
     


--ALL TRANSACTIONS: DATA
-- use and if statement to create a table if it does not exists and intsert the data into it
-- cal lthe table dbo.c_productivity_combined
--IF OBJECT_ID('dbo.c_productivity_combined', 'U') IS NULL
--	-- Create the table in the specified schema
--	CREATE TABLE dbo.c_productivity_combined (
--		pk INT IDENTITY(1, 1) NOT NULL PRIMARY KEY,
--		pt_no VARCHAR(50),
--		unique_user_id VARCHAR(50),
--		dept VARCHAR(50),
--		fol_amt VARCHAR(50),
--		fol_up_unit VARCHAR(50),
--		unit_date VARCHAR(50),
--		unique_date VARCHAR(50),
--		activity_code VARCHAR(50),
--		unit VARCHAR(50),
--		service_code VARCHAR(50),
--		ins_plan VARCHAR(50),
--		posted_amt VARCHAR(50),
--		report_run_date SMALLDATETIME,
--		report_run_year INT,
--		report_run_month INT,
--		report_run_week INT,
--		svc_cd_desc varchar
--		);

INSERT INTO dbo.c_productivity_combined (
	pt_no,
	unique_user_id,
	dept,
	fol_amt,
	fol_up_unit,
	unit_date,
	unique_date,
	activity_code,
	unit,
	service_code,
	ins_plan,
	posted_amt,
	report_run_date,
	report_run_year,
	report_run_month,
	report_run_week,
	svc_cd_desc
	--user_title
	)
SELECT DISTINCT Pt_No,
	Unique_User_ID,
	DEPT,
	[Fol AMT],
	[Fol Up Unit #],
	[Unit Date],
	Unique_Date,
	ACTIVITY_CODE,
	A.Unit,
	[Service Code],
	Ins_Plan,
	Posted_Amt,
	cast(getdate() AS SMALLDATETIME) AS report_run_date,
	DATEPART(YEAR, cast(getdate() AS DATE)) AS report_run_year,
	DATEPART(MONTH, cast(getdate() AS DATE)) AS report_run_month,
	DATEPART(WEEK, cast(getdate() AS DATE)) AS report_run_week,
	q.[Tech_Desc]
	--user_title = ( CASE
	--				WHEN unique_user_id in ('ABARBE','ABENSO','AWINFI','BGALLI','CMCCOR','DBRYA1','DHAST2','DHIRKO',
	--								'DSMITH','EPISTO','ESQUIT','FBROWN','GFARRE','JARNEM','JBROGN','JCONWA',
	--								'JMATHA','KDESPO','KGALVI','KGRIMA','KJEZEW','KKRAFF','KLINAR','LDIGIA',
	--								'LORLAN','MCASTR','MPISTO','MSILV1','MSLATE','NMURRO','NOWORK','PDINOI',
	--								'PKOMAR','PMORRO','RCOLAN','RGUTHR','RRIGOR','SGEDNE','SJAISW','SMATHE',
	--								'SSANDE','SUPV01','SUPV02','SVERMI','TCALAB','TINSIN','TKRAVI','VPADIL')
	--				THEN 'Supervisor' ELSE 'Staff' END)
FROM #CombinedTable A
LEFT JOIN #USERS B ON A.Unique_User_ID = B.[User_ID]
left join [Swarm].[dbo].[QCDEMO] q
on a.[SERVICE CODE]=q.[Svc_Cd]
WHERE pt_no IS NOT NULL;

------------------------------------------------------Second Output from Transaction Code Summary Table------------------------------------------------------
--MULTIPLE TRANSACTIONS PER ACCT: DATA
IF OBJECT_ID('dbo.c_productivity_multi_trans_per_acct', 'U') IS NULL
	CREATE TABLE dbo.c_productivity_multi_trans_per_acct (
		pk INT IDENTITY(1, 1) NOT NULL PRIMARY KEY,
		[user] VARCHAR(50),
		[dept] VARCHAR(50),
		[fol_amt] VARCHAR(50),
		[unique_date] VARCHAR(50),
		[pt_no] VARCHAR(50),
		[unit] VARCHAR(50),
		[transactions_per_acct] VARCHAR(50),
		[report_run_date] SMALLDATETIME,
		[report_run_year] INT,
		[report_run_month] INT,
		[report_run_week] INT
		--user_title VARCHAR(50)
		);

INSERT INTO dbo.c_productivity_multi_trans_per_acct (
	[user],
	[dept],
	[fol_amt],
	[unique_date],
	[pt_no],
	[unit],
	[transactions_per_acct],
	[report_run_date],
	[report_run_year],
	[report_run_month],
	[report_run_week]
	--user_title
	)
SELECT [User],
	DEPT,
	[Fol AMT],
	[Unique_Date],
	[Pt_No],
	[Unit],
	[Transactions per Acct],
	cast(getdate() AS SMALLDATETIME) AS report_run_date,
	DATEPART(YEAR, cast(getdate() AS DATE)) AS report_run_year,
	DATEPART(MONTH, cast(getdate() AS DATE)) AS report_run_month,
	DATEPART(WEEK, cast(getdate() AS DATE)) AS report_run_week
	--user_title = ( CASE
	--				WHEN [user] in ('ABARBE','ABENSO','AWINFI','BGALLI','CMCCOR','DBRYA1','DHAST2','DHIRKO',
	--								'DSMITH','EPISTO','ESQUIT','FBROWN','GFARRE','JARNEM','JBROGN','JCONWA',
	--								'JMATHA','KDESPO','KGALVI','KGRIMA','KJEZEW','KKRAFF','KLINAR','LDIGIA',
	--								'LORLAN','MCASTR','MPISTO','MSILV1','MSLATE','NMURRO','NOWORK','PDINOI',
	--								'PKOMAR','PMORRO','RCOLAN','RGUTHR','RRIGOR','SGEDNE','SJAISW','SMATHE',
	--								'SSANDE','SUPV01','SUPV02','SVERMI','TCALAB','TINSIN','TKRAVI','VPADIL')
	--				THEN 'Supervisor' ELSE 'Staff' END)
FROM #TRANSACTIONCODESUMMARY

------------------------------------------------------Third Output from the Accounts Worked Daily Table------------------------------------------------------
--ACCTS WORKED DAILY: SUMMARY
IF OBJECT_ID('dbo.c_productivity_accounts_worked_daily', 'U') IS NULL
	CREATE TABLE dbo.c_productivity_accounts_worked_daily (
		pk INT IDENTITY(1, 1) NOT NULL PRIMARY KEY,
		[user] VARCHAR(50),
		[dept] VARCHAR(50),
		[date] DATE,
		[avg_fol_amt_dly] MONEY,
		[tot_fol_amt_dly] MONEY,
		[accts_worked] INT,
		[report_run_date] SMALLDATETIME,
		[report_run_year] INT,
		[report_run_month] INT,
		[report_run_week] INT
		--user_title VARCHAR(50)
		);

INSERT INTO dbo.c_productivity_accounts_worked_daily (
	[user],
	[dept],
	[date],
	[avg_fol_amt_dly],
	[tot_fol_amt_dly],
	[accts_worked],
	[report_run_date],
	[report_run_year],
	[report_run_month],
	[report_run_week]
	--user_title
	)
SELECT A.[USER],
	A.[DEPT],
	A.[DATE],
	A.[AvgFolAMTDLY],
	A.[TotFolAMTDLY],
	A.[ACCTS_WORKED],
	cast(getdate() AS SMALLDATETIME) AS report_run_date,
	DATEPART(YEAR, cast(getdate() AS DATE)) AS report_run_year,
	DATEPART(MONTH, cast(getdate() AS DATE)) AS report_run_month,
	DATEPART(WEEK, cast(getdate() AS DATE)) AS report_run_week
	--user_title = ( CASE
	--				WHEN [USER] in ('ABARBE','ABENSO','AWINFI','BGALLI','CMCCOR','DBRYA1','DHAST2','DHIRKO',
	--								'DSMITH','EPISTO','ESQUIT','FBROWN','GFARRE','JARNEM','JBROGN','JCONWA',
	--								'JMATHA','KDESPO','KGALVI','KGRIMA','KJEZEW','KKRAFF','KLINAR','LDIGIA',
	--								'LORLAN','MCASTR','MPISTO','MSILV1','MSLATE','NMURRO','NOWORK','PDINOI',
	--								'PKOMAR','PMORRO','RCOLAN','RGUTHR','RRIGOR','SGEDNE','SJAISW','SMATHE',
	--								'SSANDE','SUPV01','SUPV02','SVERMI','TCALAB','TINSIN','TKRAVI','VPADIL')
	--				THEN 'Supervisor' ELSE 'Staff' END)
FROM (
	SELECT TSUSER AS 'USER',
		TSUSERDEPT AS 'DEPT',
		TSDATE AS 'DATE',
		AvgFolAMTDLY,
		TotFolAMTDLY,
		TSACCTSWORKED AS 'ACCTS_WORKED'
	FROM #TIMESTUDY
	
	UNION
	
	SELECT TSUSER AS 'USER',
		TSUSERDEPT AS 'DEPT',
		TSDATE AS 'DATE',
		AvgFolAMTDLY,
		TotFolAMTDLY,
		TSACCTSWORKED AS 'ACCTS_WORKED'
	FROM #ACCOUNTSWORKEDSUMMARYDAILY
	) AS A

------------------------------------------------------Fourth Output from the Accounts Aging off Worklist Table------------------------------------------------------
--ACCTS AGING TO 910.MEDCO: DATA
IF OBJECT_ID('dbo.c_productivity_accounts_aging_to_medco', 'U') IS NULL
	CREATE TABLE dbo.c_productivity_accounts_aging_to_medco (
		pk INT IDENTITY(1, 1) NOT NULL PRIMARY KEY,
		[pt_representative] VARCHAR(50),
		[pt_no] VARCHAR(50),
		[user_id] VARCHAR(50),
		[user_dept] VARCHAR(50),
		[fol_amt] MONEY,
		[last_date_rep_changed] DATE,
		[week_of_aging] DATE,
		[report_run_date] SMALLDATETIME,
		[report_run_year] INT,
		[report_run_month] INT,
		[report_run_week] INT
		--user_title VARCHAR(50)
		);

INSERT INTO dbo.c_productivity_accounts_aging_to_medco (
	[pt_representative],
	[pt_no],
	[user_id],
	[user_dept],
	[fol_amt],
	[last_date_rep_changed],
	[week_of_aging],
	[report_run_date],
	[report_run_year],
	[report_run_month],
	[report_run_week]
	--user_title
	)
SELECT Pt_Representative,
	Pt_No,
	[USER_ID],
	USER_DEPT,
	[Fol AMT],
	[Last Date REP Changed],
	Week_of_Aging,
	cast(GETDATE() AS SMALLDATETIME) AS report_run_date,
	DATEPART(YEAR, cast(GETDATE() AS DATE)) AS report_run_year,
	DATEPART(MONTH, cast(GETDATE() AS DATE)) AS report_run_month,
	DATEPART(WEEK, cast(GETDATE() AS DATE)) AS report_run_week
	--user_title = ( CASE
	--				WHEN [user_id] in ('ABARBE','ABENSO','AWINFI','BGALLI','CMCCOR','DBRYA1','DHAST2','DHIRKO',
	--								'DSMITH','EPISTO','ESQUIT','FBROWN','GFARRE','JARNEM','JBROGN','JCONWA',
	--								'JMATHA','KDESPO','KGALVI','KGRIMA','KJEZEW','KKRAFF','KLINAR','LDIGIA',
	--								'LORLAN','MCASTR','MPISTO','MSILV1','MSLATE','NMURRO','NOWORK','PDINOI',
	--								'PKOMAR','PMORRO','RCOLAN','RGUTHR','RRIGOR','SGEDNE','SJAISW','SMATHE',
	--								'SSANDE','SUPV01','SUPV02','SVERMI','TCALAB','TINSIN','TKRAVI','VPADIL')
	--				THEN 'Supervisor' ELSE 'Staff' END)
FROM #AccountsAgingOffWorklistsDATA

------------------------------------------------------Fifth Output stating how many accounts aged off to a specific rep number per week------------------------------------------------------
--ACCTS AGING OFF WORKLISTS: SUMMARY
IF OBJECT_ID('dbo.c_productivity_accounts_aging_off_worklist_summary', 'U') IS NULL
	CREATE TABLE dbo.c_productivity_accounts_aging_off_worklist_summary (
		pk INT IDENTITY(1, 1) NOT NULL PRIMARY KEY,
		[user_dept] VARCHAR(50),
		[user_id] VARCHAR(50),
		[pt_representative] VARCHAR(50),
		[week_of_aging] DATE,
		[count_aged_off_worklists] INT,
		[tot_fol_amt_aged] MONEY,
		[report_run_date] SMALLDATETIME,
		[report_run_year] INT,
		[report_run_month] INT,
		[report_run_week] INT
		--user_title VARCHAR(50)
		);

INSERT INTO dbo.c_productivity_accounts_aging_off_worklist_summary (
	[user_dept],
	[user_id],
	[pt_representative],
	[week_of_aging],
	[count_aged_off_worklists],
	[tot_fol_amt_aged],
	[report_run_date],
	[report_run_year],
	[report_run_month],
	[report_run_week]
	--user_title
	)
SELECT [USER_DEPT],
	[USER_ID],
	[Pt_Representative],
	[Week_of_Aging],
	[Count Aged Off Worklists],
	[Tot Fol AMT AGED],
	cast(getdate() AS SMALLDATETIME) AS report_run_date,
	DATEPART(YEAR, cast(getdate() AS DATE)) AS report_run_year,
	DATEPART(month, cast(getdate() AS DATE)) AS report_run_month,
	DATEPART(week, cast(getdate() AS DATE)) AS report_run_week
	--user_title = ( CASE
	--				WHEN [USER_ID] in ('ABARBE','ABENSO','AWINFI','BGALLI','CMCCOR','DBRYA1','DHAST2','DHIRKO',
	--								'DSMITH','EPISTO','ESQUIT','FBROWN','GFARRE','JARNEM','JBROGN','JCONWA',
	--								'JMATHA','KDESPO','KGALVI','KGRIMA','KJEZEW','KKRAFF','KLINAR','LDIGIA',
	--								'LORLAN','MCASTR','MPISTO','MSILV1','MSLATE','NMURRO','NOWORK','PDINOI',
	--								'PKOMAR','PMORRO','RCOLAN','RGUTHR','RRIGOR','SGEDNE','SJAISW','SMATHE',
	--								'SSANDE','SUPV01','SUPV02','SVERMI','TCALAB','TINSIN','TKRAVI','VPADIL')
	--				THEN 'Supervisor' ELSE 'Staff' END)
FROM #AccountsAgingOffWorklists

------------------------------------------------------Sixth Output-----------------------------------------------------
--WEEKLY USER SUMMARY: SUMMARY
IF OBJECT_ID('dbo.c_productivity_weekly_user_summary', 'U') IS NULL
	CREATE TABLE dbo.c_productivity_weekly_user_summary (
		pk INT IDENTITY(1, 1) NOT NULL PRIMARY KEY,
		[responsible_collector] VARCHAR(50),
		[user_dept] VARCHAR(50),
		[week_of] DATE,
		[old] INT,
		[off] INT,
		[new] INT,
		[accts_worked] INT,
		[accts_worked_w_20pct_increase] INT,
		[sum_of_aged_accts] INT,
		[report_run_date] SMALLDATETIME,
		[report_run_year] INT,
		[report_run_month] INT,
		[report_run_week] INT
		--user_title VARCHAR(50)
		);

INSERT INTO dbo.c_productivity_weekly_user_summary (
	[responsible_collector],
	[user_dept],
	[week_of],
	[old],
	[off],
	[new],
	[accts_worked],
	[accts_worked_w_20pct_increase],
	[sum_of_aged_accts],
	[report_run_date],
	[report_run_year],
	[report_run_month],
	[report_run_week]
	--user_title
	)
SELECT [RESPONSIBLE COLLECTOR],
	[user_dept],
	[week of],
	[old],
	[off],
	[new],
	[accts worked],
	[accts worked w. 20% increase],
	[SUM_OF_AGED_ACCTS],
	cast(getdate() AS SMALLDATETIME) AS report_run_date,
	DATEPART(YEAR, cast(getdate() AS DATE)) AS report_run_year,
	DATEPART(MONTH, cast(getdate() AS DATE)) AS report_run_month,
	datepart(week, cast(getdate() AS DATE)) AS report_run_week
	--user_title = ( CASE
	--				WHEN [RESPONSIBLE COLLECTOR] in ( 'ABARBE','ABENSO','AWINFI','BGALLI','CMCCOR','DBRYA1','DHAST2','DHIRKO',
	--									'DSMITH','EPISTO','ESQUIT','FBROWN','GFARRE','JARNEM','JBROGN','JCONWA',
	--									'JMATHA','KDESPO','KGALVI','KGRIMA','KJEZEW','KKRAFF','KLINAR','LDIGIA',
	--									'LORLAN','MCASTR','MPISTO','MSILV1','MSLATE','NMURRO','NOWORK','PDINOI',
	--									'PKOMAR','PMORRO','RCOLAN','RGUTHR','RRIGOR','SGEDNE','SJAISW','SMATHE',
	--									'SSANDE','SUPV01','SUPV02','SVERMI','TCALAB','TINSIN','TKRAVI','VPADIL')
	--				THEN 'Supervisor' ELSE 'Staff' END)
FROM #CollectorSummary
WHERE [RESPONSIBLE COLLECTOR] != ''
	AND [RESPONSIBLE COLLECTOR] IS NOT NULL

------------------------------------------------------Seventh Output, final summary of accounts worked per week------------------------------------------------------
--WEEKLY UNIT SUMMARY: SUMMARY
IF OBJECT_ID('dbo.c_productivity_weekly_unit_summary', 'U') IS NULL
	CREATE TABLE dbo.c_productivity_weekly_unit_summary (
		pk INT IDENTITY(1, 1) NOT NULL PRIMARY KEY,
		[user_dept] VARCHAR(50),
		[week_of] DATE,
		[sum_of_old] INT,
		[sum_of_new] INT,
		[sum_of_accts_worked] INT,
		[sum_of_accts_worked_w_20pct_increase] INT,
		[sum_of_aged_accts] INT,
		[report_run_date] SMALLDATETIME,
		[report_run_year] INT,
		[report_run_month] INT,
		[report_run_week] INT
		);

INSERT INTO dbo.c_productivity_weekly_unit_summary (
	[user_dept],
	[week_of],
	[sum_of_old],
	[sum_of_new],
	[sum_of_accts_worked],
	[sum_of_accts_worked_w_20pct_increase],
	[sum_of_aged_accts],
	[report_run_date],
	[report_run_year],
	[report_run_month],
	[report_run_week]
	)
SELECT [user_dept],
	[week of],
	[sum_of_old],
	[sum_of_new],
	[sum_of_accts_worked],
	[sum_of_accts_worked_w.20%_increase],
	[SUM_OF_AGED_ACCTS],
	cast(getdate() AS SMALLDATETIME) AS report_run_date,
	DATEPART(YEAR, cast(getdate() AS DATE)) AS report_run_year,
	datepart(month, cast(getdate() AS DATE)) AS report_run_month,
	datepart(week, cast(getdate() AS DATE)) AS report_run_week
FROM #UNITSUMMARY
WHERE SUM_OF_OLD != 0
	AND SUM_OF_OFF != 0
	AND SUM_OF_NEW != 0
	AND SUM_OF_ACCTS_WORKED != 0
	AND [SUM_OF_ACCTS_WORKED_W.20%_INCREASE] != 0;

------------------------------------------------------Eighth Output, payer org transaction summary by dept and user------------------------------------------------------
DROP TABLE IF EXISTS dbo.c_productivity_payer_orgs;

CREATE TABLE dbo.c_productivity_payer_orgs (
		pk INT IDENTITY(1, 1) NOT NULL PRIMARY KEY,
		[Report_Date] DATE,
		[Dept] VARCHAR(50),
		[User] VARCHAR(50),
		[Payer_Org] VARCHAR(50),
		[Product_Class] VARCHAR(50),
		[Instances] INT
		);

INSERT INTO dbo.c_productivity_payer_orgs (
	[Report_Date],
	[Dept],
	[User],
	[Payer_Org],
	[Product_Class],
	[Instances]
	)
SELECT 
	 z.[Report Date] AS [Report_Date]
	,z.dept AS [Dept]
	,z.[user] AS [User]
	,z.payer_organization AS [Payer_Org]
	,z.product_class AS [Product_Class]
	,count(z.[Pyr ID]) AS [Instances]
FROM (
	SELECT DISTINCT
		 a.pk
		,a.[user]
		,a.dept
		,a.unique_date
		,a.pt_no
		,a.unit
		,a.transactions_per_acct
		,a.report_run_date
		,a.report_run_year
		,a.report_run_month
		,a.report_run_week
		,b.[Report Date]
		,b.[WORKLIST]
		,b.[WORKLIST NAME]
		,b.[Pyr ID]
		,b.[Fol AMT]
		,b.[Seq No]
		,b.[FILE]
		,c.payer_organization
		,c.product_class
	FROM
		sms.dbo.c_productivity_multi_trans_per_acct AS a
		LEFT JOIN swarm.dbo.CW_DTL_productivity AS b
			ON a.pt_no = b.[PATIENT NO]  
		RIGHT JOIN sms.dbo.c_tableau_insurance_tbl AS c
			ON rtrim(b.[Pyr ID]) = rtrim(c.code) 
			AND [Report Date] >= '2023-05-31'
	WHERE
		a.report_run_date = (SELECT max(report_run_date) FROM sms.dbo.c_productivity_multi_trans_per_acct)
		) AS z
GROUP BY
	[Report Date],
	dept,
	[user],
	payer_organization,
	product_class
ORDER BY
	[Report Date],
	payer_organization ASC;

------------------------------------------------------Ninth Output, Service Code Count by Dept and User------------------------------------------------------
DROP TABLE IF EXISTS dbo.c_productivity_service_codes;

CREATE TABLE dbo.c_productivity_service_codes (
		pk INT IDENTITY(1, 1) NOT NULL PRIMARY KEY,
		[Report_Run_Date] DATE,
		[Dept] VARCHAR(50),
		[User] VARCHAR(50),
		[Payer_Org] VARCHAR(50),
		[Service_Code] VARCHAR(50),
		[Service_Code_Description] VARCHAR(256),
		[Svc_Cd_Instances] INT
		--user_title VARCHAR(50)
		);

DROP TABLE IF exists #Temp1;
SELECT
	*
INTO
	#Temp1 
FROM
	[SMS].[dbo].[c_tableau_insurance_tbl]
	LEFT JOIN swarm.[dbo].CW_DTL_productivity
		ON code = [Pyr ID]
		AND [Report Date] >= '2023-05-31';

DROP TABLE IF exists #Temp2;
SELECT DISTINCT
--SELECT
	 [pk]
	,[pt_no]
	,[unique_user_id]
	,[dept]
	,[fol_amt]
	,[fol_up_unit]
	,[unit_date]
	,[unique_date]
	,[activity_code]
	,[unit]
	,[service_code]
	,isnull([ins_plan], #Temp1.[Pyr ID]) as [Payer_ID]
	,#Temp1.payer_organization
	,[posted_amt]
	,[report_run_date]
	,[report_run_year]
	,[report_run_month]
	,[report_run_week]
	,[svc_cd_desc]
INTO
	#Temp2
FROM
	[SMS].[dbo].[c_productivity_combined]
	LEFT JOIN #Temp1
		ON pt_no = [PATIENT NO] --and [Report Date] >= '2023-05-31';
WHERE
	report_run_date >= '2023-05-31';

INSERT INTO dbo.c_productivity_service_codes (
	[Report_Run_Date],
	[Dept],
	[User],
	[Payer_Org],
	[Service_Code],
	[Service_Code_Description],
	[Svc_Cd_Instances]
	--user_title
	)
SELECT
	report_run_date AS [Report_Run_Date],
	dept AS [Dept],
	unique_user_id AS [User],
	payer_organization AS [Payer_Org],
	service_code AS [Service_Code],
	CDM.[General Description] AS [Service_Code_Description],
	count(service_code) AS [Svc_Cd_Instances] --count(payer_organization) AS [Svc_Cd_Instances]
	--user_title = ( CASE
	--				WHEN unique_user_id in ('ABARBE','ABENSO','AWINFI','BGALLI','CMCCOR','DBRYA1','DHAST2','DHIRKO',
	--								'DSMITH','EPISTO','ESQUIT','FBROWN','GFARRE','JARNEM','JBROGN','JCONWA',
	--								'JMATHA','KDESPO','KGALVI','KGRIMA','KJEZEW','KKRAFF','KLINAR','LDIGIA',
	--								'LORLAN','MCASTR','MPISTO','MSILV1','MSLATE','NMURRO','NOWORK','PDINOI',
	--								'PKOMAR','PMORRO','RCOLAN','RGUTHR','RRIGOR','SGEDNE','SJAISW','SMATHE',
	--								'SSANDE','SUPV01','SUPV02','SVERMI','TCALAB','TINSIN','TKRAVI','VPADIL')
	--				THEN 'Supervisor' ELSE 'Staff' END)
FROM
	#Temp2
	LEFT JOIN swarm.dbo.CDM as CDM
		ON #Temp2.service_code = CDM.[Service Code]
WHERE
	service_code is not null
GROUP BY
	report_run_date,
	dept,
	unique_user_id,
	service_code,
	[General Description],
	payer_organization
ORDER BY
	report_run_date,
	dept,
	unique_user_id,
	payer_organization,
	count(payer_organization) DESC;

------------------------------------------------------Tenth Output, Activity Code Count by Dept and User------------------------------------------------------
DROP TABLE IF EXISTS dbo.c_productivity_activity_codes;

CREATE TABLE dbo.c_productivity_activity_codes (
		pk INT IDENTITY(1, 1) NOT NULL PRIMARY KEY,
		[Report_Run_Date] DATE,
		[Dept] VARCHAR(50),
		[User] VARCHAR(50),
		[Payer_Org] VARCHAR(50),
		[Activity_Code] VARCHAR(50),
		[Activity_Code_Description] VARCHAR(256),
		[Act_Cd_Instances] INT
		--user_title VARCHAR(50)
		);

INSERT INTO dbo.c_productivity_activity_codes (
	[Report_Run_Date],
	[Dept],
	[User],
	[Payer_Org],
	[Activity_Code],
	[Activity_Code_Description],
	[Act_Cd_Instances]
	--user_title
	)
SELECT
	report_run_date AS [Report_Run_Date],
	dept AS [Dept],
	unique_user_id AS [User],
	payer_organization AS [Payer_Org],
	activity_code AS [Activity_Code],
	ACT.activity_description AS [Activity_Code_Description],
	count(activity_code) AS [Act_Cd_Instances] --count(payer_organization) AS [Act_Cd_Instances]
	--user_title = ( CASE
	--				WHEN unique_user_id in ('ABARBE','ABENSO','AWINFI','BGALLI','CMCCOR','DBRYA1','DHAST2','DHIRKO',
	--								'DSMITH','EPISTO','ESQUIT','FBROWN','GFARRE','JARNEM','JBROGN','JCONWA',
	--								'JMATHA','KDESPO','KGALVI','KGRIMA','KJEZEW','KKRAFF','KLINAR','LDIGIA',
	--								'LORLAN','MCASTR','MPISTO','MSILV1','MSLATE','NMURRO','NOWORK','PDINOI',
	--								'PKOMAR','PMORRO','RCOLAN','RGUTHR','RRIGOR','SGEDNE','SJAISW','SMATHE',
	--								'SSANDE','SUPV01','SUPV02','SVERMI','TCALAB','TINSIN','TKRAVI','VPADIL')
	--				THEN 'Supervisor' ELSE 'Staff' END)
FROM
	#Temp2
	LEFT JOIN sms.dbo.c_activity_code_tbl as ACT
		ON #Temp2.activity_code = ACT.actv
WHERE
	activity_code is not null
GROUP BY
	report_run_date,
	dept,
	unique_user_id,
	activity_code,
	activity_description,
	payer_organization
ORDER BY
	report_run_date,
	dept,
	unique_user_id,
	payer_organization,
	count(payer_organization) DESC;

END;