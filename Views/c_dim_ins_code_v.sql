USE [Echo_SBU_FinPARA]

/*
***********************************************************************
File: c_dim_ins_code_v.sql

Input Parameters:
	None

Tables/Views:
	dbo.c_dim_ins_code_tbl

Creates Table/View:
	dbo.c_dim_ins_code_v

Functions:
	None

Author: Steven P. Sanderson II, MPH

Department: Patient Financial Services

Purpose/Description
	A view of the insurance code dim table

Revision History:
Date		Version		Description
----		----		----
2023-04-19	v1			Initial Creation
***********************************************************************
*/

-- Create a new view called 'c_dim_ins_code_v' in schema 'dbo'
-- Drop the view if it already exists
IF EXISTS (
SELECT *
    FROM sys.views
    JOIN sys.schemas
    ON sys.views.schema_id = sys.schemas.schema_id
    WHERE sys.schemas.name = N'dbo'
    AND sys.views.name = N'c_dim_ins_code_v'
)
DROP VIEW dbo.c_dim_ins_code_v
GO
-- Create the view in the specified schema
CREATE VIEW dbo.c_dim_ins_code_v
AS
    SELECT [ins_code]
        ,[ins_desc]
        ,[i_o_ind]
        ,[plan_type]
        ,[fc]
        ,[fc_desc]
    FROM [Echo_SBU_FinPARA].[dbo].[c_dim_ins_code_tbl]
GO