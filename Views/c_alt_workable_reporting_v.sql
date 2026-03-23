USE [SMS]
GO
/*
***********************************************************************
File: c_alt_workable_reporting_v.sql

Input Parameters:
	None

Tables/Views:
    sms.dbo.c_workable_indicator_tbl
    sms.dbo.pt_accounting_reporting_alt

Creates Table:
	sms.dbo.c_alt_workable_reporting_v

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description:
	Creates a view to report on workable indicators based on the latest report run date.

Revision History:
Date		Version		Description
----		----		----
2018-07-13	v1			Initial Creation
***********************************************************************
*/

-- Drop the view if it already exists
IF EXISTS (
    SELECT *
    FROM sys.views
    JOIN sys.schemas
    ON sys.views.schema_id = sys.schemas.schema_id
    WHERE sys.schemas.name = N'dbo'
    AND sys.views.name = N'c_alt_workable_reporting_v'
)
DROP VIEW dbo.c_alt_workable_reporting_v
GO

-- Create the view in the specified schema
CREATE VIEW dbo.c_alt_workable_reporting_v
AS
    -- Define a common table expression (CTE) to get the latest workable indicators
    WITH workable_tbl AS (
        SELECT *
        FROM sms.dbo.c_workable_indicator_tbl
        WHERE report_run_date = (
                SELECT max(report_run_date)
                FROM sms.dbo.c_workable_indicator_tbl
                )
    )
    -- Select data from the accounting reporting table and join with the latest workable indicators
    SELECT a.*,
        b.department_clean,
        b.workable_indicator
    FROM sms.dbo.pt_accounting_reporting_alt AS a
    LEFT JOIN workable_tbl AS b ON a.pt_no = b.pt_no
        AND isnull(a.unit_no, '') = isnull(b.unit_no, '')
        AND isnull(a.unit_date, '') = isnull(b.unit_date, '')
GO
