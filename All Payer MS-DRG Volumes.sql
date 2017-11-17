SELECT COUNT(DISTINCT(a.[pa-pt-no-woscd])) as 'Cases'
, a.[pa-drg-no-2]

FROM [Echo_Archive].dbo.DRGInformation AS A 
LEFT OUTER JOIN [Echo_Archive].dbo.PatientDemographics AS B
ON a.[pa-pt-no-woscd] = b.[pa-pt-no-woscd]

WHERE a.[pa-drg-seg-type] = '3'
AND b.[pa-dsch-date] > '12/31/2016'
AND b.[pa-bal-tot-chg-amt] > '0'

GROUP BY a.[pa-drg-no-2]

UNION

SELECT COUNT(DISTINCT(a.[pa-pt-no-woscd])) as 'Cases'
, a.[pa-drg-no-2]

FROM [Echo_Active].dbo.DRGInformation AS A 
LEFT OUTER JOIN [Echo_Active].dbo.PatientDemographics AS 
ON a.[pa-pt-no-woscd]=b.[pa-pt-no-woscd]

WHERE a.[pa-drg-seg-type]='3'
AND b.[pa-dsch-date] > '12/31/2016'
AND b.[pa-bal-tot-chg-amt] > '0'

GROUP BY a.[pa-drg-no-2]