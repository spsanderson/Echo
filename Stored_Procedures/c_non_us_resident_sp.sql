USE [SMS]
GO 

SET QUOTED_IDENTIFIER ON
GO  

CREATE PROCEDURE dbo.c_non_us_resident_sp
AS 

SET NOCOUNT ON;

/*
***********************************************************************
File: c_non_us_resident_sp.sql

Input Parameters:
	None

Tables/Views:
	[ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Active].[dbo].[UserDefined]
	[ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Archive].[dbo].[UserDefined]

Creates Table/View:
	dbo.c_non_us_resident_tbl

Functions:
	NONE

Author: Steven P. Sanderson II, MPH

Department: Patient Financial Services

Purpose/Description
Creates a table that contains accounts that are registered for non-us 
patients.

Revision History:
Date		Version		Description
----		----		----
2024-03-25	v1			Initial Creation	
***********************************************************************
*/
BEGIN
	DROP TABLE IF EXISTS dbo.c_non_us_resident_tbl
		CREATE TABLE (
			[pt_no] VARCHAR(20),
			[pa_pt_no_woscd] VARCHAR(20),
			[pa_pt_no_scd] VARCHAR(2),
			[pa_component_id] VARCHAR(20),
			[pa_user_text] VARCHAR(2),
			[pt_last_name] VARCHAR(100),
			[pt_first_name] VARCHAR(100),
			[addr_line_one] VARCHAR(100),
			[addr_line_two] VARCHAR(100),
			[city] VARCHAR(100),
			[state] VARCHAR(100),
			[zip_cd] VARCHAR(100),
			[country_name] VARCHAR(100),
			[area_cd] VARCHAR(100),
			[phone_no] VARCHAR(100)
			)

	INSERT INTO dbo.c_non_us_resident_tbl (
		[pt_no],
		[pa_pt_no_woscd],
		[pa_pt_no_scd],
		[pa_component_id],
		[pa_user_text],
		[pt_last_name],
		[pt_first_name],
		[addr_line_one],
		[addr_line_two],
		[city],
		[state],
		[zip_cd],
		[country_name],
		[area_cd],
		[phone_no]
		)
	SELECT [pt_no] = CAST(A.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(A.[PA-PT-NO-SCD-1] AS VARCHAR),
		[pa_pt_no_woscd] = A.[PA-PT-NO-WOSCD],
		[pa_pt_no_scd] = A.[PA-PT-NO-SCD-1],
		[pa_component_id] = A.[PA-COMPONENT-ID],
		[pa_user_text] = A.[PA-USER-TEXT],
		[pt_last_name] = B.[PA-NAD-LAST-OR-ORGZ-NAME],
		[pt_first_name] = B.[PA-NAD-FIRST-OR-ORGZ-CNTC],
		[addr_line_one] = B.[pa-nad-line1-addr],
		[addr_line_two] = B.[pa-nad-line2-addr],
		[city] = B.[pa-nad-city-name],
		[state] = B.[PA-NAD-STATE-CD],
		[zip_cd] = B.[PA-NAD-ZIP-CD2],
		[country_name] = B.[PA-NAD-CNTRY-NAME],
		[area_cd] = B.[PA-NAD-PHONE-AREA-CD(1)],
		[phone_no] = B.[PA-NAD-PHONE-NO(1)],
		[pt_sex] = B.[PA-NAD-SEX-CD],
		[ssn_no] = B.[PA-NAD-SSA-NO]
	FROM Echo_Active.dbo.UserDefined AS A
	INNER JOIN Echo_Active.DBO.NADInformation AS B ON A.[PA-PT-NO-WOSCD] = B.[PA-PT-NO-WOSCD]
		AND A.[PA-PT-NO-SCD-1] = B.[PA-PT-NO-SCD-1]
		AND ISNULL(A.[PA-CTL-PAA-XFER-DATE], '') = ISNULL(B.[PA-CTL-PAA-XFER-DATE], '')
		AND B.[PA-NAD-CD] = 'PTADD'
	WHERE [PA-COMPONENT-ID] = '2C49CD25'
		AND [PA-USER-TEXT] = 'Y'
	
	UNION ALL
	
	SELECT [pt_no] = CAST(A.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(A.[PA-PT-NO-SCD-1] AS VARCHAR),
		[pa_pt_no_woscd] = A.[PA-PT-NO-WOSCD],
		[pa_pt_no_scd] = A.[PA-PT-NO-SCD-1],
		[pa_component_id] = A.[PA-COMPONENT-ID],
		[pa_user_text] = A.[PA-USER-TEXT],
		[pt_last_name] = B.[PA-NAD-LAST-OR-ORGZ-NAME],
		[pt_first_name] = B.[PA-NAD-FIRST-OR-ORGZ-CNTC],
		[addr_line_one] = B.[pa-nad-line1-addr],
		[addr_line_two] = B.[pa-nad-line2-addr],
		[city] = B.[pa-nad-city-name],
		[state] = B.[PA-NAD-STATE-CD],
		[zip_cd] = B.[PA-NAD-ZIP-CD2],
		[country_name] = B.[PA-NAD-CNTRY-NAME],
		[area_cd] = B.[PA-NAD-PHONE-AREA-CD(1)],
		[phone_no] = B.[PA-NAD-PHONE-NO(1)],
		[pt_sex] = B.[PA-NAD-SEX-CD],
		[ssn_no] = B.[PA-NAD-SSA-NO]
	FROM Echo_Archive.dbo.UserDefined AS A
	INNER JOIN Echo_Archive.DBO.NADInformation AS B ON A.[PA-PT-NO-WOSCD] = B.[PA-PT-NO-WOSCD]
		AND A.[PA-PT-NO-SCD-1] = B.[PA-PT-NO-SCD-1]
		AND ISNULL(A.[PA-CTL-PAA-XFER-DATE], '') = ISNULL(B.[PA-CTL-PAA-XFER-DATE], '')
		AND B.[PA-NAD-CD] = 'PTADD'
	WHERE [PA-COMPONENT-ID] = '2C49CD25'
		AND [PA-USER-TEXT] = 'Y'
END
