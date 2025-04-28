-- Drop the temporary table if it exists
DROP TABLE IF EXISTS #runout_dates_tbl;

-- Create a CTE to get the last 13 end-of-month timestamps
WITH CTE AS (
    SELECT TOP 13
        CAST(EOMonth_Timestamp AS DATE) AS start_eomonth_timestamp
    FROM para.dbo.Pt_Accounting_Reporting_ALT_Backup
    GROUP BY EOMonth_Timestamp
    ORDER BY EOMonth_Timestamp DESC
)
-- Create the temporary table with start and end dates
SELECT 
    start_eomonth_timestamp,
    DATEADD(MONTH, Number, start_eomonth_timestamp) AS end_eomonth_timestamp
INTO #runout_dates_tbl
FROM CTE
CROSS JOIN (
    SELECT TOP 12 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS Number
    FROM master.dbo.spt_values
) AS Numbers
ORDER BY start_eomonth_timestamp, end_eomonth_timestamp;

-- Delete the latest start date to avoid duplication
DELETE 
FROM #runout_dates_tbl
WHERE start_eomonth_timestamp = (
    SELECT MAX(start_eomonth_timestamp) 
    FROM #runout_dates_tbl
);

-- Select the remaining dates
SELECT * 
FROM #runout_dates_tbl;

-- Create a recursive CTE to union all results together
WITH start_snap_tbl AS (
    SELECT 
        Active_Archive,
        Hosp_Svc,
        Payer_organization,
        product_class,
        Pt_No,
        Unit_No,
        Unit_Date,
        Admit_Date,
        Dsch_Date,
        [start_date] = DATEADD(DAY, -1, EOMONTH_Timestamp),
        [start_fc] = FC,
        [start_ar_balance] = ISNULL(Balance, 0),
        [start_tot_chgs] = ISNULL(Tot_Chgs, 0),
        [start_tot_pay] = ISNULL(Tot_Pay_Amt, 0),
        [start_sys_allowance_amt] = ISNULL(SysAlw_Amt, 0)
    FROM PARA.dbo.Pt_Accounting_Reporting_ALT_Backup
    WHERE EOMonth_Timestamp = (SELECT MIN(start_eomonth_timestamp) FROM #runout_dates_tbl)
    AND FC NOT LIKE '%[0-9]%'
    
    UNION ALL
    
    SELECT 
        A.Active_Archive,
        A.Hosp_Svc,
        A.Payer_organization,
        A.product_class,
        A.Pt_No,
        A.Unit_No,
        A.Unit_Date,
        A.Admit_Date,
        A.Dsch_Date,
        DATEADD(DAY, -1, A.EOMonth_Timestamp) AS start_date,
        A.FC AS start_fc,
        ISNULL(A.Balance, 0) AS start_ar_balance,
        ISNULL(A.Tot_Chgs, 0) AS start_tot_chgs,
        ISNULL(A.Tot_Pay_Amt, 0) AS start_tot_pay,
        ISNULL(A.SysAlw_Amt, 0) AS start_sys_allowance_amt
    FROM PARA.dbo.Pt_Accounting_Reporting_ALT_Backup AS A
    INNER JOIN start_snap_tbl AS R ON A.Pt_No = R.Pt_No
    WHERE A.EOMonth_Timestamp != (SELECT MIN(start_eomonth_timestamp) FROM #runout_dates_tbl)
    AND A.FC NOT LIKE '%[0-9]%'
)

-- Select all results from the recursive CTE
SELECT *
FROM start_snap_tbl;
