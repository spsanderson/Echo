USE [Echo_SBU_PA]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[c_Patient_Account_tbl_sp]
AS

SET NOCOUNT ON;
SET ANSI_WARNINGS OFF;

/*
Author: Steven P Sanderson II, MPH - Consultant - Manchu Technology Corp

This stored procedure will create a table for the patient account view AS a replacement
to dbo.PtAcct_v

v1 - 2018-05-05		- Initial Creation
v2 - 2018-05-07		- Fix table insert to truncate table and insert all records
					  this will catch updates.
*/

-- The first thing we will do is see if tha table exsits, if not, then create AND fill
IF NOT EXISTS(
	SELECT TOP 1 *
	FROM SYSOBJECTS
	WHERE NAME = 'c_Patient_Account_tbl'
	AND xtype = 'U'
)

BEGIN
	CREATE TABLE dbo.c_Patient_Account_tbl (
		PK INT IDENTITY(1, 1) NOT NULL PRIMARY KEY
		, [PT_NO] VARCHAR(15)
		, [PA_UNIT_NO] VARCHAR(5)
		, [MRN] VARCHAR(10)
		, [PA_PT_NAME] VARCHAR(250)
		, [ADMIT_DATE] DATE
		, [Dsch_Date] DATE
		, [PA_UNIT_DATE] DATE
		, [AGE_FROM_DISCHARGE] VARCHAR(6)
		, [AGE_BUCKET] VARCHAR(10)
		, [PA_ACT_TYPE] VARCHAR(10)
		, [FIRST_BAL_DATE] DATE
		, [BALANCE] VARCHAR(20)
		, [PT_BALANCE] VARCHAR(20)
		, [TOTAL_CHARGES] VARCHAR(20)
		, [PA_BAL_TOT_PT_PAY_AMT] VARCHAR(20)
		, [PTACCT_TYPE] VARCHAR(5)
		, [PT_FILE_TYPE] VARCHAR(20)
		, [FC] VARCHAR(5)
		, [FC_Description] VARCHAR(30)
		, [PA_HOSP_SVC] VARCHAR(5)
		, [Hosp_Svc_Desc] VARCHAR(50)
		, [PA_ACCT_SUB_TYPE] VARCHAR(10)
		, [INS1_CD] VARCHAR(4)
		, [INS2_CD] VARCHAR(4)
		, [INS3_CD] VARCHAR(4)
		, [INS4_CD] VARCHAR(4)
		, [DISCHARGE_DX] VARCHAR(15)
		, [DISCHARGE_DX_CD_TYPE] VARCHAR(1)
		, [DISCHARGE_DX_DATE] DATE
		, [PA_PROC_CD_TYPE_1] VARCHAR(2)
		, [PA_PROC_CD_1] VARCHAR(15)
		, [PA_PROC_CD_1_DATE] DATE
		, [PA_PROC_CD_1_PRTY] VARCHAR(1)
		, [PA_PROC_CD_TYPE_2] VARCHAR(2)
		, [PA_PROC_CD_2] VARCHAR(15)
		, [PA_PROC_CD_2_DATE] DATE
		, [PA_PROC_CD_2_PRTY] VARCHAR(1)
		, [PA_PROC_CD_TYPE_3] VARCHAR(2)
		, [PA_PROC_CD_3] VARCHAR(15)
		, [PA_PROC_CD_3_DATE] DATE
		, [PA_PROC_CD_3_PRTY] VARCHAR(1)
		, [INS1_PAY_AMT] VARCHAR(20)
		, [INS2_PAY_AMT] VARCHAR(20)
		, [INS3_PAY_AMT] VARCHAR(20)
		, [INS4_PAY_AMT] VARCHAR(20)
		, [INS1_LAST_BILL_DATE] DATE
		, [INS2_LAST_BILL_DATE] DATE
		, [INS3_LAST_BILL_DATE] DATE
		, [INS4_LAST_BILL_DATE] DATE
		, [TOTAL_INSURANCE_PAY_AMT] VARCHAR(20)
		, [TOTAL_PAY_AMOUNT] VARCHAR(20)
		, [PT_LAST_FC_CHANGE_DATE] DATE
		, [REP_CODE] VARCHAR(5)
		, [RESP_CODE] VARCHAR(5)
		, [CREDIT_RATING] VARCHAR(5)
		, [PA_COURTESY_ALLOWANCE] VARCHAR(20)
		, [LAST_CHARGE_SVC_DATE] DATE
		, [PA_LAST_PAY_DATE] DATE
		, [PA_INS_LAST_PAY_DATE] DATE
		, [NO_OF_CW_SEGMENTS] VARCHAR(5)
		, [PA_PAY_SCALE] VARCHAR(5)
		, [PA_STMT_CD] VARCHAR(5)
		, [LAST_PA_BAL_INS_PAY_AMT] VARCHAR(20)
		, [LAST_PA_LAST_INS_PAY_DATE] DATE
		, [PA_CONTRACT_AMT] VARCHAR(20)
		, [PA_ACCT_BD_XFER_DATE] DATE
		, [RUN_DATE] DATE
		, [RUN_DATE_TIME] DATETIME
	);

	INSERT INTO dbo.c_Patient_Account_tbl

	SELECT (
		CAST(a.[PA-PT-NO-WOSCD] AS VARCHAR)
		+
		CAST(a.[PA-PT-NO-SCD] AS VARCHAR)
		) AS [Pt_No]
	, b.[PA-UNIT-NO]
	, a.[pa-med-rec-no] AS [MRN]
	, a.[pa-pt-name]
	, COALESCE(
		DATEADD(DAY, 1, EOMONTH(b.[pa-unit-date], -1))
		, [pa-adm-date]
		) AS [Admit_Date]
	, CASE 
		WHEN a.[pa-acct-type] <> 1 
			THEN COALESCE(
				b.[pa-unit-date]
				, a.[pa-dsch-date]
				,a.[pa-adm-date]
			)
			ELSE a.[pa-dsch-date]
	  END AS [Dsch_Date]
	, b.[pa-unit-date]
	, CASE 
		WHEN a.[pa-acct-type] <> '1' 
			THEN DATEDIFF(
				DAY
				, COALESCE(
					b.[pa-unit-date]
					, a.[pa-dsch-date]
					, a.[pa-adm-date]
				)
				, GETDATE()
			)
			ELSE ''
	  END AS [Age_From_Discharge]
	, CASE
		WHEN a.[pa-acct-type] <> 1 
			AND DATEDIFF(
				DAY
				, COALESCE(
					b.[pa-unit-date]
					, a.[pa-dsch-date]
					, a.[pa-adm-date]
				)
				,GETDATE()
			) BETWEEN '0' AND '30' 
			THEN '1_0-30'
		WHEN a.[pa-acct-type] <> 1 
			AND DATEDIFF(
				DAY
				, COALESCE(
					b.[pa-unit-date]
					, a.[pa-dsch-date]
					, a.[pa-adm-date]
				)
				,GETDATE()
			) BETWEEN '31' AND '60' 
			THEN '2_31-60'
		WHEN a.[pa-acct-type] <> 1 
			AND DATEDIFF(
				DAY
				, COALESCE(
					b.[pa-unit-date]
					, a.[pa-dsch-date]
					, a.[pa-adm-date]
				)
				, GETDATE()
			) BETWEEN '61' AND '90' 
			THEN '3_61-90'
		WHEN a.[pa-acct-type] <> 1 
			AND DATEDIFF(
				DAY
				, COALESCE(
					b.[pa-unit-date]
					, a.[pa-dsch-date]
					, a.[pa-adm-date]
				)
				, GETDATE()
			) BETWEEN '91' AND '120' 
			THEN '4_91-120'
		WHEN a.[pa-acct-type] <> 1 
			AND DATEDIFF(
				DAY
				, COALESCE(
					b.[pa-unit-date]
					, a.[pa-dsch-date]
					, a.[pa-adm-date]
				)
				, GETDATE()
			) BETWEEN '121' AND '150' 
			THEN '5_121-150'
		WHEN a.[pa-acct-type] <> 1 
			AND DATEDIFF(
				DAY
				, COALESCE(
					b.[pa-unit-date]
					, a.[pa-dsch-date]
					, a.[pa-adm-date]
				)
				, GETDATE()
			) BETWEEN '151' AND '180' 
			THEN '6_151-180'
		WHEN a.[pa-acct-type] <> 1 
			AND DATEDIFF(
				DAY
				, COALESCE(
					b.[pa-unit-date]
					, a.[pa-dsch-date]
					, a.[pa-adm-date]
				)
				, GETDATE()
			) BETWEEN '181' AND '210' 
			THEN '7_181-210'
		WHEN a.[pa-acct-type] <> 1 
			AND DATEDIFF(
				DAY
				, COALESCE(
					b.[pa-unit-date]
					, a.[pa-dsch-date]
					, a.[pa-adm-date]
				)
				, GETDATE()
			) BETWEEN '211' AND '240' 
			THEN '8_211-240'
		WHEN a.[pa-acct-type] <> 1 
			AND DATEDIFF(
				DAY
				, COALESCE(
					b.[pa-unit-date]
					, a.[pa-dsch-date]
					, a.[pa-adm-date]
				)
				, GETDATE()
			) > '240' 
			THEN '9_240+'
		WHEN a.[pa-acct-type] = 1 
			THEN 'In House/DNFB'
		ELSE ''
	  END AS 'Age_Bucket'
	, a.[pa-acct-type]
	, COALESCE(
		b.[pa-unit-op-first-ins-bl-date],
		a.[pa-final-bill-date],
		a.[pa-op-first-ins-bl-date]
		) AS '1st_Bl_Date'
	, COALESCE(
		(
			b.[pa-unit-ins1-bal] + 
			b.[pa-unit-ins2-bal] + 
			b.[pa-unit-ins3-bal] + 
			b.[pa-unit-ins4-bal] + 
			b.[pa-unit-pt-bal]
		)
		, a.[pa-bal-acct-bal]
		) AS 'Balance'
	, COALESCE(
		b.[pa-unit-pt-bal]
		, a.[pa-bal-pt-bal]
		) AS 'Pt_Balance'
	, COALESCE(
		b.[pa-unit-tot-chg-amt]
		, a.[pa-bal-tot-chg-amt]
		) AS 'Tot_Chgs'
	, a.[pa-bal-tot-pt-pay-amt] 
	, CASE
		WHEN a.[pa-acct-type] IN ('0','6','7') 
			THEN 'OP' --0=OP; 6=OP BAD DEBT; 7=OP HISTORIC
		WHEN a.[pa-acct-type] IN ('1','2','4','8') 
			THEN 'IP'  --1=IP; 2=A/R; 4=I/P BAD DEBT; 8=I/P HISTORIC
		ELSE ''
	  END AS 'PtAcct_Type'
	, CASE
		WHEN a.[pa-acct-type] IN ('6','4') 
			THEN 'Bad Debt'
		WHEN a.[pa-dsch-date] is not null 
			AND a.[pa-acct-type]='1' 
			THEN 'DNFB'
		WHEN a.[pa-acct-type] = '1' 
			THEN 'Inhouse'
		ELSE 'A/R'
	   END AS 'File'
	, [pa-fc] AS 'FC'
	, CASE
		WHEN [pa-fc]='1' THEN 'Bad Debt Medicaid Pending'
		WHEN [pa-fc] IN ('2','6') THEN 'Bad Debt AG'
		WHEN [pa-fc]='3' THEN 'MCS'
		WHEN [pa-fc]='4' THEN 'Bad Debt AG Legal'
		WHEN [pa-fc]='5' THEN 'Bad Debt POM'
		WHEN [pa-fc]='8' THEN 'Bad Debt AG Exchange Plans'
		WHEN [pa-fc]='9' THEN 'Kopp-Bad Debt'
		WHEN [pa-fc]='A' THEN 'Commercial'
		WHEN [pa-fc]='B' THEN 'Blue Cross'
		WHEN [pa-fc]='C' THEN 'Champus'
		WHEN [pa-fc]='D' THEN 'Medicaid'
		WHEN [pa-fc]='E' THEN 'Employee Health Svc'
		WHEN [pa-fc]='G' THEN 'Contract Accts'
		WHEN [pa-fc]='H' THEN 'Medicare HMO'
		WHEN [pa-fc]='I' THEN 'Balance After Ins'
		WHEN [pa-fc]='J' THEN 'Managed Care'
		WHEN [pa-fc]='K' THEN 'Pending Medicaid'
		WHEN [pa-fc]='M' THEN 'Medicare'
		WHEN [pa-fc]='N' THEN 'No-Fault'
		WHEN [pa-fc]='P' THEN 'Self Pay'
		WHEN [pa-fc]='R' THEN 'Aergo Commercial'
		WHEN [pa-fc]='T' THEN 'RTR WC NF'
		WHEN [pa-fc]='S' THEN 'Special Billing'
		WHEN [pa-fc]='U' THEN 'Medicaid Mgd Care'
		WHEN [pa-fc]='V' THEN 'First Source'
		WHEN [pa-fc]='W' THEN 'Workers Comp'
		WHEN [pa-fc]='X' THEN 'Control Accts'
		WHEN [pa-fc]='Y' THEN 'MCS'
		WHEN [pa-fc]='Z' THEN 'Unclaimed Credits'
		ELSE ''
	END AS 'FC_Description'
	,  [pa-hosp-svc]
	, ISNULL(HOSP_SVC.[hosp_desc], '') AS [Hosp_Svc_Desc]
	, a.[pa-acct-sub-type]  --D=Discharged; I=In House
	, (c.[pa-ins-co-cd] + CAST(c.[pa-ins-plan-no] AS varchar)) AS 'Ins1_Cd'
	, (d.[pa-ins-co-cd] + CAST(d.[pa-ins-plan-no] AS varchar)) AS 'Ins2_Cd'
	, (e.[pa-ins-co-cd] + CAST(e.[pa-ins-plan-no] AS varchar)) AS 'Ins3_Cd' 
	, (f.[pa-ins-co-cd] + CAST(f.[pa-ins-plan-no] AS varchar)) AS 'Ins4_Cd'
	, a.[pa-disch-dx-cd]
	, a.[pa-disch-dx-cd-type]
	, a.[pa-disch-dx-date]
	, a.[PA-PROC-CD-TYPE(1)]
	, a.[PA-PROC-CD(1)]
	, a.[PA-PROC-DATE(1)]
	, a.[pa-proc-prty(1)]
	, a.[PA-PROC-CD-TYPE(2)]
	, a.[PA-PROC-CD(2)]
	, a.[PA-PROC-DATE(2)]
	, a.[pa-proc-prty(2)]
	, a.[PA-PROC-CD-TYPE(3)]
	, a.[PA-PROC-CD(3)]
	, a.[PA-PROC-DATE(3)]
	, a.[pa-proc-prty(3)]
	, c.[pa-bal-ins-pay-amt] AS 'Pyr1_Pay_Amt'
	, d.[pa-bal-ins-pay-amt] AS 'Pyr2_Pay_Amt'
	, e.[pa-bal-ins-pay-amt] AS 'Pyr3_Pay_Amt'
	, f.[pa-bal-ins-pay-amt] AS 'Pyr4_Pay_Amt'
	, c.[pa-last-ins-bl-date] AS 'Pyr1_Last_Ins_Bl_Date'
	, d.[pa-last-ins-bl-date] AS 'Pyr2_Last_Ins_Bl_Date'
	, e.[pa-last-ins-bl-date] AS 'Pyr3_Last_Ins_Bl_Date'
	, f.[pa-last-ins-bl-date] AS 'Pyr4_Last_Ins_Bl_Date'
	, (
		CAST(ISNULL(c.[pa-bal-ins-pay-amt],0) AS MONEY) + 
	    CAST(ISNULL(d.[pa-bal-ins-pay-amt],0) AS MONEY) + 
	    CAST(ISNULL(e.[pa-bal-ins-pay-amt],0) AS MONEY) + 
	    CAST(ISNULL(f.[pa-bal-ins-pay-amt],0) AS MONEY)
	) AS 'Ins_Pay_Amt'
	, (
		CAST(ISNULL(c.[pa-bal-ins-pay-amt],0) AS MONEY) + 
		CAST(ISNULL(d.[pa-bal-ins-pay-amt],0) AS MONEY) + 
		CAST(ISNULL(e.[pa-bal-ins-pay-amt],0) AS MONEY) + 
		CAST(ISNULL(f.[pa-bal-ins-pay-amt],0) AS MONEY) + 
		CAST(ISNULL(a.[pa-bal-tot-pt-pay-amt],0) AS MONEY)
	) AS 'Tot_Pay_Amt'
	, a.[pa-last-fc-cng-date]
	, a.[pa-pt-representative] AS 'Rep_Code'
	, a.[pa-resp-cd] AS 'Resp_Code'
	, a.[pa-cr-rating] AS 'Credit Rating'
	, a.[pa-courtesy-allow]
	, a.[pa-last-actv-date] AS 'Last_Charge_Svc_Date'
	, a.[pa-last-pt-pay-date]
	, c.[pa-last-ins-pay-date]
	, a.[pa-no-of-cwi] AS 'No_Of_CW_Segments'
	, a.[pa-pay-scale]
	, a.[pa-stmt-cd]
	, LastPaymentDates.[PA-BAL-INS-PAY-AMT] AS [Last_PA_BAL_INS_PAY_AMT]
	, LastPaymentDates.[PA-LAST-INS-PAY-DATE] AS [Last_PA_LAST_INS_PAY_DATE]
	, a.[pa-ctrct-amt]
	, a.[PA-ACCT-BD-XFR-DATE]
	, CAST(GETDATE() AS DATE) AS [RUNDATE]
	, GETDATE() AS [RUNDATE_TIME]

	FROM [Echo_Active].dbo.PatientDemographics AS a 
	LEFT OUTER JOIN [Echo_Active].dbo.unitizedaccounts AS b
	ON a.[pa-pt-no-woscd] = b.[pa-pt-no-woscd] 
		AND a.[pa-pt-no-scd] = b.[pa-pt-no-scd-1] 
	LEFT OUTER JOIN [Echo_Active].dbo.insuranceinformation AS c
	ON a.[pa-pt-no-woscd] = c.[pa-pt-no-woscd] 
		AND c.[pa-ins-prty] = '1'
	LEFT OUTER JOIN [Echo_Active].dbo.insuranceinformation AS d
	ON a.[pa-pt-no-woscd] = d.[pa-pt-no-woscd] 
		AND d.[pa-ins-prty] = '2'
	LEFT OUTER JOIN [Echo_Active].dbo.insuranceinformation AS e
	ON a.[pa-pt-no-woscd] = e.[pa-pt-no-woscd] 
		AND e.[pa-ins-prty] = '3'
	LEFT OUTER JOIN [Echo_Active].dbo.insuranceinformation AS f
	ON a.[pa-pt-no-woscd] = f.[pa-pt-no-woscd] 
		AND f.[pa-ins-prty] = '4'
	LEFT OUTER JOIN [Echo_Active].dbo.diagnosisinformation g
	ON a.[pa-pt-no-woscd] = g.[pa-pt-no-woscd] 
		AND g.[pa-dx2-prio-no] = '1' 
		AND g.[pa-dx2-type1-type2-cd] = 'DF'
	LEFT OUTER JOIN [Echo_SBU_PA].[dbo].[hosp_svc_mstr] AS HOSP_SVC
	ON A.[PA-HOSP-SVC] = HOSP_SVC.HOSP_SVC
	LEFT OUTER JOIN (
		SELECT A.[PA-PT-NO-WOSCD]
		, A.[PA-PT-NO-SCD-1]
		, B.[PA-INS-PRTY]
		, (
			LTRIM(RTRIM(B.[pa-ins-co-cd])) + 
			CAST(LTRIM(RTRIM(B.[pa-ins-plan-no])) AS CHAR)
		) AS [PA-INS-PLAN]
		, B.[PA-LAST-INS-PAY-DATE]
		, B.[PA-BAL-INS-PAY-AMT]
		, RANK() OVER (PARTITION BY A.[PA-PT-NO-WOSCD] ORDER BY B.[PA-LAST-INS-PAY-DATE] DESC) AS [RANK1]

		FROM [Echo_Active].DBO.PATIENTDEMOGRAPHICS AS A 
		LEFT OUTER JOIN [Echo_Active].DBO.INSURANCEINFORMATION AS B
		ON A.[PA-PT-NO-WOSCD] = B.[PA-PT-NO-WOSCD]

		WHERE [PA-BAL-INS-PAY-AMT] <> '0'
	) AS LastPaymentDates
	ON A.[PA-PT-NO-WOSCD] = LastPaymentDates.[PA-PT-NO-WOSCD]
		AND A.[PA-PT-NO-SCD-1] = LastPaymentDates.[PA-PT-NO-SCD-1]
		AND LastPaymentDates.RANK1 = 1

	WHERE COALESCE(
		(
			b.[pa-unit-ins1-bal] + 
			b.[pa-unit-ins2-bal] + 
			b.[pa-unit-ins3-bal] + 
			b.[pa-unit-ins4-bal] + 
			b.[pa-unit-pt-bal]
		)
		, a.[pa-bal-acct-bal]
	) <> '0'
	AND COALESCE(
		b.[pa-unit-tot-chg-amt]
		, a.[pa-bal-tot-chg-amt]
	) <> '0'
	AND (
		c.[pa-ins-co-cd] = 'O' 
		OR 
		d.[pa-ins-co-cd] = 'O' 
		OR 
		e.[pa-ins-co-cd] = 'O'
	)
	AND (
		c.[pa-ins-plan-no] = '29'
		OR 
		d.[pa-ins-plan-no] = '29'
		OR 
		e.[pa-ins-plan-no] = '29'
	)
	AND b.[pa-unit-no] IS NOT NULL
END
-- IF THE TABLE ALREADY EXISTS, THEN TRUNCATE AND INSERT RECORDS
ELSE BEGIN
	
	TRUNCATE TABLE dbo.c_Patient_Account_tbl

	INSERT INTO dbo.c_Patient_Account_tbl

	SELECT (
		CAST(a.[PA-PT-NO-WOSCD] AS VARCHAR)
		+
		CAST(a.[PA-PT-NO-SCD] AS VARCHAR)
		) AS [Pt_No]
	, b.[PA-UNIT-NO] AS [PA_UNIT_NO]
	, a.[pa-med-rec-no] AS [MRN]
	, a.[pa-pt-name] AS [PA_PT_NAME]
	, COALESCE(
		DATEADD(DAY, 1, EOMONTH(b.[pa-unit-date], -1))
		, [pa-adm-date]
		) AS [Admit_Date]
	, CASE 
		WHEN a.[pa-acct-type] <> 1 
			THEN COALESCE(
				b.[pa-unit-date]
				, a.[pa-dsch-date]
				,a.[pa-adm-date]
			)
			ELSE a.[pa-dsch-date]
	  END AS [Dsch_Date]
	, b.[pa-unit-date] AS [PA_UNIT_DATE]
	, CASE 
		WHEN a.[pa-acct-type] <> '1' 
			THEN DATEDIFF(
				DAY
				, COALESCE(
					b.[pa-unit-date]
					, a.[pa-dsch-date]
					, a.[pa-adm-date]
				)
				, GETDATE()
			)
			ELSE ''
	  END AS [Age_From_Discharge]
	, CASE
		WHEN a.[pa-acct-type] <> 1 
			AND DATEDIFF(
				DAY
				, COALESCE(
					b.[pa-unit-date]
					, a.[pa-dsch-date]
					, a.[pa-adm-date]
				)
				,GETDATE()
			) BETWEEN '0' AND '30' 
			THEN '1_0-30'
		WHEN a.[pa-acct-type] <> 1 
			AND DATEDIFF(
				DAY
				, COALESCE(
					b.[pa-unit-date]
					, a.[pa-dsch-date]
					, a.[pa-adm-date]
				)
				,GETDATE()
			) BETWEEN '31' AND '60' 
			THEN '2_31-60'
		WHEN a.[pa-acct-type] <> 1 
			AND DATEDIFF(
				DAY
				, COALESCE(
					b.[pa-unit-date]
					, a.[pa-dsch-date]
					, a.[pa-adm-date]
				)
				, GETDATE()
			) BETWEEN '61' AND '90' 
			THEN '3_61-90'
		WHEN a.[pa-acct-type] <> 1 
			AND DATEDIFF(
				DAY
				, COALESCE(
					b.[pa-unit-date]
					, a.[pa-dsch-date]
					, a.[pa-adm-date]
				)
				, GETDATE()
			) BETWEEN '91' AND '120' 
			THEN '4_91-120'
		WHEN a.[pa-acct-type] <> 1 
			AND DATEDIFF(
				DAY
				, COALESCE(
					b.[pa-unit-date]
					, a.[pa-dsch-date]
					, a.[pa-adm-date]
				)
				, GETDATE()
			) BETWEEN '121' AND '150' 
			THEN '5_121-150'
		WHEN a.[pa-acct-type] <> 1 
			AND DATEDIFF(
				DAY
				, COALESCE(
					b.[pa-unit-date]
					, a.[pa-dsch-date]
					, a.[pa-adm-date]
				)
				, GETDATE()
			) BETWEEN '151' AND '180' 
			THEN '6_151-180'
		WHEN a.[pa-acct-type] <> 1 
			AND DATEDIFF(
				DAY
				, COALESCE(
					b.[pa-unit-date]
					, a.[pa-dsch-date]
					, a.[pa-adm-date]
				)
				, GETDATE()
			) BETWEEN '181' AND '210' 
			THEN '7_181-210'
		WHEN a.[pa-acct-type] <> 1 
			AND DATEDIFF(
				DAY
				, COALESCE(
					b.[pa-unit-date]
					, a.[pa-dsch-date]
					, a.[pa-adm-date]
				)
				, GETDATE()
			) BETWEEN '211' AND '240' 
			THEN '8_211-240'
		WHEN a.[pa-acct-type] <> 1 
			AND DATEDIFF(
				DAY
				, COALESCE(
					b.[pa-unit-date]
					, a.[pa-dsch-date]
					, a.[pa-adm-date]
				)
				, GETDATE()
			) > '240' 
			THEN '9_240+'
		WHEN a.[pa-acct-type] = 1 
			THEN 'In House/DNFB'
		ELSE ''
	  END AS 'Age_Bucket'
	, a.[pa-acct-type] AS [PA_ACT_TYPE]
	, COALESCE(
		b.[pa-unit-op-first-ins-bl-date],
		a.[pa-final-bill-date],
		a.[pa-op-first-ins-bl-date]
		) AS [FIRST_BAL_DATE]
	, COALESCE(
		(
			b.[pa-unit-ins1-bal] + 
			b.[pa-unit-ins2-bal] + 
			b.[pa-unit-ins3-bal] + 
			b.[pa-unit-ins4-bal] + 
			b.[pa-unit-pt-bal]
		)
		, a.[pa-bal-acct-bal]
		) AS [Balance]
	, COALESCE(
		b.[pa-unit-pt-bal]
		, a.[pa-bal-pt-bal]
		) AS [Pt_Balance]
	, COALESCE(
		b.[pa-unit-tot-chg-amt]
		, a.[pa-bal-tot-chg-amt]
		) AS [TOTAL_CHARGES]
	, a.[pa-bal-tot-pt-pay-amt] AS [PA_BAL_TOT_PT_PAY_AMT]
	, CASE
		WHEN a.[pa-acct-type] IN ('0','6','7') 
			THEN 'OP' --0=OP; 6=OP BAD DEBT; 7=OP HISTORIC
		WHEN a.[pa-acct-type] IN ('1','2','4','8') 
			THEN 'IP'  --1=IP; 2=A/R; 4=I/P BAD DEBT; 8=I/P HISTORIC
		ELSE ''
	  END AS [PtAcct_Type]
	, CASE
		WHEN a.[pa-acct-type] IN ('6','4') 
			THEN 'Bad Debt'
		WHEN a.[pa-dsch-date] is not null 
			AND a.[pa-acct-type]='1' 
			THEN 'DNFB'
		WHEN a.[pa-acct-type] = '1' 
			THEN 'Inhouse'
		ELSE 'A/R'
	   END AS [PT_FILE_TYPE]
	, [pa-fc] AS [FC]
	, CASE
		WHEN [pa-fc]='1' THEN 'Bad Debt Medicaid Pending'
		WHEN [pa-fc] IN ('2','6') THEN 'Bad Debt AG'
		WHEN [pa-fc]='3' THEN 'MCS'
		WHEN [pa-fc]='4' THEN 'Bad Debt AG Legal'
		WHEN [pa-fc]='5' THEN 'Bad Debt POM'
		WHEN [pa-fc]='8' THEN 'Bad Debt AG Exchange Plans'
		WHEN [pa-fc]='9' THEN 'Kopp-Bad Debt'
		WHEN [pa-fc]='A' THEN 'Commercial'
		WHEN [pa-fc]='B' THEN 'Blue Cross'
		WHEN [pa-fc]='C' THEN 'Champus'
		WHEN [pa-fc]='D' THEN 'Medicaid'
		WHEN [pa-fc]='E' THEN 'Employee Health Svc'
		WHEN [pa-fc]='G' THEN 'Contract Accts'
		WHEN [pa-fc]='H' THEN 'Medicare HMO'
		WHEN [pa-fc]='I' THEN 'Balance After Ins'
		WHEN [pa-fc]='J' THEN 'Managed Care'
		WHEN [pa-fc]='K' THEN 'Pending Medicaid'
		WHEN [pa-fc]='M' THEN 'Medicare'
		WHEN [pa-fc]='N' THEN 'No-Fault'
		WHEN [pa-fc]='P' THEN 'Self Pay'
		WHEN [pa-fc]='R' THEN 'Aergo Commercial'
		WHEN [pa-fc]='T' THEN 'RTR WC NF'
		WHEN [pa-fc]='S' THEN 'Special Billing'
		WHEN [pa-fc]='U' THEN 'Medicaid Mgd Care'
		WHEN [pa-fc]='V' THEN 'First Source'
		WHEN [pa-fc]='W' THEN 'Workers Comp'
		WHEN [pa-fc]='X' THEN 'Control Accts'
		WHEN [pa-fc]='Y' THEN 'MCS'
		WHEN [pa-fc]='Z' THEN 'Unclaimed Credits'
		ELSE ''
	END AS [FC_Description]
	,  [pa-hosp-svc] AS [PA_HOSP_SVC]
	, ISNULL(HOSP_SVC.[hosp_desc], '') AS [Hosp_Svc_Desc]
	, a.[pa-acct-sub-type] AS [PA_ACCT_SUB_TYPE] --D=Discharged; I=In House
	, (c.[pa-ins-co-cd] + CAST(c.[pa-ins-plan-no] AS varchar)) AS [Ins1_Cd]
	, (d.[pa-ins-co-cd] + CAST(d.[pa-ins-plan-no] AS varchar)) AS [Ins2_Cd]
	, (e.[pa-ins-co-cd] + CAST(e.[pa-ins-plan-no] AS varchar)) AS [Ins3_Cd] 
	, (f.[pa-ins-co-cd] + CAST(f.[pa-ins-plan-no] AS varchar)) AS [Ins4_Cd]
	, a.[pa-disch-dx-cd] AS [DISCHARGE_DX]
	, a.[pa-disch-dx-cd-type] AS [DISCHARGE_DX_CD_TYPE]
	, a.[pa-disch-dx-date] AS [DISCHARGE_DX_DATE]
	, a.[PA-PROC-CD-TYPE(1)] AS [PA_PROC_CD_TYPE_1]
	, a.[PA-PROC-CD(1)] AS [PA_PROC_CD_1]
	, a.[PA-PROC-DATE(1)] AS [PA_PROC_CD_1_DATE]
	, a.[pa-proc-prty(1)] AS [PA_PROC_CD_1_PRTY]
	, a.[PA-PROC-CD-TYPE(2)] AS [PA_PROC_CD_TYPE_2]
	, a.[PA-PROC-CD(2)] AS [PA_PROC_CD_2]
	, a.[PA-PROC-DATE(2)] AS [PA_PROC_CD_2_DATE]
	, a.[pa-proc-prty(2)] AS [PA_PROC_CD_2_PRTY]
	, a.[PA-PROC-CD-TYPE(3)] AS [PA_PROC_CD_TYPE_3]
	, a.[PA-PROC-CD(3)] AS [PA_PROC_CD_3]
	, a.[PA-PROC-DATE(3)] AS [PA_PROC_CD_3_DATE]
	, a.[pa-proc-prty(3)] AS [PA_PROC_CD_3_PRTY]
	, c.[pa-bal-ins-pay-amt] AS [INS1_PAY_AMT]
	, d.[pa-bal-ins-pay-amt] AS [INS2_PAY_AMT]
	, e.[pa-bal-ins-pay-amt] AS [INS3_PAY_AMT]
	, f.[pa-bal-ins-pay-amt] AS [INS4_pAY_AMT]
	, c.[pa-last-ins-bl-date] AS [INS1_LAST_BILL_DATE]
	, d.[pa-last-ins-bl-date] AS [INS2_LAST_BILL_DATE]
	, e.[pa-last-ins-bl-date] AS [INS3_LAST_BILL_DATE]
	, f.[pa-last-ins-bl-date] AS [INS4_LAST_BILL_DATE]
	, (
		CAST(ISNULL(c.[pa-bal-ins-pay-amt],0) AS MONEY) + 
	    CAST(ISNULL(d.[pa-bal-ins-pay-amt],0) AS MONEY) + 
	    CAST(ISNULL(e.[pa-bal-ins-pay-amt],0) AS MONEY) + 
	    CAST(ISNULL(f.[pa-bal-ins-pay-amt],0) AS MONEY)
	) AS [TOTAL_INSURANCE_PAY_AMT]
	, (
		CAST(ISNULL(c.[pa-bal-ins-pay-amt],0) AS MONEY) + 
		CAST(ISNULL(d.[pa-bal-ins-pay-amt],0) AS MONEY) + 
		CAST(ISNULL(e.[pa-bal-ins-pay-amt],0) AS MONEY) + 
		CAST(ISNULL(f.[pa-bal-ins-pay-amt],0) AS MONEY) + 
		CAST(ISNULL(a.[pa-bal-tot-pt-pay-amt],0) AS MONEY)
	) AS [TOTAL_PAY_AMOUNT]
	, a.[pa-last-fc-cng-date] AS [PT_LAST_FC_CHANGE_DATE]
	, a.[pa-pt-representative] AS [Rep_Code]
	, a.[pa-resp-cd] AS [Resp_Code]
	, a.[pa-cr-rating] AS [Credit_Rating]
	, a.[pa-courtesy-allow] AS [PA_COURTESY_ALLOWANCE]
	, a.[pa-last-actv-date] AS [LAST_CHARGE_SVC_DATE]
	, a.[pa-last-pt-pay-date] AS [PA_LAST_PAY_DATE]
	, c.[pa-last-ins-pay-date] AS [PA_INS_LAST_PAY_DATE]
	, a.[pa-no-of-cwi] AS [NO_OF_CW_SEGMENTS]
	, a.[pa-pay-scale] AS [PA_PAY_SCALE]
	, a.[pa-stmt-cd] AS [PA_STMT_CD]
	, LastPaymentDates.[PA-BAL-INS-PAY-AMT] AS [Last_PA_BAL_INS_PAY_AMT]
	, LastPaymentDates.[PA-LAST-INS-PAY-DATE] AS [Last_PA_LAST_INS_PAY_DATE]
	, a.[pa-ctrct-amt] AS [PA_CONTRACT_AMT]
	, a.[PA-ACCT-BD-XFR-DATE] AS [PA_ACCT_BD_XFER_DATE]
	, CAST(GETDATE() AS DATE) AS [RUN_DATE]
	, GETDATE() AS [RUN_DATE_TIME]

	FROM [Echo_Active].dbo.PatientDemographics AS a 
	LEFT OUTER JOIN [Echo_Active].dbo.unitizedaccounts AS b
	ON a.[pa-pt-no-woscd] = b.[pa-pt-no-woscd] 
		AND a.[pa-pt-no-scd] = b.[pa-pt-no-scd-1] 
	LEFT OUTER JOIN [Echo_Active].dbo.insuranceinformation AS c
	ON a.[pa-pt-no-woscd] = c.[pa-pt-no-woscd] 
		AND c.[pa-ins-prty] = '1'
	LEFT OUTER JOIN [Echo_Active].dbo.insuranceinformation AS d
	ON a.[pa-pt-no-woscd] = d.[pa-pt-no-woscd] 
		AND d.[pa-ins-prty] = '2'
	LEFT OUTER JOIN [Echo_Active].dbo.insuranceinformation AS e
	ON a.[pa-pt-no-woscd] = e.[pa-pt-no-woscd] 
		AND e.[pa-ins-prty] = '3'
	LEFT OUTER JOIN [Echo_Active].dbo.insuranceinformation AS f
	ON a.[pa-pt-no-woscd] = f.[pa-pt-no-woscd] 
		AND f.[pa-ins-prty] = '4'
	LEFT OUTER JOIN [Echo_Active].dbo.diagnosisinformation g
	ON a.[pa-pt-no-woscd] = g.[pa-pt-no-woscd] 
		AND g.[pa-dx2-prio-no] = '1' 
		AND g.[pa-dx2-type1-type2-cd] = 'DF'
	LEFT OUTER JOIN [Echo_SBU_PA].[dbo].[hosp_svc_mstr] AS HOSP_SVC
	ON A.[PA-HOSP-SVC] = HOSP_SVC.HOSP_SVC
	LEFT OUTER JOIN (
		SELECT A.[PA-PT-NO-WOSCD]
		, A.[PA-PT-NO-SCD-1]
		, B.[PA-INS-PRTY]
		, (
			LTRIM(RTRIM(B.[pa-ins-co-cd])) + 
			CAST(LTRIM(RTRIM(B.[pa-ins-plan-no])) AS CHAR)
		) AS [PA-INS-PLAN]
		, B.[PA-LAST-INS-PAY-DATE]
		, B.[PA-BAL-INS-PAY-AMT]
		, RANK() OVER (PARTITION BY A.[PA-PT-NO-WOSCD] ORDER BY B.[PA-LAST-INS-PAY-DATE] DESC) AS [RANK1]

		FROM [Echo_Active].DBO.PATIENTDEMOGRAPHICS AS A 
		LEFT OUTER JOIN [Echo_Active].DBO.INSURANCEINFORMATION AS B
		ON A.[PA-PT-NO-WOSCD] = B.[PA-PT-NO-WOSCD]

		WHERE [PA-BAL-INS-PAY-AMT] <> '0'
	) AS LastPaymentDates
	ON A.[PA-PT-NO-WOSCD] = LastPaymentDates.[PA-PT-NO-WOSCD]
		AND A.[PA-PT-NO-SCD-1] = LastPaymentDates.[PA-PT-NO-SCD-1]
		AND LastPaymentDates.RANK1 = 1

	WHERE COALESCE(
		(
			b.[pa-unit-ins1-bal] + 
			b.[pa-unit-ins2-bal] + 
			b.[pa-unit-ins3-bal] + 
			b.[pa-unit-ins4-bal] + 
			b.[pa-unit-pt-bal]
		)
		, a.[pa-bal-acct-bal]
	) <> '0'
	AND COALESCE(
		b.[pa-unit-tot-chg-amt]
		, a.[pa-bal-tot-chg-amt]
	) <> '0'
	AND (
		c.[pa-ins-co-cd] = 'O' 
		OR 
		d.[pa-ins-co-cd] = 'O' 
		OR 
		e.[pa-ins-co-cd] = 'O'
	)
	AND (
		c.[pa-ins-plan-no] = '29'
		OR 
		d.[pa-ins-plan-no] = '29'
		OR 
		e.[pa-ins-plan-no] = '29'
	)
	AND b.[pa-unit-no] IS NOT NULL
	;

END
;
