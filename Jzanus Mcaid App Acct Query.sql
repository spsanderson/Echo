SELECT CAST([pa-pt-no-woscd] as varchar) +CAST([pa-pt-no-scd-1] as varchar) as 'PA-PT-NO',
MAX([pa-smart-svc-cd-woscd]) as 'Jzanus-Ind',
[pa-smart-comment] as 'Jzanus-Comment'
FROM [Echo_Archive].dbo.AccountComments
WHERE [pa-smart-svc-cd-woscd] IN ('200','201','202','203','204','205','206','207','208','209','210','211','212','213')

GROUP BY CAST([pa-pt-no-woscd] as varchar) +CAST([pa-pt-no-scd-1] as varchar),[pa-smart-comment]



UNION


SELECT CAST([pa-pt-no-woscd] as varchar) +CAST([pa-pt-no-scd-1] as varchar) as 'PA-PT-NO',
MAX([pa-smart-svc-cd-woscd]) as 'Jzanus-Ind',
[pa-smart-comment] as 'Jzanus-Comment'
FROM [Echo_Active].dbo.AccountComments
WHERE [pa-smart-svc-cd-woscd] IN ('200','201','202','203','204','205','206','207','208','209','210','211','212','213')

GROUP BY CAST([pa-pt-no-woscd] as varchar) +CAST([pa-pt-no-scd-1] as varchar),[pa-smart-comment];