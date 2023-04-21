USE [Echo_SBU_FinPARA]

/*
***********************************************************************
File: c_dim_user_defined_component_xwalk_v.sql

Input Parameters:
	None

Tables/Views:
	echo_sbu_finpara.dbo.c_dim_user_defined_component_xwalk_tbl

Creates Table/View:
	dbo.c_dim_user_defined_component_xwalk_v

Functions:
	None

Author: Steven P. Sanderson II, MPH

Department: Patient Financial Services

Purpose/Description
	Create a view that will return the user defined component crosswalk table.

Revision History:
Date		Version		Description
----		----		----
2023-04-13	v1			Initial Creation
***********************************************************************
*/

-- Create a new view called 'c_dim_user_defined_component_xwalk_v' in schema 'dbo'
-- Drop the view if it already exists
IF EXISTS (
SELECT *
    FROM sys.views
    JOIN sys.schemas
    ON sys.views.schema_id = sys.schemas.schema_id
    WHERE sys.schemas.name = N'dbo'
    AND sys.views.name = N'c_dim_user_defined_component_xwalk_v'
)
DROP VIEW dbo.c_dim_user_defined_component_xwalk_v
GO
-- Create the view in the specified schema
CREATE VIEW dbo.c_dim_user_defined_component_xwalk_v
AS
    -- body of the view
    SELECT orig_cmpnt,
        dest_cmpnt,
        data_ind,
        data_desc,
        cmpnt_desc
    FROM dbo.c_dim_user_defined_component_xwalk_tbl
GO