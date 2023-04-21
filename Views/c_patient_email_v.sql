/*
***********************************************************************
File: c_patient_email_v.sql

Input Parameters:
	None

Tables/Views:
	dbo.userdefined

Creates Table/View:
	c_patient_email_v

Functions:
	None

Author: Steven P. Sanderson II, MPH

Department: Patient Financial Services

Purpose/Description
	Crate a view for the patient email view

Revision History:
Date		Version		Description
----		----		----
2023-04-12	v1			Initial Creation
***********************************************************************
*/

-- Create a new view called 'c_patient_email_v' in schema 'dbo'
-- Drop the view if it already exists
IF EXISTS (
		SELECT *
		FROM sys.VIEWS
		JOIN sys.schemas ON sys.VIEWS.schema_id = sys.schemas.schema_id
		WHERE sys.schemas.name = N'dbo'
			AND sys.VIEWS.name = N'c_patient_email_v'
		)
	DROP VIEW dbo.c_patient_email_v
GO

-- Create the view in the specified schema
CREATE VIEW dbo.c_patient_email_v
AS
    SELECT EM1.[PA-PT-NO-WOSCD],
        EM1.[PA-PT-NO-SCD-1],
        CAST(EM1.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(EM1.[PA-PT-NO-SCD-1] AS VARCHAR) AS [pt_no],
        EM1.[PA-CTL-PAA-XFER-DATE],
        EM1.[PA-REC-CREATE-DATE],
        [email_address] = ISNULL(EM1.[PA-USER-TEXT], '') + ISNULL(EM2.[PA-USER-TEXT], '') + ISNULL(EM3.[PA-USER-TEXT], '')
    FROM Echo_Active.dbo.UserDefined AS EM1
    LEFT JOIN Echo_Active.DBO.UserDefined AS EM2 ON EM1.[PA-PT-NO-SCD-1] = EM2.[PA-PT-NO-SCD-1]
        AND EM1.[PA-PT-NO-WOSCD] = EM2.[PA-PT-NO-WOSCD]
        AND EM2.[PA-COMPONENT-ID] = 'GUAREMA2'
    LEFT JOIN Echo_Active.DBO.UserDefined AS EM3 ON EM1.[PA-PT-NO-SCD-1] = EM3.[PA-PT-NO-SCD-1]
        AND EM1.[PA-PT-NO-WOSCD] = EM3.[PA-PT-NO-WOSCD]
        AND EM3.[PA-COMPONENT-ID] = 'GUAREMA3'
    WHERE EM1.[PA-COMPONENT-ID] = 'GUAREMA1'

        UNION ALL

    SELECT EM1.[PA-PT-NO-WOSCD],
        EM1.[PA-PT-NO-SCD-1],
        CAST(EM1.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(EM1.[PA-PT-NO-SCD-1] AS VARCHAR) AS [pt_no],
        EM1.[PA-CTL-PAA-XFER-DATE],
        EM1.[PA-REC-CREATE-DATE],
        [email_address] = ISNULL(EM1.[PA-USER-TEXT], '') + ISNULL(EM2.[PA-USER-TEXT], '') + ISNULL(EM3.[PA-USER-TEXT], '')
    FROM Echo_Archive.dbo.UserDefined AS EM1
    LEFT JOIN Echo_Archive.DBO.UserDefined AS EM2 ON EM1.[PA-PT-NO-SCD-1] = EM2.[PA-PT-NO-SCD-1]
        AND EM1.[PA-PT-NO-WOSCD] = EM2.[PA-PT-NO-WOSCD]
        AND EM2.[PA-COMPONENT-ID] = 'GUAREMA2'
    LEFT JOIN Echo_Archive.DBO.UserDefined AS EM3 ON EM1.[PA-PT-NO-SCD-1] = EM3.[PA-PT-NO-SCD-1]
        AND EM1.[PA-PT-NO-WOSCD] = EM3.[PA-PT-NO-WOSCD]
        AND EM3.[PA-COMPONENT-ID] = 'GUAREMA3'
    WHERE EM1.[PA-COMPONENT-ID] = 'GUAREMA1'

GO


