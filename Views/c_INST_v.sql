/*
***********************************************************************
File: c_INST_v.sql

Input Parameters:
	None

Tables/Views:
    [EMSEE].[dbo].[INST]
    [sms].[DBO].[C_NPI_EIN_FACILITY_DIM_TBL]

Creates Table/View:
	dbo.c_INST_v
	

Functions:
	None

Author: Fang Wu

Department: Patient Financial Services

Purpose/Description
	Create a View for [EMSEE].[dbo].[INST] table in SMS database 

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
        AND sys.views.name = N'c_INST_v'
) DROP VIEW dbo.c_INST_v
GO

-- Create the view in the specified schema

CREATE VIEW dbo.c_INST_v AS -- body of the view
SELECT A.[Patient_Account_Number]
      ,cast(substring(A.[Patient_Account_Number],1,12) as numeric) as 'Pt_NO'
      ,substring(A.[Patient_Account_Number],15,3) as 'Ins_CD'
      ,case when substring(A.[Patient_Account_Number],13,2) not in ('AA','00') then substring(A.[Patient_Account_Number],13,2)
       else null
       end as 'Unit_NO'
      ,substring(A.[Patient_Account_Number],18,3) as 'Seq_No'
	  ,A.[INST]
      ,A.[Export_Date_Time]
      ,A.[File_Name]
      ,A.[Interchange_Sender_ID]
      ,A.[Interchange_Receiver_ID]
      ,A.[Interchange_Control_Number]
      ,A.[File_Creation_Date]
      ,A.[EDI_Version]
      ,A.[EDI_Format]
      ,A.[Transaction_Set_Control_Number]
      ,A.[EDI_Purpose_Code]
      ,A.[Originator_Application_Transaction_ID]
      ,A.[Submitter_Name]
      ,A.[Submitter_ID]
      ,A.[Submitter_Contact]
      ,A.[Submitter_Contact_Method]
      ,A.[Receiver_Name]
      ,A.[Receiver_ID]
      ,A.[Billing_Provider_Specialty_Code]
      ,A.[Billing_Provider]
      ,A.[Billing_Provider_ID]
      ,A.[Billing_NPI]
      ,A.[Billing_Provider_Address]
      ,A.[Billing_Address_1]
      ,A.[Billing_Address_2]
      ,A.[Billing_City]
      ,A.[Billing_State]
      ,A.[Billing_ZIP]
      ,A.[Billing_Provider_Tax_ID]
      ,A.[Pay_To_Address]
      ,A.[Pay_To_Address1]
      ,A.[Pay_To_Address2]
      ,A.[Pay_To_City]
      ,A.[Pay_To_State]
      ,A.[Pay_To_ZIP]
      ,A.[Pay_To_Plan_Name]
      ,A.[Pay_To_Plan_ID]
      ,A.[Pay_To_Plan_Address]
      ,A.[Payer_Sequence_Number]
      ,A.[Individual_Relationship_Code]
      ,A.[Subscriber_Group_or_Policy_Number]
      ,A.[Billed_Insured_Group]
      ,A.[Claim_Filing_Indicator_Code]
      ,A.[Billed_Subscriber_Name]
      ,A.[Billed_Subscriber_Entity_Type]
      ,A.[Billed_Subscriber_Last_Name]
      ,A.[Billed_Subscriber_First_Name]
      ,A.[Billed_Subscriber_Middle_Name]
      ,A.[Billed_Subscriber_ID]
      ,A.[Subscriber_Address1]
      ,A.[Subscriber_Address2]
      ,A.[Subscriber_City]
      ,A.[Subscriber_State]
      ,A.[Subscriber_Zip]
      ,A.[Subscriber_Gender]
      ,A.[Subscriber_DOB]
      ,A.[Subscriber_Secondary_ID]
      ,A.[Subscriber_Property_Casualty_Claim_Number]
      ,A.[Payer_Name]
      ,A.[Payer_ID_Code_Qualifier]
      ,A.[Payer_ID]
      ,A.[Payer_Address_1]
      ,A.[Payer_Address_2]
      ,A.[Payer_City]
      ,A.[Payer_State]
      ,A.[Payer_Zip]
      ,A.[Billing_Provider_Secondary_ID]
      ,A.[Payer_Secondary_ID]
      ,A.[Provider_Commercial_Number]
      ,A.[Patient_Name]
      ,A.[Patient_Address1]
      ,A.[Patient_Address2]
      ,A.[Patient_City]
      ,A.[Patient_State]
      ,A.[Patient_Zip]
      ,A.[Patient_DOB]
      ,A.[Patient_Gender]
      ,A.[Patient_Property_Casualty_Claim_Number]
      ,A.[Charge_Amount]
      ,A.[Facility_Type_Code]
      ,A.[Facility_Code]
      ,A.[Frequency_Code]
      ,A.[Delay_Reason_Code]
      ,A.[Discharge_Hour]
      ,A.[Statement_Dates]
      ,A.[Statement_From_Date]
      ,A.[Statement_Through_Date]
      ,A.[Admission_Date_Time]
      ,A.[Repricer_Received_Date]
      ,A.[Inst_Claim_Code]
      ,A.[Admission_Type_Code]
      ,A.[Admission_Source_Code]
      ,A.[Patient_Status_Code]
      ,A.[Attachment_Report_Type_Code]
      ,A.[Attachment_Transmission_Code]
      ,A.[Attachment_Control_Number]
      ,A.[Contract_Type_Code]
      ,A.[Contract_Amount]
      ,A.[Contract_Code]
      ,A.[Patient_Amount_Due]
      ,A.[Claim_Approved_Amount]
      ,A.[SAE_Code]
      ,A.[Prior_Authorization]
      ,A.[Clearinghouse_Trace_Number]
      ,A.[Repriced_Claim_Number]
      ,A.[Repriced(Adj_)_Claim_Number]
      ,A.[Investigational_Device_Exemption_ID]
      ,A.[Original_Reference_Number]
      ,A.[Auto_Accident_State]
      ,A.[Medical_Record_Number]
      ,A.[Demonstration_Project_ID]
      ,A.[Referral_Number]
      ,A.[Payers_DCN]
      ,A.[Claim_Note]
      ,A.[Claim_Billing_Note]
      ,A.[Repriced_Methodology]
      ,A.[Repriced_Allowed_Amount]
      ,A.[Repriced_Savings_Amount]
      ,A.[Repricing_Organization_ID]
      ,A.[Reject_Reason_Code]
      ,A.[Reject_Reason]
      ,A.[Attending_Phys_ID]
      ,A.[Attending_Phys]
      ,A.[Attending_Phys_Last_Name]
      ,A.[Attending_Phys_First_Name]
      ,A.[Attending_Phys_Middle_Name]
      ,A.[Attending_Phys_Specialty]
      ,A.[Attending_Phys_Sec_ID]
      ,A.[Operating_Phys_ID]
      ,A.[Operating_Phys]
      ,A.[Other_Operating_Phys_ID]
      ,A.[Other_Operating_Phys]
      ,A.[Rendering_Provider_ID]
      ,A.[Rendering_Provider]
      ,A.[Service_Facility]
      ,A.[Service_Facility_Name]
      ,A.[Service_Facility_ID]
      ,A.[Service_Facility_Address]
      ,A.[Service_Facility_Address_1]
      ,A.[Service_Facility_Address_2]
      ,A.[Service_Facility_City]
      ,A.[Service_Facility_State]
      ,A.[Service_Facility_ZIP]
      ,A.[Service_Facility_Secondary_ID]
      ,A.[Service_Facility_Location_Number]
      ,A.[Referring_Provider_ID]
      ,A.[Referring_Provider]
	  ,B.[id_type]
      ,B.[number]
      ,B.[parent_name]
      ,B.[parent_name_extended]
  FROM [EMSEE].[dbo].[INST] AS A
  LEFT JOIN sms.DBO.C_NPI_EIN_FACILITY_DIM_TBL AS B ON A.[Billing_NPI] = B.number

GO