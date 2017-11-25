USE [Echo_SBU_PA]
GO

/****** Object:  View [dbo].[PtAcct_v]    Script Date: 11/24/2017 7:33:11 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

ALTER VIEW [dbo].[PtAcct_v] AS 

SELECT CAST(a.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(a.[PA-PT-NO-SCD] AS VARCHAR) AS [Pt_No]
, b.[PA-UNIT-NO]
, a.[pa-med-rec-no] AS [MRN]
, a.[pa-pt-name]
, COALESCE(DATEADD(DAY,1,EOMONTH(b.[pa-unit-date],-1)),[pa-adm-date]) AS [Admit_Date]
, CASE 
	WHEN a.[pa-acct-type] <> 1 
		THEN COALESCE(
			b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]
		)
		ELSE a.[pa-dsch-date]
  END AS [Dsch_Date]
, b.[pa-unit-date]
, CASE 
	WHEN a.[pa-acct-type] <> '1' 
		THEN DATEDIFF(DAY,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),GETDATE())
		ELSE ''
  END AS [Age_From_Discharge]
, CASE
	WHEN a.[pa-acct-type]<> 1 
		AND DATEDIFF(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),getdate()) between '0' AND '30' 
		THEN '1_0-30'
	WHEN a.[pa-acct-type]<> 1 
		AND DATEDIFF(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),getdate()) between '31' AND '60' 
		THEN '2_31-60'
	WHEN a.[pa-acct-type]<> 1 
		AND DATEDIFF(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),getdate()) between '61' AND '90' 
		THEN '3_61-90'
	WHEN a.[pa-acct-type]<> 1 
		AND DATEDIFF(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),getdate()) between '91' AND '120' 
		THEN '4_91-120'
	WHEN a.[pa-acct-type]<> 1 
		AND DATEDIFF(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),getdate()) between '121' AND '150' 
		THEN '5_121-150'
	WHEN a.[pa-acct-type]<> 1 
		AND DATEDIFF(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),getdate()) between '151' AND '180' 
		THEN '6_151-180'
	WHEN a.[pa-acct-type]<> 1 
		AND DATEDIFF(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),getdate()) between '181' AND '210' 
		THEN '7_181-210'
	WHEN a.[pa-acct-type]<> 1 
		AND DATEDIFF(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),getdate()) between '211' AND '240' 
		THEN '8_211-240'
	WHEN a.[pa-acct-type]<> 1 
		AND DATEDIFF(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),getdate()) > '240' 
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
		b.[pa-unit-ins4-bal] + b.[pa-unit-pt-bal]
	)
	,a.[pa-bal-acct-bal]
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
	WHEN a.[pa-acct-type] in ('0','6','7') 
		THEN 'OP' --0=OP; 6=OP BAD DEBT; 7=OP HISTORIC
	WHEN a.[pa-acct-type] in ('1','2','4','8') 
		THEN 'IP'  --1=IP; 2=A/R; 4=I/P BAD DEBT; 8=I/P HISTORIC
	ELSE ''
  END AS 'PtAcct_Type'
, CASE
	WHEN a.[pa-acct-type] in ('6','4') 
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
	WHEN [pa-fc] in ('2','6') THEN 'Bad Debt AG'
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
, (c.[pa-ins-co-cd] + CAST(c.[pa-ins-plan-no] AS VARCHAR)) AS 'Ins1_Cd'
, (d.[pa-ins-co-cd] + CAST(d.[pa-ins-plan-no] AS VARCHAR)) AS 'Ins2_Cd'
, (e.[pa-ins-co-cd] + CAST(e.[pa-ins-plan-no] AS VARCHAR)) AS 'Ins3_Cd' 
, (f.[pa-ins-co-cd] + CAST(f.[pa-ins-plan-no] AS VARCHAR)) AS 'Ins4_Cd'
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
, (CAST(ISNULL(c.[pa-bal-ins-pay-amt],0) AS money) + CAST(ISNULL(d.[pa-bal-ins-pay-amt],0) AS money) + CAST(ISNULL(e.[pa-bal-ins-pay-amt],0) AS money) + CAST(ISNULL(f.[pa-bal-ins-pay-amt],0) AS money)) AS 'Ins_Pay_Amt'
, (CAST(ISNULL(c.[pa-bal-ins-pay-amt],0) AS money) + CAST(ISNULL(d.[pa-bal-ins-pay-amt],0) AS money) + CAST(ISNULL(e.[pa-bal-ins-pay-amt],0) AS money) + CAST(ISNULL(f.[pa-bal-ins-pay-amt],0) AS money))+ CAST(ISNULL(a.[pa-bal-tot-pt-pay-amt],0) AS money) AS 'Tot_Pay_Amt'
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
	, (LTRIM(RTRIM(B.[pa-ins-co-cd])) + CAST(LTRIM(RTRIM(B.[pa-ins-plan-no])) AS char)) AS [PA-INS-PLAN]
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
	,a.[pa-bal-acct-bal]
) <> '0'
AND COALESCE(b.[pa-unit-tot-chg-amt],a.[pa-bal-tot-chg-amt]) <> '0'
AND (
	c.[pa-ins-co-cd] = 'O' 
	or 
	d.[pa-ins-co-cd] = 'O' 
	or 
	e.[pa-ins-co-cd] = 'O'
)
AND (
	c.[pa-ins-plan-no] = '29'
	or 
	d.[pa-ins-plan-no] = '29'
	or 
	e.[pa-ins-plan-no] = '29'
)
AND b.[pa-unit-no] IS NOT NULL
;
GO


