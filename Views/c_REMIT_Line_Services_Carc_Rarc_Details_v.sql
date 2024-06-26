/*
***********************************************************************
File: c_REMIT_line_services_Carc_Rarc_details_v.sql

Input Parameters:
	None

Tables/Views:
    [EMSEE].[dbo].[c_REMIT_JOIN_ALL_v]
	[PARA].[dbo].[Carc_Category]

Creates Table/View:
	dbo.c_REMIT_line_services_Carc_Rarc_details_v

Functions:
	None

Author: Fang Wu

Department: Patient Financial Services

Purpose/Description
	Create a View for service line carc rarc detials from EMSEE remit database. 

Revision History:
Date		Version		Description
----		----		----
2023-09-20	v1			Initial Creation
2023-09-22  v2	        Added Carc Category and Sub-Category
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
        AND sys.views.name = N'c_REMIT_line_services_Carc_Rarc_details_v'
) DROP VIEW dbo.c_REMIT_line_services_Carc_Rarc_details_v
GO

-- Create the view in the specified schema

CREATE VIEW dbo.c_REMIT_line_services_Carc_Rarc_details_v AS
select   [Remit]
        ,[pt_no]
        ,[Ins_CD]
		,[Unit_No]
		,[Seq_No]
		,[Check_EFT_Date]
		,[Date_of_Service]
		,[Service_Date_Through]
		,[Payer_Name]
		,[Claim_Status]
		,[Claim_Status_Code]
	    ,[REMIT_cas]
        ,[Remit_Adjustment_Group_Code]
        ,[Remit_Adjustment_Reason_Code]
        ,[Remit_Adjustment_Reason_Description]
        ,[Remit_Adjustment_Amount]
        ,[Remit_Adjustment_Quantity]
		,[remit_line]
		,[Line_Procedure_Codes]
		,[Line_Procedure_Modifier_1]
        ,[Line_Procedure_Modifier_2]
        ,[Line_Procedure_Modifier_3]
        ,[Line_Procedure_Modifier_4]
		,[Line_Revenue_Code]
		,[Line_Charged]
        ,[Line_Paid]
		,[total_Line_Adjustments]
		,[Line_Allowed_Amount]
		,[Error_Code]
		,[Error_Description]
		,[REMIT_line_cas]
        ,[line_Adjustment_Group_Code]
        ,[line_Adjustment_Reason_Code]		
        ,[line_Adjustment_Reason_Description]
        ,[line_Adjustment_Amount]
        ,[line_Adjustment_Quantity]
        ,b.[Category]
		,b.[Sub-Category]
   FROM [SMS].[dbo].[c_REMIT_JOIN_ALL_v] a left join [PARA].[dbo].[Carc_Category] b
   on (a.[line_Adjustment_Group_Code]=b.[Group Code] and a.[line_Adjustment_Reason_Code]=b.[Reason Code]) or 
      (a.[line_Adjustment_Group_Code] is null and a.[Remit_Adjustment_Group_Code]=b.[Group Code] and a.[Remit_Adjustment_Reason_Code]=b.[Reason Code])
   where [claim_status_code] in ( '1','2','4','19','20','22')

/*
***********************************************************************   
    claim_status_code	claim_status
		1				Processed As Primary
		4				Denied
		19				Processed as Primary, Forwarded to Additional Payer(s)	
		22				Reversal of Previous Payment
		2				Processed As Secondary
		20				Processed as Secondary, Forwarded to Additional Payer(s)
		
***********************************************************************
*/
   
  
   
  --- [Pt_NO]='10205445330'

   ---select distinct [claim_status_code],[claim_status] from [SMS].[dbo].[c_REMIT_JOIN_ALL_v]


GO