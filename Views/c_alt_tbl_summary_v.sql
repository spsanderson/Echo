/*
***********************************************************************
File: c_alt_tbl_summary_v.sql

Input Parameters:
	None

Tables/Views:
	SMS.dbo.Pt_Accounting_Reporting_ALT

Creates Table/View:
	dbo.c_alt_tbl_summary_v

Functions:
	None

Author: Steven P. Sanderson II, MPH

Department: Patient Financial Services

Purpose/Description
	Create a summary view of the ALT table to see if it has successfully
    updated with the latest data.

Revision History:
Date		Version		Description
----		----		----
2026-03-04	v1			Initial Creation
2026-03-05  v2          Fix update_date_time column to just update_date
***********************************************************************
*/

USE SMS
GO

-- Create a view to summarize the data from Pt_Accounting_Reporting_ALT
ALTER VIEW dbo.c_alt_tbl_summary_v
AS
    -- body of the view
SELECT 
    [visit_count] = COUNT(*),
    [balance] = SUM(BALANCE),
    [active_archive_ind] = Active_Archive,
    [file_type] = [FILE],
    [acct_type] = Acct_Type,
    [update_date] = CAST(SP_RunDateTime AS DATE),
    [update_time] = CONVERT(VARCHAR(8), SP_rundatetime, 108)
FROM SMS.dbo.Pt_Accounting_Reporting_ALT
GROUP BY Active_Archive,
         [FILE],
         [Acct_Type],
         SP_RunDateTime,
         CAST(SP_rundatetime as time)

UNION ALL

SELECT 
    [visit_count] = SUM(COUNT(*)) OVER(),
    [balance] = SUM(SUM(BALANCE)) OVER(),
    [active_archive_ind] = 'GRAND TOTALS',
    [file_type] = NULL,
    [acct_type] = NULL,
    [update_date] = NULL,
    [update_time] = NULL
FROM SMS.dbo.Pt_Accounting_Reporting_ALT
GO
