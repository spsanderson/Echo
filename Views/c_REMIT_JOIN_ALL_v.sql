/*
***********************************************************************
File: c_REMIT_JOIN_ALL_v.sql

Input Parameters:
	None

Tables/Views:
    [SMS].[dbo].[c_REMIT_v]
    [SMS].[dbo].[c_REMIT_cas_v]
	[SMS].[dbo].[c_REMIT_line_cas_v]
	[SMS].[dbo].[c_REMIT_line_v]

Creates Table/View:
	dbo.c_REMIT_JOIN_ALL_v
	

Functions:
	None

Author: Fang Wu

Department: Patient Financial Services

Purpose/Description
	Create a View to join 4 REMIT tables from EMSEE database in SMS database 

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
        AND sys.views.name = N'c_REMIT_JOIN_All_v'
) DROP VIEW dbo.c_REMIT_JOIN_ALL_v
GO

-- Create the view in the specified schema

CREATE VIEW dbo.c_REMIT_JOIN_ALL_v AS

select a.[Patient_Control_Number]
      ,a.[Pt_NO]
      ,a.[Ins_CD]
      ,a.[Unit_NO]
      ,a.[Seq_No]
      ,a.[REMIT]
      ,a.[Export_Date_Time]
      ,a.[File_Name]
      ,a.[Contractual_Diff]
      ,a.[Payer_Message]
      ,a.[Sender_ID]
      ,a.[App_Sender_Code]
      ,a.[File_Creation_Date]
      ,a.[EDI_Version]
      ,a.[EDI_Format]
      ,a.[Transaction_Control_Number]
      ,a.[Check_EFT_Date]
      ,a.[Check_EFT_Trace_Number]
      ,a.[Trace_Payer_ID]
      ,a.[Trace_Supplemental_Code]
      ,a.[Production_Date]
      ,a.[EDI_Purpose_Code]
      ,a.[Payer_Name]
      ,a.[Payer_ID]
      ,a.[Payer_Address_1]
      ,a.[Payer_Address_2]
      ,a.[Payer_City]
      ,a.[Payer_State]
      ,a.[Payer_Zip]
      ,a.[Additional_Payer_ID]
      ,a.[Payee_Name]
      ,a.[Payee_ID]
      ,a.[Payee_Address]
      ,a.[Payee_City]
      ,a.[Payee_State]
      ,a.[Payee_Zip_Code]
      ,a.[Provider_Summary_Reference_ID]
      ,a.[Claim_Status]
      ,a.[Claim_Status_Code]
      ,a.[Charge_Amount]
      ,a.[Paid_Amount]
      ,a.[CoInsured_CoPay]
      ,a.[Filing_Indicator]
      ,a.[Payer_Claim_Control_Number]
      ,a.[Bill_Type]
      ,a.[DRG_Code]
      ,a.[DRG_Weight]
      ,a.[Claim_Adjustments]
      ,a.[Subscriber_Name]
      ,a.[Subscriber_ID]
      ,a.[Patient_Last_Name]
      ,a.[Patient_First_Name]
      ,a.[Patient_Middle_Name]
      ,a.[Corrected_Patient_Name]
      ,a.[Corrected_Patient_ID]
      ,a.[Rendering_Provider]
      ,a.[Rendering_Provider_ID]
      ,a.[Crossover_Carrier]
      ,a.[Crossover_Carrier_ID]
      ,a.[MIA_Remark_Codes]
      ,a.[MIA_Covered_Days]
      ,a.[MIA_PPS_Operating_Outlier_Amount]
      ,a.[MIA_Lifetime_Psychiatric_Days_Count]
      ,a.[MIA_Claim_DRG_Amount]
      ,a.[MIA_Claim_Payment_Remark_Code]
      ,a.[MIA_Claim_Disproportionate_Share_Amount]
      ,a.[MIA_Claim_MSP_Pass_through_Amount]
      ,a.[MIA_Claim_PPS_Capital_Amount]
      ,a.[MIA_PPS_Capital_FSP_DRG_Amount]
      ,a.[MIA_PPS_Capital_HSP_DRG_Amount]
      ,a.[MIA_PPS_Capital_DSH_DRG_Amount]
      ,a.[MIA_Old_Capital_Amount]
      ,a.[MIA_PPS_Capital_IME_Amount]
      ,a.[MIA_PPS_Operating_Hospital_Specific_DRG_Amount]
      ,a.[MIA_Cost_Report_Day_Count]
      ,a.[MIA_PPS_Operating_Federal_Specific_DRG_Amount]
      ,a.[MIA_Claim_PPS_Capital_Outlier_Amount]
      ,a.[MIA_Claim_Indirect_Teaching_Amount]
      ,a.[MIA_Nonpayable_Professional_Component_Amount]
      ,a.[MIA_Claim_Payment_Remark_Code_1]
      ,a.[MIA_Claim_Payment_Remark_Code_2]
      ,a.[MIA_Claim_Payment_Remark_Code_3]
      ,a.[MIA_Claim_Payment_Remark_Code_4]
      ,a.[MIA_PPS_Capital_Exception_Amount]
      ,a.[MOA_Remark_Codes]
      ,a.[MOA_Reimbursement_Rate]
      ,a.[MOA_Claim_HCPCS_Payable_Amount]
      ,a.[MOA_Claim_Payment_Remark_Code_1]
      ,a.[MOA_Claim_Payment_Remark_Code_2]
      ,a.[MOA_Claim_Payment_Remark_Code_3]
      ,a.[MOA_Claim_Payment_Remark_Code_4]
      ,a.[MOA_Claim_Payment_Remark_Code_5]
      ,a.[MOA_Claim_ESRD_Payment_Amount]
      ,a.[MOA_Nonpayable_Professional_Component_Amount]
      ,a.[Medical_Record_Number]
      ,a.[Repriced_Claim_ID]
      ,a.[Prior_Authorization]
      ,a.[Group_or_Policy_Number]
      ,a.[Contract_Code]
      ,a.[Date_of_Service]
      ,a.[Service_Date_Through]
      ,a.[Supplemental_Info]
      ,a.[Oper_Cost_Outlier]
      ,a.[Supplemental_Info_Coverage_Amount]
      ,a.[Supplemental_Info_Per_Day_Limit]
      ,a.[Covered_Days]
      ,a.[CoInsured_Days]
      ,a.[Non_Covered_Days]
      ,a.[id_type]
      ,a.[number]
      ,a.[parent_name]
      ,a.[parent_name_extended]
	  ,b.[REMIT_cas]
      ,b.[Remit_Adjustment_Group_Code]
      ,b.[Remit_Adjustment_Reason_Code]
      ,b.[Remit_Adjustment_Reason_Description]
      ,b.[Remit_Adjustment_Amount]
      ,b.[Remit_Adjustment_Quantity]
	  ,c.[REMIT_line]
      ,c.[Line_Procedure_Codes]
      ,c.[Line_Procedure_Modifier_1]
      ,c.[Line_Procedure_Modifier_2]
      ,c.[Line_Procedure_Modifier_3]
      ,c.[Line_Procedure_Modifier_4]
      ,c.[Line_Procedure_Desc]
      ,c.[Line_Charged]
      ,c.[Line_Paid]
      ,c.[Line_Revenue_Code]
      ,c.[Line_Units]
      ,c.[Combine_with_CPT]
      ,c.[Line_Units_Original]
      ,c.[Line_Date_of_Service]
      ,c.[Total_Line_Adjustments]
      ,c.[Line_ID]
      ,c.[APG_Code]
      ,c.[Rate_Code_Number]
      ,c.[Line_Item_Control_Number]
	  ,c.[Line_No]
      ,c.[Line_Rendering_Prov_ID]
      ,c.[Line_Allowed_Amount]
      ,c.[APG_Paid_Amount]
      ,c.[Existing_Operating_Amount]
      ,c.[APG_Full_Weight]
      ,c.[APG_Allowed_Percentage]
      ,c.[Error_Code]
      ,c.[Error_Description]
	  ,d.[REMIT_line_cas]
      ,d.[line_Adjustment_Group_Code]
      ,d.[line_Adjustment_Reason_Code]
      ,d.[line_Adjustment_Reason_Description]
      ,d.[line_Adjustment_Amount]
      ,d.[line_Adjustment_Quantity]

FROM [dbo].[c_REMIT_v] a  left join [dbo].[c_REMIT_cas_v] b
on a.[remit]=b.[remit]
left join [dbo].[c_REMIT_line_v] c
on a.[remit]=c.[remit]
left join [dbo].[c_REMIT_line_cas_v] d
on c.[remit_line]=d.[remit_line]

GO