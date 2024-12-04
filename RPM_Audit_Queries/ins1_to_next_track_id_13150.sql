SELECT  DISTINCT [track_id] = '13150',
	[spol_group] = 'Group_1',
	[PT-NO] = CAST(PD.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(PD.[PA-PT-NO-SCD-1] AS VARCHAR)
FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].echo_active.dbo.PatientDemographics AS PD
INNER JOIN [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].echo_active.dbo.InsuranceInformation AS II ON PD.[PA-PT-NO-WOSCD] = II.[PA-PT-NO-WOSCD]
	AND PD.[PA-PT-NO-SCD-1] = II.[PA-PT-NO-SCD-1]
	AND II.[PA-INS-CO-CD] = 'H'
	AND II.[PA-INS-PLAN-NO] IN ('1','99')
	AND II.[PA-INS-PRTY] = '1'
LEFT JOIN [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].echo_active.dbo.UnitizedAccounts AS UA ON PD.[PA-PT-NO-WOSCD] = UA.[PA-PT-NO-WOSCD]
	AND PD.[PA-PT-NO-SCD-1] = UA.[PA-PT-NO-SCD-1]
WHERE PD.[PA-UNIT-STS] != 'U'
AND (
	PD.[PA-FINAL-BILL-DATE] IS NOT NULL
	OR PD.[PA-OP-FIRST-INS-BL-DATE] IS NOT NULL
	OR UA.[PA-UNIT-OP-FIRST-INS-BL-DATE] IS NOT NULL
	)
AND (
	(
		II.[PA-BAL-INS-PROR-NET-AMT] IS NOT NULL
		AND II.[PA-BAL-INS-PROR-NET-AMT] != 0
	)
	OR (
		UA.[PA-UNIT-INS1-BAL] IS NOT NULL
		AND UA.[PA-UNIT-INS1-BAL] != 0
	)
)

UNION ALL

SELECT  DISTINCT [track_id] = '13150',
	[spol_group] = 'Group_2',
	[PT-NO] = CAST(PD.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(PD.[PA-PT-NO-SCD-1] AS VARCHAR)
FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].echo_active.dbo.PatientDemographics AS PD
INNER JOIN [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].echo_active.dbo.InsuranceInformation AS II ON PD.[PA-PT-NO-WOSCD] = II.[PA-PT-NO-WOSCD]
	AND PD.[PA-PT-NO-SCD-1] = II.[PA-PT-NO-SCD-1]
LEFT JOIN [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].echo_active.dbo.UnitizedAccounts AS UA ON PD.[PA-PT-NO-WOSCD] = UA.[PA-PT-NO-WOSCD]
	AND PD.[PA-PT-NO-SCD-1] = UA.[PA-PT-NO-SCD-1]
WHERE (
	(
		II.[PA-INS-CO-CD] = 'H'
		AND II.[PA-INS-PLAN-NO] = '3'
		AND II.[PA-INS-PRTY] = '1'
	)
	OR (
		II.[PA-INS-CO-CD] = 'H'
		AND II.[PA-INS-PLAN-NO] IN ('0','10','20','30','40','45','51','60','65','70','75','80','90','95')
		AND II.[PA-INS-PRTY] = '2'
	)
)
AND (
	(
		II.[PA-BAL-INS-PROR-NET-AMT] IS NOT NULL
		AND II.[PA-BAL-INS-PROR-NET-AMT] != 0
	)
	OR (
		UA.[PA-UNIT-INS1-BAL] IS NOT NULL
		AND UA.[PA-UNIT-INS1-BAL] != 0
	)
)
AND EXISTS (
	SELECT 1
	FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].echo_active.dbo.DetailInformation AS DI
	WHERE DI.[PA-PT-NO-WOSCD] = PD.[PA-PT-NO-WOSCD]
	AND DI.[PA-PT-NO-SCD-1] = PD.[PA-PT-NO-SCD-1]
	AND DI.[PA-DTL-SVC-CD-WOSCD] = '79802'
	AND CAST(DI.[PA-DTL-POST-DATE] AS DATE) = CAST(DATEADD(DAY, -1, GETDATE()) AS DATE)
)

UNION ALL

SELECT DISTINCT [track_id] = '13150',
	[spol_group] = 'Group_3',
	[pt_no] = CAST(PD.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(PD.[PA-PT-NO-SCD-1] AS VARCHAR)
FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].echo_active.dbo.PatientDemographics AS PD
INNER JOIN [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].echo_active.dbo.InsuranceInformation AS II ON PD.[PA-PT-NO-WOSCD] = II.[PA-PT-NO-WOSCD]
	AND PD.[PA-PT-NO-SCD-1] = II.[PA-PT-NO-SCD-1]
	AND II.[PA-INS-CO-CD] = 'H'
	AND II.[PA-INS-PLAN-NO] IN ('1','99')
	AND II.[PA-INS-PRTY] = '1'
LEFT JOIN [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].echo_active.dbo.UnitizedAccounts AS UA ON PD.[PA-PT-NO-WOSCD] = UA.[PA-PT-NO-WOSCD]
	AND PD.[PA-PT-NO-SCD-1] = UA.[PA-PT-NO-SCD-1]
WHERE PD.[PA-UNIT-STS] = 'U'
AND (
	PD.[PA-FINAL-BILL-DATE] IS NOT NULL
	OR PD.[PA-OP-FIRST-INS-BL-DATE] IS NOT NULL
	OR UA.[PA-UNIT-OP-FIRST-INS-BL-DATE] IS NOT NULL
	)
AND (
	(
		II.[PA-BAL-INS-PROR-NET-AMT] IS NOT NULL
		AND II.[PA-BAL-INS-PROR-NET-AMT] != 0
	)
	OR (
		UA.[PA-UNIT-INS1-BAL] IS NOT NULL
		AND UA.[PA-UNIT-INS1-BAL] != 0
	)
)