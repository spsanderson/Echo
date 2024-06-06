/*
***********************************************************************
File: c_REMIT_cas_v.sql

Input Parameters:
	None

Tables/Views:
    [EMSEE].[dbo].[REMIT_cas]

Creates Table/View:
	dbo.c_Remit_cas_v
	

Functions:
	None

Author: Fang Wu

Department: Patient Financial Services

Purpose/Description
	Create a View for [EMSEE].[dbo].[REMIT_cas] table in SMS database 

Revision History:
Date		Version		Description
----		----		----
2023-09-01	v1			Initial Creation
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
        AND sys.views.name = N'c_REMIT_cas_v'
) DROP VIEW dbo.c_REMIT_cas_v
GO

-- Create the view in the specified schema

CREATE VIEW dbo.c_REMIT_cas_v AS -- body of the view
SELECT
	   [REMIT_cas]
      ,[REMIT]
      ,[Remit_Adjustment_Group_Code]
      ,[Remit_Adjustment_Reason_Code]
      ,[Remit_Adjustment_Reason_Description]
      ,[Remit_Adjustment_Amount]
      ,[Remit_Adjustment_Quantity]
  FROM [EMSEE].[dbo].[REMIT_cas]

GO