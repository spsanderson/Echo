USE [Echo_SBU_FinPARA]

/*
***********************************************************************
File: c_dim_carc_v.sql

Input Parameters:
	None

Tables/Views:
	dbo.c_dim_carc_tbl

Creates Table/View:
	dbo.c_dim_carc_v

Functions:
	None

Author: Steven P. Sanderson II, MPH

Department: Patient Financial Services

Purpose/Description
	A view of the carc dim table

Revision History:
Date		Version		Description
----		----		----
2023-04-14	v1			Initial Creation
***********************************************************************
*/

-- Create a new view called 'c_dim_carc_v' in schema 'dbo'
-- Drop the view if it already exists
IF EXISTS (
		SELECT *
		FROM sys.VIEWS
		JOIN sys.schemas ON sys.VIEWS.schema_id = sys.schemas.schema_id
		WHERE sys.schemas.name = N'dbo'
			AND sys.VIEWS.name = N'c_dim_carc_v'
		)
	DROP VIEW dbo.c_dim_carc_v
GO

-- Create the view in the specified schema
CREATE VIEW dbo.c_dim_carc_v
AS
SELECT [code],
	[group_code],
	[category],
	[sub_category],
	[code_description],
	[start_date],
	[special_notes],
	[denial_flag]
FROM [dbo].[c_dim_carc_tbl]
GO




