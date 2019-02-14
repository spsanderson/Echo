USE [DSH]

/*
Encounters_For_DSH
*/

DROP TABLE IF EXISTS dbo.[#DSH_Units]
GO

CREATE TABLE [#DSH_Units] (
	[PA-PT-NO-WOSCD] DECIMAL(11,0) NOT NULL,
	[PA-PT-NO-SCD] CHAR(1) NOT NULL,
	[UNIT-DATE] DATETIME NULL,
	[pa-unit-no] char(4) null
);

INSERT INTO [#DSH_Units] (
	[PA-PT-NO-WOSCD]
	, [PA-PT-NO-SCD]
	, [UNIT-DATE]
	, [pa-unit-no]
)

SELECT A.[PA-PT-NO-woscd]
, A.[pa-pt-no-scd-1]
, b.[PA-UNIT-DATE]
, b.[PA-UNIT-NO]
--,RANK() OVER (PARTITION BY [pa-pt-no] ORDER BY [unit-date] asc) as 'alt-pa-unit-no'

FROM [Echo_ACTIVE].dbo.PatientDemographics as a 
left outer join [Echo_ACTIVE].dbo.unitizedaccounts as b
ON a.[pa-pt-no-woscd] = b.[pa-pt-no-woscd] 
and a.[pa-pt-no-scd] = b.[pa-pt-no-scd-1]

WHERE a.[pa-acct-type] in ('0','6','7') 
AND b.[pa-unit-no] is not null 
and b.[pa-unit-date] BETWEEN '2016-01-01 00:00:00.000' AND '2016-12-31 23:59:59.000'

UNION

SELECT A.[PA-PT-NO-woscd]
, A.[pa-pt-no-scd-1]
, b.[PA-UNIT-DATE]
, b.[PA-UNIT-NO]
--,RANK() OVER (PARTITION BY [pa-pt-no] ORDER BY [unit-date] asc) as 'alt-pa-unit-no'

FROM [Echo_ARCHIVE].dbo.PatientDemographics as a 
left outer join [Echo_ARCHIVE].dbo.unitizedaccounts as b
ON a.[pa-pt-no-woscd] = b.[pa-pt-no-woscd] 
and a.[pa-pt-no-scd] = b.[pa-pt-no-scd-1]

WHERE a.[pa-acct-type] in ('0','6','7') 
AND b.[pa-unit-no] is not null 
and b.[pa-unit-date] BETWEEN '2016-01-01 00:00:00.000' AND '2016-12-31 23:59:59.000')

 

-----------------------------------------------------------------------

DROP TABLE IF EXISTS dbo.[#DSH_Units_W_Rank]
GO

CREATE TABLE [#DSH_Units_W_Rank] (
	[PA-PT-NO-WOSCD] DECIMAL(11,0) NOT NULL,
	[PA-PT-NO-SCD] CHAR(1) NOT NULL,
	[UNIT-DATE] DATETIME NULL,
	[pa-unit-no] char(4) null,
	[alt-pa-unit-no] char(5) null
);

INSERT INTO [#DSH_Units_W_Rank] (
	[PA-PT-NO-WOSCD]
	, [PA-PT-NO-SCD]
	, [UNIT-DATE]
	, [pa-unit-no]
	, [alt-pa-unit-no]
)

SELECT [PA-PT-NO-woscd]
, [pa-pt-no-scd]
, [UNIT-DATE]
, [PA-UNIT-NO]
, RANK() OVER (PARTITION BY [pa-pt-no-woscd] ORDER BY [unit-date] asc) as 'alt-pa-unit-no'

FROM dbo.[#DSH_Units]

-----------------------------------------------------------------------

USE [DSH]

DROP TABLE IF EXISTS [DSH_Unit_Partitions]
GO

SELECT a.[pa-pt-no-woscd]
, a.[pa-pt-no-scd]
, isnull(
	DATEADD(DAY, 1, b.[unit-date])
	, DATEADD(DAY,1,EOMONTH(a.[unit-date],-1))
) as 'Start_Unit_Date'
, DATEADD(DAY,0,a.[unit-date]) as 'End_Unit_Date'
, a.[pa-unit-no]

INTO [DSH_Unit_Partitions]

FROM [dbo].[#DSH_Units_W_Rank] as a 
left outer join [dbo].[#DSH_Units_W_Rank] as b
ON a.[pa-pt-no-woscd] = b.[pa-pt-no-woscd] 
	and b.[alt-pa-unit-no] = a.[alt-pa-unit-no]-1

-----------------------------------------------------------------------

/*

Create Table of 2016 Encounters for DSH Reporting

*/

DROP TABLE IF EXISTS Encounters_For_DSH
GO

/*
Add Table
*/

CREATE TABLE [Encounters_For_DSH] (
	[PA-PT-NO-WOSCD] DECIMAL(11,0) NOT NULL,
	[PA-PT-NO-SCD] CHAR(1) NOT NULL,
	[PA-CTL-PAA-XFER-DATE] DATETIME NULL,
	[pa-unit-no] decimal(4,0) NULL,
	[pa-med-rec-no] char(12) null,
	[pa-pt-name] char(25) null,
	[admit_date] datetime null,
	[dsch_date] datetime null,
	[pa-unit-date] datetime null,
	[start_unit_date] datetime null,
	[end_unit_date] datetime null,
	[pa-acct-type] char(1) null,
	[1st_bl_date] datetime null,
	[balance] money null,
	[pt_balance] money null,
	[tot_chgs] money null,
	[pa-bal-tot-pt-pay-amt] money null,
	[ptacct_type] char(3) null,
	[pa-fc] char(1) null,
	[fc_description] char(50) null,
	[pa-hosp-svc] char(3) null,
	[pa-acct-sub-type] char(1) null
	--[pa-nad-first-or-orgz-cntc] char(30) null,
	--[pa-nad-last-or-orgz-name] char(40) null
)

INSERT INTO Encounters_For_DSH (
	[PA-PT-NO-WOSCD]
	, [PA-PT-NO-SCD]
	, [PA-CTL-PAA-XFER-DATE]
	, [pa-unit-no]
	, [pa-med-rec-no]
	, [pa-pt-name]
	, [admit_date]
	, [dsch_date]
	, [pa-unit-date]
	, [start_unit_date]
	, [end_unit_date]
	, [pa-acct-type]
	, [1st_bl_date]
	, [balance]
	, [pt_balance]
	, [tot_chgs]
	, [pa-bal-tot-pt-pay-amt]
	, [ptacct_type]
	, [pa-fc]
	, [fc_description]
	, [pa-hosp-svc]
	, [pa-acct-sub-type]
)--,[pa-nad-first-or-orgz-cntc],[pa-nad-last-or-orgz-name])

SELECT a.[PA-PT-NO-WOSCD]
,a.[PA-PT-NO-SCD]
,A.[PA-CTL-PAA-XFER-DATE]
,b.[PA-UNIT-NO]
,a.[pa-med-rec-no]
,a.[pa-pt-name]
,COALESCE(DATEADD(DAY,1,EOMONTH(b.[pa-unit-date],-1)),a.[pa-adm-date]) as 'Admit_Date'
,CASE WHEN a.[pa-acct-type]<> 1 THEN COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date])
ELSE a.[pa-dsch-date]
END as 'Dsch_Date'
,b.[pa-unit-date]
,m.[start_unit_date]
,m.[end_unit_date]
,a.[pa-acct-type]
,COALESCE(b.[pa-unit-op-first-ins-bl-date],a.[pa-final-bill-date],a.[pa-op-first-ins-bl-date]) as '1st_Bl_Date'
,COALESCE((b.[pa-unit-ins1-bal] + b.[pa-unit-ins2-bal] + b.[pa-unit-ins3-bal]+b.[pa-unit-ins4-bal]+b.[pa-unit-pt-bal]),a.[pa-bal-acct-bal]) as 'Balance'
,COALESCE(b.[pa-unit-pt-bal],a.[pa-bal-pt-bal]) as 'Pt_Balance'
,COALESCE(b.[pa-unit-tot-chg-amt],a.[pa-bal-tot-chg-amt]) as 'Tot_Chgs'
,a.[pa-bal-tot-pt-pay-amt]
,CASE
	WHEN a.[pa-acct-type] in ('0','6','7') 
		THEN 'OP' --0=OP; 6=OP BAD DEBT; 7=OP HISTORIC
	WHEN a.[pa-acct-type] in ('1','2','4','8') 
		THEN 'IP'  --1=IP; 2=A/R; 4=I/P BAD DEBT; 8=I/P HISTORIC
	ELSE ''
END AS 'PtAcct_Type'
,a.[pa-fc] as 'FC'
,CASE
	WHEN a.[pa-fc]='1' THEN 'Bad Debt Medicaid Pending'
	WHEN a.[pa-fc] in ('2','6') THEN 'Bad Debt AG'
	WHEN a.[pa-fc]='3' THEN 'MCS'
	WHEN a.[pa-fc]='4' THEN 'Bad Debt AG Legal'
	WHEN a.[pa-fc]='5' THEN 'Bad Debt POM'
	WHEN a.[pa-fc]='8' THEN 'Bad Debt AG Exchange Plans'
	WHEN a.[pa-fc]='9' THEN 'Kopp-Bad Debt'
	WHEN a.[pa-fc]='A' THEN 'Commercial'
	WHEN a.[pa-fc]='B' THEN 'Blue Cross'
	WHEN a.[pa-fc]='C' THEN 'Champus'
	WHEN a.[pa-fc]='D' THEN 'Medicaid'
	WHEN a.[pa-fc]='E' THEN 'Employee Health Svc'
	WHEN a.[pa-fc]='G' THEN 'Contract Accts'
	WHEN a.[pa-fc]='H' THEN 'Medicare HMO'
	WHEN a.[pa-fc]='I' THEN 'Balance After Ins'
	WHEN a.[pa-fc]='J' THEN 'Managed Care'
	WHEN a.[pa-fc]='K' THEN 'Pending Medicaid'
	WHEN a.[pa-fc]='M' THEN 'Medicare'
	WHEN a.[pa-fc]='N' THEN 'No-Fault'
	WHEN a.[pa-fc]='P' THEN 'Self Pay'
	WHEN a.[pa-fc]='R' THEN 'Aergo Commercial'
	WHEN a.[pa-fc]='T' THEN 'RTR WC NF'
	WHEN a.[pa-fc]='S' THEN 'Special Billing'
	WHEN a.[pa-fc]='U' THEN 'Medicaid Mgd Care'
	WHEN a.[pa-fc]='V' THEN 'First Source'
	WHEN a.[pa-fc]='W' THEN 'Workers Comp'
	WHEN a.[pa-fc]='X' THEN 'Control Accts'
	WHEN a.[pa-fc]='Y' THEN 'MCS'
	WHEN a.[pa-fc]='Z' THEN 'Unclaimed Credits'
	ELSE ''
END as 'FC_Description'
,a.[pa-hosp-svc]
,a.[pa-acct-sub-type]  --D=Discharged; I=In House
--k.[pa-nad-first-or-orgz-cntc],
--k.[pa-nad-last-or-orgz-name]

FROM [Echo_Archive].dbo.PatientDemographics as a 
left outer join [Echo_Archive].dbo.unitizedaccounts as b
ON a.[pa-pt-no-woscd] = b.[pa-pt-no-woscd] 
	and a.[pa-pt-no-scd] = b.[pa-pt-no-scd-1]
LEFT OUTER JOIN [DSH_Unit_Partitions] as m
ON a.[pa-pt-no-woscd] = m.[pa-pt-no-woscd] 
	and b.[pa-unit-no] = m.[pa-unit-no]
left outer join [Echo_Archive].dbo.diagnosisinformation as g
ON a.[pa-pt-no-woscd] = g.[pa-pt-no-woscd] 
	and g.[pa-dx2-prio-no] = '1' 
	and g.[pa-dx2-type1-type2-cd] = 'DF'
--left outer join dbo.[#LastPaymentDates] j
--ON a.[pa-pt-no-woscd]=j.[pa-pt-no-woscd] and j.[rank1]='1'
--left outer join [Echo_Archive].dbo.[NADInformation] k
--ON a.[pa-pt-no-woscd]=k.[pa-pt-no-woscd] and k.[pa-nad-cd]='PTGAR'
left outer join [Echo_Archive].dbo.PatientDemographics as l
ON a.[pa-pt-no-woscd] = l.[pa-pt-no-woscd]

WHERE (
	(
		a.[pa-acct-type] in ('2','4','8') 
		and a.[pa-dsch-date] BETWEEN '2016-01-01 00:00:00.000' AND '2016-12-31 23:59:59.000'
	)
	OR 
	(
		a.[pa-acct-type] in ('0','6','7') 
		AND b.[pa-unit-no] is not null 
		and b.[pa-unit-date] BETWEEN '2016-01-01 00:00:00.000' AND '2016-12-31 23:59:59.000'
	)
	OR 
	(
		a.[pa-acct-type] in ('0','6','7') 
		and b.[pa-unit-no] is null 
		and a.[pa-adm-date] BETWEEN '2016-01-01 00:00:00.000' AND '2016-12-31 23:59:59.000'
	)
)
AND COALESCE(b.[pa-unit-tot-chg-amt], a.[pa-bal-tot-chg-amt]) <> '0'
AND a.[pa-acct-sub-type] <> 'P'

UNION

SELECT a.[PA-PT-NO-WOSCD]
,a.[PA-PT-NO-SCD]
,A.[PA-CTL-PAA-XFER-DATE]
,b.[PA-UNIT-NO]
,a.[pa-med-rec-no]
,a.[pa-pt-name]
,COALESCE(DATEADD(DAY,1,EOMONTH(b.[pa-unit-date],-1)),a.[pa-adm-date]) as 'Admit_Date'
,CASE 
	WHEN a.[pa-acct-type]<> 1 
		THEN COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date])
		ELSE a.[pa-dsch-date]
END as 'Dsch_Date'
,b.[pa-unit-date]
,m.[start_unit_date]
,m.[end_unit_date]
,a.[pa-acct-type]
,COALESCE(b.[pa-unit-op-first-ins-bl-date],a.[pa-final-bill-date],a.[pa-op-first-ins-bl-date]) as '1st_Bl_Date'
,COALESCE((b.[pa-unit-ins1-bal] + b.[pa-unit-ins2-bal] + b.[pa-unit-ins3-bal]+b.[pa-unit-ins4-bal]+b.[pa-unit-pt-bal]),a.[pa-bal-acct-bal]) as 'Balance'
,COALESCE(b.[pa-unit-pt-bal],a.[pa-bal-pt-bal]) as 'Pt_Balance'
,COALESCE(b.[pa-unit-tot-chg-amt],a.[pa-bal-tot-chg-amt]) as 'Tot_Chgs'
,a.[pa-bal-tot-pt-pay-amt]
,CASE
	WHEN a.[pa-acct-type] in ('0','6','7') THEN 'OP' --0=OP; 6=OP BAD DEBT; 7=OP HISTORIC
	WHEN a.[pa-acct-type] in ('1','2','4','8') THEN 'IP'  --1=IP; 2=A/R; 4=I/P BAD DEBT; 8=I/P HISTORIC
	ELSE ''
END AS 'PtAcct_Type'
,a.[pa-fc] as 'FC'
,CASE
	WHEN a.[pa-fc]='1' THEN 'Bad Debt Medicaid Pending'
	WHEN a.[pa-fc] in ('2','6') THEN 'Bad Debt AG'
	WHEN a.[pa-fc]='3' THEN 'MCS'
	WHEN a.[pa-fc]='4' THEN 'Bad Debt AG Legal'
	WHEN a.[pa-fc]='5' THEN 'Bad Debt POM'
	WHEN a.[pa-fc]='8' THEN 'Bad Debt AG Exchange Plans'
	WHEN a.[pa-fc]='9' THEN 'Kopp-Bad Debt'
	WHEN a.[pa-fc]='A' THEN 'Commercial'
	WHEN a.[pa-fc]='B' THEN 'Blue Cross'
	WHEN a.[pa-fc]='C' THEN 'Champus'
	WHEN a.[pa-fc]='D' THEN 'Medicaid'
	WHEN a.[pa-fc]='E' THEN 'Employee Health Svc'
	WHEN a.[pa-fc]='G' THEN 'Contract Accts'
	WHEN a.[pa-fc]='H' THEN 'Medicare HMO'
	WHEN a.[pa-fc]='I' THEN 'Balance After Ins'
	WHEN a.[pa-fc]='J' THEN 'Managed Care'
	WHEN a.[pa-fc]='K' THEN 'Pending Medicaid'
	WHEN a.[pa-fc]='M' THEN 'Medicare'
	WHEN a.[pa-fc]='N' THEN 'No-Fault'
	WHEN a.[pa-fc]='P' THEN 'Self Pay'
	WHEN a.[pa-fc]='R' THEN 'Aergo Commercial'
	WHEN a.[pa-fc]='T' THEN 'RTR WC NF'
	WHEN a.[pa-fc]='S' THEN 'Special Billing'
	WHEN a.[pa-fc]='U' THEN 'Medicaid Mgd Care'
	WHEN a.[pa-fc]='V' THEN 'First Source'
	WHEN a.[pa-fc]='W' THEN 'Workers Comp'
	WHEN a.[pa-fc]='X' THEN 'Control Accts'
	WHEN a.[pa-fc]='Y' THEN 'MCS'
	WHEN a.[pa-fc]='Z' THEN 'Unclaimed Credits'
	ELSE ''
END as 'FC_Description'
,a.[pa-hosp-svc]
,a.[pa-acct-sub-type]  --D=Discharged; I=In House
--k.[pa-nad-first-or-orgz-cntc],
--k.[pa-nad-last-or-orgz-name]

FROM [Echo_ACTIVE].dbo.PatientDemographics as a 
left outer join [Echo_ACTIVE].dbo.unitizedaccounts as b
ON a.[pa-pt-no-woscd] = b.[pa-pt-no-woscd] 
	and a.[pa-pt-no-scd] = b.[pa-pt-no-scd-1]
left outer join [DSH_Unit_Partitions] as m
ON a.[pa-pt-no-woscd] = m.[pa-pt-no-woscd] 
	and b.[pa-unit-no]=m.[pa-unit-no]
left outer join [Echo_ACTIVE].dbo.diagnosisinformation as g
ON a.[pa-pt-no-woscd] = g.[pa-pt-no-woscd] 
	and g.[pa-dx2-prio-no] = '1' 
	and g.[pa-dx2-type1-type2-cd]='DF'
--left outer join dbo.[#LastPaymentDates] j
--ON a.[pa-pt-no-woscd]=j.[pa-pt-no-woscd] and j.[rank1]='1'
--left outer join [Echo_ACTIVE].dbo.[NADInformation] k
--ON a.[pa-pt-no-woscd]=k.[pa-pt-no-woscd] and k.[pa-nad-cd]='PTGAR'
left outer join [Echo_ACTIVE].dbo.PatientDemographics l
ON a.[pa-pt-no-woscd]=l.[pa-pt-no-woscd]

WHERE (
	(
		a.[pa-acct-type] in ('2','4','8') 
		and a.[pa-dsch-date] BETWEEN '2016-01-01 00:00:00.000' AND '2016-12-31 23:59:59.000'
	)
	OR 
	(
		a.[pa-acct-type] in ('0','6','7') 
		AND b.[pa-unit-no] is not null 
		and b.[pa-unit-date] BETWEEN '2016-01-01 00:00:00.000' AND '2016-12-31 23:59:59.000'
	)
	OR 
	(
		a.[pa-acct-type] in ('0','6','7') 
		and b.[pa-unit-no] is null 
		and a.[pa-adm-date] BETWEEN '2016-01-01 00:00:00.000' AND '2016-12-31 23:59:59.000'
	)
)
AND COALESCE(b.[pa-unit-tot-chg-amt],a.[pa-bal-tot-chg-amt]) <> '0'
AND a.[pa-acct-sub-type] <> 'P'