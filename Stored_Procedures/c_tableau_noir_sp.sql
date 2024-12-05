USE [SMS];

-- Create a new stored procedure called 'c_tableau_noir_sp' in schema 'dbo'
-- Drop the stored procedure if it already exists
IF EXISTS (
SELECT *
	FROM INFORMATION_SCHEMA.ROUTINES
	WHERE SPECIFIC_SCHEMA = N'dbo'
	AND SPECIFIC_NAME = N'c_tableau_noir_sp'
)
DROP PROCEDURE dbo.c_tableau_noir_sp
GO
-- Create the stored procedure in the specified schema
CREATE PROCEDURE dbo.c_tableau_noir_sp
AS
SET ANSI_NULLS ON
SET ANSI_WARNINGS ON
SET QUOTED_IDENTIFIER ON

BEGIN
	SET NOCOUNT ON;
	/************************************************************************
	File: c_tableau_noir_sp.sql

	Input Parameters:
		None

	Tables/Views:
		sms.dbo.c_NOIR_Codes_Comments_tbl
		sms.dbo.c_NOIR_Comments_No_SVC_Codes_tbl
		sms.dbo.c_NOIR_SVC_Codes_No_Comments_tbl
		sms.dbo.Pt_Accounting_Reporting_ALT
		[ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].Echo_Active.dbo.DetailInformation
		swarm.dbo.CDM
		
	Creates Table/View:
		c_tableau_noir_*_tbl

	Functions:
		None

	Authors: Casey Delaney

	Department: Revenue Cycle Management

	Purpose/Description:
		To build the tables necessary for the NOIR Dashboard in Tableau

	Revision History:
	Date		Version		Description
	----		----		----
	2024-05-13	v1			Initial Creation
	2024-05-16	v2			Adding payments tables
	2024-05-23	v3			Removing payments with 00 ins plan
	2024-06-17	v4			Adding date lags
	************************************************************************/

	DROP TABLE IF EXISTS dbo.c_tableau_noir_post_tbl;
	DROP TABLE IF EXISTS dbo.c_tableau_noir_all_payments_tbl;
	DROP TABLE IF EXISTS dbo.c_tableau_noir_payments_tbl;

	-- #All_NOIR_Posts: Get info from all three NOIR tables, payer org and product class from ALT table, and classify as success/error.
	DROP TABLE IF EXISTS #All_NOIR_Posts;
	
	WITH CTE AS (
		SELECT
			NOIR.*,
			ALT.payer_organization,
			ALT.product_class,
			Post_Type = 'Correct Posting',
			NOIR_Post_Date = COALESCE(Post_Date, [COMMENT-DATE])
		FROM
			sms.dbo.c_NOIR_Codes_Comments_tbl as NOIR
			LEFT JOIN sms.dbo.Pt_Accounting_Reporting_ALT as ALT
				on NOIR.Pt_No = ALT.Pt_No
		
		UNION ALL
		
		SELECT
			NOIR.*,
			ALT.payer_organization,
			ALT.product_class,
			Post_Type = 'Error: No Svc Code',
			NOIR_Post_Date = COALESCE(Post_Date, [COMMENT-DATE])
		FROM
			sms.dbo.c_NOIR_Comments_No_SVC_Codes_tbl as NOIR
			LEFT JOIN sms.dbo.Pt_Accounting_Reporting_ALT as ALT
				on NOIR.Pt_No = ALT.Pt_No
		
		UNION ALL
		
		SELECT
			NOIR.*,
			ALT.payer_organization,
			ALT.product_class,
			Post_Type = 'Error: No Comment',
			NOIR_Post_Date = COALESCE(Post_Date, [COMMENT-DATE])
		FROM
			sms.dbo.c_NOIR_SVC_Codes_No_Comments_tbl as NOIR
			LEFT JOIN sms.dbo.Pt_Accounting_Reporting_ALT as ALT
				on NOIR.Pt_No = ALT.Pt_No
		)
	SELECT DISTINCT
		*
	INTO #All_NOIR_Posts
	FROM
		CTE;
	

	-- #All_NOIR_Posts_CLEANED_v1: Cleaning column names and potential takebacks that were entered incorrectly, thus causing issues when converting to money.
	DROP TABLE IF EXISTS #All_NOIR_Posts_CLEANED_v1;

	SELECT
		Pt_No,
		Pt_Name,
		[PA-CTL-PAA-XFER-DATE],
		[PA-SMART-COMMENT],
		[pa-dtl-batch-seq-no] as Seq_No,
		[COMMENT-DATE] as Comment_Date,
		[PA-INS-Plan] as Ins_Cd,
		Post_Date,
		Potential_Takeback as Potential_Takeback_raw,
		Potential_Takeback_clean = CASE
				WHEN Potential_Takeback IN ('NO SERVICE CODE POSTED','')
					THEN NULL
				WHEN Potential_Takeback LIKE '%[a-z+]%'
					THEN NULL
				WHEN RIGHT(Potential_Takeback, 1) = '.'
					THEN Potential_Takeback + '00'
				WHEN LEFT(Potential_Takeback, 2) = '-0' AND LEFT(Potential_Takeback, 3) != '-0.'
					THEN NULL
				WHEN LEFT(Potential_Takeback, 1) = '0' AND LEFT(Potential_Takeback, 2) != '0.'
					THEN NULL
				ELSE Potential_Takeback
				END,
		[Ins Desc] as Ins_Desc,
		[FC Desc] as FC_Desc,
		payer_organization as Payer_Org,
		Product_Class,
		Post_Type,
		NOIR_Post_Date
	INTO #All_NOIR_Posts_CLEANED_v1
	FROM
		#All_NOIR_Posts;


	-- #All_NOIR_Posts_CLEANED_v2: Converting cleaned potential takeback to money.
	DROP TABLE IF EXISTS #All_NOIR_Posts_CLEANED_v2;

	SELECT
		Pt_No,
		Pt_Name,
		[PA-CTL-PAA-XFER-DATE],
		[PA-SMART-COMMENT],
		Seq_No,
		Comment_Date,
		Ins_Cd,
		Post_Date,
		Potential_Takeback_raw,
		CAST(Potential_Takeback_clean as MONEY) as Potential_Takeback,
		Ins_Desc,
		FC_Desc,
		Payer_Org,
		Product_Class,
		Post_Type,
		NOIR_Post_Date
	INTO #All_NOIR_Posts_CLEANED_v2
	FROM
		#All_NOIR_Posts_CLEANED_v1;


	-- #NOIR_All_Payments: All payments that occurred on accounts that had an NOIR post.
	DROP TABLE IF EXISTS #NOIR_All_Payments;

	SELECT
		PT_NO,
		[PA-DTL-DATE] as [Service_Date],
		[PA-DTL-POST-DATE] as [Payment_Post_Date],
		SVC_CD,
		CDM_DESCRIPTION,
		DTL_Type_Ind,
		FC,
		INS_PLAN,
		[PA-DTL-CHG-AMT] as [tot_pay_adj_amt],
		DATEDIFF(DAY, [PA-DTL-DATE], [PA-DTL-POST-DATE]) as service_to_payment_post_lag
	INTO #NOIR_All_Payments
	FROM
		sms.dbo.Payments_Adjustments_For_Reporting as a
	WHERE
		EXISTS (
			SELECT 1
			FROM #All_NOIR_Posts_CLEANED_v2 as b
			WHERE a.Pt_No = b.PT_NO
		)
		AND DTL_Type_Ind = '1'
		AND INS_PLAN != '00'
		AND SVC_CD NOT IN ('102764','102020','103036','148106','129411');


	-- #Min_NOIR_Date: First NOIR post date per account.
	DROP TABLE IF EXISTS #Min_NOIR_Date;

	SELECT
		Pt_No,
		MIN(NOIR_Post_Date) as [min_NOIR_Post_Date]
	INTO #Min_NOIR_Date
	FROM 
		#All_NOIR_Posts_CLEANED_v2
	GROUP BY
		Pt_No;


	-- #NOIR_Payments: All payments after NOIR dates.
	DROP TABLE IF EXISTS #NOIR_Payments;

	SELECT
		a.Pt_No,
		a.min_NOIR_Post_Date,
		b.Service_Date,
		b.Payment_Post_Date,
		b.SVC_CD,
		b.DTL_Type_Ind,
		b.FC,
		b.tot_pay_adj_amt,
		b.service_to_payment_post_lag,
		DATEDIFF(DAY, a.min_NOIR_Post_Date, b.Payment_Post_Date) as noir_post_to_payment_post_lag
	INTO #NOIR_Payments
	FROM
		#Min_NOIR_Date as a
		LEFT JOIN #NOIR_All_Payments as b
			on a.Pt_No = b.Pt_No
	WHERE
		b.Service_Date >= a.min_NOIR_Post_Date;


	-- #Full_Refund: Create a flag to mark accounts that had the full takeback amount refunded.
	DROP TABLE IF EXISTS #Full_Refund;

	SELECT
		a.Pt_No,
		Full_Refund_Flag = CASE
						WHEN SUM(a.Potential_Takeback) - SUM(b.tot_pay_adj_amt) = 0
						THEN 1
						ELSE 0
						END
	INTO #Full_Refund
	FROM
		#All_NOIR_Posts_CLEANED_v2 as a
		LEFT JOIN #NOIR_Payments as b
			on a.pt_no = b.Pt_NO
	GROUP BY
		a.Pt_No;


	-- #All_NOIR_Posts_CLEANED_v3: Join NOIR Payments info with the fully refunded columns.
	DROP TABLE IF EXISTS #All_NOIR_Posts_CLEANED_v3;

	SELECT
		a.*,
		b.Full_Refund_Flag
	INTO #All_NOIR_Posts_CLEANED_v3
	FROM
		#All_NOIR_Posts_CLEANED_v2 as a
		LEFT JOIN #Full_Refund as b
			on a.Pt_No = b.Pt_No;


	/*
	Post Table: All NOIR posts.
	*/

	CREATE TABLE dbo.c_tableau_noir_post_tbl (
		c_tableau_noir_post_tblId INT IDENTITY(1, 1) NOT NULL PRIMARY KEY, -- primary key column
		Pt_No VARCHAR(60),
		Pt_Name VARCHAR(65),
		[PA-CTL-PAA-XFER-DATE] DATE,
		[PA-SMART-COMMENT] VARCHAR(255),
		Seq_No NUMERIC(4,0),
		Comment_Date DATE,
		Ins_Cd VARCHAR(3),
		Post_Date DATE,
		Potential_Takeback_raw VARCHAR(30),
		Potential_Takeback MONEY,
		Ins_Desc NVARCHAR(255),
		FC_Desc NVARCHAR(255),
		Payer_Org VARCHAR(255),
		Product_Class VARCHAR(255),
		Post_Type VARCHAR(255),
		NOIR_Post_Date DATE,
		Full_Refund_Flag INT
	);
	-- Insert #All_NOIR_Posts_CLEANED_v3 into the post table
	INSERT INTO dbo.c_tableau_noir_post_tbl (
		Pt_No,
		Pt_Name,
		[PA-CTL-PAA-XFER-DATE],
		[PA-SMART-COMMENT],
		Seq_No,
		Comment_Date,
		Ins_Cd,
		Post_Date,
		Potential_Takeback_raw,
		Potential_Takeback,
		Ins_Desc,
		FC_Desc,
		Payer_Org,
		Product_Class,
		Post_Type,
		NOIR_Post_Date,
		Full_Refund_Flag
	)
	SELECT
		*
	FROM
		#All_NOIR_Posts_CLEANED_v3;


	/*
	All Payments Table: All payments after NOIR post dates.
	*/

	CREATE TABLE dbo.c_tableau_noir_all_payments_tbl (
		c_tableau_noir_all_payments_tblId INT IDENTITY(1, 1) NOT NULL PRIMARY KEY, -- primary key column
		pt_no VARCHAR(60),
		min_noir_post_date DATE,
		service_date DATE,
		payment_post_date DATE,
		service_code VARCHAR(255),
		dtl_type_ind VARCHAR(255),
		fin_class VARCHAR(255),
		tot_pay_adj_amt MONEY,
		service_to_payment_post_lag INT,
		noir_post_to_payment_post_lag INT
	);

	INSERT INTO dbo.c_tableau_noir_all_payments_tbl (
		pt_no,
		min_noir_post_date,
		service_date,
		payment_post_date,
		service_code,
		dtl_type_ind,
		fin_class,
		tot_pay_adj_amt,
		service_to_payment_post_lag,
		noir_post_to_payment_post_lag
	)
	SELECT
		*
	FROM
		#NOIR_Payments;


	-- #NOIR_Date_SEQ: Sequence the NOIR post dates for each account.
	DROP TABLE IF EXISTS #NOIR_Date_SEQ;

	SELECT
		Pt_No,
		noir_post_date,
		next_noir_post_date = LEAD(noir_post_date, 1, GETDATE())
			OVER(PARTITION BY pt_no ORDER BY noir_post_date)
	INTO #NOIR_Date_SEQ
	FROM
		sms.dbo.c_tableau_noir_post_tbl;


	-- #NOIR_Date_Dupes: Delete rows where the noir_post_date and the next_noir_post_date are the same.
	DROP TABLE IF EXISTS #NOIR_Date_Dupes;

	SELECT
		*
	INTO #NOIR_Date_Dupes
	FROM
		#NOIR_Date_SEQ
	WHERE
		noir_post_date != next_noir_post_date;


	-- #Payment_Metrics: Payment metrics for each account and NOIR post date.
	DROP TABLE IF EXISTS #Payment_Metrics;

	SELECT
		t1.*,
		ca1.first_payment_service_date,
		ca2.payments_between_noir_posts,
		ca2.payment_amount_between_noir_posts
	INTO #Payment_Metrics
	FROM
		#NOIR_Date_Dupes as t1
	CROSS APPLY (
			SELECT TOP 1
				Service_Date as first_payment_service_date
			FROM
				#NOIR_Payments
			WHERE
				Pt_No = t1.Pt_No
				AND Service_Date >= t1.noir_post_date
				AND Service_Date < t1.next_noir_post_date
			GROUP BY
				Pt_No,
				Service_Date
	) ca1
	CROSS APPLY (
			SELECT TOP 1
				COUNT([tot_pay_adj_amt]) as [payments_between_noir_posts],
				SUM([tot_pay_adj_amt]) as [payment_amount_between_noir_posts]
			FROM
				#NOIR_Payments
			WHERE
				Pt_No = t1.Pt_No
				AND Service_Date >= t1.noir_post_date
				AND Service_Date < t1.next_noir_post_date
			GROUP BY
				Pt_No
	) ca2;


	-- #Payment_Metrics2: Payment metrics for each account and NOIR post date.
	DROP TABLE IF EXISTS #Payment_Metrics2;

	SELECT
		a.*,
		b.first_payment_service_date,
		b.payment_amount_between_noir_posts,
		b.payments_between_noir_posts
	INTO #Payment_Metrics2
	FROM
		#NOIR_Date_Dupes as a
		LEFT JOIN #Payment_Metrics as b
			on a.Pt_No = b.Pt_No
			AND a.noir_post_date = b.noir_post_date
			AND a.next_noir_post_date = b.next_noir_post_date;


	/*
	Payments Table: Payment metrics for each account between noir post dates.
	*/

	CREATE TABLE dbo.c_tableau_noir_payments_tbl (
		c_tableau_noir_payments_tblId INT IDENTITY(1, 1) NOT NULL PRIMARY KEY, -- primary key column
		pt_no VARCHAR(60),
		noir_post_date DATE,
		next_noir_post_date DATE,
		first_payment_service_date DATE,
		payment_amount_between_noir_posts MONEY,
		payments_between_noir_posts VARCHAR(255)
	);

	INSERT INTO dbo.c_tableau_noir_payments_tbl (
		pt_no,
		noir_post_date,
		next_noir_post_date,
		first_payment_service_date,
		payment_amount_between_noir_posts,
		payments_between_noir_posts
	)
	SELECT
		*
	FROM
		#Payment_Metrics2;

END;