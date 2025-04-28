/*
***********************************************************************
File: c_ar_fc_composition.sql

Input Parameters:
	None

Tables/Views:
	sms.dbo.Pt_Accounting_Reporting_ALT
	para.dbo.Pt_Accounting_Reporting_ALT_Backup

Creates Table/View:
	None

Functions:
	None

Author: Steven P. Sanderson II, MPH

Department: Patient Financial Services

Purpose/Description
	Aggregate the total balance amounts for each FC and File combination

Revision History:
Date		Version		Description
----		----		----
2018-07-13	v1			Initial Creation
***********************************************************************
*/
DECLARE @START_DATE AS DATE;

SET @START_DATE = '2024-01-01';

-- create all unique fc and file combinations
DROP TABLE IF EXISTS #FCAndFileCombo_tbl;
SELECT DISTINCT FC,
	[ar_type] = [File]
INTO #FCAndFileCombo_tbl
FROM SMS.dbo.Pt_Accounting_Reporting_ALT
WHERE FC != 'X'
OPTION (HASH GROUP);

DROP TABLE IF EXISTS #TotalBalances_tbl;
SELECT [snapshot_date] = CAST(DATEADD(DAY, -1, EOMonth_Timestamp) AS date),
	SUM(Balance) AS TotalBal
INTO #TotalBalances_tbl
FROM para.dbo.Pt_Accounting_Reporting_ALT_Backup
WHERE EOMonth_Timestamp >= @START_DATE
AND Active_Archive = 'ACTIVE'
AND FC != 'X'
AND Tot_Chgs > 0
GROUP BY EOMonth_Timestamp;

DROP TABLE IF EXISTS #PercentToTotals_tbl;
SELECT [snapshot_date] = CAST(DATEADD(DAY, -1, B.EOMonth_Timestamp) AS date),
	A.[FC],
	A.ar_type,
	[tot_bal_amt] = SUM(B.Balance),
	[percent_to_total] = CASE
		WHEN C.TotalBal = 0 
			THEN 0
		ELSE SUM(B.Balance) * 1.0 / C.TotalBal * 100 
		END
INTO #PercentToTotals_tbl
FROM #FCAndFileCombo_tbl AS A
LEFT OUTER JOIN para.dbo.Pt_Accounting_Reporting_ALT_Backup AS B ON A.ar_type = B.[File]
	AND A.FC = B.FC
INNER JOIN #TotalBalances_tbl AS C ON CAST(DATEADD(DAY, -1, B.EOMonth_Timestamp) AS date) = C.snapshot_date
WHERE B.EOMonth_Timestamp >= @START_DATE
AND B.Active_Archive = 'ACTIVE'
AND B.FC != 'X'
AND B.Tot_Chgs > 0
GROUP BY B.EOMonth_Timestamp, C.TotalBal, A.FC, A.ar_type;

SELECT snapshot_date, 
	FC,
	ar_type,
	[category] = CONCAT(FC, ' - ', ar_type),
	[tot_bal_amt] = CAST(tot_bal_amt AS money),
	[percent_to_total] = CAST(ROUND(percent_to_total, 2) AS FLOAT(2)),
	[cumulative_percent] = CAST(ROUND(SUM(percent_to_total) OVER (
		PARTITION BY snapshot_date
		ORDER BY snapshot_date, FC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
		, 2
	) AS float(2))
FROM #PercentToTotals_tbl
ORDER BY snapshot_date, FC, ar_type;