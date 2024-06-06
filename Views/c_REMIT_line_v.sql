/*
***********************************************************************
File: c_REMIT_line_v.sql

Input Parameters:
	None

Tables/Views:
    [EMSEE].[dbo].[REMIT_line]

Creates Table/View:
	dbo.c_Remit_line_v

Functions:
	None

Author: Fang Wu

Department: Patient Financial Services

Purpose/Description
	Create a View for [EMSEE].[dbo].[REMIT_line] table in SMS database 

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
        AND sys.views.name = N'c_REMIT_line_v'
) DROP VIEW dbo.c_REMIT_line_v
GO

-- Create the view in the specified schema

CREATE VIEW dbo.c_REMIT_line_v AS -- body of the view
SELECT
	   [REMIT_line]
      ,[REMIT]
	  ,Case when (len([line_Procedure_codes])=3 or (len([line_Procedure_codes])=4 and left([line_Procedure_codes],1)='0'))
           and ISNUMERIC([line_Procedure_codes])=1
		  then null
	      else [Line_Procedure_Codes] 
	      end  as 'Line_Procedure_Codes'
      --,[Line_Procedure_Codes]
      ,[Line_Procedure_Modifier_1]
      ,[Line_Procedure_Modifier_2]
      ,[Line_Procedure_Modifier_3]
      ,[Line_Procedure_Modifier_4]
      ,[Line_Procedure_Desc]
      ,[Line_Charged]
      ,[Line_Paid]
      ,Case when [line_revenue_code] is null 
          and [line_Procedure_codes] is not null 
          and (len([line_Procedure_codes])=3 or (len([line_Procedure_codes])=4 and left([line_Procedure_codes],1)='0'))
          and ISNUMERIC([line_Procedure_codes])=1
        then [line_Procedure_codes]      --Rev Code is null and it is in the Procedure Code field, move it to the Rev code field

        when [line_revenue_code] is not null 
           and [line_Procedure_codes] is not null 
           and (len([line_Procedure_codes])=3 or (len([line_Procedure_codes])=4 and left([line_Procedure_codes],1)='0'))
           and ISNUMERIC([line_Procedure_codes])=1
           and [line_revenue_code]!=[line_Procedure_codes]
        then [line_Procedure_codes]      --Rev Code is in the Procedure Code field and Rev Code Field has the value of "0000", also remove from the Procedure Code field 

	    else [line_Revenue_code] 
	    end  as 'Line_Revenue_Code'
      ,[Line_Units]
      ,[Combine_with_CPT]
      ,[Line_Units_Original]
      ,[Line_Date_of_Service]
      ,[Total_Line_Adjustments]
      ,[Line_ID]
      ,[APG_Code]
      ,[Line_Number]
      ,[Rate_Code_Number]
      ,[Line_Item_Control_Number]
	  ,case when len([Line_Item_Control_Number])=23 then cast(substring([Line_Item_Control_Number],1,12) as numeric) 
	        else null 
			end as 'Pt_NO'
      ,case when len([Line_Item_Control_Number])=23 then substring([Line_Item_Control_Number],15,3) 
	        else null
			end as 'Ins_CD'
      ,case when len([Line_Item_Control_Number])=23 and substring([Line_Item_Control_Number],13,2) not in ('AA','00') then substring([Line_Item_Control_Number],13,2)
            else null
            end as 'Unit_NO'
      ,case when len([Line_Item_Control_Number])=23 then substring([Line_Item_Control_Number],18,3) 
	        else null
			end as 'Seq_No'
	  ,case when len([Line_Item_Control_Number])=23 then substring([Line_Item_Control_Number],21,3) 
	        else null
			end as 'Line_No'
      ,[Line_Rendering_Prov_ID]
      ,[Line_Allowed_Amount]
      ,[APG_Paid_Amount]
      ,[Existing_Operating_Amount]
      ,[APG_Full_Weight]
      ,[APG_Allowed_Percentage]
      ,[Error_Code]
      ,[Error_Description]
	  FROM [EMSEE].[dbo].[REMIT_line]

GO