SELECT A.[PA-PT-NO-WOSCD],
	A.[PA-PT-NO-SCD],
	A.[PT-NO],
	A.[PA-UNIT-NO],
	B.[admit_date],
	C.[PA-DTL-REV-CD],
	C.[Adjusted Rev Code],
	C.[Rev Code from CDM],
	A.[PA-DTL-SVC-CD],
	[PA-DTL-UNIT-DATE],
	A.[TYPE],
	[340B-IND],
	[REPORTING-GROUP],
	[TOT-CHG-QTY],
	[Total Charges including Prof Fees]
FROM [DSH].[dbo].[2016_340B_INDICATOR] a
LEFT JOIN [Encounters_For_DSH] b ON a.[pa-pt-no-woscd] = b.[pa-pt-no-woscd]
	--AND A.[PA-DTL-DATE] >= B.[START_UNIT_DATE]
	--AND A.[PA-DTL-DATE] <= B.[END_UNIT_DATE]
	--AND a.[pa-ctl-paa-xfer-date] = b.[pa-ctl-paa-xfer-date]
	--AND A.[PA-UNIT-DATE] = B.[pa-unit-date]
	AND A.[pa-unit-no] = B.[pa-unit-no]
--DATEADD(DAY,-(DAY(DATEADD(MONTH, 1,a.[pa-dtl-date]))),DATEADD(MONTH,1,a.[pa-dtl-date]))
LEFT JOIN [dbo].[2016_DSH_Costs] C ON a.[pa-pt-no-woscd] = b.[pa-pt-no-woscd]
	AND A.[PA-PT-NO-SCD] = B.[PA-PT-NO-SCD]
	AND A.[PA-DTL-SVC-CD] = C.[PA-DTL-SVC-CD]
WHERE [REPORTING-GROUP] IN ('PRIMARY MEDICAID', 'PRIMARY MEDICAID MANAGED CARE', 'MEDICAID FFS DUAL ELIGIBLE', 'MEDICAID MANAGED CARE DUAL ELIGIBLE', 'PRIMARY OUT OF STATE MEDICAID', 'DUAL ELIGIBLE OUT OF STATE MEDICAID')
	--AND [PA-PT-NO-WOSCD] = '1010716363'
	--order by [admit_date] desc
