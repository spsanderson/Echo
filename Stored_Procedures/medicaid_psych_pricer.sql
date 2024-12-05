USE [SMS]
GO
/****** Object:  StoredProcedure [dbo].[c_sms_Medicaid_Psych_Pricer_sp]    Script Date: 3/4/2024 9:43:45 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[c_sms_Medicaid_Psych_Pricer_sp]
AS
SET ANSI_NULLS ON
SET ANSI_WARNINGS ON
SET QUOTED_IDENTIFIER ON

BEGIN
	SET NOCOUNT ON;

	DROP TABLE IF EXISTS [SMS].[dbo].[Accts With ECT]
		SELECT C.[Pt_No],
			C.[Admit_Date],
			C.[Dsch_Date],
			C.[Tot_Chgs],
			C.[Ins1_Cd],
			C.[Ins1_Balance],
			C.[Pyr1_Pay_Amt],
			C.[Billing_DRG_NO] AS [PA-DRG-NO-2],
			C.[Billing_DRG_SOI_IND] AS [PA-DRG-SOI-IND],
			F.[PA-DTL-REV-CD],
			F.[PA-DTL-SVC-CD],
			C.Pt_Birth_Date
		INTO [SMS].[dbo].[Accts With ECT]
		FROM [SMS].[dbo].[Pt_Accounting_Reporting_ALT] C
		LEFT JOIN [SMS].[DBO].[Charges_For_Reporting] F ON C.PT_NO = F.PT_NO
		WHERE (
				LEFT(C.INS1_CD, 1) IN ('D', 'U', 'Y')
				OR c.ins1_cd = 'J41'
				)
			AND c.[Acct_Type] = 'IP'
			AND f.[pa-dtl-svc-cd] IN ('46760013', '46760039', '46760047')
			AND c.[Dsch_Date] >= '2020-01-01 00:00:00.000'
			AND c.[Pt_Type] = 'U';

	--This table is used to determine if the Accounts have an ECT Billed. The output is on the "Accts With ECT" tab of the pricer
	DROP TABLE IF EXISTS [SMS].[dbo].[Unique IP Psych Accts]
		SELECT DISTINCT C.[Pt_No],
			ltrim(rtrim(substring(c.[Pt_Name], 1, charindex(',', c.[Pt_Name]) - 1))) AS 'Pt_Last_Name',
			ltrim(rtrim(substring(c.[Pt_Name], charindex(',', c.[Pt_Name]) + 1, LEN(c.[Pt_Name])))) AS 'Pt_First_Name',
			C.[Admit_Date],
			C.[Dsch_Date],
			C.[Tot_Chgs],
			C.[Ins1_Cd],
			C.[Ins1_Balance],
			C.[Pyr1_Pay_Amt],
			C.[Billing_DRG_NO] AS [PA-DRG-NO-2],
			C.[Billing_DRG_SOI_IND] AS [PA-DRG-SOI-IND],
			C.Pt_Birth_Date
		INTO [SMS].[dbo].[Unique IP Psych Accts]
		FROM [SMS].[dbo].[Pt_Accounting_Reporting_ALT] C
		LEFT JOIN [SMS].[DBO].[Charges_For_Reporting] F ON C.PT_NO = F.PT_NO
		WHERE (
				LEFT(C.INS1_CD, 1) IN ('D', 'U', 'Y')
				OR c.ins1_cd = 'J41'
				)
			AND f.[pa-dtl-svc-cd] NOT IN ('46760013', '46760039', '46760047')
			AND c.[Acct_Type] = 'IP'
			AND c.[Dsch_Date] >= '2020-01-01 00:00:00.000'
			AND c.[Pt_Type] = 'U';

	--This table is to identify unique accounts Psych accounts, the output is on "Unique IP Psych Accts" tab of the pricer
	DROP TABLE IF EXISTS [SMS].[dbo].[Diagnoses]
		SELECT DISTINCT c.[Pt_No],
			CAST(c.[pt_no] AS VARCHAR) + CAST(RANK() OVER (
					PARTITION BY c.[pt_no] ORDER BY a.[PA-DX2-CODE]
					) AS VARCHAR) AS 'UniqueID'
			--,a.[PA-DX2-CODE]
			,
			REPLACE(a.[PA-DX2-CODE], '.', '') AS '[PA-DX2-CODE]',
			a.[PA-DX2-TYPE1-TYPE2-CD]
		--,rank() over(partition by c.[pt_no] order by a.[PA-DX2-CODE]) as 'Rank'
		INTO [SMS].[dbo].[Diagnoses]
		FROM [SMS].[dbo].[Pt_Accounting_Reporting_ALT] C
		LEFT JOIN [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Active].DBO.DiagnosisINFORMATION a ON c.[pt_no] = cast(a.[pa-pt-no-woscd] AS VARCHAR) + cast(a.[pa-pt-no-scd-1] AS VARCHAR)
		WHERE (
				LEFT(C.INS1_CD, 1) IN ('D', 'U', 'Y')
				OR c.ins1_cd = 'J41'
				)
			AND a.[PA-DX2-TYPE1-TYPE2-CD] = 'DF'
			AND c.[Acct_Type] = 'IP'
			AND c.[Dsch_Date] >= '2020-01-01 00:00:00.000'
			AND c.[Pt_Type] = 'U'
		
		UNION
		
		SELECT DISTINCT c.[Pt_No],
			cast(c.[pt_no] AS VARCHAR) + cast(rank() OVER (
					PARTITION BY c.[pt_no] ORDER BY a.[PA-DX2-CODE]
					) AS VARCHAR) AS 'UniqueID'
			--,a.[PA-DX2-CODE]
			,
			REPLACE(a.[PA-DX2-CODE], '.', '') AS '[PA-DX2-CODE]',
			a.[PA-DX2-TYPE1-TYPE2-CD]
		--,rank() over(partition by c.[pt_no] order by a.[PA-DX2-CODE]) as 'Rank'
		FROM [SMS].[dbo].[Pt_Accounting_Reporting_ALT] C
		LEFT JOIN [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Archive].DBO.DiagnosisINFORMATION a ON c.[pt_no] = cast(a.[pa-pt-no-woscd] AS VARCHAR) + cast(a.[pa-pt-no-scd-1] AS VARCHAR)
		WHERE (
				LEFT(C.INS1_CD, 1) IN ('D', 'U', 'Y')
				OR c.ins1_cd = 'J41'
				)
			AND a.[PA-DX2-TYPE1-TYPE2-CD] = 'DF'
			AND c.[Acct_Type] = 'IP'
			AND c.[Dsch_Date] >= '2020-01-01 00:00:00.000'
			AND c.[Pt_Type] = 'U'
			--This table pulls the final Diagnoses from the encounter, the output is on the "Diagnoses" table
			--Can we add a unique number column in this table by appending a the count of how many times the pt_no has occured in the query so far to the Pt_No?
			--Can we remove the decimal from the [PA-DX2-CODE] column?
END;
