/*
***********************************************************************
File: c_EMSEE_Claim_No_v.sql

Input Parameters:
	None

Tables/Views:
    [EMSEE].[dbo].[REMIT]

Creates Table/View:
	dbo.c_EMSEE_Claim_No_v

Functions:
	None

Author: Fang Wu

Department: Patient Financial Services

Purpose/Description
	Create a View for extracting Claim Number (Payer_Claim_Control_Number) from the EMSEE REMIT table 

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
        AND sys.views.name = N'c_EMSEE_Claim_No_v'
) DROP VIEW dbo.c_EMSEE_Claim_No_v
GO

-- Create the view in the specified schema

CREATE VIEW dbo.c_EMSEE_Claim_No_v AS -- body of the view
SELECT [Patient_Control_Number],
   case when len([Patient_Control_Number])=20 
             and isnumeric(substring([patient_Control_Number],1,12))=1 
        then cast(substring([patient_Control_Number],1,12) as numeric)
		
        else null
	    end  as 'Pt_NO',
   case when len([Patient_Control_Number])=20 
             and isnumeric(substring([patient_Control_Number],1,12))=1 
			 and substring([patient_Control_Number],13,2) not in ('AA','00') 
			 and ISNUMERIC(substring([patient_Control_Number],13,2))=1
		then cast(substring([patient_Control_Number],13,2) as numeric)
        else null
        end as 'Unit_NO',
   case when len([Patient_Control_Number])=20 
             and isnumeric(substring([patient_Control_Number],1,12))=1
	    then substring([patient_Control_Number],15,3) 
	    else null
		end as 'Ins_CD',
   [Check_EFT_Date],
   [Payer_Claim_Control_Number],
   [Claim_Status],
   [Claim_Status_Code],
   [Bill_Type]
    
  FROM [EMSEE].[dbo].[REMIT]
 

 GO

  