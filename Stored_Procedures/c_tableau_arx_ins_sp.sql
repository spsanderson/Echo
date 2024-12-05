USE [SMS]

-- Create a new stored procedure called 'c_tableau_arx_ins_sp' in schema 'dbo'
-- Drop the stored procedure if it already exists
IF EXISTS (
SELECT *
	FROM INFORMATION_SCHEMA.ROUTINES
	WHERE SPECIFIC_SCHEMA = N'dbo'
	AND SPECIFIC_NAME = N'c_tableau_arx_ins_sp'
)
DROP PROCEDURE dbo.c_tableau_arx_ins_sp
GO
-- Create the stored procedure in the specified schema
CREATE PROCEDURE dbo.c_tableau_arx_ins_sp
AS
SET ANSI_NULLS ON
SET ANSI_WARNINGS ON
SET QUOTED_IDENTIFIER ON

BEGIN
	SET NOCOUNT ON;
	/************************************************************************
	File: c_tableau_arx_ins_sp.sql

	Input Parameters:
		None

	Tables/Views:
		PARA.dbo.ARxChange_INSUSCRN_Placements_Backup
		Swarm.dbo.[INSUSCRN RETURN]
		[ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Active].[dbo].[AccountComments]
		[ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Archive].[dbo].[AccountComments]
		sms.dbo.Payments_Adjustments_For_Reporting
		sms.dbo.c_tableau_insurance_tbl
		sms.dbo.Pt_Accounting_Reporting_ALT
		
	Creates Table/View:
		c_tableau_arx_ins_tbl
		c_tableau_arx_ins_payments_tbl

	Functions:
		None

	Authors: Casey Delaney
			 Steve Sanderson

	Department: Revenue Cycle Management

	Purpose/Description:
		To build the tables necessary for the ARxChange Insurance Scrub DB in Tableau

	Revision History:
	Date		Version		Description
	----		----		----
	2024-10-04	V1			Initial Creation
	************************************************************************/


	-- Drop tables

	DROP TABLE IF EXISTS dbo.c_tableau_arx_ins_tbl;
	DROP TABLE IF EXISTS dbo.c_tableau_arx_ins_payments_tbl;
	

	-- #ins_volume: Identify all accounts sent to ARxChange for Insurance Scrub and those there were returned with discovered insurance policies.
	DROP TABLE IF EXISTS #ins_volume;
	SELECT DISTINCT
		a.EncounterID as 'pt_no',
		a.[I/O_Indicator] as 'acct_type',
		a.DateOfdischarge as 'dsch_date',
		a.Payor1Code as 'ins1_cd',
		a.CurrentFiancialClassName as 'fc',
		a.[Service/DepartmentCode] as 'hosp_svc',
		a.[Service/DepartmentName] as 'hosp_svc_desc',
		a.TotalCharges as 'outbound_tot_charges',
		a.TotalAmountDue as 'outbound_tot_amt_due',
		a.[Capture Date] as 'referral_date', -- when the data is pulled and sent out
		--b.Date_Referral as 'inbound_referral_date', -- when an account is tagged with 28 records, and it should be 2 days prior to the capture date
		--b.request_date as 'inbound_request_date', -- when the data is sent out, should match Capture Date in PARA.dbo.ARxChange_INSUSCRN_Placements_Backup
		b.Import_to_SQL_Date as 'inbound_import_to_sql_date', -- when the returned data is exported to SQL
		b.Total_Charges as 'inbound_tot_charges',
		b.Total_amount_Due as 'inbound_tot_amt_due',
		b.Policies_Found as 'policies_found',
		b.[1] as 'payer1',
		b.[2] as 'payer2',
		b.[3] as 'payer3',
		b.[4] as 'payer4',
		ins_found_ind = CASE
						WHEN b.ClientAccountNumber is null
						THEN 0
						ELSE 1
					END
	INTO #ins_volume
	FROM
		PARA.dbo.ARxChange_INSUSCRN_Placements_Backup as a -- referrals to ARxChange (outbound)
		LEFT JOIN (
			SELECT
				pvt.Date_Referral,
				pvt.request_date,
				pvt.Import_to_SQL_Date,
				pvt.ClientAccountNumber,
				pvt.Total_Charges,
				pvt.Total_amount_Due,
				pvt.Inpatient_Outpatient,
				pvt.Policies_Found,
				pvt.[1],
				pvt.[2],
				pvt.[3],
				pvt.[4]
			FROM (
				SELECT
					Date_Referral,
					request_date,
					Import_to_SQL_Date,
					ClientAccountNumber,
					Total_Charges,
					Total_Amount_Due,
					Inpatient_Outpatient,
					Policies_Found,
					Payer_Name,
					rec_no = ROW_NUMBER() OVER (PARTITION BY ClientAccountNumber ORDER BY ClientAccountNumber)
				FROM
					Swarm.dbo.[INSUSCRN RETURN]
				) as z -- inbound insurance scrub data from ARxChange (inbound)
			PIVOT(MAX(Payer_Name) FOR rec_no in ("1","2","3","4")) as pvt	
			) as b
				on a.EncounterID = b.ClientAccountNumber;
	

	/*

	Create dbo.c_tableau_arx_ins_tbl

	*/


	CREATE TABLE dbo.c_tableau_arx_ins_tbl (
		pk INT IDENTITY(1, 1) NOT NULL PRIMARY KEY,
		pt_no VARCHAR(255),
		acct_type VARCHAR(255),
		dsch_date DATETIME,
		ins1_cd VARCHAR(255),
		fc VARCHAR(255),
		hosp_svc VARCHAR(255),
		hosp_svc_desc VARCHAR(255),
		outbound_tot_charges MONEY,
		outbound_tot_amt_due MONEY,
		referral_date DATETIME,
		inbound_import_to_sql_date DATETIME,
		inbound_tot_charges MONEY,
		inbound_tot_amt_due MONEY,
		policies_found INT,
		payer1 VARCHAR(255),
		payer2 VARCHAR(255),
		payer3 VARCHAR(255),
		payer4 VARCHAR(255),
		ins_found_ind INT
		);

	INSERT INTO dbo.c_tableau_arx_ins_tbl (
		pt_no,
		acct_type,
		dsch_date,
		ins1_cd,
		fc,
		hosp_svc,
		hosp_svc_desc,
		outbound_tot_charges,
		outbound_tot_amt_due,
		referral_date,
		inbound_import_to_sql_date,
		inbound_tot_charges,
		inbound_tot_amt_due,
		policies_found,
		payer1,
		payer2,
		payer3,
		payer4,
		ins_found_ind
		)
	SELECT
		*
	FROM
		#ins_volume;

	
	-- #echo_payments: Get all payments on accounts where insurance was updated that were posted after the insurance was updated.
	DROP TABLE IF EXISTS #echo_payments;
	SELECT
		echo.echo_pt_no,
		echo.cdm_code,
		echo.ins_update_date,
		echo.echo_status,
		payments.Unit_No,
		payments.Unit_Date,
		payments.FC as 'payment_fc',
		payments.DTL_Type_Ind,
		payments.Transaction_Type,
		payments.INS_PLAN,
		payments.SVC_CD,
		payments.CDM_DESCRIPTION,
		payments.[PA-DTL-DATE] as 'payment_post_date',
		payments.[PA-DTL-CHG-AMT] as 'payment_amt',
		payments.payer_name,
		payments.payer_organization,
		payments.product_class
	INTO #echo_payments
	FROM (
		SELECT
			(CAST([PA-PT-NO-WOSCD] AS VARCHAR) + CAST([PA-PT-NO-SCD-1] AS VARCHAR)) as 'echo_pt_no',
			(CAST([PA-SMART-SVC-CD-WOSCD] AS VARCHAR) + CAST([PA-SMART-SVC-CD-SCD] AS VARCHAR)) as 'cdm_code',
			[PA-SMART-DATE] as 'ins_update_date',
			echo_status = 'Active'
		FROM
			[ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Active].[dbo].[AccountComments]
		WHERE
			(CAST([PA-SMART-SVC-CD-WOSCD] AS VARCHAR) + CAST([PA-SMART-SVC-CD-SCD] AS VARCHAR)) = '38000493' -- service code indicates an ins plan was updated
		
		UNION
		
		SELECT
			(CAST([PA-PT-NO-WOSCD] AS VARCHAR) + CAST([PA-PT-NO-SCD-1] AS VARCHAR)) as 'echo_pt_no',
			(CAST([PA-SMART-SVC-CD-WOSCD] AS VARCHAR) + CAST([PA-SMART-SVC-CD-SCD] AS VARCHAR)) as 'cdm_code',
			[PA-SMART-DATE] as 'ins_update_date',
			echo_status = 'Archive'
		FROM
			[ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Archive].[dbo].[AccountComments]
		WHERE
			(CAST([PA-SMART-SVC-CD-WOSCD] AS VARCHAR) + CAST([PA-SMART-SVC-CD-SCD] AS VARCHAR)) = '38000493'
		) as echo
		LEFT JOIN (
			SELECT
				a.*,
				b.payer_name,
				b.payer_organization,
				b.product_class
			FROM
				sms.dbo.Payments_Adjustments_For_Reporting as a
				LEFT JOIN sms.dbo.c_tableau_insurance_tbl as b
					on a.INS_PLAN = b.code
			WHERE
				a.DTL_Type_Ind = '1'
				OR a.SVC_CD in ('603209','602151')
			) as payments
				on echo.echo_pt_no = payments.PT_NO
					AND payments.[PA-DTL-DATE] > echo.ins_update_date -- payments that were posted after the insurance was changed
	WHERE
		payments.PT_NO is not null;
	
	
	-- #payments: Payments after insurance was updated on accounts that ARxChange discovered insurance plans.
	DROP TABLE IF EXISTS #payments;
	SELECT
		a.pt_no,
		b.echo_status,
		b.Unit_No,
		b.Unit_Date,
		b.payment_fc,
		b.DTL_Type_Ind,
		b.Transaction_Type,
		b.INS_PLAN,
		b.ins_update_date,
		b.SVC_CD,
		b.cdm_code,
		b.CDM_DESCRIPTION,
		b.payment_post_date,
		b.payment_amt,
		b.payer_name,
		b.payer_organization,
		b.product_class,
		c.SP_RunDateTime
	INTO #payments
	FROM
		#ins_volume as a
		INNER JOIN #echo_payments as b
			on a.pt_no = b.echo_pt_no
		LEFT JOIN sms.dbo.Pt_Accounting_Reporting_ALT as c
			on a.pt_no = c.Pt_No
	WHERE
		a.ins_found_ind = '1';


	/*

	Create dbo.c_tableau_arx_ins_payments_tbl

	*/

	CREATE TABLE dbo.c_tableau_arx_ins_payments_tbl (
		pk INT IDENTITY(1, 1) NOT NULL PRIMARY KEY,
		pt_no VARCHAR(255),
		echo_status VARCHAR(255),
		unit_no VARCHAR(255),
		unit_date DATETIME,
		payment_fc VARCHAR(255),
		dtl_type_ind VARCHAR(255),
		transaction_type VARCHAR(255),
		ins_plan VARCHAR(255),
		ins_update_date DATETIME,
		svc_cd VARCHAR(255),
		cdm_code VARCHAR(255),
		cdm_description VARCHAR(255),
		payment_post_date DATETIME,
		payment_amt MONEY,
		payer_name VARCHAR(255),
		payer_organization VARCHAR(255),
		product_class VARCHAR(255),
		SP_RunDateTime DATETIME
		);

	INSERT INTO dbo.c_tableau_arx_ins_payments_tbl (
		pt_no,
		echo_status,
		unit_no,
		unit_date,
		payment_fc,
		dtl_type_ind,
		transaction_type,
		ins_plan,
		ins_update_date,
		svc_cd,
		cdm_code,
		cdm_description,
		payment_post_date,
		payment_amt,
		payer_name,
		payer_organization,
		product_class,
		SP_RunDateTime
		)
	SELECT
		*
	FROM
		#payments;


END;




/*

-- Outbound/Inbound Charges and Amt Due Comparison

select
	pt_no,
	outbound_tot_charges,
	inbound_tot_charges,
	chgs_diff = outbound_tot_charges - inbound_tot_charges,
	outbound_tot_amt_due,
	inbound_tot_amt_due,
	amt_due_diff = outbound_tot_amt_due - inbound_tot_amt_due
from #ins_volume
where
	inbound_tot_charges is not null
	and (
	(outbound_tot_charges - inbound_tot_charges != 0)
	or
	(outbound_tot_amt_due - inbound_tot_amt_due != 0)
	)

*/