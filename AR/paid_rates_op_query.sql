/*
***********************************************************************
File: paid_rates_op_query.sql

Input Parameters:
	None

Tables/Views:
	dbo.pt_accounting_reporting_alt
    dbo.pt_type
    dbo.c_tableau_insurance_tbl

Creates Table/View:
	None

Functions:
	None

Author: Steven P. Sanderson II, MPH

Department: Patient Financial Services

Purpose/Description
	Entere Here

Revision History:
Date		Version		Description
----		----		----
2024-01-19	v1			Initial Creation
***********************************************************************
*/

DECLARE @PTTYPE TABLE (
	pt_type_cd VARCHAR(2),
	pt_type_cd_desc VARCHAR(100)
	)

INSERT INTO @PTTYPE (
	pt_type_cd,
	pt_type_cd_desc
	)
SELECT PatientTypeCode,
	PatientType
FROM dbo.pt_type

DECLARE @PYR_GROUP TABLE (
	pyr_cd VARCHAR(5),
	pyr_org VARCHAR(255),
	product_class VARCHAR(100)
	)

INSERT INTO @PYR_GROUP (
	pyr_cd,
	pyr_org,
	product_class
	)
SELECT CODE,
	payer_organization,
	product_class
FROM dbo.c_tableau_insurance_tbl

DROP TABLE IF EXISTS #PT_PG;
SELECT DISTINCT PT.pt_type_cd,
	PT.pt_type_cd_desc,
	PG.pyr_cd,
	PG.pyr_org,
	PG.product_class
INTO #PT_PG
FROM @PTTYPE AS PT
CROSS JOIN @PYR_GROUP AS PG;

-- DATE VARIABLES FOR ALL ACCOUNTS
DECLARE @START DATE
DECLARE @END DATE

-- First day of current year
SET @START = DATEADD(MONTH, DATEDIFF(MONTH, 0, CAST(GETDATE() AS DATE)) - 9, 0)
-- First day of current month
SET @END = DATEADD(MONTH, DATEDIFF(MONTH, 0, CAST(GETDATE() AS DATE)), 0)

SELECT PTPG.pt_type_cd_desc,
	PTPG.pyr_org,
	PTPG.product_class,
	COUNT(DISTINCT ALT.PT_NO) AS [VISITS],
	ISNULL(SUM(ALT.Tot_Chgs), 0) AS [TOTAL_CHARGES],
	ISNULL(SUM(ALT.TOT_PAY_AMT), 0) AS [TOTAL_PAY_AMT],
	ISNULL(SUM(ALT.BALANCE), 0) AS [TOTAL_AMT_DUE],
	ISNULL(SUM(ALT.Tot_Chgs - ALT.Expected_Payment), 0) AS [TOTAL_SYSTEM_ALLOWANCES]
FROM #PT_PG AS PTPG
LEFT OUTER JOIN DBO.Pt_Accounting_Reporting_ALT AS ALT ON PTPG.pt_type_cd = ALT.Pt_Type
	AND PTPG.pyr_cd = ALT.Ins1_Cd
	AND ALT.Dsch_Date >= @START
	AND ALT.Dsch_Date < @END
	AND ALT.Acct_Type = 'OP'
	AND ALT.Tot_Chgs > 0
	AND ALT.Balance BETWEEN - 50
		AND 50
	AND ALT.Tot_Pay_Amt != 0
GROUP BY PTPG.pt_type_cd_desc,
	PTPG.pyr_org,
	PTPG.product_class
ORDER BY PTPG.pt_type_cd_desc,
	PTPG.pyr_org,
	PTPG.product_class
