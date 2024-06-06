/*
***********************************************************************
File: c_fin_class_v.sql

Input Parameters:
	None

Tables/Views:
	sms.dbo.c_fc_comments_tbl

Creates Table/View:
	dbo.c_fc_comments_tbl

Functions:
	NONE

Author: Steven P. Sanderson II, MPH

Department: Patient Financial Services

Purpose/Description
Creates a table that contains the financial class change history for patients.

Revision History:
Date		Version		Description
----		----		----
2024-03-26	v1			Initial Creation	
***********************************************************************
*/

-- Create a new view called 'c_fin_class_v' in schema 'dbo'
-- Drop the view if it already exists
IF EXISTS (
		SELECT *
		FROM sys.VIEWS
		JOIN sys.schemas ON sys.VIEWS.schema_id = sys.schemas.schema_id
		WHERE sys.schemas.name = N'dbo'
			AND sys.VIEWS.name = N'c_fin_class_v'
		)
	DROP VIEW dbo.c_fin_class_v
GO

-- Create the view in the specified schema
CREATE VIEW dbo.c_fin_class_v
AS
-- Select the columns from the table
SELECT A.pt_no,
	A.svc_date,
	A.post_date,
	A.pa_smart_comment,
	A.FC,
	A.fc_class,
	A.fc_group,
	A.comment_yr,
	A.comment_month,
	A.comment_wk,
	[event_number] = ROW_NUMBER() OVER (
		PARTITION BY PT_NO ORDER BY SVC_DATE
		),
	[next_svc_date] = lead(svc_date) OVER (
		PARTITION BY pt_no ORDER BY svc_date
		),
	[next_post_date] = lead(post_date) OVER (
		PARTITION BY pt_no ORDER BY post_date
		),
	[days_to_next_event] = DATEDIFF(DAY, A.svc_date, lead(svc_date) OVER (
			PARTITION BY pt_no ORDER BY svc_date
			)),
	[next_pa_smart_comment] = lead(pa_smart_comment) OVER (
		PARTITION BY pt_no ORDER BY svc_date
		),
	[next_fc] = lead(fc) OVER (
		PARTITION BY pt_no ORDER BY svc_date
		),
	[next_fc_class] = lead(fc_class) OVER (
		PARTITION BY pt_no ORDER BY svc_date
		),
	[next_fc_group] = lead(fc_group) OVER (
		PARTITION BY pt_no ORDER BY svc_date
		),
	[next_comment_yr] = lead(comment_yr) OVER (
		PARTITION BY pt_no ORDER BY svc_date
		),
	[next_comment_month] = lead(comment_month) OVER (
		PARTITION BY pt_no ORDER BY svc_date
		),
	[next_comment_wk] = lead(comment_wk) OVER (
		PARTITION BY pt_no ORDER BY svc_date
		)
FROM sms.dbo.c_fc_comments_tbl AS A
GO


