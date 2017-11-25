SELECT cast(a.[PA-PT-NO-WOSCD] AS VARCHAR) + cast(a.[PA-PT-NO-SCD-1] AS VARCHAR) AS 'Pt_No'
,b.[pa-drg-no-2]
,b.[pa-drg-desc]
,b.[pa-drg-scheme]
,c.[pa-bal-tot-chg-amt]
,SUM([pa-dtl-chg-qty]) as 'Chg_Qty'
,SUM([pa-dtl-chg-amt]) as 'Chg_Amt'
--,[pa-dtl-rev-cd] as 'Rev_Cd'
--, cast([pa-dtl-svc-cd-woscd] as varchar) + cast([pa-dtl-svc-cd-scd] as varchar) as 'Charge_Code'


FROM [Echo_Archive].dbo.DetailInformation a left outer join [Echo_Archive].dbo.DRGInformation b
ON a.[pa-pt-no-woscd]=b.[pa-pt-no-woscd] 
left outer join [Echo_Archive].dbo.PatientDemographics c
ON a.[pa-pt-no-woscd]=c.[pa-pt-no-woscd]


WHERE b.[pa-drg-no-2] IN ('795','775','765','871','794','291','885','247','470','774')--Top Volume DRG's YTD 5-8-17 Concurrent MS-DRG
AND b.[pa-drg-seg-type]='3'--All Payer
AND a.[pa-acct-type] IN ('2','4','8')--Inpatient
AND c.[pa-dsch-date] > '12/31/2016'
AND a.[pa-dtl-type-ind] IN ('7','8','A','B')



GROUP BY cast(a.[PA-PT-NO-WOSCD] AS VARCHAR) + cast(a.[PA-PT-NO-SCD-1] AS VARCHAR) 
,b.[pa-drg-no-2]
,b.[pa-drg-desc]
,b.[pa-drg-scheme]
,c.[pa-bal-tot-chg-amt]



UNION


SELECT cast(a.[PA-PT-NO-WOSCD] AS VARCHAR) + cast(a.[PA-PT-NO-SCD-1] AS VARCHAR) AS 'Pt_No'
,b.[pa-drg-no-2]
,b.[pa-drg-desc]
,b.[pa-drg-scheme]
,c.[pa-bal-tot-chg-amt]
,SUM([pa-dtl-chg-qty]) as 'Chg_Qty'
,SUM([pa-dtl-chg-amt]) as 'Chg_Amt'
--,[pa-dtl-rev-cd] as 'Rev_Cd'
--, cast([pa-dtl-svc-cd-woscd] as varchar) + cast([pa-dtl-svc-cd-scd] as varchar) as 'Charge_Code'


FROM [Echo_Active].dbo.DetailInformation a left outer join [Echo_Active].dbo.DRGInformation b
ON a.[pa-pt-no-woscd]=b.[pa-pt-no-woscd] 
left outer join [Echo_Active].dbo.PatientDemographics c
ON a.[pa-pt-no-woscd]=c.[pa-pt-no-woscd]


WHERE b.[pa-drg-no-2] IN ('795','775','765','871','794','291','885','247','470','774')--Top Volume DRG's YTD 5-8-17 Concurrent MS-DRG
AND b.[pa-drg-seg-type]='3'--All Payer
AND a.[pa-acct-type] IN ('2','4','8')--Inpatient
AND c.[pa-dsch-date] > '12/31/2016'
AND a.[pa-dtl-type-ind] IN ('7','8','A','B')


GROUP BY cast(a.[PA-PT-NO-WOSCD] AS VARCHAR) + cast(a.[PA-PT-NO-SCD-1] AS VARCHAR) 
,b.[pa-drg-no-2]
,b.[pa-drg-desc]
,b.[pa-drg-scheme]
,c.[pa-bal-tot-chg-amt]