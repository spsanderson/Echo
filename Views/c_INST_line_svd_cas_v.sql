/*
***********************************************************************
File: c_INST_line_svd_cas_v.sql

Input Parameters:
	None

Tables/Views:
    [EMSEE].[dbo].[INST_line_svd_cas]

Creates Table/View:
	dbo.c_INST_line_svd_cas_v
	

Functions:
	None

Author: Fang Wu

Department: Patient Financial Services

Purpose/Description
	Create a View for [EMSEE].[dbo].[INST_line_svd_cas] table in SMS database 

Revision History:
Date		Version		Description
----		----		----
2023-09-06	v1			Initial Creation
***********************************************************************
*/

IF EXISTS (
    SELECT
        *
    FROM
        sys.views
        JOIN sys.schemas ON sys.views.schema_id = sys.schemas.schema_id
    WHERE
        sys.schemas.name = N'dbo'
        AND sys.views.name = N'c_INST_line_svd_cas_v'
) DROP VIEW dbo.c_INST_line_svd_cas_v
GO

-- Create the view in the specified schema

CREATE VIEW dbo.c_INST_line_svd_cas_v AS -- body of the view
SELECT [INST_line_svd_cas]
      ,[INST_line_svd]
      ,[INST_line]
      ,[INST]
      ,[line_Adjustment_Group_Code]
      ,[line_Adjustment_Reason_Code]
      ,[line_Adjustment_Reason_Description]
      ,[line_Adjustment_Amount]
      ,[line_Adjustment_Quantity]
  FROM [EMSEE].[dbo].[INST_line_svd_cas]

GO