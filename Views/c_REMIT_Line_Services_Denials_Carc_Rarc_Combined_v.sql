/*
***********************************************************************
File: c_REMIT_line_services_Denials_Carc_Rarc_Combined_v.sql

Input Parameters:
	None

Tables/Views:
    [SMS].[dbo].[c_REMIT_line_services_denial_details_v]

Creates Table/View:
	dbo.c_REMIT_line_services_Denials_Carc_Rarc_Combined_v

Functions:
	None

Author: Fang Wu

Department: Patient Financial Services

Purpose/Description
	Create a View for service line denial detials with combined Carcs and Rarcs from EMSEE remit database. 

Revision History:
Date		Version		Description
----		----		----
2023-09-22	v1			Initial Creation

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
        AND sys.views.name = N'c_REMIT_line_services_Denials_Carc_Rarc_Combined_v'
) DROP VIEW dbo.c_REMIT_line_services_Denials_Carc_Rarc_Combined_v
GO

-- Create the view in the specified schema

CREATE VIEW dbo.c_REMIT_line_services_Denials_Carc_Rarc_Combined_v AS

 SELECT [pt_no]
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
      ,stuff((
	  select distinct ' '+ (cast(a.[Remit_Adjustment_Group_Code] as varchar) + ' - ' + cast([Remit_Adjustment_Reason_Code] as varchar))
	  from [SMS].[dbo].[c_REMIT_line_services_denial_details_v] a
	  where a.[remit_line]=t.[remit_line]
	  for xml path ('')),1,1,''
	  ) [Combined_Remit_Adjustment_Group_code]
      --,[Remit_Adjustment_Reason_Code]
      ,stuff((
	  select distinct ' '+ [Remit_Adjustment_Reason_Description]
	  from [SMS].[dbo].[c_REMIT_line_services_denial_details_v] a
	  where a.[remit_line]=t.[remit_line]
	  for xml path ('')),1,1,''
	  ) [Combined_Remit_Adjustment_Reason_Description]
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
	  ,stuff((
	  select distinct ', '+ [Error_Code]
	  from [SMS].[dbo].[c_REMIT_line_services_denial_details_v] a
	  where a.[remit_line]=t.[remit_line]
	  for xml path ('')),1,1,''
	  ) [RemarkCodeCombined]
      
      ,stuff((
	  select distinct ', '+ [Error_Description]
	  from [SMS].[dbo].[c_REMIT_line_services_denial_details_v] a
	  where a.[remit_line]=t.[remit_line]
	  for xml path ('')),1,1,''
	  ) [RemarkDescCombined]
      --,[REMIT_line_cas]
	  ,stuff((
	  select distinct ', '+ (cast(a.[line_Adjustment_Group_Code] as varchar) + ' - ' + cast([line_Adjustment_Reason_Code] as varchar))
	  from [SMS].[dbo].[c_REMIT_line_services_denial_details_v] a
	  where a.[remit_line]=t.[remit_line]
	  for xml path ('')),1,1,''
	  ) [Combined_Line_Adjustment_Group_code]
     -- ,cast([line_Adjustment_Group_Code] as varchar) + ' - ' + cast([line_adjustment_reason_code] as varchar) as 'Line_Adjustment_Carc'
      ---,[line_Adjustment_Reason_Code]
      --,[line_Adjustment_Reason_Description]
	  ,stuff((
	  select distinct ', '+ [line_Adjustment_Reason_Description]
	  from [SMS].[dbo].[c_REMIT_line_services_denial_details_v] a
	  where a.[remit_line]=t.[remit_line]
	  for xml path ('')),1,1,''
	  ) [Combined_Line_Adjustment_Reason_Description]
      ,[line_Adjustment_Amount]
      ,[line_Adjustment_Quantity]
	  ,stuff((
	  select distinct ', '+ [category]
	  from [SMS].[dbo].[c_REMIT_line_services_denial_details_v] a
	  where a.[remit_line]=t.[remit_line]
	  for xml path ('')),1,1,''
	  ) [CarcCategoryCombined]
	  
	  ,stuff((
	  select distinct ', '+ [sub-category]
	  from [SMS].[dbo].[c_REMIT_line_services_denial_details_v] a
	  where a.[remit_line]=t.[remit_line]
	  for xml path ('')),1,1,''
	  ) [CarcSubCategoryCombined]
  FROM [SMS].[dbo].[c_REMIT_line_services_denial_details_v] t
 
  group by 
       [pt_no]
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
      ,[line_Adjustment_Amount]
      ,[line_Adjustment_Quantity]
 
