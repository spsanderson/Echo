/*
***********************************************************************
File: c_REMIT_v.sql

Input Parameters:
	None

Tables/Views:
    [EMSEE].[dbo].[REMIT]
    [sms].[DBO].[C_NPI_EIN_FACILITY_DIM_TBL]

Creates Table/View:
	dbo.c_Remit_v
	

Functions:
	None

Author: Fang Wu

Department: Patient Financial Services

Purpose/Description
	Create a View for [EMSEE].[dbo].[REMIT] table in SMS database 

Revision History:
Date		Version		Description
----		----		----
2023-09-01	v1			Initial Creation
2023-09-13  v2			Abnormal PCN are not parsed to Pt_NO Unit_No Ins_CD			
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
        AND sys.views.name = N'c_REMIT_v'
) DROP VIEW dbo.c_REMIT_v
GO

-- Create the view in the specified schema

CREATE VIEW dbo.c_REMIT_v AS -- body of the view
SELECT  A.[Patient_Control_Number]

      ,case when len(A.[Patient_Control_Number])=20 
	             and isnumeric(substring([patient_Control_Number],1,12))=1 
			then cast(substring(a.[patient_Control_Number],1,12) as numeric)
	        else null
			end  as 'Pt_NO'
      ,case when len(A.[Patient_Control_Number])=20 
	             and isnumeric(substring([patient_Control_Number],1,12))=1
	        then substring(a.[patient_Control_Number],15,3) 
	        else null
			end as 'Ins_CD'
      ,case when len(A.[Patient_Control_Number])=20 
	             and isnumeric(substring([patient_Control_Number],1,12))=1
	             and substring(a.[patient_Control_Number],13,2) not in ('AA','00') 
	             and ISNUMERIC(substring([patient_Control_Number],13,2))=1
            then cast(substring(a.[patient_Control_Number],13,2) as numeric)
            else null
            end as 'Unit_NO'
      ,case when len(A.[Patient_Control_Number])=20
	             and isnumeric(substring([patient_Control_Number],1,12))=1
		    then substring(a.[patient_Control_Number],18,3) 
	        else null
			end as 'Seq_No'
	  ,A.[REMIT]
      ,A.[Export_Date_Time]
      ,A.[File_Name]
      ,A.[Contractual_Diff]
      ,A.[Payer_Message]
      ,A.[Sender_ID]
      ,A.[App_Sender_Code]
      ,A.[File_Creation_Date]
      ,A.[EDI_Version]
      ,A.[EDI_Format]
      ,A.[Transaction_Control_Number]
      ,A.[Check_EFT_Date]
      ,A.[Check_EFT_Trace_Number]
      ,A.[Trace_Payer_ID]
      ,A.[Trace_Supplemental_Code]
      ,A.[Production_Date]
      ,A.[EDI_Purpose_Code]
      ,A.[Payer_Name]
      ,A.[Payer_ID]
      ,A.[Payer_Address_1]
      ,A.[Payer_Address_2]
      ,A.[Payer_City]
      ,A.[Payer_State]
      ,A.[Payer_Zip]
      ,A.[Additional_Payer_ID]
      ,A.[Payee_Name]
      ,A.[Payee_ID]
      ,A.[Payee_Address]
      ,A.[Payee_City]
      ,A.[Payee_State]
      ,A.[Payee_Zip_Code]
      ,A.[Provider_Summary_Reference_ID]
     
      ,A.[Claim_Status]
      ,A.[Claim_Status_Code]
      ,A.[Charge_Amount]
      ,A.[Paid_Amount]
      ,A.[CoInsured_CoPay]
      ,A.[Filing_Indicator]
      ,A.[Payer_Claim_Control_Number]
      ,A.[Bill_Type]
      ,A.[DRG_Code]
      ,A.[DRG_Weight]
      ,A.[Claim_Adjustments]
      ,A.[Subscriber_Name]
      ,A.[Subscriber_ID]
      ,A.[Patient_Last_Name]
      ,A.[Patient_First_Name]
      ,A.[Patient_Middle_Name]
      ,A.[Corrected_Patient_Name]
      ,A.[Corrected_Patient_ID]
      ,A.[Rendering_Provider]
      ,A.[Rendering_Provider_ID]
      ,A.[Crossover_Carrier]
      ,A.[Crossover_Carrier_ID]
      ,A.[MIA_Remark_Codes]
      ,A.[MIA_Covered_Days]
      ,A.[MIA_PPS_Operating_Outlier_Amount]
      ,A.[MIA_Lifetime_Psychiatric_Days_Count]
      ,A.[MIA_Claim_DRG_Amount]
      ,A.[MIA_Claim_Payment_Remark_Code]
      ,A.[MIA_Claim_Disproportionate_Share_Amount]
      ,A.[MIA_Claim_MSP_Pass_through_Amount]
      ,A.[MIA_Claim_PPS_Capital_Amount]
      ,A.[MIA_PPS_Capital_FSP_DRG_Amount]
      ,A.[MIA_PPS_Capital_HSP_DRG_Amount]
      ,A.[MIA_PPS_Capital_DSH_DRG_Amount]
      ,A.[MIA_Old_Capital_Amount]
      ,A.[MIA_PPS_Capital_IME_Amount]
      ,A.[MIA_PPS_Operating_Hospital_Specific_DRG_Amount]
      ,A.[MIA_Cost_Report_Day_Count]
      ,A.[MIA_PPS_Operating_Federal_Specific_DRG_Amount]
      ,A.[MIA_Claim_PPS_Capital_Outlier_Amount]
      ,A.[MIA_Claim_Indirect_Teaching_Amount]
      ,A.[MIA_Nonpayable_Professional_Component_Amount]
      ,A.[MIA_Claim_Payment_Remark_Code_1]
      ,A.[MIA_Claim_Payment_Remark_Code_2]
      ,A.[MIA_Claim_Payment_Remark_Code_3]
      ,A.[MIA_Claim_Payment_Remark_Code_4]
      ,A.[MIA_PPS_Capital_Exception_Amount]
      ,A.[MOA_Remark_Codes]
      ,A.[MOA_Reimbursement_Rate]
      ,A.[MOA_Claim_HCPCS_Payable_Amount]
      ,A.[MOA_Claim_Payment_Remark_Code_1]
      ,A.[MOA_Claim_Payment_Remark_Code_2]
      ,A.[MOA_Claim_Payment_Remark_Code_3]
      ,A.[MOA_Claim_Payment_Remark_Code_4]
      ,A.[MOA_Claim_Payment_Remark_Code_5]
      ,A.[MOA_Claim_ESRD_Payment_Amount]
      ,A.[MOA_Nonpayable_Professional_Component_Amount]
      ,A.[Medical_Record_Number]
      ,A.[Repriced_Claim_ID]
      ,A.[Prior_Authorization]
      ,A.[Group_or_Policy_Number]
      ,A.[Contract_Code]
      ,A.[Date_of_Service]
      ,A.[Service_Date_Through]
      ,A.[Supplemental_Info]
      ,A.[Oper_Cost_Outlier]
      ,A.[Supplemental_Info_Coverage_Amount]
      ,A.[Supplemental_Info_Per_Day_Limit]
      ,A.[Covered_Days]
      ,A.[CoInsured_Days]
      ,A.[Non_Covered_Days]
	  ,B.[id_type]
      ,B.[number]
      ,B.[parent_name]
      ,B.[parent_name_extended]
  FROM [EMSEE].[dbo].[REMIT] AS A
  LEFT JOIN sms.DBO.C_NPI_EIN_FACILITY_DIM_TBL AS B ON A.Payee_ID = B.number

GO