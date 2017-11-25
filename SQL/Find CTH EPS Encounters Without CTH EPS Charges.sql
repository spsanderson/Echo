SELECT [pa-pt-no-woscd],[pa-pt-no-scd],
[pa-hosp-svc],
[pa-adm-date],
[pa-bal-acct-bal],
[pa-bal-tot-chg-amt]


FROM dbo.PatientDemographics


WHERE [pa-adm-date] BETWEEN '2016-11-01 00:00:00.000' AND '2017-04-30 23:59:59.000'
AND [pa-hosp-svc] IN ('CTH','EPS')
AND [pa-pt-no-woscd] NOT IN


(
 SELECT DISTINCT([pa-pt-no-woscd])
 FROM [Echo_Archive].dbo.DetailInformation
 WHERE [pa-dtl-gl-no] IN ('386','431','771','481')
 AND [pa-dtl-date] BETWEEN '2016-11-01 00:00:00.000' AND '2017-04-30 23:59:59.000'
 )