/*
***********************************************************************
File: c_patient_demos_atn_dr_v.sql

Input Parameters:
	None

Tables/Views:
	[dbo].[PatientDemographics]

Creates Table/View:
	c_patient_demos_atn_dr_v

Functions:
	None

Author: Fang Wu

Department: Patient Financial Services

Purpose/Description
	Crate a view for the patient atn doctor

Revision History:
Date		Version		Description
----		----		----
2023-09-08	v1			Initial Creation
***********************************************************************
*/

-- Create a new view called 'c_patient_demos_atn_dr_v' in schema 'dbo'
-- Drop the view if it already exists
IF EXISTS (
		SELECT *
		FROM sys.VIEWS
		JOIN sys.schemas ON sys.VIEWS.schema_id = sys.schemas.schema_id
		WHERE sys.schemas.name = N'dbo'
			AND sys.VIEWS.name = N'c_patient_demos_atn_dr_v'
		)
	DROP VIEW dbo.c_patient_demos_atn_dr_v
GO

-- Create the view in the specified schema
CREATE VIEW dbo.c_patient_demos_atn_dr_v
AS
    SELECT [pa-pt-no-woscd],
        [pa-pt-no-scd-1],
        CAST([PA-PT-NO-WOSCD] AS VARCHAR) + CAST([PA-PT-NO-SCD-1] AS VARCHAR) AS [pt_no],
        [pa-ctl-paa-xfer-date],
        cast([PA-ATN-DR-NO-WOSCD] as varchar) + cast([PA-ATN-DR-NO-SCD] as varchar) as [Attn_Dr_No]
      
    FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Active].[dbo].[PatientDemographics]
	

	UNION ALL

     SELECT [pa-pt-no-woscd],
        [pa-pt-no-scd-1],
        CAST([PA-PT-NO-WOSCD] AS VARCHAR) + CAST([PA-PT-NO-SCD-1] AS VARCHAR) AS [pt_no],
        [pa-ctl-paa-xfer-date],
        cast([PA-ATN-DR-NO-WOSCD] as varchar) + cast([PA-ATN-DR-NO-SCD] as varchar) as [Attn_Dr_No]
      
    FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Archive].[dbo].[PatientDemographics]

GO


