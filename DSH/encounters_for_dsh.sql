USE [DSH]

DROP TABLE IF EXISTS dbo.[#DSH_Units] GO
	CREATE TABLE [#DSH_Units] (
		[PA-PT-NO-WOSCD] DECIMAL(11, 0) NOT NULL,
		[PA-PT-NO-SCD] CHAR(1) NOT NULL,
		[UNIT-DATE] DATETIME NULL,
		[pa-unit-no] CHAR(4) NULL
		);

INSERT INTO [#DSH_Units] (
	[PA-PT-NO-WOSCD],
	[PA-PT-NO-SCD],
	[UNIT-DATE],
	[pa-unit-no]
	)
SELECT A.[PA-PT-NO-woscd],
	A.[pa-pt-no-scd-1],
	b.[PA-UNIT-DATE],
	b.[PA-UNIT-NO]
--,RANK() OVER (PARTITION BY [pa-pt-no] ORDER BY [unit-date] asc) as 'alt-pa-unit-no'
FROM [Echo_ACTIVE].dbo.PatientDemographics a
LEFT OUTER JOIN [Echo_ACTIVE].dbo.unitizedaccounts b ON a.[pa-pt-no-woscd] = b.[pa-pt-no-woscd]
	AND a.[pa-pt-no-scd] = b.[pa-pt-no-scd-1]
WHERE (
		a.[pa-acct-type] IN ('0', '6', '7')
		AND b.[pa-unit-no] IS NOT NULL
		AND b.[pa-unit-date] BETWEEN '2016-01-01 00:00:00.000'
			AND '2016-12-31 23:59:59.000'
		)

UNION

SELECT A.[PA-PT-NO-woscd],
	A.[pa-pt-no-scd-1],
	b.[PA-UNIT-DATE],
	b.[PA-UNIT-NO]
--,RANK() OVER (PARTITION BY [pa-pt-no] ORDER BY [unit-date] asc) as 'alt-pa-unit-no'
FROM [Echo_ARCHIVE].dbo.PatientDemographics a
LEFT OUTER JOIN [Echo_ARCHIVE].dbo.unitizedaccounts b ON a.[pa-pt-no-woscd] = b.[pa-pt-no-woscd]
	AND a.[pa-pt-no-scd] = b.[pa-pt-no-scd-1]
WHERE (
		a.[pa-acct-type] IN ('0', '6', '7')
		AND b.[pa-unit-no] IS NOT NULL
		AND b.[pa-unit-date] BETWEEN '2016-01-01 00:00:00.000'
			AND '2016-12-31 23:59:59.000'
		)

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
DROP TABLE IF EXISTS dbo.[#DSH_Units_W_Rank] GO
	CREATE TABLE [#DSH_Units_W_Rank] (
		[PA-PT-NO-WOSCD] DECIMAL(11, 0) NOT NULL,
		[PA-PT-NO-SCD] CHAR(1) NOT NULL,
		[UNIT-DATE] DATETIME NULL,
		[pa-unit-no] CHAR(4) NULL,
		[alt-pa-unit-no] CHAR(5) NULL
		);

INSERT INTO [#DSH_Units_W_Rank] (
	[PA-PT-NO-WOSCD],
	[PA-PT-NO-SCD],
	[UNIT-DATE],
	[pa-unit-no],
	[alt-pa-unit-no]
	)
SELECT [PA-PT-NO-woscd],
	[pa-pt-no-scd],
	[UNIT-DATE],
	[PA-UNIT-NO],
	RANK() OVER (
		PARTITION BY [pa-pt-no-woscd] ORDER BY [unit-date] ASC
		) AS 'alt-pa-unit-no'
FROM dbo.[#DSH_Units]

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
USE [DSH]

DROP TABLE IF EXISTS [DSH_Unit_Partitions] GO
	SELECT a.[pa-pt-no-woscd],
		a.[pa-pt-no-scd],
		isnull(DATEADD(DAY, 1, b.[unit-date]), DATEADD(DAY, 1, EOMONTH(a.[unit-date], - 1))) AS 'Start_Unit_Date',
		DATEADD(DAY, 0, a.[unit-date]) AS 'End_Unit_Date',
		a.[pa-unit-no]
	INTO [DSH_Unit_Partitions]
	FROM [dbo].[#DSH_Units_W_Rank] a
	LEFT OUTER JOIN [dbo].[#DSH_Units_W_Rank] b ON a.[pa-pt-no-woscd] = b.[pa-pt-no-woscd]
		AND b.[alt-pa-unit-no] = a.[alt-pa-unit-no] - 1

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*Create Table of 2016 Encounters for DSH Reporting*/
DROP TABLE IF EXISTS Encounters_For_DSH GO
	/*Add Table*/
	CREATE TABLE [Encounters_For_DSH] (
		[PA-PT-NO-WOSCD] DECIMAL(11, 0) NOT NULL,
		[PA-PT-NO-SCD] CHAR(1) NOT NULL,
		[PA-CTL-PAA-XFER-DATE] DATETIME NULL,
		[pa-unit-no] DECIMAL(4, 0) NULL,
		[pa-med-rec-no] CHAR(12) NULL,
		[pa-pt-name] CHAR(25) NULL,
		[admit_date] DATETIME NULL,
		[dsch_date] DATETIME NULL,
		[pa-unit-date] DATETIME NULL,
		[start_unit_date] DATETIME NULL,
		[end_unit_date] DATETIME NULL,
		[pa-acct-type] CHAR(1) NULL,
		[1st_bl_date] DATETIME NULL,
		[balance] MONEY NULL,
		[pt_balance] MONEY NULL,
		[tot_chgs] MONEY NULL,
		[pa-bal-tot-pt-pay-amt] MONEY NULL,
		[ptacct_type] CHAR(3) NULL,
		[pa-fc] CHAR(1) NULL,
		[fc_description] CHAR(50) NULL,
		[pa-hosp-svc] CHAR(3) NULL,
		[pa-acct-sub-type] CHAR(1) NULL
		)

--[pa-nad-first-or-orgz-cntc] char(30) null,
--[pa-nad-last-or-orgz-name] char(40) null
INSERT INTO Encounters_For_DSH (
	[PA-PT-NO-WOSCD],
	[PA-PT-NO-SCD],
	[PA-CTL-PAA-XFER-DATE],
	[pa-unit-no],
	[pa-med-rec-no],
	[pa-pt-name],
	[admit_date],
	[dsch_date],
	[pa-unit-date],
	[start_unit_date],
	[end_unit_date],
	[pa-acct-type],
	[1st_bl_date],
	[balance],
	[pt_balance],
	[tot_chgs],
	[pa-bal-tot-pt-pay-amt],
	[ptacct_type],
	[pa-fc],
	[fc_description],
	[pa-hosp-svc],
	[pa-acct-sub-type]
	) --,[pa-nad-first-or-orgz-cntc],[pa-nad-last-or-orgz-name])
SELECT a.[PA-PT-NO-WOSCD],
	a.[PA-PT-NO-SCD],
	A.[PA-CTL-PAA-XFER-DATE],
	b.[PA-UNIT-NO],
	a.[pa-med-rec-no],
	a.[pa-pt-name],
	COALESCE(DATEADD(DAY, 1, EOMONTH(b.[pa-unit-date], - 1)), a.[pa-adm-date]) AS 'Admit_Date',
	CASE 
		WHEN a.[pa-acct-type] <> 1
			THEN COALESCE(b.[pa-unit-date], a.[pa-dsch-date], a.[pa-adm-date])
		ELSE a.[pa-dsch-date]
		END AS 'Dsch_Date',
	b.[pa-unit-date],
	m.[start_unit_date],
	m.[end_unit_date],
	a.[pa-acct-type],
	COALESCE(b.[pa-unit-op-first-ins-bl-date], a.[pa-final-bill-date], a.[pa-op-first-ins-bl-date]) AS '1st_Bl_Date',
	COALESCE((b.[pa-unit-ins1-bal] + b.[pa-unit-ins2-bal] + b.[pa-unit-ins3-bal] + b.[pa-unit-ins4-bal] + b.[pa-unit-pt-bal]), a.[pa-bal-acct-bal]) AS 'Balance',
	COALESCE(b.[pa-unit-pt-bal], a.[pa-bal-pt-bal]) AS 'Pt_Balance',
	COALESCE(b.[pa-unit-tot-chg-amt], a.[pa-bal-tot-chg-amt]) AS 'Tot_Chgs',
	a.[pa-bal-tot-pt-pay-amt],
	CASE 
		WHEN a.[pa-acct-type] IN ('0', '6', '7')
			THEN 'OP' --0=OP; 6=OP BAD DEBT; 7=OP HISTORIC
		WHEN a.[pa-acct-type] IN ('1', '2', '4', '8')
			THEN 'IP' --1=IP; 2=A/R; 4=I/P BAD DEBT; 8=I/P HISTORIC
		ELSE ''
		END AS 'PtAcct_Type',
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
	a.[pa-hosp-svc],
	a.[pa-acct-sub-type] --D=Discharged; I=In House
	--k.[pa-nad-first-or-orgz-cntc],
	--k.[pa-nad-last-or-orgz-name]
FROM [Echo_Archive].dbo.PatientDemographics a
LEFT OUTER JOIN [Echo_Archive].dbo.unitizedaccounts b ON a.[pa-pt-no-woscd] = b.[pa-pt-no-woscd]
	AND a.[pa-pt-no-scd] = b.[pa-pt-no-scd-1]
LEFT OUTER JOIN [DSH_Unit_Partitions] m ON a.[pa-pt-no-woscd] = m.[pa-pt-no-woscd]
	AND b.[pa-unit-no] = m.[pa-unit-no]
LEFT OUTER JOIN [Echo_Archive].dbo.diagnosisinformation g ON a.[pa-pt-no-woscd] = g.[pa-pt-no-woscd]
	AND g.[pa-dx2-prio-no] = '1'
	AND g.[pa-dx2-type1-type2-cd] = 'DF'
--left outer join dbo.[#LastPaymentDates] j
--ON a.[pa-pt-no-woscd]=j.[pa-pt-no-woscd] and j.[rank1]='1'
--left outer join [Echo_Archive].dbo.[NADInformation] k
--ON a.[pa-pt-no-woscd]=k.[pa-pt-no-woscd] and k.[pa-nad-cd]='PTGAR'
LEFT OUTER JOIN [Echo_Archive].dbo.PatientDemographics l ON a.[pa-pt-no-woscd] = l.[pa-pt-no-woscd]
WHERE (
		(
			a.[pa-acct-type] IN ('2', '4', '8')
			AND a.[pa-dsch-date] BETWEEN '2016-01-01 00:00:00.000'
				AND '2016-12-31 23:59:59.000'
			)
		OR (
			a.[pa-acct-type] IN ('0', '6', '7')
			AND b.[pa-unit-no] IS NOT NULL
			AND b.[pa-unit-date] BETWEEN '2016-01-01 00:00:00.000'
				AND '2016-12-31 23:59:59.000'
			)
		OR (
			a.[pa-acct-type] IN ('0', '6', '7')
			AND b.[pa-unit-no] IS NULL
			AND a.[pa-adm-date] BETWEEN '2016-01-01 00:00:00.000'
				AND '2016-12-31 23:59:59.000'
			)
		)
	AND COALESCE(b.[pa-unit-tot-chg-amt], a.[pa-bal-tot-chg-amt]) <> '0'
	AND a.[pa-acct-sub-type] <> 'P'

UNION

SELECT a.[PA-PT-NO-WOSCD],
	a.[PA-PT-NO-SCD],
	A.[PA-CTL-PAA-XFER-DATE],
	b.[PA-UNIT-NO],
	a.[pa-med-rec-no],
	a.[pa-pt-name],
	COALESCE(DATEADD(DAY, 1, EOMONTH(b.[pa-unit-date], - 1)), a.[pa-adm-date]) AS 'Admit_Date',
	CASE 
		WHEN a.[pa-acct-type] <> 1
			THEN COALESCE(b.[pa-unit-date], a.[pa-dsch-date], a.[pa-adm-date])
		ELSE a.[pa-dsch-date]
		END AS 'Dsch_Date',
	b.[pa-unit-date],
	m.[start_unit_date],
	m.[end_unit_date],
	a.[pa-acct-type],
	COALESCE(b.[pa-unit-op-first-ins-bl-date], a.[pa-final-bill-date], a.[pa-op-first-ins-bl-date]) AS '1st_Bl_Date',
	COALESCE((b.[pa-unit-ins1-bal] + b.[pa-unit-ins2-bal] + b.[pa-unit-ins3-bal] + b.[pa-unit-ins4-bal] + b.[pa-unit-pt-bal]), a.[pa-bal-acct-bal]) AS 'Balance',
	COALESCE(b.[pa-unit-pt-bal], a.[pa-bal-pt-bal]) AS 'Pt_Balance',
	COALESCE(b.[pa-unit-tot-chg-amt], a.[pa-bal-tot-chg-amt]) AS 'Tot_Chgs',
	a.[pa-bal-tot-pt-pay-amt],
	CASE 
		WHEN a.[pa-acct-type] IN ('0', '6', '7')
			THEN 'OP' --0=OP; 6=OP BAD DEBT; 7=OP HISTORIC
		WHEN a.[pa-acct-type] IN ('1', '2', '4', '8')
			THEN 'IP' --1=IP; 2=A/R; 4=I/P BAD DEBT; 8=I/P HISTORIC
		ELSE ''
		END AS 'PtAcct_Type',
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
	a.[pa-hosp-svc],
	a.[pa-acct-sub-type] --D=Discharged; I=In House
	--k.[pa-nad-first-or-orgz-cntc],
	--k.[pa-nad-last-or-orgz-name]
FROM [Echo_ACTIVE].dbo.PatientDemographics a
LEFT OUTER JOIN [Echo_ACTIVE].dbo.unitizedaccounts b ON a.[pa-pt-no-woscd] = b.[pa-pt-no-woscd]
	AND a.[pa-pt-no-scd] = b.[pa-pt-no-scd-1]
LEFT OUTER JOIN [DSH_Unit_Partitions] m ON a.[pa-pt-no-woscd] = m.[pa-pt-no-woscd]
	AND b.[pa-unit-no] = m.[pa-unit-no]
LEFT OUTER JOIN [Echo_ACTIVE].dbo.diagnosisinformation g ON a.[pa-pt-no-woscd] = g.[pa-pt-no-woscd]
	AND g.[pa-dx2-prio-no] = '1'
	AND g.[pa-dx2-type1-type2-cd] = 'DF'
--left outer join dbo.[#LastPaymentDates] j
--ON a.[pa-pt-no-woscd]=j.[pa-pt-no-woscd] and j.[rank1]='1'
--left outer join [Echo_ACTIVE].dbo.[NADInformation] k
--ON a.[pa-pt-no-woscd]=k.[pa-pt-no-woscd] and k.[pa-nad-cd]='PTGAR'
LEFT OUTER JOIN [Echo_ACTIVE].dbo.PatientDemographics l ON a.[pa-pt-no-woscd] = l.[pa-pt-no-woscd]
WHERE (
		(
			a.[pa-acct-type] IN ('2', '4', '8')
			AND a.[pa-dsch-date] BETWEEN '2016-01-01 00:00:00.000'
				AND '2016-12-31 23:59:59.000'
			)
		OR (
			a.[pa-acct-type] IN ('0', '6', '7')
			AND b.[pa-unit-no] IS NOT NULL
			AND b.[pa-unit-date] BETWEEN '2016-01-01 00:00:00.000'
				AND '2016-12-31 23:59:59.000'
			)
		OR (
			a.[pa-acct-type] IN ('0', '6', '7')
			AND b.[pa-unit-no] IS NULL
			AND a.[pa-adm-date] BETWEEN '2016-01-01 00:00:00.000'
				AND '2016-12-31 23:59:59.000'
			)
		)
	AND COALESCE(b.[pa-unit-tot-chg-amt], a.[pa-bal-tot-chg-amt]) <> '0'
	AND a.[pa-acct-sub-type] <> 'P'
