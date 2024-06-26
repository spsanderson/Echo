/*
***********************************************************************
File: c_INST_line_v.sql

Input Parameters:
	None

Tables/Views:
    [EMSEE].[dbo].[INST_line]

Creates Table/View:
	dbo.c_INST_line_v
	

Functions:
	None

Author: Fang Wu

Department: Patient Financial Services

Purpose/Description
	Create a View for [EMSEE].[dbo].[INST_line] table in SMS database 

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
        AND sys.views.name = N'c_INST_line_v'
) DROP VIEW dbo.c_INST_line_v
GO

-- Create the view in the specified schema

CREATE VIEW dbo.c_INST_line_v AS -- body of the view
SELECT 
       [Line_Control_Number]
	  ,cast(substring([Line_Control_Number],1,12) as numeric) as 'Pt_NO'
      ,substring([Line_Control_Number],15,3) as 'Ins_CD'
      ,case when substring([Line_Control_Number],13,2) not in ('AA','00') then substring([Line_Control_Number],13,2)
       else null
       end as 'Unit_NO'
      ,substring([Line_Control_Number],18,3) as 'Seq_No'
	  ,substring([Line_Control_Number],21,3) as 'Line_No'
      ,[INST_line]
      ,[INST]
      ,[Line_Serial]
      ,[Line_Revenue_Code]
      ,[Line_Product_or_Service_ID_Qualifier]
      ,[Line_Procedure_Code]
      ,[Line_Procedure_Modifiers]
      ,[Line_Procedure_Modifier_1]
      ,[Line_Procedure_Modifier_2]
      ,[Line_Procedure_Modifier_3]
      ,[Line_Procedure_Modifier_4]
      ,[Line_Procedure_Description]
      ,[Line_Amount_Total]
      ,[Line_Units_Code]
      ,[Line_Units]
      ,[Line_Attachment_Control_Number]
      ,[Line_Service_Date]
     
      ,[FS_Allowed_Amount]
      ,[UC_Allowed_Amount]
      ,[Line_Note]
      ,[Line_Pricing_Methodology]
      ,[Line_Repriced_Allowed_Amount]
      ,[Line_Repriced_Savings_Amount]
      ,[Line_Repricing_Organization_ID]
      ,[Line_Repriced_Approved_HCPCS_Code]
      ,[Line_Repriced_Measurment_Code]
      ,[Line_Repriced_Quantity]
      ,[Line_Reject_Reason_Code]
      ,[Line_Reject_Reason]
      ,[NDC_Number]
      ,[Drug_Quantity]
      ,[Composite_Unit_Of_Measure]
      ,[Prescription_Number]
      ,[Prior_Payers_Service_Level_Amount_Paid]
  FROM [EMSEE].[dbo].[INST_line]

GO
 