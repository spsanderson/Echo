USE [SMS]

-- Create a new stored procedure called 'c_tableau_registration_error_sp' in schema 'dbo'
-- Drop the stored procedure if it already exists
IF EXISTS (
SELECT *
	FROM INFORMATION_SCHEMA.ROUTINES
	WHERE SPECIFIC_SCHEMA = N'dbo'
	AND SPECIFIC_NAME = N'c_tableau_registration_error_sp'
)
DROP PROCEDURE dbo.c_tableau_registration_error_sp
GO
-- Create the stored procedure in the specified schema
CREATE PROCEDURE dbo.c_tableau_registration_error_sp
AS
SET ANSI_NULLS ON
SET ANSI_WARNINGS ON
SET QUOTED_IDENTIFIER ON

BEGIN
	SET NOCOUNT ON;
	/************************************************************************
	File: c_tableau_registration_error_sp.sql

	Input Parameters:
		None

	Tables/Views:
		[ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Active].[dbo].[AccountComments]
		[SMS].[dbo].[Pt_Accounting_Reporting_ALT]
		[Swarm].[dbo].[CDM]
		[Swarm].[dbo].[HospSvcCategories]
		
	Creates Table/View:
		c_tableau_registration_error_tbl

	Functions:
		None

	Authors: Casey Delaney
			 Mayur Shah

	Department: Revenue Cycle Management

	Purpose/Description:
		To build the table necessary for the Registration Error Report DB

	Revision History:
	Date		Version		Description
	----		----		----
	2024-03-27	v1			Initial Creation
	2024-04-03	v2			Calcs for billing info and lag days
	2024-04-16	v3			Added attending physician and ALT SP run date
	2024-05-06	v4			Removed the max date temp table; post dates now reflect the date in Invision
	2024-07-03	v5			Reworked the entire SP to eliminate duplicate errors
	2024-08-23	v6			Added the first version of hospital service categories
	2024-09-19	v7			Removed hosp svc category mapping and joined the new mapping table in Swarm
							Added admit/service date to each row
	************************************************************************/

	DROP TABLE IF EXISTS dbo.c_tableau_registration_error_tbl;	
	
	-- #reg_errors: Identify accounts that have registration error service codes.
	DROP TABLE IF EXISTS #reg_errors;
	SELECT DISTINCT
	    A.*,
	    (CAST(B.[PA-SMART-SVC-CD-WOSCD] AS VARCHAR) + CAST(B.[PA-SMART-SVC-CD-SCD] AS VARCHAR)) AS 'Service_Code',
	    B.[PA-SMART-DATE] AS 'Post_Date'
	INTO #reg_errors
	FROM
	    [SMS].[dbo].[Pt_Accounting_Reporting_ALT] AS A
	    INNER JOIN [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Active].[dbo].[AccountComments] AS B
		    ON A.[Pt_No] = (CAST(B.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(B.[PA-PT-NO-SCD-1] AS VARCHAR))
	WHERE
	    (CAST(B.[PA-SMART-SVC-CD-WOSCD] AS VARCHAR) + CAST(B.[PA-SMART-SVC-CD-SCD] AS VARCHAR)) IN (
	        '38000261',
	        '38002366',
	        '38002374',
	        '38002382',
	        '38002390',
	        '38008512',
	        '38008520',
	        '38008538',
	        '38008546',
	        '38008553',
	        '38008561',
	        '38008587',
	        '38008595',
	        '38008611',
	        '38008629',
	        '38008637',
	        '38008645',
	        '38000923',
	        '38580106')
	    AND B.[PA-SMART-DATE] >= '2022-12-01';
	
	
	-- #descriptions: Pull in the service code description (registration error description) for each error as well as the attending physician.
	DROP TABLE IF EXISTS #descriptions;
	SELECT DISTINCT
	    A.*,
	    B.[General Description] as 'General_Description',
		coalesce(ARCHIVE.[PA-ATN-DR-NAME], ACTIVE.[PA-ATN-DR-NAME]) as [Attending_Physician]
	INTO #descriptions
	FROM
	    #reg_errors AS A
		INNER JOIN [Swarm].[dbo].[CDM] AS B
	        ON A.Service_Code = B.[Service Code]
		LEFT JOIN [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Archive].[dbo].[PatientDemographics] AS ARCHIVE
		    ON A.Pt_No = concat(ARCHIVE.[PA-PT-NO-WOSCD], ARCHIVE.[PA-PT-NO-SCD-1])
		LEFT JOIN [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Active].[dbo].[PatientDemographics] AS ACTIVE
		    ON A.Pt_No = concat(ACTIVE.[PA-PT-NO-WOSCD], ACTIVE.[PA-PT-NO-SCD-1])
	ORDER BY
	    Post_Date;
	
	
	-- #max_billed_date: Get the max billed date for each account, this helps eliminate duplicate errors moving forward.
	DROP TABLE IF EXISTS #max_billed_date;
	SELECT
		Pt_No,
		MAX(coalesce(First_Ins_Bl_Date, [1st_Bl_Exported_Date])) as Max_Billed_Date
	INTO #max_billed_date
	FROM
		#descriptions
	GROUP BY
		Pt_No;
	
		
	-- #info_needed
	DROP TABLE IF EXISTS #info_needed;
	SELECT
		a.Pt_No,
		a.Active_Archive,
		a.Acct_Type,
		a.Pt_Type_Desc,
		b.Max_Billed_Date,
		a.Tot_Chgs,
		a.Tot_Pay_Amt,
		a.[File] as Bucket,
		a.FC,
		a.FC_Description,
		a.Hosp_Svc,
		a.Hosp_Svc_Description,
		a.Ins1_Cd,
		a.Ins1_Desc,
		a.Expected_Payment,
		a.payer_organization,
		a.product_class,
		a.Service_Code,
		a.Post_Date,
		a.General_Description,
		a.Attending_Physician,
		a.SP_RunDateTime
	INTO #info_needed
	FROM
		#descriptions as a
		LEFT JOIN #max_billed_date as b
			on a.Pt_No = b.Pt_No;
	
	
	-- #grouping: Grouping $ amounts per account.
	DROP TABLE IF EXISTS #grouping;
	SELECT
		Pt_No,
		Active_Archive,
		Acct_Type,
		Pt_Type_Desc,
		Max_Billed_Date,
		SUM(Tot_Chgs) as Tot_Chgs,
		SUM(Tot_Pay_Amt) as Tot_Pay_Amt,
		Bucket,
		FC,
		FC_Description,
		Hosp_Svc,
		Hosp_Svc_Description,
		Ins1_Cd,
		Ins1_Desc,
		SUM(Expected_Payment) as Expected_Payment,
		payer_organization,
		product_class,
		Service_Code,
		Post_Date,
		General_Description,
		Attending_Physician,
		SP_RunDateTime
	INTO #grouping
	FROM
		#info_needed
	GROUP BY
		Pt_No,
		Active_Archive,
		Acct_Type,
		Pt_Type_Desc,
		Max_Billed_Date,
		Bucket,
		FC,
		FC_Description,
		Hosp_Svc,
		Hosp_Svc_Description,
		Ins1_Cd,
		Ins1_Desc,
		payer_organization,
		product_class,
		Service_Code,
		Post_Date,
		General_Description,
		Attending_Physician,
		SP_RunDateTime;
	
	
	-- #final: Adding in the final billing metrics for each account.
	DROP TABLE IF EXISTS #final;
	SELECT
		Pt_No,
		Active_Archive,
		Acct_Type,
		Pt_Type_Desc,
		ca.Service_Date,
		Max_Billed_Date,
		Billed_Flag = CASE
						WHEN Max_Billed_Date is not null
						THEN 1
						ELSE 0
					  END,
		Days_Lag = CASE
					WHEN Max_Billed_Date is not null
					THEN datediff(day, Max_Billed_Date, Post_Date)
					ELSE null
				   END,
		Billing_Status = CASE
							WHEN (datediff(day, Max_Billed_Date, Post_Date)) <= 0
								or (datediff(day, Max_Billed_Date, Post_Date)) is null
							THEN 'Pre-Bill'
							ELSE 'Post-Bill'
						  END,
		Tot_Chgs,
		Tot_Pay_Amt,
		Bucket,
		FC,
		FC_Description,
		Hosp_Svc,
		Hosp_Svc_Description,
		b.hosp_svc_category,
		Ins1_Cd,
		Ins1_Desc,
		Expected_Payment,
		payer_organization,
		product_class,
		Service_Code,
		Post_Date,
		General_Description,
		Attending_Physician,
		SP_RunDateTime
	INTO #final
	FROM
		#grouping as a
		LEFT JOIN Swarm.dbo.HospSvcCategories as b
			on a.Hosp_Svc = b.Hospital_Svc_Code
	OUTER APPLY (
			SELECT
				max(c.admit_date) as 'Service_Date'
			FROM
				sms.dbo.Pt_Accounting_Reporting_ALT as c
			WHERE
				c.Pt_No = a.Pt_No
				and c.Admit_Date <= a.Post_Date
			GROUP BY
				c.Pt_No
	) as ca;

	-- Create and populate dbo.c_tableau_registration_error_tbl
	CREATE TABLE dbo.c_tableau_registration_error_tbl (
	    pk INT IDENTITY(1, 1) NOT NULL PRIMARY KEY,
		Pt_No VARCHAR(255),
		Active_Archive VARCHAR(255),
		Acct_Type VARCHAR(255),
		Pt_Type_Desc VARCHAR(255),
		Service_Date DATETIME,
		Billed_Date DATETIME,
		Billed_Flag INT,
		Days_Lag INT,
		Billing_Status VARCHAR(255),
		Tot_Chgs MONEY,
		Tot_Pay_Amt MONEY,
		Bucket VARCHAR(255),
		FC VARCHAR(255),
		FC_Description VARCHAR(255),
		Hosp_Svc VARCHAR(255),
		Hosp_Svc_Description VARCHAR(255),
		Hosp_Svc_Category VARCHAR(255),
		Ins1_Cd VARCHAR(255),
		Ins1_Desc VARCHAR(255),
		Expected_Payment MONEY,
		payer_organization VARCHAR(255),
		product_class VARCHAR(255),
		Service_Code VARCHAR(255),
		Post_Date DATETIME,
		General_Description VARCHAR(255),
		Attending_Physician VARCHAR(255),
		SP_RunDateTime DATETIME
		);

	INSERT INTO dbo.c_tableau_registration_error_tbl (
	    Pt_No,
		Active_Archive,
		Acct_Type,
		Pt_Type_Desc,
		Service_Date,
		Billed_Date,
		Billed_Flag,
		Days_Lag,
		Billing_Status,
		Tot_Chgs,
		Tot_Pay_Amt,
		Bucket,
		FC,
		FC_Description,
		Hosp_Svc,
		Hosp_Svc_Description,
		Hosp_Svc_Category,
		Ins1_Cd,
		Ins1_Desc,
		Expected_Payment,
		payer_organization,
		product_class,
		Service_Code,
		Post_Date,
		General_Description,
		Attending_Physician,
		SP_RunDateTime
		)
	SELECT
		*
	FROM
		#final;

END;
