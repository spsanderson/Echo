WITH [PRINPROC_CTE] ([pa-pt-no-woscd],[pa-pt-no-scd-1],[pa-acct-type],[pa-proc3-date],[pa-proc3-prty],[pa-proc3-resp-party],[pa-proc3-cd-type],[pa-proc3-cd],[pa-proc3-cd-modf(1)],[pa-proc3-cd-modf(2)],[pa-proc3-cd-modf(3)],[PRIORITY])

AS

(
SELECT [pa-pt-no-woscd],
[pa-pt-no-scd-1],
[pa-acct-type],
[pa-proc3-date],
[pa-proc3-prty],
[pa-proc3-resp-party],
[pa-proc3-cd-type],
[pa-proc3-cd],
[pa-proc3-cd-modf(1)],
[pa-proc3-cd-modf(2)],
[pa-proc3-cd-modf(3)],
RANK() OVER(PARTITION BY [PA-PT-NO-WOSCD] ORDER BY [PA-PROC3-PRTY] ASC) AS 'PRIORITY'


FROM [ECHO_ARCHIVE].dbo.[ProcedureInformation]

WHERE [pa-proc3-cd-type]='0'--ICD-10

)


SELECT a.[pa-pt-no-woscd],
[pa-pt-no-scd],
COUNT(DISTINCT(a.[pa-pt-no-woscd])) as 'Cases',
a.[pa-proc3-cd],
AVG(b.[pa-bal-tot-chg-amt]) as 'Average_Chgs'


FROM [prinproc_cte] a left outer join [Echo_Archive].dbo.PatientDemographics b
ON a.[pa-pt-no-woscd]=b.[pa-pt-no-woscd]

WHERE [PRIORITY] ='1'
AND [pa-proc3-date] > '2016-12-31 23:59:59.000'
AND b.[pa-hosp-svc] = 'EPS'


GROUP BY a.[pa-pt-no-woscd],
[pa-pt-no-scd],a.[pa-proc3-cd]