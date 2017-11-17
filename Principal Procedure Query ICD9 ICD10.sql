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

WHERE ([pa-proc3-date]< '2015-10-01 00:00:00.000' AND [pa-proc3-cd-type]='9')--ICD-9
OR ([pa-proc3-date]>= '2015-10-01 00:00:00.000' AND [pa-proc3-cd-type]='0')--ICD-10

)

,

[PRINPROC2_CTE] ([pa-pt-no-woscd],[pa-pt-no-scd-1],[pa-acct-type],[pa-proc3-date],[pa-proc3-prty],[pa-proc3-resp-party],[pa-proc3-cd-type],[pa-proc3-cd],[pa-proc3-cd-modf(1)],[pa-proc3-cd-modf(2)],[pa-proc3-cd-modf(3)],[PRIORITY])

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


FROM [ECHO_ACTIVE].dbo.[ProcedureInformation]

WHERE ([pa-proc3-date]< '2015-10-01 00:00:00.000' AND [pa-proc3-cd-type]='9')--ICD-9
OR ([pa-proc3-date]>= '2015-10-01 00:00:00.000' AND [pa-proc3-cd-type]='0')--ICD-10

)


SELECT cast(a.[PA-PT-NO-WOSCD] AS VARCHAR) + cast(a.[PA-PT-NO-SCD-1] AS VARCHAR) AS 'Pt_No',
a.*,
b.[pa-acct-type]

FROM [prinproc_cte] a left outer join [Echo_Archive].dbo.PatientDemographics b
ON a.[pa-pt-no-woscd]=b.[pa-pt-no-woscd]
left outer join [Echo_Archive].dbo.[InsuranceInformation] c
ON a.[pa-pt-no-woscd]=c.[pa-pt-no-woscd] and c.[pa-ins-prty]='1'

WHERE [PRIORITY] ='1'
AND [pa-proc3-date] > '2014-01-01 00:00:00.000'
AND c.[pa-ins-co-cd]='L'
AND c.[pa-ins-plan-no]='76'




UNION

SELECT cast(b.[PA-PT-NO-WOSCD] AS VARCHAR) + cast(b.[PA-PT-NO-SCD-1] AS VARCHAR) AS 'Pt_No',
b.*,
c.[pa-acct-type]


FROM [prinproc2_cte] b left outer join [Echo_Active].dbo.PatientDemographics c
ON b.[pa-pt-no-woscd]=c.[pa-pt-no-woscd]
left outer join [Echo_Active].dbo.[InsuranceInformation] d
ON b.[pa-pt-no-woscd]=d.[pa-pt-no-woscd] and d.[pa-ins-prty]='1'

WHERE [PRIORITY] ='1'
AND [pa-proc3-date] > '2014-01-01 00:00:00.000'
AND d.[pa-ins-co-cd]='L'
AND d.[pa-ins-plan-no]='76'



