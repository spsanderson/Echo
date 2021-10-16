USE [DSH_Southampton_2019]

-- Make the insurance pivot table
DROP TABLE IF EXISTS #ins_prio_tbl
CREATE TABLE #ins_prio_tbl (
	acct VARCHAR(12),
	ins_name VARCHAR(255),
	insurance_grouping VARCHAR(255),
	calculated_priority VARCHAR(10),
	rowid INT
)

INSERT INTO #ins_prio_tbl (acct, ins_name, insurance_grouping, calculated_priority, rowid)
SELECT zzz.Acct#,
	zzz.Ins_Name,
	xxx.insurance_groupings,
	ZZZ.[CALCULATED_PRIORITY],
	[rn] = ROW_NUMBER() OVER(
		PARTITION BY ZZZ.ACCT#, ZZZ.CALCULATED_PRIORITY
		ORDER BY ZZZ.ACCT#
	)
FROM DBO.[DSH_Ins_Remit_self_pay] AS ZZZ
INNER JOIN DBO.[InsurancePlanListing] AS XXX ON ZZZ.Ins_Name = XXX.InsCode
WHERE ZZZ.[Calculated_Priority] <= '5'
--AND ZZZ.Acct# = '5238559';

DELETE
FROM #ins_prio_tbl
WHERE rowid != 1;

DROP TABLE IF EXISTS #ins_name_group_tbl
CREATE TABLE #ins_name_group_tbl (
	acct VARCHAR(12),
	Primary_Ins_Name VARCHAR(255),
	Primary_Ins_Grouping VARCHAR(255),
	Secondary_Ins_Name VARCHAR(255),
	Secondary_Ins_Grouping VARCHAR(255),
	Tertiary_Ins_Name VARCHAR(255),
	Tertiary_Ins_Grouping VARCHAR(255),
	Quaternary_Ins_Name VARCHAR(255),
	Quaternary_Ins_Grouping VARCHAR(255),
	Quinary_Ins_Name VARCHAR(255),
	Quinary_Ins_Grouping VARCHAR(255)
)

INSERT INTO #ins_name_group_tbl (
	acct,
	Primary_Ins_Name, Primary_Ins_Grouping,
	Secondary_Ins_Name, Secondary_Ins_Grouping,
	Tertiary_Ins_Name, Tertiary_Ins_Grouping,
	Quaternary_Ins_Name, Quaternary_Ins_Grouping,
	Quinary_Ins_Name, Quinary_Ins_Grouping
)
SELECT acct,
MAX(pvtb.[1]) AS [Primary_Ins_Name],
MAX(pvtb.[01]) AS [Primary_Ins_Grouping],
MAX(PVTB.[2]) AS [Secondary_Ins_Name],
MAX(PVTB.[02]) AS [Secondary_Ins_Grouping],
MAX(PVTB.[3]) AS [Tertiary_Ins_Name],
MAX(PVTB.[03]) AS [Tertiary_Ins_Grouping],
MAX(PVTB.[4]) AS [Quaternary_Ins_Name],
MAX(PVTB.[04]) AS [Quaternary_Ins_Grouping],
MAX(PVTB.[5]) AS [Quinary_Ins_Name],
MAX(PVTB.[05]) AS [Quinary_Ins_Grouping]
FROM (
SELECT acct,
	ins_name,
	insurance_grouping,
	calculated_priority,
	calculated_priorityb = '0' + cast(calculated_priority as varchar) 
FROM #ins_prio_tbl
) AS A

PIVOT(
	MAX(ins_name)
	FOR calculated_priority IN ("1","2","3","4","5")
) AS PVT

PIVOT(
	MAX(insurance_grouping)
	FOR calculated_priorityb IN ("01","02","03","04","05")
) AS PVTB
GROUP BY ACCT;

-- get data
DROP TABLE IF EXISTS dbo.[SHH_DSH_CHARGES]
GO

CREATE TABLE dbo.[SHH_DSH_CHARGES] (
	Acct VARCHAR(8000),
	Med_Rec VARCHAR(8000),
	Patient_Name VARCHAR(8000),
	Admit_Date DATETIME2,
	Disch_Date DATETIME2,
	Stay_Type VARCHAR(8000),
	[Stay_Type_Description] VARCHAR(5000),
	[Stay_Type_Dtl_Description] VARCHAR(5000),
	Service_Code VARCHAR(8000),
	SERVICE_CD_mod_for_DSH VARCHAR(8000),
	SERVICE_CODE_Description VARCHAR(8000),
	Item VARCHAR(8000),
	ItemDesc VARCHAR(8000),
	Sum_Code VARCHAR(8000),
	SUM_Code_Description VARCHAR(8000),
	CPSI_Category VARCHAR(8000),
	Rev_Code VARCHAR(8000),
	ICR_CC VARCHAR(8000),
	CPT VARCHAR(8000),
	Charge_Date DATETIME2,
	QTY REAL,
	QTY_Mod REAL,
	Amount MONEY,
	RCC FLOAT,
	Per_Diem FLOAT,
	SVC_Date DATETIME2,
	GL VARCHAR(8000),
	[Primary_Ins_Name] VARCHAR(5000),
	[Primary_Ins_Grouping] VARCHAR(5000),
	[Secondary_Ins_Name] VARCHAR(5000),
	[Secondary_Ins_Grouping] VARCHAR(5000),
	[Tertiary_Ins_Name] VARCHAR(5000),
	[Tertiary_Ins_Grouping] VARCHAR(5000),
	[Quaternary_Ins_Name] VARCHAR(5000),
	[Quaternary_Ins_Grouping] VARCHAR(5000),
	[Quinary_Ins_Name] VARCHAR(5000),
	[Quinary_Ins_Grouping] VARCHAR(5000),
	[Admit_Code] VARCHAR(5000), -- CAS 3-23-21
	[Disch_Disp] VARCHAR(5000),
	[Disch_Disp_Long_Description] VARCHAR(5000),
	[Admit_Source] VARCHAR(5000),
	[Admit_Source_Desc] VARCHAR(5000),
	[Reporting_Group] VARCHAR(1000)
	);

INSERT INTO dbo.[SHH_DSH_CHARGES]
SELECT a.[Acct],
	a.[Med_Rec],
	a.[Patient_Name],
	a.[Admit_Date],
	a.[Disch_Date],
	a.[Stay_Type],
	d.[Stay_Type_Description],
	d.[Stay_Type_Dtl_Description],
	a.[Service_Code],
	h.[SERVICE_CD_mod_for_DSH],
	H.[SERVICE_CODE_Description],
	a.[Item],
	a.[ItemDesc],
	a.[Sum_Code],
	COALESCE(I.[DESCRIPTION], J.[DESCRIPTION], K.[DESCRIPTION]) AS 'Sum_Code_Description',
	K.[CPSI_Category],
	a.[Rev_Code],
	COALESCE(I.[ICR_CC], J.[ICR_CC]) AS 'ICR_CC',
	a.[CPT],
	a.[Charge_Date],
	a.[QTY],
	[QTY_Mod] = CASE 
		WHEN A.Amount < 0
		AND A.[QTY] > 0  --  CAS 3-23-21
			THEN CAST(A.[QTY] AS INT) * - 1
		ELSE A.[QTY]
		END,
	a.[Amount],
	I.[RCC],
	J.[PER_DIEM],
	a.[SVC_Date],
	a.[GL],
	INS_TBL.Primary_Ins_Name,
	INS_TBL.Primary_Ins_Grouping,
	INS_TBL.Secondary_Ins_Name,
	INS_TBL.Secondary_Ins_Grouping,
	INS_TBL.Tertiary_Ins_Name,
	INS_TBL.Tertiary_Ins_Grouping,
	INS_TBL.Quaternary_Ins_Name,
	INS_TBL.Quaternary_Ins_Grouping,
	INS_TBL.Quinary_Ins_Name,
	INS_TBL.Quinary_Ins_Grouping,
	--(
	--	SELECT TOP 1 ZZZ.[Ins_Name]
	--	FROM DBO.[DSH_Ins_Remit_self_pay] AS ZZZ
	--	WHERE ZZZ.[Calculated_Priority] = '1'
	--		AND ZZZ.Acct# = A.ACCT
	--	) AS [Primary_Ins_Name],
	--(
	--	SELECT TOP 1 XXX.Insurance_Groupings
	--	FROM DBO.[DSH_Ins_Remit_self_pay] AS ZZZ
	--	INNER JOIN DBO.[InsurancePlanListing] AS XXX ON ZZZ.Ins_Name = XXX.InsCode
	--		AND ZZZ.Acct# = A.Acct
	--		AND ZZZ.[Calculated_Priority] = '1'
	--	) AS [Primary_Ins_Grouping],
	--(
	--	SELECT TOP 1 ZZZ.[Ins_Name]
	--	FROM DBO.[DSH_Ins_Remit_self_pay] AS ZZZ
	--	WHERE ZZZ.[Calculated_Priority] = '2'
	--		AND ZZZ.Acct# = A.ACCT
	--	) AS [Secondary_Ins_Name],
	--(
	--	SELECT TOP 1 XXX.Insurance_Groupings
	--	FROM DBO.[DSH_Ins_Remit_self_pay] AS ZZZ
	--	INNER JOIN DBO.InsurancePlanListing AS XXX ON ZZZ.Ins_Name = XXX.InsCode
	--		AND ZZZ.Acct# = A.Acct
	--		AND ZZZ.[Calculated_Priority] = '2'
	--	) AS [Secondary_Ins_Grouping],
	--(
	--	SELECT TOP 1 ZZZ.[Ins_Name]
	--	FROM DBO.[DSH_Ins_Remit_self_pay] AS ZZZ
	--	WHERE ZZZ.[Calculated_Priority] = '3'
	--		AND ZZZ.Acct# = A.ACCT
	--	) AS [Tertiary_Ins_Name],
	--(
	--	SELECT TOP 1 XXX.Insurance_Groupings
	--	FROM DBO.[DSH_Ins_Remit_self_pay] AS ZZZ
	--	INNER JOIN DBO.InsurancePlanListing AS XXX ON ZZZ.Ins_Name = XXX.InsCode
	--		AND ZZZ.Acct# = A.Acct
	--		AND ZZZ.[Calculated_Priority] = '3'
	--	) AS [Tertiary_Ins_Grouping],
	--(
	--	SELECT TOP 1 ZZZ.[Ins_Name]
	--	FROM DBO.[DSH_Ins_Remit_self_pay] AS ZZZ
	--	WHERE ZZZ.[Calculated_Priority] = '4'
	--		AND ZZZ.Acct# = A.ACCT
	--	) AS [Quaternary_Ins_Name],
	--(
	--	SELECT TOP 1 XXX.Insurance_Groupings
	--	FROM DBO.[DSH_Ins_Remit_self_pay] AS ZZZ
	--	INNER JOIN DBO.InsurancePlanListing AS XXX ON ZZZ.Ins_Name = XXX.InsCode
	--		AND ZZZ.Acct# = A.Acct
	--		AND ZZZ.[Calculated_Priority] = '4'
	--	) AS [Quaternary_Ins_Grouping],
	--(
	--	SELECT TOP 1 ZZZ.[Ins_Name]
	--	FROM DBO.[DSH_Ins_Remit_self_pay] AS ZZZ
	--	WHERE ZZZ.[Calculated_Priority] = '5'
	--		AND ZZZ.Acct# = A.ACCT
	--	) AS [Quinary_Ins_Name],
	--(
	--	SELECT TOP 1 XXX.Insurance_Groupings
	--	FROM DBO.[DSH_Ins_Remit_self_pay] AS ZZZ
	--	INNER JOIN DBO.InsurancePlanListing AS XXX ON ZZZ.Ins_Name = XXX.InsCode
	--		AND ZZZ.Acct# = A.Acct
	--		AND ZZZ.[Calculated_Priority] = '5'
	--	) AS [Quinary_Ins_Grouping],
	e.[Admit_Code], -- CAS 3-23-21
	e.[Disch_Disp],
	f.[Long_Description] AS 'Disch_Disp_Long_Desc',
	e.[Admit_Source],
	g.[Admit_Source_Desc],
	[Reporting_Group] = (
		SELECT MAX(ZZZ.Reporting_Group)
		FROM dbo.[DSH_INSURANCE_TABLE_W_REPORT_GROUPS] AS ZZZ
		WHERE ZZZ.Acct = A.Acct
		GROUP BY ZZZ.Acct
		)
FROM [dbo].[SHH_DSH_Charge_Detail_Import_Issues_Fixed] AS A
LEFT OUTER JOIN [dbo].[Stay_Type] d ON A.[Stay_Type] = D.[Stay_Type]
LEFT OUTER JOIN [dbo].[DSH_Visit] e ON A.[Acct] = E.[Acct#]
LEFT OUTER JOIN [dbo].[Disch_Disp] f ON E.[Disch_Disp] = F.[CPSI_Code] COLLATE Latin1_General_100_CS_AS
LEFT OUTER JOIN [dbo].[Admit_Source] G ON E.[Admit_Source] = G.[Code]
LEFT OUTER JOIN [dbo].[ServiceCode] H ON A.[Service_Code] = H.[SERVICE_CODE] COLLATE Latin1_General_100_CS_AS
LEFT OUTER JOIN [dbo].[SHH_ChgCd_wICRs_RCCs] I ON I.[CPSI_CODE] = A.[Sum_Code]
LEFT OUTER JOIN [dbo].[SHH_ChgCd_wICRs_Per_Diem] J ON J.[CPSI_CODE] = A.[Sum_Code]
LEFT OUTER JOIN [dbo].[ChgCd_wCPSI_Category_Fixed] K ON K.[CPSI_CODE] = A.[Sum_Code]
LEFT OUTER JOIN #ins_name_group_tbl AS INS_TBL ON A.Acct = INS_TBL.acct
WHERE [Disch_Disp] != '1' --(TRANS TO STONY BROOK FOR INPATIENT CARE)
	AND [Admit_Source] != '16' --(Transfer Stony Brook)
	AND [CPSI_Category] IN ('ANCILLARY CHARGE', 'Room and Board Charge')
	-- EDIT SPS 3/16/2021
	-- EDIT SPS 3/22/2021 FIXED
	-- Below coding to remove any O/P Inmate (Only I/P inmates can be part of DSH).
		AND A.Acct NOT IN (        --- (Removes encounter if O/P and Admit Code is ER Police)
		SELECT BBB.Acct#
		FROM DSH_Visit AS BBB  -- Yes you can, I changed it for you already to BBB (ASK Steve could I change this "ZZZ" coding to say BBB instead of ZZZ b/c ZZZ is used above and is confusing to use for a different table down here?)
		WHERE BBB.Stay_Type IN ('2', '3', '4')  -- (O/P) 
			AND BBB.Admit_Code = 'P' --- (ER Police)
		)
	--AND A.Acct = '5141777'
	-- END EDIT
	-- 1,868,892
