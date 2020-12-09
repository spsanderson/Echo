USE [SMS]
GO

/*
***********************************************************************
File: sms_ptacct_v_encounters_for_reporting_Pt_Accounting_Reporting_ALT_sp.sql

Input Parameters:
	None

Tables/Views:
	dbo.[Encounters_For_Reporting_NonUnit]
    [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Active].dbo.[AccountComments]

Creates Table:
	dbo.Pt_Accounting_Reporting_ALT

Functions:
	none	

Author: Steven P Sanderson II, MPH

Purpose/Description
    Run in Batch 3
	Create patient account view dbo.Pt_Accounting_Reporting_ALT

Revision History:
Date		Version		Description
----		----		----
2020-12-08	v1			Initial Creation
***********************************************************************
*/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE dbo.c_sms_ptacct_v_encounters_for_reporting_Pt_Accounting_Reporting_ALT_sp
AS
SET ANSI_NULLS ON
SET ANSI_WARNINGS ON
SET QUOTED_IDENTIFIER ON

BEGIN
	SET NOCOUNT ON;

	/*Create Insurance Final Ins Table*/
	IF OBJECT_ID('SMS.dbo.Pt_Accounting_Reporting_ALT', 'U') IS NOT NULL
		TRUNCATE TABLE [SMS].dbo.[Pt_Accounting_Reporting_ALT];
	ELSE
		CREATE TABLE [SMS].dbo.[Pt_Accounting_Reporting_ALT] (
			[PK] INT IDENTITY(1, 1) PRIMARY KEY NOT NULL,
			[Pt_No] VARCHAR(14) NOT NULL,
			[Unit_No] VARCHAR(6) NULL,
			[PA_Ctl_PAA_Xfer_Date] DATETIME NULL, --ADD**************************
			[MRN] CHAR(12) NULL,
			[Pt_Name] CHAR(65) NULL,
			[Admit_Date] DATETIME NOT NULL,
			[Dsch_Date] DATETIME NULL,
			[Unit_Date] DATETIME NULL,
			[Acct_Type] CHAR(10) NULL,
			[Age_Bucket] VARCHAR(55) NULL,
			[First_Ins_Bl_Date] DATETIME NULL,
			[SSI_Last_Ins_Bill_Date] DATETIME NULL,
			[Days_To_First_Paid] DECIMAL(6, 0) NULL,
			[Days_To_Secondary_Payment] DECIMAL(6, 0) NULL,
			[Balance] MONEY NULL,
			[COB1_Balance] MONEY NULL,
			[Pt_Balance] MONEY NULL,
			[Tot_Chgs] MONEY NULL,
			[Ins_Pay_Amt] MONEY NULL,
			[Tot_Pay_Amt] MONEY NULL,
			[File] VARCHAR(30) NULL,
			[FC] VARCHAR(10) NULL,
			[FC_Description] VARCHAR(75) NULL,
			[Hosp_Svc] VARCHAR(3) NULL,
			[Hosp_Svc_Description] VARCHAR(75) NULL,
			[COB_1] CHAR(3) NULL, --ADD*******************************
			[Ins1_Cd] CHAR(4) NULL,
			[Ins1_Member_ID] CHAR(30) NULL,
			[Ins1_Pol_No] CHAR(30) NULL,
			[Ins1_Subscr_Group_ID] CHAR(30) NULL,
			[Ins1_Grp_No] CHAR(30) NULL,
			[Ins1_Balance] MONEY NULL,
			[Pyr1_Pay_Amt] MONEY NULL,
			[Ins1_First_Paid] DATETIME NULL,
			[COB_2] CHAR(2) NULL, --ADD***********************
			[Ins2_Cd] CHAR(4) NULL,
			[Ins2_Member_ID] CHAR(30) NULL, ---ADD***********************
			[Ins2_Pol_No] CHAR(30) NULL, --ADD*******************
			[Ins2_Subscr_Group_ID] CHAR(30) NULL, --ADD*******************
			[Ins2_Grp_No] CHAR(30) NULL, --ADD*****************************
			[Ins2_Balance] MONEY NULL, --ADD**********************************
			[Pyr2_Pay_Amt] MONEY NULL,
			[Ins2_First_Paid] DATETIME NULL,
			[COB_3] CHAR(2) NULL, --ADD***********************************
			[Ins3_Cd] CHAR(4) NULL,
			[Ins3_Member_ID] CHAR(30) NULL,
			[Ins3_Pol_No] CHAR(30) NULL,
			[Ins3_Subscr_Group_ID] CHAR(30) NULL,
			[Ins3_Grp_No] CHAR(30) NULL,
			[Ins3_Balance] MONEY NULL,
			[Pyr3_Pay_Amt] MONEY NULL,
			[Ins3_First_Paid] DATETIME NULL,
			[COB_4] CHAR(2) NULL, --ADD*****************************************
			[Ins4_Cd] CHAR(4) NULL,
			[Ins4_Member_ID] CHAR(30) NULL, --ADD******************************
			[Ins4_Pol_No] CHAR(30) NULL, --ADD********************************
			[Ins4_Subscr_Group_ID] CHAR(30) NULL, --ADD***************************
			[Ins4_Grp_No] CHAR(30) NULL, --ADD**************************
			[Ins4_Balance] MONEY NULL,
			[Pyr4_Pay_Amt] MONEY NULL,
			[Ins4_First_Paid] DATETIME NULL,
			[Pt_Representative] CHAR(3) NULL
			)

	INSERT INTO [SMS].dbo.[Pt_Accounting_Reporting_ALT] (
		[Pt_No],
		[Unit_No],
		[PA_Ctl_PAA_Xfer_Date],
		[MRN],
		[Pt_Name],
		[Admit_Date],
		[Dsch_Date],
		[Unit_Date],
		[Acct_Type],
		[Age_Bucket],
		[First_Ins_Bl_Date],
		[SSI_Last_Ins_Bill_Date],
		[Days_To_First_Paid],
		[Days_To_Secondary_Payment],
		[Balance],
		[COB1_Balance],
		[Pt_Balance],
		[Tot_Chgs],
		[Ins_Pay_Amt],
		[Tot_Pay_Amt],
		[File],
		[FC],
		[FC_Description],
		[Hosp_Svc],
		[Hosp_Svc_Description],
		[COB_1],
		[Ins1_Cd],
		[Ins1_Member_ID],
		[Ins1_Pol_No],
		[Ins1_Subscr_Group_ID],
		[Ins1_Grp_No],
		[Ins1_Balance],
		[Pyr1_Pay_Amt],
		[Ins1_First_Paid],
		[COB_2],
		[Ins2_Cd],
		[Ins2_Member_ID],
		[Ins2_Pol_No],
		[Ins2_Subscr_Group_ID],
		[Ins2_Grp_No],
		[Ins2_Balance],
		[Pyr2_Pay_Amt],
		[Ins2_First_Paid],
		[COB_3],
		[Ins3_Cd],
		[Ins3_Member_ID],
		[Ins3_Pol_No],
		[Ins3_Subscr_Group_ID],
		[Ins3_Grp_No],
		[Ins3_Balance],
		[Pyr3_Pay_Amt],
		[Ins3_First_Paid],
		[COB_4],
		[Ins4_Cd],
		[Ins4_Member_ID],
		[Ins4_Pol_No],
		[Ins4_Subscr_Group_ID],
		[Ins4_Grp_No],
		[Ins4_Balance],
		[Pyr4_Pay_Amt],
		[Ins4_First_Paid],
		[Pt_Representative]
		)
	SELECT cast(a.[PA-PT-NO-WOSCD] AS VARCHAR) + cast(a.[PA-PT-NO-SCD] AS VARCHAR) AS 'Pt_No',
		a.[PA-UNIT-NO],
		a.[PA-CTL-PAA-XFER-DATE],
		a.[pa-med-rec-no] AS 'MRN',
		a.[pa-pt-name] AS 'Pt_Name',
		a.[admit_date] AS 'Admit_Date',
		a.[dsch_date] AS 'Dsch_Date',
		a.[pa-unit-date] AS 'Unit_Date',
		CASE 
			WHEN a.[pa-acct-type] IN ('0', '6', '7')
				THEN 'OP' --0=OP; 6=OP BAD DEBT; 7=OP HISTORIC
			WHEN a.[pa-acct-type] IN ('1', '2', '4', '8')
				THEN 'IP' --1=IP; 2=A/R; 4=I/P BAD DEBT; 8=I/P HISTORIC
			ELSE ''
			END AS 'Acct_Type',
		CASE 
			WHEN a.[pa-acct-type] <> 1
				AND datediff(day, COALESCE(a.[pa-unit-date], a.[dsch_date], a.[admit_date]), getdate()) BETWEEN '0'
					AND '30'
				THEN '1_0-30'
			WHEN a.[pa-acct-type] <> 1
				AND datediff(day, COALESCE(a.[pa-unit-date], a.[dsch_date], a.[admit_date]), getdate()) BETWEEN '31'
					AND '60'
				THEN '2_31-60'
			WHEN a.[pa-acct-type] <> 1
				AND datediff(day, COALESCE(a.[pa-unit-date], a.[dsch_date], a.[admit_date]), getdate()) BETWEEN '61'
					AND '90'
				THEN '3_61-90'
			WHEN a.[pa-acct-type] <> 1
				AND datediff(day, COALESCE(a.[pa-unit-date], a.[dsch_date], a.[admit_date]), getdate()) BETWEEN '91'
					AND '120'
				THEN '4_91-120'
			WHEN a.[pa-acct-type] <> 1
				AND datediff(day, COALESCE(a.[pa-unit-date], a.[dsch_date], a.[admit_date]), getdate()) BETWEEN '121'
					AND '150'
				THEN '5_121-150'
			WHEN a.[pa-acct-type] <> 1
				AND datediff(day, COALESCE(a.[pa-unit-date], a.[dsch_date], a.[admit_date]), getdate()) BETWEEN '151'
					AND '180'
				THEN '6_151-180'
			WHEN a.[pa-acct-type] <> 1
				AND datediff(day, COALESCE(a.[pa-unit-date], a.[dsch_date], a.[admit_date]), getdate()) BETWEEN '181'
					AND '210'
				THEN '7_181-210'
			WHEN a.[pa-acct-type] <> 1
				AND datediff(day, COALESCE(a.[pa-unit-date], a.[dsch_date], a.[admit_date]), getdate()) BETWEEN '211'
					AND '240'
				THEN '8_211-240'
			WHEN a.[pa-acct-type] <> 1
				AND datediff(day, COALESCE(a.[pa-unit-date], a.[dsch_date], a.[admit_date]), getdate()) BETWEEN '241'
					AND '365'
				THEN '9_241-365'
			WHEN a.[pa-acct-type] <> 1
				AND datediff(day, coalesce(a.[pa-unit-date], a.[dsch_date], a.[admit_date]), getdate()) BETWEEN '366'
					AND '525'
				THEN '90_1yr-1.5yrs'
			WHEN a.[pa-acct-type] <> 1
				AND datediff(day, coalesce(a.[pa-unit-date], a.[dsch_date], a.[admit_date]), getdate()) BETWEEN '526'
					AND '720'
				THEN '91_1.5-2yrs'
			WHEN a.[pa-acct-type] <> 1
				AND datediff(day, coalesce(a.[pa-unit-date], a.[dsch_date], a.[admit_date]), getdate()) > '720'
				THEN '91_2+yrs'
			WHEN a.[pa-acct-type] = 1
				THEN 'In House/DNFB'
			ELSE ''
			END AS 'Age_Bucket',
		a.[1st_bl_date] AS 'First_Ins_Bl_Date',
		'' AS 'SSI_Last_Ins_Bill_Date',
		CASE 
			WHEN a.[1st_bl_date] IS NOT NULL
				AND c.[ins1_first_paid] IS NOT NULL
				THEN datediff(dd, a.[1st_bl_date], c.[ins1_First_Paid])
			ELSE ''
			END AS 'Days_To_First_Paid',
		CASE 
			WHEN c.[ins1_pymts] < '0'
				AND c.[ins2_pymts] < '0'
				THEN DATEDIFF(dd, a.[1st_Bl_Date], [Ins2_First_Paid])
			ELSE ''
			END AS 'Days_To_Secondary_Pymt',
		COALESCE((b.[pa-unit-ins1-bal] + b.[pa-unit-ins2-bal] + b.[pa-unit-ins3-bal] + b.[pa-unit-ins4-bal] + b.[pa-unit-pt-bal]), a.[balance]) AS 'Balance',
		COALESCE(b.[pa-unit-ins1-bal], ISNULL(c.[Ins1_Balance], 0)) AS 'COB1_Balance',
		COALESCE(b.[pa-unit-pt-bal], a.[pt_balance]) AS 'Pt_Balance',
		COALESCE(b.[pa-unit-tot-chg-amt], a.[tot_chgs]) AS 'Tot_Chgs',
		(CAST(ISNULL(c.[ins1_pymts], 0) AS MONEY) + CAST(ISNULL(c.[ins2_pymts], 0) AS MONEY) + CAST(ISNULL(c.[ins3_pymts], 0) AS MONEY) + CAST(ISNULL(c.[ins4_pymts], 0) AS MONEY)) AS 'Ins_Pay_Amt',
		(CAST(ISNULL(c.[ins1_pymts], 0) AS MONEY) + CAST(ISNULL(c.[ins2_pymts], 0) AS MONEY) + CAST(ISNULL(c.[ins3_pymts], 0) AS MONEY) + CAST(ISNULL(c.[ins4_pymts], 0) AS MONEY)) + CAST(ISNULL(a.[pa-bal-tot-pt-pay-amt], 0) AS MONEY) AS 'Tot_Pay_Amt',
		CASE 
			WHEN a.[pa-acct-type] IN ('6', '4')
				THEN 'Bad Debt'
			WHEN a.[dsch_date] IS NOT NULL
				AND a.[pa-acct-type] = '1'
				THEN 'DNFB'
			WHEN a.[dsch_date] IS NULL
				AND a.[pa-acct-type] = '1'
				THEN 'Inhouse'
			ELSE 'A/R'
			END AS 'File',
		a.[pa-fc] AS 'FC',
		CASE 
			WHEN a.[pa-fc] = '1'
				THEN 'Bad Debt Medicaid Pending'
			WHEN a.[pa-fc] IN ('2', '6')
				THEN 'Bad Debt AG'
			WHEN a.[pa-fc] = '3'
				THEN 'MCS'
			WHEN a.[pa-fc] = '4'
				THEN 'Bad Debt AG Legal'
			WHEN a.[pa-fc] = '5'
				THEN 'Bad Debt POM'
			WHEN a.[pa-fc] = '8'
				THEN 'Bad Debt AG Exchange Plans'
			WHEN a.[pa-fc] = '9'
				THEN 'Kopp-Bad Debt'
			WHEN a.[pa-fc] = 'A'
				THEN 'Commercial'
			WHEN a.[pa-fc] = 'B'
				THEN 'Blue Cross'
			WHEN a.[pa-fc] = 'C'
				THEN 'Champus'
			WHEN a.[pa-fc] = 'D'
				THEN 'Medicaid'
			WHEN a.[pa-fc] = 'E'
				THEN 'Employee Health Svc'
			WHEN a.[pa-fc] = 'G'
				THEN 'Contract Accts'
			WHEN a.[pa-fc] = 'H'
				THEN 'Medicare HMO'
			WHEN a.[pa-fc] = 'I'
				THEN 'Balance After Ins'
			WHEN a.[pa-fc] = 'J'
				THEN 'Managed Care'
			WHEN a.[pa-fc] = 'K'
				THEN 'Pending Medicaid'
			WHEN a.[pa-fc] = 'M'
				THEN 'Medicare'
			WHEN a.[pa-fc] = 'N'
				THEN 'No-Fault'
			WHEN a.[pa-fc] = 'P'
				THEN 'Self Pay'
			WHEN a.[pa-fc] = 'R'
				THEN 'Aergo Commercial'
			WHEN a.[pa-fc] = 'T'
				THEN 'RTR WC NF'
			WHEN a.[pa-fc] = 'S'
				THEN 'Special Billing'
			WHEN a.[pa-fc] = 'U'
				THEN 'Medicaid Mgd Care'
			WHEN a.[pa-fc] = 'V'
				THEN 'First Source'
			WHEN a.[pa-fc] = 'W'
				THEN 'Workers Comp'
			WHEN a.[pa-fc] = 'X'
				THEN 'Control Accts'
			WHEN a.[pa-fc] = 'Y'
				THEN 'MCS'
			WHEN a.[pa-fc] = 'Z'
				THEN 'Unclaimed Credits'
			ELSE ''
			END AS 'FC_Description',
		a.[pa-hosp-svc] AS 'Hosp_Svc',
		d.[Hosp Svc Desc] AS 'Hosp Svc Description',
		'1' AS 'COB1',
		c.[INS1] AS 'Ins1_Cd',
		COALESCE(c.[Ins1_Pol_No], c.[Ins1_Subscr_Group_Id], [Ins1_Grp_No]) AS 'Ins1_Member_ID',
		c.[Ins1_Pol_No],
		c.[Ins1_Subscr_Group_ID],
		c.[Ins1_Grp_No],
		c.[Ins1_Balance],
		c.[ins1_pymts] AS 'Pyr1_Pay_Amt',
		c.[ins1_First_Paid],
		'2' AS 'COB2',
		c.[ins2] AS 'Ins2_Cd',
		COALESCE(c.[Ins2_Pol_No], c.[Ins2_Subscr_Group_Id], [Ins2_Grp_No]) AS 'Ins2_Member_ID',
		c.[Ins2_Pol_No],
		c.[Ins2_Subscr_Group_ID],
		c.[Ins2_Grp_No],
		ISNULL(c.[Ins2_Balance], 0) AS 'Ins2_Balance',
		c.[ins2_pymts] AS 'Pyr2_Pay_Amt',
		c.[ins2_first_Paid],
		'3' AS 'COB3',
		c.[INS3] AS 'Ins3_Cd',
		COALESCE(c.[Ins3_Pol_No], c.[Ins3_Subscr_Group_Id], c.[Ins3_Grp_No]) AS 'Ins3_Member_ID',
		c.[Ins3_Pol_No],
		c.[Ins3_Subscr_Group_ID],
		c.[Ins3_Grp_No],
		ISNULL(c.[Ins3_Balance], 0) AS 'Ins3_Balance',
		c.[ins3_pymts] AS 'Pyr3_Pay_Amt',
		c.[Ins3_First_Paid],
		'4' AS 'COB4',
		c.[INS4] AS 'Ins4_Cd',
		COALESCE(c.[Ins4_Pol_No], c.[Ins4_Subscr_Group_Id], c.[Ins4_Grp_No]) AS 'Ins4_Member_ID',
		c.[Ins4_Pol_No],
		c.[Ins4_Subscr_Group_ID],
		c.[Ins4_Grp_No],
		ISNULL(c.[Ins4_Balance], 0) AS 'Ins4_Balance',
		c.[ins4_pymts] AS 'Pyr4_Pay_Amt',
		c.[Ins4_First_Paid],
		a.[pa-pt-representative]
	FROM dbo.encounters_for_reporting_unit a
	LEFT OUTER JOIN [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Active].dbo.[UnitizedAccounts] b ON a.[pa-pt-no-woscd] = b.[pa-pt-no-woscd]
		AND a.[pa-unit-date] = b.[pa-unit-date]
		AND a.[pa-ctl-paa-xfer-date] = b.[pa-ctl-paa-xfer-date]
	LEFT OUTER JOIN [SMS].dbo.[CUSTOM_INSURANCE_SM_ALT] c --_3] C
		ON A.[PA-PT-NO-WOSCD] = C.[PA-PT-NO-WOSCD]
		AND A.[PA-UNIT-DATE] = C.[PA-UNIT-DATE]
		AND a.[pa-ctl-paa-xfer-date] = c.[pa-ctl-paa-xfer-date]
	LEFT OUTER JOIN [Swarm].dbo.[HospSvc] d ON a.[pa-hosp-svc] = d.[Hosp Svc]
	WHERE a.[pa-unit-no] <> '0'
		AND (
			COALESCE((b.[pa-unit-ins1-bal] + b.[pa-unit-ins2-bal] + b.[pa-unit-ins3-bal] + b.[pa-unit-ins4-bal] + b.[pa-unit-pt-bal]), a.[balance]) <> '0'
			OR COALESCE(b.[pa-unit-tot-chg-amt], a.[tot_chgs]) <> '0'
			)
	
	UNION
	
	SELECT cast(a.[PA-PT-NO-WOSCD] AS VARCHAR) + cast(a.[PA-PT-NO-SCD] AS VARCHAR) AS 'Pt_No',
		a.[PA-UNIT-NO],
		a.[PA-CTL-PAA-XFER-DATE],
		a.[pa-med-rec-no] AS 'MRN',
		a.[pa-pt-name] AS 'Pt_Name',
		a.[admit_date] AS 'Admit_Date',
		a.[dsch_date] AS 'Dsch_Date',
		a.[pa-unit-date] AS 'Unit_Date',
		CASE 
			WHEN a.[pa-acct-type] IN ('0', '6', '7')
				THEN 'OP' --0=OP; 6=OP BAD DEBT; 7=OP HISTORIC
			WHEN a.[pa-acct-type] IN ('1', '2', '4', '8')
				THEN 'IP' --1=IP; 2=A/R; 4=I/P BAD DEBT; 8=I/P HISTORIC
			ELSE ''
			END AS 'Acct_Type',
		CASE 
			WHEN a.[pa-acct-type] <> 1
				AND datediff(day, COALESCE(a.[pa-unit-date], a.[dsch_date], a.[admit_date]), getdate()) BETWEEN '0'
					AND '30'
				THEN '1_0-30'
			WHEN a.[pa-acct-type] <> 1
				AND datediff(day, COALESCE(a.[pa-unit-date], a.[dsch_date], a.[admit_date]), getdate()) BETWEEN '31'
					AND '60'
				THEN '2_31-60'
			WHEN a.[pa-acct-type] <> 1
				AND datediff(day, COALESCE(a.[pa-unit-date], a.[dsch_date], a.[admit_date]), getdate()) BETWEEN '61'
					AND '90'
				THEN '3_61-90'
			WHEN a.[pa-acct-type] <> 1
				AND datediff(day, COALESCE(a.[pa-unit-date], a.[dsch_date], a.[admit_date]), getdate()) BETWEEN '91'
					AND '120'
				THEN '4_91-120'
			WHEN a.[pa-acct-type] <> 1
				AND datediff(day, COALESCE(a.[pa-unit-date], a.[dsch_date], a.[admit_date]), getdate()) BETWEEN '121'
					AND '150'
				THEN '5_121-150'
			WHEN a.[pa-acct-type] <> 1
				AND datediff(day, COALESCE(a.[pa-unit-date], a.[dsch_date], a.[admit_date]), getdate()) BETWEEN '151'
					AND '180'
				THEN '6_151-180'
			WHEN a.[pa-acct-type] <> 1
				AND datediff(day, COALESCE(a.[pa-unit-date], a.[dsch_date], a.[admit_date]), getdate()) BETWEEN '181'
					AND '210'
				THEN '7_181-210'
			WHEN a.[pa-acct-type] <> 1
				AND datediff(day, COALESCE(a.[pa-unit-date], a.[dsch_date], a.[admit_date]), getdate()) BETWEEN '211'
					AND '240'
				THEN '8_211-240'
			WHEN a.[pa-acct-type] <> 1
				AND datediff(day, COALESCE(a.[pa-unit-date], a.[dsch_date], a.[admit_date]), getdate()) > '240'
				THEN '9_240+'
			WHEN a.[pa-acct-type] = 1
				THEN 'In House/DNFB'
			ELSE ''
			END AS 'Age_Bucket',
		a.[1st_bl_date] AS 'First_Ins_Bl_Date',
		e.[SSI_Last_Ins_Bill_Date],
		CASE 
			WHEN e.[SSI_Last_Ins_Bill_Date] > a.[1st_Bl_Date]
				THEN datediff(dd, e.[SSI_Last_Ins_Bill_Date], c.[ins1_First_Paid])
			WHEN e.[SSI_Last_Ins_Bill_Date] IS NULL
				AND a.[1st_bl_date] IS NOT NULL
				AND c.[ins1_first_paid] IS NOT NULL
				THEN datediff(dd, a.[1st_bl_date], c.[ins1_First_Paid])
			ELSE ''
			END AS 'Days_To_First_Paid',
		CASE 
			WHEN c.[ins1_pymts] < '0'
				AND c.[ins2_pymts] < '0'
				THEN DATEDIFF(dd, a.[1st_Bl_Date], [Ins2_First_Paid])
			ELSE ''
			END AS 'Days_To_Secondary_Pymt',
		COALESCE((b.[pa-unit-ins1-bal] + b.[pa-unit-ins2-bal] + b.[pa-unit-ins3-bal] + b.[pa-unit-ins4-bal] + b.[pa-unit-pt-bal]), a.[balance]) AS 'Balance',
		COALESCE(b.[pa-unit-ins1-bal], ISNULL(c.[Ins1_Balance], 0)) AS 'COB1_Balance',
		COALESCE(b.[pa-unit-pt-bal], a.[pt_balance]) AS 'Pt_Balance',
		COALESCE(b.[pa-unit-tot-chg-amt], a.[tot_chgs]) AS 'Tot_Chgs',
		(CAST(ISNULL(c.[ins1_pymts], 0) AS MONEY) + CAST(ISNULL(c.[ins2_pymts], 0) AS MONEY) + CAST(ISNULL(c.[ins3_pymts], 0) AS MONEY) + CAST(ISNULL(c.[ins4_pymts], 0) AS MONEY)) AS 'Ins_Pay_Amt',
		(CAST(ISNULL(c.[ins1_pymts], 0) AS MONEY) + CAST(ISNULL(c.[ins2_pymts], 0) AS MONEY) + CAST(ISNULL(c.[ins3_pymts], 0) AS MONEY) + CAST(ISNULL(c.[ins4_pymts], 0) AS MONEY)) + CAST(ISNULL(a.[pa-bal-tot-pt-pay-amt], 0) AS MONEY) AS 'Tot_Pay_Amt',
		CASE 
			WHEN a.[pa-acct-type] IN ('6', '4')
				THEN 'Bad Debt'
			WHEN a.[dsch_date] IS NOT NULL
				AND a.[pa-acct-type] = '1'
				THEN 'DNFB'
			WHEN a.[dsch_date] IS NULL
				AND a.[pa-acct-type] = '1'
				THEN 'Inhouse'
			ELSE 'A/R'
			END AS 'File',
		a.[pa-fc] AS 'FC',
		CASE 
			WHEN a.[pa-fc] = '1'
				THEN 'Bad Debt Medicaid Pending'
			WHEN a.[pa-fc] IN ('2', '6')
				THEN 'Bad Debt AG'
			WHEN a.[pa-fc] = '3'
				THEN 'MCS'
			WHEN a.[pa-fc] = '4'
				THEN 'Bad Debt AG Legal'
			WHEN a.[pa-fc] = '5'
				THEN 'Bad Debt POM'
			WHEN a.[pa-fc] = '8'
				THEN 'Bad Debt AG Exchange Plans'
			WHEN a.[pa-fc] = '9'
				THEN 'Kopp-Bad Debt'
			WHEN a.[pa-fc] = 'A'
				THEN 'Commercial'
			WHEN a.[pa-fc] = 'B'
				THEN 'Blue Cross'
			WHEN a.[pa-fc] = 'C'
				THEN 'Champus'
			WHEN a.[pa-fc] = 'D'
				THEN 'Medicaid'
			WHEN a.[pa-fc] = 'E'
				THEN 'Employee Health Svc'
			WHEN a.[pa-fc] = 'G'
				THEN 'Contract Accts'
			WHEN a.[pa-fc] = 'H'
				THEN 'Medicare HMO'
			WHEN a.[pa-fc] = 'I'
				THEN 'Balance After Ins'
			WHEN a.[pa-fc] = 'J'
				THEN 'Managed Care'
			WHEN a.[pa-fc] = 'K'
				THEN 'Pending Medicaid'
			WHEN a.[pa-fc] = 'M'
				THEN 'Medicare'
			WHEN a.[pa-fc] = 'N'
				THEN 'No-Fault'
			WHEN a.[pa-fc] = 'P'
				THEN 'Self Pay'
			WHEN a.[pa-fc] = 'R'
				THEN 'Aergo Commercial'
			WHEN a.[pa-fc] = 'T'
				THEN 'RTR WC NF'
			WHEN a.[pa-fc] = 'S'
				THEN 'Special Billing'
			WHEN a.[pa-fc] = 'U'
				THEN 'Medicaid Mgd Care'
			WHEN a.[pa-fc] = 'V'
				THEN 'First Source'
			WHEN a.[pa-fc] = 'W'
				THEN 'Workers Comp'
			WHEN a.[pa-fc] = 'X'
				THEN 'Control Accts'
			WHEN a.[pa-fc] = 'Y'
				THEN 'MCS'
			WHEN a.[pa-fc] = 'Z'
				THEN 'Unclaimed Credits'
			ELSE ''
			END AS 'FC_Description',
		a.[pa-hosp-svc] AS 'Hosp_Svc',
		d.[Hosp Svc Desc] AS 'Hosp Svc Description',
		'1' AS 'COB1',
		c.[INS1] AS 'Ins1_Cd',
		COALESCE(c.[Ins1_Pol_No], c.[Ins1_Subscr_Group_Id], [Ins1_Grp_No]) AS 'Ins1_Member_ID',
		c.[Ins1_Pol_No],
		c.[Ins1_Subscr_Group_ID],
		c.[Ins1_Grp_No],
		c.[Ins1_Balance],
		c.[ins1_pymts] AS 'Pyr1_Pay_Amt',
		c.[ins1_First_Paid],
		'2' AS 'COB2',
		c.[ins2] AS 'Ins2_Cd',
		COALESCE(c.[Ins2_Pol_No], c.[Ins2_Subscr_Group_Id], [Ins2_Grp_No]) AS 'Ins2_Member_ID',
		c.[Ins2_Pol_No],
		c.[Ins2_Subscr_Group_ID],
		c.[Ins2_Grp_No],
		ISNULL(c.[Ins2_Balance], 0) AS 'Ins2_Balance',
		c.[ins2_pymts] AS 'Pyr2_Pay_Amt',
		c.[ins2_First_Paid],
		'3' AS 'COB3',
		c.[INS3] AS 'Ins3_Cd',
		COALESCE(c.[Ins3_Pol_No], c.[Ins3_Subscr_Group_Id], c.[Ins3_Grp_No]) AS 'Ins3_Member_ID',
		c.[Ins3_Pol_No],
		c.[Ins3_Subscr_Group_ID],
		c.[Ins3_Grp_No],
		ISNULL(c.[Ins3_Balance], 0) AS 'Ins3_Balance',
		c.[ins3_pymts] AS 'Pyr3_Pay_Amt',
		c.[ins3_First_Paid],
		'4' AS 'COB4',
		c.[INS4] AS 'Ins4_Cd',
		COALESCE(c.[Ins4_Pol_No], c.[Ins4_Subscr_Group_Id], c.[Ins4_Grp_No]) AS 'Ins4_Member_ID',
		c.[Ins4_Pol_No],
		c.[Ins4_Subscr_Group_ID],
		c.[Ins4_Grp_No],
		ISNULL(c.[Ins4_Balance], 0) AS 'Ins4_Balance',
		c.[ins4_pymts] AS 'Pyr4_Pay_Amt',
		c.[ins4_First_Paid],
		a.[pa-pt-representative]
	FROM dbo.[Encounters_For_Reporting_NonUnit] a
	LEFT OUTER JOIN [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Active].dbo.[UnitizedAccounts] b ON a.[pa-pt-no-woscd] = b.[pa-pt-no-woscd]
		AND a.[pa-ctl-paa-xfer-date] = b.[pa-ctl-paa-xfer-date] --and a.[pa-unit-date]=b.[pa-unit-date]
	LEFT OUTER JOIN dbo.[#CUSTOM_INSURANCE_SM_3_NonUnit] C ON A.[PA-PT-NO-WOSCD] = C.[PA-PT-NO-WOSCD]
		AND A.[PA-UNIT-DATE] IS NULL
		AND a.[pa-ctl-paa-xfer-date] = c.[pa-ctl-paa-xfer-date]
	LEFT OUTER JOIN [Swarm].dbo.[HospSvc] d ON a.[pa-hosp-svc] = d.[Hosp Svc]
	LEFT OUTER JOIN [#SSI_Primary_Claim_Release_Date] e ON CAST(a.[pa-pt-no-woscd] AS VARCHAR) + CAST(a.[pa-pt-no-scd] AS VARCHAR) = e.[pt_no]
		AND e.[rank] = '1'
	WHERE (
			COALESCE((b.[pa-unit-ins1-bal] + b.[pa-unit-ins2-bal] + b.[pa-unit-ins3-bal] + b.[pa-unit-ins4-bal] + b.[pa-unit-pt-bal]), a.[balance]) <> '0'
			OR COALESCE(b.[pa-unit-tot-chg-amt], a.[tot_chgs]) <> '0'
			)
		AND a.[pa-unit-date] IS NULL
	
	UNION
	
	/*Add Open Units-------------------------------------------------------------------*/
	SELECT cast(a.[PA-PT-NO-WOSCD] AS VARCHAR) + cast(a.[PA-PT-NO-SCD] AS VARCHAR) AS 'Pt_No',
		a.[PA-UNIT-NO],
		a.[PA-CTL-PAA-XFER-DATE],
		a.[pa-med-rec-no] AS 'MRN',
		a.[pa-pt-name] AS 'Pt_Name',
		a.[admit_date] AS 'Admit_Date',
		a.[dsch_date] AS 'Dsch_Date',
		a.[pa-unit-date] AS 'Unit_Date',
		CASE 
			WHEN a.[pa-acct-type] IN ('0', '6', '7')
				THEN 'OP' --0=OP; 6=OP BAD DEBT; 7=OP HISTORIC
			WHEN a.[pa-acct-type] IN ('1', '2', '4', '8')
				THEN 'IP' --1=IP; 2=A/R; 4=I/P BAD DEBT; 8=I/P HISTORIC
			ELSE ''
			END AS 'Acct_Type',
		CASE 
			WHEN a.[pa-acct-type] <> 1
				AND datediff(day, COALESCE(a.[pa-unit-date], a.[dsch_date], a.[admit_date]), getdate()) BETWEEN '0'
					AND '30'
				THEN '1_0-30'
			WHEN a.[pa-acct-type] <> 1
				AND datediff(day, COALESCE(a.[pa-unit-date], a.[dsch_date], a.[admit_date]), getdate()) BETWEEN '31'
					AND '60'
				THEN '2_31-60'
			WHEN a.[pa-acct-type] <> 1
				AND datediff(day, COALESCE(a.[pa-unit-date], a.[dsch_date], a.[admit_date]), getdate()) BETWEEN '61'
					AND '90'
				THEN '3_61-90'
			WHEN a.[pa-acct-type] <> 1
				AND datediff(day, COALESCE(a.[pa-unit-date], a.[dsch_date], a.[admit_date]), getdate()) BETWEEN '91'
					AND '120'
				THEN '4_91-120'
			WHEN a.[pa-acct-type] <> 1
				AND datediff(day, COALESCE(a.[pa-unit-date], a.[dsch_date], a.[admit_date]), getdate()) BETWEEN '121'
					AND '150'
				THEN '5_121-150'
			WHEN a.[pa-acct-type] <> 1
				AND datediff(day, COALESCE(a.[pa-unit-date], a.[dsch_date], a.[admit_date]), getdate()) BETWEEN '151'
					AND '180'
				THEN '6_151-180'
			WHEN a.[pa-acct-type] <> 1
				AND datediff(day, COALESCE(a.[pa-unit-date], a.[dsch_date], a.[admit_date]), getdate()) BETWEEN '181'
					AND '210'
				THEN '7_181-210'
			WHEN a.[pa-acct-type] <> 1
				AND datediff(day, COALESCE(a.[pa-unit-date], a.[dsch_date], a.[admit_date]), getdate()) BETWEEN '211'
					AND '240'
				THEN '8_211-240'
			WHEN a.[pa-acct-type] <> 1
				AND datediff(day, COALESCE(a.[pa-unit-date], a.[dsch_date], a.[admit_date]), getdate()) > '240'
				THEN '9_240+'
			WHEN a.[pa-acct-type] = 1
				THEN 'In House/DNFB'
			ELSE ''
			END AS 'Age_Bucket',
		a.[1st_bl_date] AS 'First_Ins_Bl_Date',
		'' AS 'SSI_Last_Ins_Bill_Date',
		CASE 
			WHEN a.[1st_bl_date] IS NOT NULL
				AND c.[ins1_first_paid] IS NOT NULL
				THEN datediff(dd, a.[1st_bl_date], c.[ins1_First_Paid])
			WHEN a.[1st_bl_Date] IS NOT NULL
				AND c.[ins1_First_Paid] IS NULL
				AND c.[ins2_first_paid] IS NOT NULL
				THEN datediff(dd, a.[1st_Bl_Date], c.[ins2_first_paid])
			WHEN a.[1st_bl_Date] IS NOT NULL
				AND c.[ins1_First_Paid] IS NULL
				AND c.[ins2_first_paid] IS NULL
				AND c.[ins3_first_paid] IS NOT NULL
				THEN datediff(dd, a.[1st_Bl_Date], c.[ins3_first_paid])
			WHEN a.[1st_bl_Date] IS NOT NULL
				AND c.[ins1_First_Paid] IS NULL
				AND c.[ins2_first_paid] IS NULL
				AND c.[ins3_first_paid] IS NULL
				AND c.[ins4_first_paid] IS NOT NULL
				THEN datediff(dd, a.[1st_Bl_Date], c.[ins4_first_paid])
			ELSE ''
			END AS 'Days_To_First_Paid',
		CASE 
			WHEN c.[ins1_pymts] < '0'
				AND c.[ins2_pymts] < '0'
				THEN DATEDIFF(dd, a.[1st_Bl_Date], [Ins2_First_Paid])
			ELSE ''
			END AS 'Days_To_Secondary_Pymt',
		COALESCE((b.[pa-unit-ins1-bal] + b.[pa-unit-ins2-bal] + b.[pa-unit-ins3-bal] + b.[pa-unit-ins4-bal] + b.[pa-unit-pt-bal]), a.[balance]) AS 'Balance',
		COALESCE(b.[pa-unit-ins1-bal], ISNULL(c.[Ins1_Balance], 0)) AS 'COB1_Balance',
		COALESCE(b.[pa-unit-pt-bal], a.[pt_balance]) AS 'Pt_Balance',
		COALESCE(b.[pa-unit-tot-chg-amt], a.[tot_chgs]) AS 'Tot_Chgs',
		(CAST(ISNULL(c.[ins1_pymts], 0) AS MONEY) + CAST(ISNULL(c.[ins2_pymts], 0) AS MONEY) + CAST(ISNULL(c.[ins3_pymts], 0) AS MONEY) + CAST(ISNULL(c.[ins4_pymts], 0) AS MONEY)) AS 'Ins_Pay_Amt',
		(CAST(ISNULL(c.[ins1_pymts], 0) AS MONEY) + CAST(ISNULL(c.[ins2_pymts], 0) AS MONEY) + CAST(ISNULL(c.[ins3_pymts], 0) AS MONEY) + CAST(ISNULL(c.[ins4_pymts], 0) AS MONEY)) + CAST(ISNULL(a.[pa-bal-tot-pt-pay-amt], 0) AS MONEY) AS 'Tot_Pay_Amt',
		CASE 
			WHEN a.[pa-acct-type] IN ('6', '4')
				THEN 'Bad Debt'
			WHEN a.[dsch_date] IS NOT NULL
				AND a.[pa-acct-type] = '1'
				THEN 'DNFB'
			WHEN a.[dsch_date] IS NULL
				AND a.[pa-acct-type] = '1'
				THEN 'Inhouse'
			ELSE 'A/R'
			END AS 'File',
		a.[pa-fc] AS 'FC',
		CASE 
			WHEN a.[pa-fc] = '1'
				THEN 'Bad Debt Medicaid Pending'
			WHEN a.[pa-fc] IN ('2', '6')
				THEN 'Bad Debt AG'
			WHEN a.[pa-fc] = '3'
				THEN 'MCS'
			WHEN a.[pa-fc] = '4'
				THEN 'Bad Debt AG Legal'
			WHEN a.[pa-fc] = '5'
				THEN 'Bad Debt POM'
			WHEN a.[pa-fc] = '8'
				THEN 'Bad Debt AG Exchange Plans'
			WHEN a.[pa-fc] = '9'
				THEN 'Kopp-Bad Debt'
			WHEN a.[pa-fc] = 'A'
				THEN 'Commercial'
			WHEN a.[pa-fc] = 'B'
				THEN 'Blue Cross'
			WHEN a.[pa-fc] = 'C'
				THEN 'Champus'
			WHEN a.[pa-fc] = 'D'
				THEN 'Medicaid'
			WHEN a.[pa-fc] = 'E'
				THEN 'Employee Health Svc'
			WHEN a.[pa-fc] = 'G'
				THEN 'Contract Accts'
			WHEN a.[pa-fc] = 'H'
				THEN 'Medicare HMO'
			WHEN a.[pa-fc] = 'I'
				THEN 'Balance After Ins'
			WHEN a.[pa-fc] = 'J'
				THEN 'Managed Care'
			WHEN a.[pa-fc] = 'K'
				THEN 'Pending Medicaid'
			WHEN a.[pa-fc] = 'M'
				THEN 'Medicare'
			WHEN a.[pa-fc] = 'N'
				THEN 'No-Fault'
			WHEN a.[pa-fc] = 'P'
				THEN 'Self Pay'
			WHEN a.[pa-fc] = 'R'
				THEN 'Aergo Commercial'
			WHEN a.[pa-fc] = 'T'
				THEN 'RTR WC NF'
			WHEN a.[pa-fc] = 'S'
				THEN 'Special Billing'
			WHEN a.[pa-fc] = 'U'
				THEN 'Medicaid Mgd Care'
			WHEN a.[pa-fc] = 'V'
				THEN 'First Source'
			WHEN a.[pa-fc] = 'W'
				THEN 'Workers Comp'
			WHEN a.[pa-fc] = 'X'
				THEN 'Control Accts'
			WHEN a.[pa-fc] = 'Y'
				THEN 'MCS'
			WHEN a.[pa-fc] = 'Z'
				THEN 'Unclaimed Credits'
			ELSE ''
			END AS 'FC_Description',
		a.[pa-hosp-svc] AS 'Hosp_Svc',
		d.[Hosp Svc Desc] AS 'Hosp Svc Description',
		'1' AS 'COB1',
		c.[INS1] AS 'Ins1_Cd',
		COALESCE(c.[Ins1_Pol_No], c.[Ins1_Subscr_Group_Id], [Ins1_Grp_No]) AS 'Ins1_Member_ID',
		c.[Ins1_Pol_No],
		c.[Ins1_Subscr_Group_ID],
		c.[Ins1_Grp_No],
		c.[Ins1_Balance],
		c.[ins1_pymts] AS 'Pyr1_Pay_Amt',
		c.[Ins1_FIRST_PAID],
		'2' AS 'COB2',
		c.[ins2] AS 'Ins2_Cd',
		COALESCE(c.[Ins2_Pol_No], c.[Ins2_Subscr_Group_Id], [Ins2_Grp_No]) AS 'Ins2_Member_ID',
		c.[Ins2_Pol_No],
		c.[Ins2_Subscr_Group_ID],
		c.[Ins2_Grp_No],
		ISNULL(c.[Ins2_Balance], 0) AS 'Ins2_Balance',
		c.[ins2_pymts] AS 'Pyr2_Pay_Amt',
		c.[ins2_first_paid],
		'3' AS 'COB3',
		c.[INS3] AS 'Ins3_Cd',
		COALESCE(c.[Ins3_Pol_No], c.[Ins3_Subscr_Group_Id], c.[Ins3_Grp_No]) AS 'Ins3_Member_ID',
		c.[Ins3_Pol_No],
		c.[Ins3_Subscr_Group_ID],
		c.[Ins3_Grp_No],
		ISNULL(c.[Ins3_Balance], 0) AS 'Ins3_Balance',
		c.[ins3_pymts] AS 'Pyr3_Pay_Amt',
		c.[ins3_first_paid],
		'4' AS 'COB4',
		c.[INS4] AS 'Ins4_Cd',
		COALESCE(c.[Ins4_Pol_No], c.[Ins4_Subscr_Group_Id], c.[Ins4_Grp_No]) AS 'Ins4_Member_ID',
		c.[Ins4_Pol_No],
		c.[Ins4_Subscr_Group_ID],
		c.[Ins4_Grp_No],
		ISNULL(c.[Ins4_Balance], 0) AS 'Ins4_Balance',
		c.[ins4_pymts] AS 'Pyr4_Pay_Amt',
		c.[ins4_first_paid],
		a.[pa-pt-representative]
	FROM dbo.[Encounters_For_Reporting_Open_Unit] a
	LEFT OUTER JOIN [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Active].dbo.[UnitizedAccounts] b ON a.[pa-pt-no-woscd] = b.[pa-pt-no-woscd]
		AND a.[pa-unit-no] = b.[pa-unit-no]
		AND a.[pa-ctl-paa-xfer-date] = b.[pa-ctl-paa-xfer-date]
	LEFT OUTER JOIN [SMS].dbo.[CUSTOM_INSURANCE_SM_ALT] C --_3] C
		ON A.[PA-PT-NO-WOSCD] = C.[PA-PT-NO-WOSCD]
		AND A.[PA-UNIT-NO] = C.[PA-UNIT-NO]
		AND a.[pa-ctl-paa-xfer-date] = c.[pa-ctl-paa-xfer-date]
	LEFT OUTER JOIN [Swarm].dbo.[HospSvc] d ON a.[pa-hosp-svc] = d.[Hosp Svc]
	WHERE (
			COALESCE((b.[pa-unit-ins1-bal] + b.[pa-unit-ins2-bal] + b.[pa-unit-ins3-bal] + b.[pa-unit-ins4-bal] + b.[pa-unit-pt-bal]), a.[balance]) <> '0'
			OR COALESCE(b.[pa-unit-tot-chg-amt], a.[tot_chgs]) <> '0'
			)
END
GO





