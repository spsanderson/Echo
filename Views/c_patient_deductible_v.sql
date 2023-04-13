/*
***********************************************************************
File: c_patient_deductible_v.sql

Input Parameters:
	None

Tables/Views:
	dbo.UserDefined

Creates Table/View:
	c_patient_deductible_v

Functions:
	None

Author: Steven P. Sanderson II, MPH

Department: Patient Financial Services

Purpose/Description
	Crate a view for the patient deductible for payer 1, 2, and 3

Revision History:
Date		Version		Description
----		----		----
2023-04-13	v1			Initial Creation
***********************************************************************
*/

-- Create a new view called 'c_patient_deductible_v' in schema 'dbo'
-- Drop the view if it already exists
IF EXISTS (
		SELECT *
		FROM sys.VIEWS
		JOIN sys.schemas ON sys.VIEWS.schema_id = sys.schemas.schema_id
		WHERE sys.schemas.name = N'dbo'
			AND sys.VIEWS.name = N'c_patient_deductible_v'
		)
	DROP VIEW dbo.c_patient_deductible_v
GO

-- Create the view in the specified schema
CREATE VIEW dbo.c_patient_deductible_v
AS
SELECT a.[PA-PT-NO-WOSCD],
	A.[PA-PT-NO-SCD-1],
	A.pt_no,
	a.[PA-CTL-PAA-XFER-DATE],
	a.unit_date,
	a.[PA-USER-CREATE-DATE],
	a.[deductible_pyr1],
	a.deductible_pyr2,
	a.deductible_pyr3
FROM (
	SELECT PVT.[PA-PT-NO-WOSCD],
		PVT.[PA-PT-NO-SCD-1],
		PVT.pt_no,
		PVT.[PA-CTL-PAA-XFER-DATE],
		PVT.unit_date,
		PVT.[PA-USER-CREATE-DATE],
		ISNULL(PVT.[6C49VCA1], 0) AS [deductible_pyr1],
		ISNULL(PVT.[6C49VCB1], 0) AS [deductible_pyr2],
		ISNULL(PVT.[6C49VCC1], 0) AS [deductible_pyr3]
	FROM (
		SELECT a.[PA-PT-NO-WOSCD],
			a.[PA-PT-NO-SCD-1],
			cast(a.[pa-pt-no-woscd] AS VARCHAR) + cast(a.[pa-pt-no-scd-1] AS VARCHAR) AS [pt_no],
			a.[PA-CTL-PAA-XFER-DATE],
			a.[PA-USER-DATE-2] AS [unit_date],
			a.[pa-user-create-date],
			A.[PA-COMPONENT-ID],
			CAST(REPLACE(a.[pa-user-text], '+', '') AS MONEY) AS [deductible]
		FROM Echo_Active.DBO.UserDefined AS a
		WHERE a.[PA-COMPONENT-ID] IN ('6C49VCA1', '6C49VCB1', '6C49VCC1') --deductible
		) AS A
	PIVOT(MAX([deductible]) FOR [PA-COMPONENT-ID] IN ("6C49VCA1", "6C49VCB1", "6C49VCC1")) AS PVT
	
	UNION ALL
	
	SELECT PVT.[PA-PT-NO-WOSCD],
		PVT.[PA-PT-NO-SCD-1],
		PVT.pt_no,
		PVT.[PA-CTL-PAA-XFER-DATE],
		PVT.unit_date,
		PVT.[PA-USER-CREATE-DATE],
		ISNULL(PVT.[6C49VCA1], 0) AS [deductible_pyr1],
		ISNULL(PVT.[6C49VCB1], 0) AS [deductible_pyr2],
		ISNULL(PVT.[6C49VCC1], 0) AS [deductible_pyr3]
	FROM (
		SELECT a.[PA-PT-NO-WOSCD],
			a.[PA-PT-NO-SCD-1],
			cast(a.[pa-pt-no-woscd] AS VARCHAR) + cast(a.[pa-pt-no-scd-1] AS VARCHAR) AS [pt_no],
			a.[PA-CTL-PAA-XFER-DATE],
			a.[PA-USER-DATE-2] AS [unit_date],
			a.[pa-user-create-date],
			A.[PA-COMPONENT-ID],
			CAST(REPLACE(a.[pa-user-text], '+', '') AS MONEY) AS [deductible]
		FROM Echo_Archive.DBO.UserDefined AS a
		WHERE a.[PA-COMPONENT-ID] IN ('6C49VCA1', '6C49VCB1', '6C49VCC1') --deductible
		) AS A
	PIVOT(MAX([deductible]) FOR [PA-COMPONENT-ID] IN ("6C49VCA1", "6C49VCB1", "6C49VCC1")) AS PVT
	) AS A
GO
