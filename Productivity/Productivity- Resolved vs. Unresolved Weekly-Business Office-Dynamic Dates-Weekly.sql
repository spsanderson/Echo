/* Productivity Version 2 as of 3/29/2023 */
DECLARE @BEGINDATE DATETIME
DECLARE @ENDDATE DATETIME
DECLARE @PRODREPORTDATE DATETIME
DECLARE @ThisDate DATETIME

SET @ThisDate = getdate()
SET @BEGINDATE = dateadd(wk, datediff(wk, 0, @ThisDate) - 1, - 1)
SET @ENDDATE = dateadd(wk, datediff(wk, 0, @ThisDate) - 1, 6)
SET @PRODREPORTDATE = @BEGINDATE - 1

DROP TABLE IF EXISTS DBO.#USERS
	SELECT DISTINCT TOP (1000) [User_ID],
		CAST(NULL AS VARCHAR) AS 'UNIT'
	INTO #USERS
	FROM SWARM.DBO.[OAMCOMB ]
	WHERE [User_ID] IN ('AWINFI', 'CHALL ', 'CPAREN', 'KPERDI', 'KWASHI', 'RHOAG ', 'TARNAL', 'BSHARA', 'FCOFFE', 'JCONWA', 'RNEUGE', 'SZULUA', 'AHIGGI', 'CPIACE', 'CVETRO', 'LMOSCO', 'LWERTH', 'NMURRO', 'JCHANC', 'JTHEBN', 'JBROGN', 'LSACKA', 'SPAULR', 'DBRAUN', 'EBROW2', 'AHERNA', 'ABENSO', 'ESQUIT', 'KBALZ1', 'PDINOI', 'JDEMOT', 'TLYNCH', 'YYANG1', 'DFEENE', 'BGALLI', 'MSILV1', 'KLINAR', 'KMCDON', 'KRICE', 'MAUDIT', 'DTORRE', 'SCRUET', 'LDONOV', 'JGONZA')

UPDATE #USERS
SET UNIT = 'VARIANCE'
WHERE [User_ID] IN ('PDINOI', 'JDEMOT', 'TLYNCH', 'YYANG1', 'DFEENE', 'BGALLI', 'KBALZ1')

UPDATE #USERS
SET UNIT = 'RECURRING'
WHERE [User_ID] IN ('ESQUIT', 'ABENSO', 'AHERNA', 'EBROW2', 'DBRAUN')

UPDATE #USERS
SET UNIT = 'NON-GOVERNMENTAL FOLLOW UP'
WHERE [User_ID] IN ('AHIGGI', 'CPIACE', 'CVETRO', 'LMOSCO', 'LWERTH', 'NMURRO', 'JCHANC', 'JTHEBN', 'JBROGN', 'LSACKA', 'SPAULR')

UPDATE #USERS
SET UNIT = 'CUSTOMER SERVICE'
WHERE [User_ID] IN ('AWINFI', 'CHALL ', 'CPAREN', 'KPERDI', 'KWASHI', 'RHOAG ', 'TARNAL')

UPDATE #USERS
SET UNIT = 'FINANCIAL ASSISTANCE'
WHERE [User_ID] IN ('BSHARA', 'FCOFFE', 'JCONWA', 'RNEUGE', 'SZULUA')

UPDATE #USERS
SET UNIT = 'DENIALS & APPEALS'
WHERE [User_ID] IN ('MSILV1', 'KLINAR', 'KMCDON', 'KRICE', 'MAUDIT', 'DTORRE', 'SCRUET', 'LDONOV', 'JGONZA')

DROP TABLE IF EXISTS #ACPRODUCTIVITY
	--Creating a temp table of all Activity codes posted by Users in the Business office
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
	INTO #ACPRODUCTIVITY
	FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[ECHO_ACTIVE].[DBO].[ACCOUNTCOMMENTS] F
	RIGHT JOIN #USERS M ON SUBSTRING([PA-SMART-COMMENT], 6, 6) = M.[User_ID]
	WHERE [PA-SMART-DATE] BETWEEN @BEGINDATE
			AND @ENDDATE

DROP TABLE IF EXISTS #TCPRODUCTIVITY
	--Creating a temp table of all Transaction codes posted by Users in the Business office
	SELECT [PA_File],
		[Batch_No],
		[Encounter Number],
		CASE
			WHEN t.[Unit] = ''
				THEN 'A'
			ELSE T.[Unit]
		END	AS 'Unit',
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
		[Encounter Number] + '_' + t.[Unit] + '_' + convert(VARCHAR, [Post_Date], 101) + '_' + t.[User_ID] AS 'Unique for Join'
	INTO #TCPRODUCTIVITY
	FROM [SWARM].[DBO].[OAMCOMB ] T
	RIGHT JOIN #USERS M ON t.[User_ID] = M.[User_ID]
	WHERE [POST_DATE] BETWEEN @BEGINDATE
			AND @ENDDATE

-- UPDATE #TCPRODUCTIVITY
-- SET Unit = 'A'
-- WHERE Unit = ''

DROP TABLE IF EXISTS dbo.#PRECOMBINE
	--Creating a temp table for step 1 of combining the TC/AC tables
	SELECT #ACPRODUCTIVITY.Unique_for_Join AS 'UNIQUE FOR JOIN',
		#ACPRODUCTIVITY.Pt_No AS 'PTNUM'
	INTO #PRECOMBINE
	FROM #ACPRODUCTIVITY
	
	UNION
	
	SELECT #TCPRODUCTIVITY.[Unique for Join] AS 'UNIQUE FOR JOIN',
		#TCPRODUCTIVITY.[Encounter Number] AS 'PTNUM'
	FROM #TCPRODUCTIVITY

DROP TABLE IF EXISTS DBO.#COMBINEDTABLE
	--Creating a temp table to represent all transactions posted, combining Activity Codes and Transaction Codes
	SELECT M.[UNIQUE FOR JOIN],
		isnull(f.Pt_No, t.[Encounter Number]) AS 'Pt_No',
		left(isnull(f.[USER-ID], t.[User_ID]), 6) AS 'Unique_User_ID',
		f.[USER-ID] AS 'Activity Code User ID',
		t.[User_ID] AS 'Transaction Code User ID',
		left(CONCAT (
				f.[USER-ID],
				t.[User_ID]
				), 6) + '_' + f.Pt_No + '_' + f.[ACTIVITY_CODE] + '_' + left(CONCAT (
				f.SmartDate,
				t.Post_Date
				), 10) AS 'Unique ID' --Unique ID for Activity Codes
		,
		SUBSTRING([PA-SMART-COMMENT], 6, 6) + '_' + CAST([PA-PT-NO-WOSCD] AS VARCHAR) + CAST([PA-PT-NO-SCD-1] AS VARCHAR) + '_' + convert(VARCHAR, f.SmartDate, 101) AS 'Unique Code',
		left(CONCAT (
				f.SmartDate,
				t.Post_Date
				), 10) AS 'Unique_Date',
		left(CONCAT (
				[USER-ID],
				t.[User_ID]
				), 6) + '_' + ISNULL(t.[Encounter Number], f.Pt_No) + '_' + ISNULL(t.Unit, 'A') + '_' + left(CONCAT (
				SmartDate,
				Post_Date
				), 10) AS 'Unique_Pt_No' -- Unique for Transaction Codes
		,
		f.[USER-ID],
		f.Pt_No AS 'Activity Code Pt No',
		f.[ACTIVITY_CODE],
		f.SmartDate,
		t.[User_ID],
		t.[Encounter Number] AS 'Transaction Code Pt No',
		t.Unit --pulling the Unit from the TCPRODUCTIVITY table
		,
		t.[Service Code],
		t.Ins_Plan,
		t.[Posted_Amt],
		t.Post_Date,
		t.[Encounter Number]
	INTO #CombinedTable
	FROM #PRECOMBINE M
	FULL OUTER JOIN #ACPRODUCTIVITY F ON M.[UNIQUE FOR JOIN] = F.Unique_for_Join
	FULL OUTER JOIN #TCPRODUCTIVITY t ON M.[UNIQUE FOR JOIN] = t.[Unique for Join]
	RIGHT JOIN #USERS z ON z.[User_ID] = isnull(f.[USER-ID], t.[User_ID])

UPDATE #CombinedTable
SET Unique_Pt_No = [Unique Code]
WHERE Unique_Pt_No IS NULL

SELECT Pt_No,
	Unique_User_ID,
	[Activity Code User ID],
	[Transaction Code User ID],
	Unique_Date,
	[User-ID],
	[Activity Code Pt No],
	ACTIVITY_CODE,
	SmartDate,
	[User_ID],
	[Transaction Code Pt No],
	Unit,
	[Service Code],
	Ins_Plan,
	Posted_Amt,
	Post_Date,
	[Encounter Number]
FROM #CombinedTable

DROP TABLE IF EXISTS #TRANSACTIONCODESUMMARY
	--Creating a temp table to count of Multiple Transactions on Same Acct, on the same day, per user
	SELECT Unique_User_ID AS 'USER',
		Unique_Date,
		s.pt_no,
		s.Unit,
		count(Unique_Pt_No) AS 'Transactions per Acct',
		Unique_Pt_No
	INTO #TRANSACTIONCODESUMMARY
	FROM #CombinedTable s
	RIGHT JOIN #USERS m ON s.Unique_User_ID = m.[User_ID]
	GROUP BY [Unique_Pt_No],
		Unique_User_ID,
		Unique_Date,
		Pt_No,
		s.Unit
	ORDER BY COUNT([Unique_Pt_No]) DESC;

SELECT [User],
	[Unique_Date],
	[Pt_No],
	[Unit],
	[Transactions per Acct]
FROM #TRANSACTIONCODESUMMARY
ORDER BY [Transactions per Acct] DESC

DROP TABLE IF EXISTS #ACCOUNTSWORKEDSUMMARYDAILY
	-- Creating a temp table to determine how many accounts were worked on a given day per user
	SELECT [USER],
		m.UNIT,
		COUNT(Unique_Pt_No) AS '# OF ACCTS WORKED',
		Unique_Date
	INTO #ACCOUNTSWORKEDSUMMARYDAILY
	FROM #TRANSACTIONCODESUMMARY s
	RIGHT JOIN #USERS m ON s.[USER] = m.[User_ID]
	GROUP BY Unique_Date,
		[USER],
		m.UNIT
	ORDER BY COUNT(Unique_Pt_No) DESC;

SELECT *
FROM #ACCOUNTSWORKEDSUMMARYDAILY
WHERE [user] IS NOT NULL

DROP TABLE IF EXISTS DBO.#ACCOUNTSWORKEDSUMMARYWEEKLY
	--Creating a temp table to determine how many accounts were worked throughout the week per user
	SELECT CAST(datepart(week, Unique_Date) AS VARCHAR) AS 'WEEK',
		[USER],
		sum([# OF ACCTS WORKED]) AS 'ACCTS WORKED'
	INTO #ACCOUNTSWORKEDSUMMARYWEEKLY
	FROM #ACCOUNTSWORKEDSUMMARYDAILY
	GROUP BY datepart([WEEK], Unique_Date),
		[USER] --,Unique_Date

DROP TABLE IF EXISTS DBO.#COLLECTORWORKLIST
	SELECT *
	INTO #CollectorWorklist
	FROM swarm.dbo.CW_DTL_productivity c
	RIGHT JOIN #USERS z ON c.[RESPONSIBLE COLLECTOR] = z.[User_ID]
	--right join #USERS m on c.[RESPONSIBLE COLLECTOR] = m.[User_ID]
	WHERE c.[Report Date] = @PRODREPORTDATE

DROP TABLE IF EXISTS DBO.#CollectorWorklistOld
	-- Creating a temp table to determine the number of Old accounts in their worklist
	SELECT [RESPONSIBLE COLLECTOR],
		COUNT(IfAcctNewOldOff) AS 'Count of Old',
		left(convert(VARCHAR, [Report Date], 101), 10) AS 'Report Date2'
	INTO #CollectorWorklistOld
	FROM #CollectorWorklist
	WHERE IfAcctNewOldOff IN ('Old')
	GROUP BY [RESPONSIBLE COLLECTOR],
		[Report Date]
	ORDER BY COUNT(IfAcctNewOldOff) DESC;

DROP TABLE IF EXISTS DBO.#CollectorWorklistOff
	-- Creating a temp table to determine the number of accounts that came off their worklist within this week
	SELECT [RESPONSIBLE COLLECTOR],
		COUNT(IfAcctNewOldOff) AS 'Count of Off',
		left(convert(VARCHAR, [Report Date], 101), 10) AS 'Report Date2'
	INTO #CollectorWorklistOff
	FROM #CollectorWorklist
	WHERE IfAcctNewOldOff IN ('Off')
	GROUP BY [RESPONSIBLE COLLECTOR],
		[Report Date]
	ORDER BY COUNT(IfAcctNewOldOff) DESC;

DROP TABLE IF EXISTS DBO.#CollectorWorklistNew
	-- Creating a temp table to determine the number of accounts that were added their worklist within this week
	SELECT [RESPONSIBLE COLLECTOR],
		COUNT(IfAcctNewOldOff) AS 'Count of New',
		left(convert(VARCHAR, [Report Date], 101), 10) AS 'Report Date2'
	INTO #CollectorWorklistNew
	FROM #CollectorWorklist
	WHERE IfAcctNewOldOff IN ('New')
	GROUP BY [RESPONSIBLE COLLECTOR],
		[Report Date]
	ORDER BY COUNT(IfAcctNewOldOff) DESC;

DROP TABLE IF EXISTS DBO.#CollectorSummary
	--Creating a final Output summary to show how many acounts a user worked in a week compared to the accounts in their worklists
	SELECT left(CONCAT (
				c.[responsible collector],
				s.[user]
				), 6) AS 'RESPONSIBLE COLLECTOR',
		z.UNIT,
		@BEGINDATE AS 'Week Of',
		C.[Count of Old],
		M.[Count of Off],
		F.[Count of New],
		s.[ACCTS WORKED],
		cast(round(s.[ACCTS WORKED] * 1.2, 0) AS INT) AS 'Accts Worked w. 20% Increase'
	INTO #CollectorSummary
	FROM #USERS z
	LEFT JOIN #CollectorWorklistOld C ON z.[User_ID] = c.[RESPONSIBLE COLLECTOR]
	LEFT JOIN #CollectorWorklistNew F ON z.[User_ID] = F.[RESPONSIBLE COLLECTOR]
	LEFT JOIN #CollectorWorklistOff M ON z.[User_ID] = M.[RESPONSIBLE COLLECTOR]
	FULL OUTER JOIN #ACCOUNTSWORKEDSUMMARYWEEKLY S ON z.[User_ID] = S.[USER]
	
	UNION
	
	SELECT left(CONCAT (
				c.[responsible collector],
				s.[user]
				), 6) AS 'RESPONSIBLE COLLECTOR',
		z.UNIT,
		@BEGINDATE AS 'Week Of',
		C.[Count of Old],
		M.[Count of Off],
		F.[Count of New],
		s.[ACCTS WORKED],
		cast(round(s.[ACCTS WORKED] * 1.2, 0) AS INT) AS 'Accts Worked w. 20% Increase'
	FROM #USERS z
	LEFT JOIN #CollectorWorklistOld C ON z.[User_ID] = c.[RESPONSIBLE COLLECTOR]
	LEFT JOIN #CollectorWorklistNew F ON z.[User_ID] = F.[RESPONSIBLE COLLECTOR]
	LEFT JOIN #CollectorWorklistOff M ON z.[User_ID] = M.[RESPONSIBLE COLLECTOR]
	FULL OUTER JOIN #ACCOUNTSWORKEDSUMMARYWEEKLY S ON z.[User_ID] = S.[USER]

UPDATE #CollectorSummary
SET [Count of Old] = 0
WHERE [Count of Old] IS NULL

UPDATE #CollectorSummary
SET [Count of Off] = 0
WHERE [Count of Off] IS NULL

UPDATE #CollectorSummary
SET [Count of New] = 0
WHERE [Count of New] IS NULL

UPDATE #CollectorSummary
SET [ACCTS WORKED] = 0
WHERE [ACCTS WORKED] IS NULL

UPDATE #CollectorSummary
SET [Accts Worked w. 20% Increase] = 0
WHERE [Accts Worked w. 20% Increase] IS NULL

SELECT *
FROM #CollectorSummary
WHERE [RESPONSIBLE COLLECTOR] != ''
ORDER BY [RESPONSIBLE COLLECTOR] ASC
