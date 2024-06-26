/*
***********************************************************************
File: c_INST_info_code_v.sql

Input Parameters:
	None

Tables/Views:
    [EMSEE].[dbo].[INST_info_code]

Creates Table/View:
	dbo.c_INST_info_code_v
	

Functions:
	None

Author: Fang Wu

Department: Patient Financial Services

Purpose/Description
	Create a View for [EMSEE].[dbo].[INST_info_code] table in SMS database 

Revision History:
Date		Version		Description
----		----		----
2023-09-05	v1			Initial Creation
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
        AND sys.views.name = N'c_INST_info_code_v'
) DROP VIEW dbo.c_INST_info_code_v
GO

-- Create the view in the specified schema

CREATE VIEW dbo.c_INST_info_code_v AS -- body of the view
SELECT [INST_info_code]
      ,[INST]
      ,[info_Code_description]
      ,[info_Code_description_short]
      ,[info_Code_qualifier]
      ,[info_Code]
      ,[info_Code_Date]
      ,[info_Code_Date_Through]
      ,[info_Code_Amount]
      ,[info_Code_Quantity]
      ,[info_Code_VersionID]
      ,[info_Code_Industry_Code]
      ,[info_Code_Response_Code]
  FROM [EMSEE].[dbo].[INST_info_code]

Go