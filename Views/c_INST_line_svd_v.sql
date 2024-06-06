/*
***********************************************************************
File: c_INST_line_svd_v.sql

Input Parameters:
	None

Tables/Views:
    [EMSEE].[dbo].[INST_line_svd]

Creates Table/View:
	dbo.c_INST_line_svd_v
	

Functions:
	None

Author: Fang Wu

Department: Patient Financial Services

Purpose/Description
	Create a View for [EMSEE].[dbo].[INST_line_svd] table in SMS database 

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
        AND sys.views.name = N'c_INST_line_svd_v'
) DROP VIEW dbo.c_INST_line_svd_v
GO

-- Create the view in the specified schema

CREATE VIEW dbo.c_INST_line_svd_v AS -- body of the view
SELECT [INST_line_svd]
      ,[INST_line]
      ,[INST]
      ,[Line_Adjudication_Other_Payer_ID_1]
      ,[Line_Adjudication_Paid_Amount_1]
      ,[Line_Adjudication_Procedure_Code_1]
      ,[Line_Adjudication_Revenue_Code_1]
      ,[Line_Adjudication_Quantity_1]
      ,[Line_Adjudication_Date]
  FROM [EMSEE].[dbo].[INST_line_svd]

GO