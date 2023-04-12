/*
***********************************************************************
File: c_patient_employer_v.sql

Input Parameters:
	None

Tables/Views:
	dbo.NADInformation

Creates Table/View:
	c_patient_employer_v

Functions:
	None

Author: Steven P. Sanderson II, MPH

Department: Patient Financial Services

Purpose/Description
	Crate a view for the patient employer data

Revision History:
Date		Version		Description
----		----		----
2023-04-12	v1			Initial Creation
***********************************************************************
*/

-- Create a new view called 'c_patient_employer_v' in schema 'dbo'
-- Drop the view if it already exists
IF EXISTS (
		SELECT *
		FROM sys.VIEWS
		JOIN sys.schemas ON sys.VIEWS.schema_id = sys.schemas.schema_id
		WHERE sys.schemas.name = N'dbo'
			AND sys.VIEWS.name = N'c_patient_employer_v'
		)
	DROP VIEW dbo.c_patient_employer_v
GO

-- Create the view in the specified schema
CREATE VIEW dbo.c_patient_employer_v
AS
    SELECT [pa-pt-no-woscd],
        [pa-pt-no-scd-1],
        CAST([PA-PT-NO-WOSCD] AS VARCHAR) + CAST([PA-PT-NO-SCD-1] AS VARCHAR) AS [pt_no],
        [pa-ctl-paa-xfer-date],
        [PA-NAD-LAST-OR-ORGZ-NAME] AS [pt_last_name],
        [PA-NAD-FIRST-OR-ORGZ-CNTC] AS [pt_first_name],
        [pa-nad-line1-addr] AS [addr_line_one],
        [pa-nad-line2-addr] AS [addr_line_two],
        [pa-nad-city-name] AS [city],
        [pa-nad-state-cd] AS [state],
        [pa-nad-zip-cd2] AS [zip_cd],
        [pa-nad-phone-area-cd(1)] AS [area_cd],
        [pa-nad-phone-no(1)] AS [phone_no]
    FROM [Echo_Active].[dbo].[NADInformation]
	WHERE [pa-nad-cd] = 'PTEMP'

	UNION ALL

    SELECT [pa-pt-no-woscd],
        [pa-pt-no-scd-1],
        CAST([PA-PT-NO-WOSCD] AS VARCHAR) + CAST([PA-PT-NO-SCD-1] AS VARCHAR) AS [pt_no],
        [pa-ctl-paa-xfer-date],
        [PA-NAD-LAST-OR-ORGZ-NAME] AS [pt_last_name],
        [PA-NAD-FIRST-OR-ORGZ-CNTC] AS [pt_first_name],
        [pa-nad-line1-addr] AS [addr_line_one],
        [pa-nad-line2-addr] AS [addr_line_two],
        [pa-nad-city-name] AS [city],
        [pa-nad-state-cd] AS [state],
        [pa-nad-zip-cd2] AS [zip_cd],
        [pa-nad-phone-area-cd(1)] AS [area_cd],
        [pa-nad-phone-no(1)] AS [phone_no]
    FROM [Echo_Archive].[dbo].[NADInformation]
	WHERE [pa-nad-cd] = 'PTEMP'

GO


