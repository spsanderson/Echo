SELECT DISTINCT [track_id] = '13153',
	[spol_group] = 'Group_1',
	[pt_no] = CAST(PD.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(PD.[PA-PT-NO-SCD-1] AS VARCHAR),
	[unit_no] = UA.[PA-UNIT-NO],
	[unit_date] = CAST(UA.[PA-UNIT-DATE] AS DATE)
FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].echo_active.dbo.PatientDemographics AS PD
LEFT JOIN [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].echo_active.dbo.InsuranceInformation AS I1 ON PD.[PA-PT-NO-WOSCD] = I1.[PA-PT-NO-WOSCD]
	AND PD.[PA-PT-NO-SCD-1] = I1.[PA-PT-NO-SCD-1]
	AND I1.[PA-INS-PRTY] = '3'
INNER JOIN [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].echo_active.dbo.UnitizedAccounts AS UA ON PD.[PA-PT-NO-WOSCD] = UA.[PA-PT-NO-WOSCD]
	AND PD.[PA-PT-NO-SCD-1] = UA.[PA-PT-NO-SCD-1]
WHERE PD.[PA-UNIT-STS] = 'U' 
AND (
	PD.[PA-FINAL-BILL-DATE] IS NOT NULL
	OR PD.[PA-OP-FIRST-INS-BL-DATE] IS NOT NULL
	OR UA.[PA-UNIT-OP-FIRST-INS-BL-DATE] IS NOT NULL
)
AND I1.[PA-INS-CO-CD] = 'H'
AND I1.[PA-INS-PLAN-NO] IN ('1','99')
AND (
	ISNULL(I1.[PA-BAL-INS-PROR-NET-AMT], 0) != 0
	OR ISNULL(UA.[PA-UNIT-INS3-BAL], 0) != 0
)