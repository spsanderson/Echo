USE [Echo_SBU_FinPARA]

/*
***********************************************************************
File: c_second_treatment_auth_v.sql

Input Parameters:
	None

Tables/Views:
    [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Active].[dbo].[UserDefined]
    [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Archive].[dbo].[UserDefined]

Creates Table/View:
	dbo.c_second_treatment_auth_v

Functions:
	None

Author: Your Name Here

Department: Patient Financial Services

Purpose/Description
	Make a view to see all of the 5c49auth records in the Echo database

Revision History:
Date		Version		Description
----		----		----
2023-04-12	v1			Initial Creation
***********************************************************************
*/

-- Create a new view called 'c_second_treatment_auth_v' in schema 'dbo'
-- Drop the view if it already exists
IF EXISTS (
SELECT *
    FROM sys.views
    JOIN sys.schemas
    ON sys.views.schema_id = sys.schemas.schema_id
    WHERE sys.schemas.name = N'dbo'
    AND sys.views.name = N'c_second_treatment_auth_v'
)
DROP VIEW dbo.c_second_treatment_auth_v
GO
-- Create the view in the specified schema
CREATE VIEW dbo.c_second_treatment_auth_v
AS
SELECT Auth.[PA-REGION-CD] AS [PA_REGION_CD],
	Auth.[PA-HOSP-CD] AS [PA_HOSP_CD],
	Auth.[PA-PT-NO-WOSCD] AS [PA_PT_NO_WOSCD],
	Auth.[PA-PT-NO-SCD-1] AS [PA_PT_NO_SCD],
	Auth.[PT-NO] AS [PT_NO],
	Auth.[PA-COMPONENT-ID] AS [PA_COMPONENT_ID],
	Auth.[POST-DATE] AS [POST_DATE],
	Auth.[COMPONENT-DESCRIPTION] AS [COMPONENT_DESCRIPTION],
	Auth.[PA-USER-TEXT] AS [AUTHORIZATION_CODE],
	Auth.[PA-INS-PLAN-CO-CD]
FROM (
	SELECT [PA-REGION-CD]
		  ,[PA-HOSP-CD]
		  ,[PA-PT-NO-WOSCD]
		  ,[PA-PT-NO-SCD-1]
		  ,[PT-NO] = CAST([PA-PT-NO-WOSCD] AS VARCHAR) + CAST([PA-PT-NO-SCD-1] AS VARCHAR)
		  ,[PA-COMPONENT-ID]
		  ,CAST([PA-USER-CREATE-DATE] AS DATE) AS [POST-DATE]
		  ,[COMPONENT-DESCRIPTION] = 'SECOND TREATMENT AUTHORIZATION'
		  ,[PA-USER-TEXT]
		  , CASE
			WHEN LEN([PA-USER-INS-PLAN-NO]) = 1
				THEN CAST([PA-USER-INS-CO-CD] AS VARCHAR) + '0' + CAST([PA-USER-INS-PLAN-NO] AS VARCHAR)
			ELSE CAST([PA-USER-INS-CO-CD] AS VARCHAR) + CAST([PA-USER-INS-PLAN-NO] AS VARCHAR)
			END AS [PA-INS-PLAN-CO-CD]
	  FROM [Echo_Active].[dbo].[UserDefined]
	  WHERE [PA-COMPONENT-ID] = '5C49ATH2'
	  AND LEN([PA-USER-INS-PLAN-NO]) < 3

	  UNION 

	  SELECT [PA-REGION-CD]
		  ,[PA-HOSP-CD]
		  ,[PA-PT-NO-WOSCD]
		  ,[PA-PT-NO-SCD-1]
		  ,[PT-NO] = CAST([PA-PT-NO-WOSCD] AS VARCHAR) + CAST([PA-PT-NO-SCD-1] AS VARCHAR)
		  ,[PA-COMPONENT-ID]
		  ,CAST([PA-USER-CREATE-DATE] AS DATE) AS [POST-DATE]
		  ,[COMPONENT-DESCRIPTION] = 'SECOND TREATMENT AUTHORIZATION'
		  ,[PA-USER-TEXT]
		  , CASE
			WHEN LEN([PA-USER-INS-PLAN-NO]) = 1
				THEN CAST([PA-USER-INS-CO-CD] AS VARCHAR) + '0' + CAST([PA-USER-INS-PLAN-NO] AS VARCHAR)
			ELSE CAST([PA-USER-INS-CO-CD] AS VARCHAR) + CAST([PA-USER-INS-PLAN-NO] AS VARCHAR)
			END AS [PA-INS-PLAN-CO-CD]
	  FROM [Echo_Archive].[dbo].[UserDefined]
	  WHERE [PA-COMPONENT-ID] = '5C49ATH2'
	  AND LEN([PA-USER-INS-PLAN-NO]) < 3
 ) AS Auth
GO


