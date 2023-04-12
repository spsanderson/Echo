USE [Echo_SBU_FinPARA]

/*
***********************************************************************
File: c_ins_user_fields_v.sql

Input Parameters:
	None

Tables/Views:
	echo_active.dbo.UserDefined
    echo_archive.dbo.UserDefined

Creates Table/View:
	dbo.c_ins_user_field_v

Functions:
	None

Author: Steven P. Sanderson II, MPH

Department: Patient Financial Services

Purpose/Description
	Create a view that will return the insurance company address and name

Revision History:
Date		Version		Description
----		----		----
2018-07-13	v1			Initial Creation
***********************************************************************
*/

-- Create a new view called 'c_ins_user_field_v' in schema 'dbo'
-- Drop the view if it already exists
IF EXISTS (
SELECT *
	FROM sys.views
	JOIN sys.schemas
	ON sys.views.schema_id = sys.schemas.schema_id
	WHERE sys.schemas.name = N'dbo'
	AND sys.views.name = N'c_ins_user_field_v'
)
DROP VIEW dbo.c_ins_user_field_v
GO
-- Create the view in the specified schema
CREATE VIEW dbo.c_ins_user_field_v
AS

	SELECT A.[PA-PT-NO-WOSCD],
		A.[PA-PT-NO-SCD-1],
		A.[PA-ACCT-TYPE],
		A.[PA-ACCT-SUB-TYPE],
		A.[PA-USER-INS-CO-CD],
		A.[PA-USER-INS-PLAN-NO],
		B.[PA-USER-TEXT] AS [PA-USER-INS-ADDR1],
		c.[PA-USER-TEXT] AS [PA-USER-INS-ADDR2],
		f.[PA-USER-TEXT] AS [PA-USER-INS-NAME]
	FROM [Echo_Active].[dbo].[UserDefined] AS a
	LEFT JOIN [Echo_Active].dbo.UserDefined AS b ON a.[PA-PT-NO-WOSCD] = b.[PA-PT-NO-WOSCD]
		AND a.[PA-PT-NO-SCD-1] = b.[PA-PT-NO-SCD-1]
		AND A.[PA-USER-INS-CO-CD] = B.[PA-USER-INS-CO-CD]
		AND A.[PA-USER-INS-PLAN-NO] = B.[PA-USER-INS-PLAN-NO]
		AND B.[PA-COMPONENT-ID] = '5C49ADD1'
	LEFT JOIN [Echo_Active].DBO.UserDefined AS C ON A.[PA-PT-NO-WOSCD] = C.[PA-PT-NO-WOSCD]
		AND A.[PA-PT-NO-SCD-1] = C.[PA-PT-NO-SCD-1]
		AND A.[PA-USER-INS-CO-CD] = c.[PA-USER-INS-CO-CD]
		AND A.[PA-USER-INS-PLAN-NO] = c.[PA-USER-INS-PLAN-NO]
		AND C.[PA-COMPONENT-ID] = '5C49ADD2'
	LEFT JOIN [Echo_Active].dbo.UserDefined AS f ON a.[PA-PT-NO-WOSCD] = f.[PA-PT-NO-WOSCD]
		AND a.[PA-PT-NO-SCD-1] = f.[PA-PT-NO-SCD-1]
		AND A.[PA-USER-INS-CO-CD] = f.[PA-USER-INS-CO-CD]
		AND A.[PA-USER-INS-PLAN-NO] = f.[PA-USER-INS-PLAN-NO]
		AND f.[PA-COMPONENT-ID] = '5C49NAME'
	GROUP BY A.[PA-PT-NO-WOSCD],
		A.[PA-PT-NO-SCD-1],
		A.[PA-ACCT-TYPE],
		A.[PA-ACCT-SUB-TYPE],
		A.[PA-USER-INS-CO-CD],
		A.[PA-USER-INS-PLAN-NO],
		B.[PA-USER-TEXT],
		C.[PA-USER-TEXT],
		f.[PA-USER-TEXT]

    UNION ALL

    SELECT A.[PA-PT-NO-WOSCD],
		A.[PA-PT-NO-SCD-1],
		A.[PA-ACCT-TYPE],
		A.[PA-ACCT-SUB-TYPE],
		A.[PA-USER-INS-CO-CD],
		A.[PA-USER-INS-PLAN-NO],
		B.[PA-USER-TEXT] AS [PA-USER-INS-ADDR1],
		c.[PA-USER-TEXT] AS [PA-USER-INS-ADDR2],
		f.[PA-USER-TEXT] AS [PA-USER-INS-NAME]
	FROM [Echo_Active].[dbo].[UserDefined] AS a
	LEFT JOIN [Echo_Archive].dbo.UserDefined AS b ON a.[PA-PT-NO-WOSCD] = b.[PA-PT-NO-WOSCD]
		AND a.[PA-PT-NO-SCD-1] = b.[PA-PT-NO-SCD-1]
		AND A.[PA-USER-INS-CO-CD] = B.[PA-USER-INS-CO-CD]
		AND A.[PA-USER-INS-PLAN-NO] = B.[PA-USER-INS-PLAN-NO]
		AND B.[PA-COMPONENT-ID] = '5C49ADD1'
	LEFT JOIN [Echo_Archive].DBO.UserDefined AS C ON A.[PA-PT-NO-WOSCD] = C.[PA-PT-NO-WOSCD]
		AND A.[PA-PT-NO-SCD-1] = C.[PA-PT-NO-SCD-1]
		AND A.[PA-USER-INS-CO-CD] = c.[PA-USER-INS-CO-CD]
		AND A.[PA-USER-INS-PLAN-NO] = c.[PA-USER-INS-PLAN-NO]
		AND C.[PA-COMPONENT-ID] = '5C49ADD2'
	LEFT JOIN [Echo_Archive].dbo.UserDefined AS f ON a.[PA-PT-NO-WOSCD] = f.[PA-PT-NO-WOSCD]
		AND a.[PA-PT-NO-SCD-1] = f.[PA-PT-NO-SCD-1]
		AND A.[PA-USER-INS-CO-CD] = f.[PA-USER-INS-CO-CD]
		AND A.[PA-USER-INS-PLAN-NO] = f.[PA-USER-INS-PLAN-NO]
		AND f.[PA-COMPONENT-ID] = '5C49NAME'
	GROUP BY A.[PA-PT-NO-WOSCD],
		A.[PA-PT-NO-SCD-1],
		A.[PA-ACCT-TYPE],
		A.[PA-ACCT-SUB-TYPE],
		A.[PA-USER-INS-CO-CD],
		A.[PA-USER-INS-PLAN-NO],
		B.[PA-USER-TEXT],
		C.[PA-USER-TEXT],
		f.[PA-USER-TEXT]

GO


