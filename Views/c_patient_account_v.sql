USE [Echo_SBU_FinPARA]
/************************************************************************

File: c_patient_account_v.sql

Input Parameters:
	None

Tables/Views:
	[Echo_Active].dbo.PatientDemographics
    [Echo_Active].dbo.unitizedaccounts
    [Echo_Active].dbo.insuranceinformation
	[Echo_Active].dbo.diagnosisinformation
	[Echo_SBU_FinPARA].[dbo].[HospSvc] 

Creates Table:
	dbo.c_patient_account_v

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Patient Financial Services

Purpose/Description
	Create a patient account view, only uses the Echo_Active DB

Revision History:
Date		Version		Description
----		----		----
2023-04-10	v1			Initial Creation
***********************************************************************
*/

-- Create a new view called 'c_patient_account_v' in schema 'dbo'
-- Drop the view if it already exists
IF EXISTS (
		SELECT *
		FROM sys.VIEWS
		JOIN sys.schemas ON sys.VIEWS.schema_id = sys.schemas.schema_id
		WHERE sys.schemas.name = N'dbo'
			AND sys.VIEWS.name = N'c_patient_account_v'
		)
	DROP VIEW dbo.patient_account_v
GO

-- Create the view in the specified schema
CREATE VIEW dbo.c_patient_account_v
AS
-- body of the view
SELECT CAST(a.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(a.[PA-PT-NO-SCD] AS VARCHAR) AS [Pt_No],
	b.[PA-UNIT-NO] AS [Unit_No],
	a.[pa-med-rec-no] AS [MRN],
	a.[pa-pt-name] AS [Pt_Name],
	COALESCE(DATEADD(DAY, 1, EOMONTH(b.[pa-unit-date], - 1)), [pa-adm-date]) AS [Admit_Date],
	CASE 
		WHEN a.[pa-acct-type] <> 1
			THEN COALESCE(b.[pa-unit-date], a.[pa-dsch-date], a.[pa-adm-date])
		ELSE a.[pa-dsch-date]
		END AS [Dsch_Date],
	b.[pa-unit-date] AS [Unit_Date],
	CASE 
		WHEN a.[pa-acct-type] <> '1'
			THEN DATEDIFF(DAY, COALESCE(b.[pa-unit-date], a.[pa-dsch-date], a.[pa-adm-date]), GETDATE())
		ELSE ''
		END AS [Age_From_Discharge],
	CASE 
		WHEN a.[pa-acct-type] <> 1
			AND DATEDIFF(day, COALESCE(b.[pa-unit-date], a.[pa-dsch-date], a.[pa-adm-date]), getdate()) BETWEEN '0'
				AND '30'
			THEN '1_0-30'
		WHEN a.[pa-acct-type] <> 1
			AND DATEDIFF(day, COALESCE(b.[pa-unit-date], a.[pa-dsch-date], a.[pa-adm-date]), getdate()) BETWEEN '31'
				AND '60'
			THEN '2_31-60'
		WHEN a.[pa-acct-type] <> 1
			AND DATEDIFF(day, COALESCE(b.[pa-unit-date], a.[pa-dsch-date], a.[pa-adm-date]), getdate()) BETWEEN '61'
				AND '90'
			THEN '3_61-90'
		WHEN a.[pa-acct-type] <> 1
			AND DATEDIFF(day, COALESCE(b.[pa-unit-date], a.[pa-dsch-date], a.[pa-adm-date]), getdate()) BETWEEN '91'
				AND '120'
			THEN '4_91-120'
		WHEN a.[pa-acct-type] <> 1
			AND DATEDIFF(day, COALESCE(b.[pa-unit-date], a.[pa-dsch-date], a.[pa-adm-date]), getdate()) BETWEEN '121'
				AND '150'
			THEN '5_121-150'
		WHEN a.[pa-acct-type] <> 1
			AND DATEDIFF(day, COALESCE(b.[pa-unit-date], a.[pa-dsch-date], a.[pa-adm-date]), getdate()) BETWEEN '151'
				AND '180'
			THEN '6_151-180'
		WHEN a.[pa-acct-type] <> 1
			AND DATEDIFF(day, COALESCE(b.[pa-unit-date], a.[pa-dsch-date], a.[pa-adm-date]), getdate()) BETWEEN '181'
				AND '210'
			THEN '7_181-210'
		WHEN a.[pa-acct-type] <> 1
			AND DATEDIFF(day, COALESCE(b.[pa-unit-date], a.[pa-dsch-date], a.[pa-adm-date]), getdate()) BETWEEN '211'
				AND '240'
			THEN '8_211-240'
		WHEN a.[pa-acct-type] <> 1
			AND DATEDIFF(day, COALESCE(b.[pa-unit-date], a.[pa-dsch-date], a.[pa-adm-date]), getdate()) > '240'
			THEN '9_240+'
		WHEN a.[pa-acct-type] = 1
			THEN 'In House/DNFB'
		ELSE ''
		END AS 'Age_Bucket',
	a.[pa-acct-type],
	COALESCE(b.[pa-unit-op-first-ins-bl-date], a.[pa-final-bill-date], a.[pa-op-first-ins-bl-date]) AS [1st_Bl_Date],
	COALESCE((b.[pa-unit-ins1-bal] + b.[pa-unit-ins2-bal] + b.[pa-unit-ins3-bal] + b.[pa-unit-ins4-bal] + b.[pa-unit-pt-bal]), a.[pa-bal-acct-bal]) AS [Balance],
	COALESCE(b.[pa-unit-pt-bal], a.[pa-bal-pt-bal]) AS [Pt_Balance],
	COALESCE(b.[pa-unit-tot-chg-amt], a.[pa-bal-tot-chg-amt]) AS [Tot_Chgs],
	a.[pa-bal-tot-pt-pay-amt] AS [Pt_Pay_Amt],
	CASE 
		WHEN a.[pa-acct-type] IN ('0', '6', '7')
			THEN 'OP' --0=OP; 6=OP BAD DEBT; 7=OP HISTORIC
		WHEN a.[pa-acct-type] IN ('1', '2', '4', '8')
			THEN 'IP' --1=IP; 2=A/R; 4=I/P BAD DEBT; 8=I/P HISTORIC
		ELSE ''
		END AS [PtAcct_Type],
	CASE 
		WHEN a.[pa-acct-type] IN ('6', '4')
			THEN 'Bad Debt'
		WHEN a.[pa-dsch-date] IS NOT NULL
			AND a.[pa-acct-type] = '1'
			THEN 'DNFB'
		WHEN a.[pa-acct-type] = '1'
			THEN 'Inhouse'
		ELSE 'A/R'
		END AS [File],
	[pa-fc] AS [FC],
	CASE 
		WHEN [pa-fc] = '1'
			THEN 'Bad Debt Medicaid Pending'
		WHEN [pa-fc] IN ('2', '6')
			THEN 'Bad Debt AG'
		WHEN [pa-fc] = '3'
			THEN 'MCS'
		WHEN [pa-fc] = '4'
			THEN 'Bad Debt AG Legal'
		WHEN [pa-fc] = '5'
			THEN 'Bad Debt POM'
		WHEN [pa-fc] = '8'
			THEN 'Bad Debt AG Exchange Plans'
		WHEN [pa-fc] = '9'
			THEN 'Kopp-Bad Debt'
		WHEN [pa-fc] = 'A'
			THEN 'Commercial'
		WHEN [pa-fc] = 'B'
			THEN 'Blue Cross'
		WHEN [pa-fc] = 'C'
			THEN 'Champus'
		WHEN [pa-fc] = 'D'
			THEN 'Medicaid'
		WHEN [pa-fc] = 'E'
			THEN 'Employee Health Svc'
		WHEN [pa-fc] = 'G'
			THEN 'Contract Accts'
		WHEN [pa-fc] = 'H'
			THEN 'Medicare HMO'
		WHEN [pa-fc] = 'I'
			THEN 'Balance After Ins'
		WHEN [pa-fc] = 'J'
			THEN 'Managed Care'
		WHEN [pa-fc] = 'K'
			THEN 'Pending Medicaid'
		WHEN [pa-fc] = 'M'
			THEN 'Medicare'
		WHEN [pa-fc] = 'N'
			THEN 'No-Fault'
		WHEN [pa-fc] = 'P'
			THEN 'Self Pay'
		WHEN [pa-fc] = 'R'
			THEN 'Aergo Commercial'
		WHEN [pa-fc] = 'T'
			THEN 'RTR WC NF'
		WHEN [pa-fc] = 'S'
			THEN 'Special Billing'
		WHEN [pa-fc] = 'U'
			THEN 'Medicaid Mgd Care'
		WHEN [pa-fc] = 'V'
			THEN 'First Source'
		WHEN [pa-fc] = 'W'
			THEN 'Workers Comp'
		WHEN [pa-fc] = 'X'
			THEN 'Control Accts'
		WHEN [pa-fc] = 'Y'
			THEN 'MCS'
		WHEN [pa-fc] = 'Z'
			THEN 'Unclaimed Credits'
		ELSE ''
		END AS [FC_Description],
	[pa-hosp-svc],
	ISNULL(HOSP_SVC.[Hosp Svc Desc], '') AS [Hosp_Svc_Desc],
	a.[pa-acct-sub-type] AS [Acct_Sub_Type],
	(c.[pa-ins-co-cd] + CAST(c.[pa-ins-plan-no] AS VARCHAR)) AS [Ins1_Cd],
	(d.[pa-ins-co-cd] + CAST(d.[pa-ins-plan-no] AS VARCHAR)) AS [Ins2_Cd],
	(e.[pa-ins-co-cd] + CAST(e.[pa-ins-plan-no] AS VARCHAR)) AS [Ins3_Cd],
	(f.[pa-ins-co-cd] + CAST(f.[pa-ins-plan-no] AS VARCHAR)) AS [Ins4_Cd],
	a.[pa-disch-dx-cd] AS [Disch_Dx_Cd],
	a.[pa-disch-dx-cd-type] AS [Disch_Dx_Cd_Type],
	a.[pa-disch-dx-date] AS [Disch_Dx_Date],
	a.[PA-PROC-CD-TYPE(1)] AS [Proc1_Cd_Type],
	a.[PA-PROC-CD(1)] AS [Proc1_Cd],
	a.[PA-PROC-DATE(1)] AS [Proc1_Date],
	a.[pa-proc-prty(1)] AS [Proc1_Priority],
	a.[PA-PROC-CD-TYPE(2)] AS [Proc2_Cd_Type],
	a.[PA-PROC-CD(2)] AS [Proc2_Cd],
	a.[PA-PROC-DATE(2)] AS [Proc2_Date],
	a.[pa-proc-prty(2)] AS [Proc2_Priority],
	a.[PA-PROC-CD-TYPE(3)] AS [Proc3_Cd_Type],
	a.[PA-PROC-CD(3)] AS [Proc3_Cd],
	a.[PA-PROC-DATE(3)] AS [Proc3_Date],
	a.[pa-proc-prty(3)] AS [Proc3_Priority],
	c.[pa-bal-ins-pay-amt] AS [Pyr1_Pay_Amt],
	d.[pa-bal-ins-pay-amt] AS [Pyr2_Pay_Amt],
	e.[pa-bal-ins-pay-amt] AS [Pyr3_Pay_Amt],
	f.[pa-bal-ins-pay-amt] AS [Pyr4_Pay_Amt],
	c.[pa-last-ins-bl-date] AS [Pyr1_Last_Ins_Bl_Date],
	d.[pa-last-ins-bl-date] AS [Pyr2_Last_Ins_Bl_Date],
	e.[pa-last-ins-bl-date] AS [Pyr3_Last_Ins_Bl_Date],
	f.[pa-last-ins-bl-date] AS [Pyr4_Last_Ins_Bl_Date],
	(CAST(ISNULL(c.[pa-bal-ins-pay-amt], 0) AS MONEY) + CAST(ISNULL(d.[pa-bal-ins-pay-amt], 0) AS MONEY) + CAST(ISNULL(e.[pa-bal-ins-pay-amt], 0) AS MONEY) + CAST(ISNULL(f.[pa-bal-ins-pay-amt], 0) AS MONEY)) AS [Ins_Pay_Amt],
	(CAST(ISNULL(c.[pa-bal-ins-pay-amt], 0) AS MONEY) + CAST(ISNULL(d.[pa-bal-ins-pay-amt], 0) AS MONEY) + CAST(ISNULL(e.[pa-bal-ins-pay-amt], 0) AS MONEY) + CAST(ISNULL(f.[pa-bal-ins-pay-amt], 0) AS MONEY)) + CAST(ISNULL(a.[pa-bal-tot-pt-pay-amt], 0) AS MONEY) AS [Tot_Pay_Amt],
	a.[pa-last-fc-cng-date] AS [Last_FC_Change_Date],
	a.[pa-pt-representative] AS [Rep_Code],
	a.[pa-resp-cd] AS [Resp_Code],
	a.[pa-cr-rating] AS [Credit Rating],
	a.[pa-courtesy-allow] AS [Courtesy_Allow],
	a.[pa-last-actv-date] AS [Last_Charge_Svc_Date],
	a.[pa-last-pt-pay-date] AS [Last_Pt_Pay_Date],
	c.[pa-last-ins-pay-date] AS [Pyr1_Last_Ins_Pay_Date],
	a.[pa-no-of-cwi] AS [No_Of_CW_Segments],
	a.[pa-pay-scale] AS [Pay_Scale],
	a.[pa-stmt-cd] AS [Stmt_Cd],
	LastPaymentDates.[PA-BAL-INS-PAY-AMT] AS [Last_Ins_Pay_Amt],
	LastPaymentDates.[PA-LAST-INS-PAY-DATE] AS [Last_Ins_Pay_Date],
	a.[pa-ctrct-amt] AS [Contract_Amount],
	a.[PA-ACCT-BD-XFR-DATE] AS [Acct_Bd_Xfr_Date]
FROM [Echo_Active].dbo.PatientDemographics AS a
LEFT OUTER JOIN [Echo_Active].dbo.unitizedaccounts AS b ON a.[pa-pt-no-woscd] = b.[pa-pt-no-woscd]
	AND a.[pa-pt-no-scd] = b.[pa-pt-no-scd-1]
LEFT OUTER JOIN [Echo_Active].dbo.insuranceinformation AS c ON a.[pa-pt-no-woscd] = c.[pa-pt-no-woscd]
	AND c.[pa-ins-prty] = '1'
LEFT OUTER JOIN [Echo_Active].dbo.insuranceinformation AS d ON a.[pa-pt-no-woscd] = d.[pa-pt-no-woscd]
	AND d.[pa-ins-prty] = '2'
LEFT OUTER JOIN [Echo_Active].dbo.insuranceinformation AS e ON a.[pa-pt-no-woscd] = e.[pa-pt-no-woscd]
	AND e.[pa-ins-prty] = '3'
LEFT OUTER JOIN [Echo_Active].dbo.insuranceinformation AS f ON a.[pa-pt-no-woscd] = f.[pa-pt-no-woscd]
	AND f.[pa-ins-prty] = '4'
LEFT OUTER JOIN [Echo_Active].dbo.diagnosisinformation g ON a.[pa-pt-no-woscd] = g.[pa-pt-no-woscd]
	AND g.[pa-dx2-prio-no] = '1'
	AND g.[pa-dx2-type1-type2-cd] = 'DF'
LEFT OUTER JOIN [dbo].[HospSvc] AS HOSP_SVC ON A.[PA-HOSP-SVC] = HOSP_SVC.[HOSP SVC]
LEFT OUTER JOIN (
	SELECT A.[PA-PT-NO-WOSCD],
		A.[PA-PT-NO-SCD-1],
		B.[PA-INS-PRTY],
		(LTRIM(RTRIM(B.[pa-ins-co-cd])) + CAST(LTRIM(RTRIM(B.[pa-ins-plan-no])) AS CHAR)) AS [PA-INS-PLAN],
		B.[PA-LAST-INS-PAY-DATE],
		B.[PA-BAL-INS-PAY-AMT],
		RANK() OVER (
			PARTITION BY A.[PA-PT-NO-WOSCD] ORDER BY B.[PA-LAST-INS-PAY-DATE] DESC
			) AS [RANK1]
	FROM [Echo_Active].DBO.PATIENTDEMOGRAPHICS AS A
	LEFT OUTER JOIN [Echo_Active].DBO.INSURANCEINFORMATION AS B ON A.[PA-PT-NO-WOSCD] = B.[PA-PT-NO-WOSCD]
	WHERE [PA-BAL-INS-PAY-AMT] <> '0'
	) AS LastPaymentDates ON A.[PA-PT-NO-WOSCD] = LastPaymentDates.[PA-PT-NO-WOSCD]
	AND A.[PA-PT-NO-SCD-1] = LastPaymentDates.[PA-PT-NO-SCD-1]
	AND LastPaymentDates.RANK1 = 1
GO





