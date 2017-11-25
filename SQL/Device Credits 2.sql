select b.[pa-pt-name],a.*


from [Echo_Archive].dbo.ProcedureInformation a left outer join [Echo_Archive].dbo.PatientDemographics b
ON a.[pa-pt-no-woscd]=b.[pa-pt-no-woscd]

where [pa-proc3-cd-modf(1)] = 'FB'
OR [pa-proc3-cd-modf(2)]='FB'
OR [pa-proc3-cd] LIKE '%FB%'

UNION

select b.[pa-pt-name],a.*


from [Echo_Active].dbo.ProcedureInformation a left outer join [Echo_Active].dbo.PatientDemographics b
ON a.[pa-pt-no-woscd]=b.[pa-pt-no-woscd]

where [pa-proc3-cd-modf(1)] = 'FB'
OR [pa-proc3-cd-modf(2)]='FB'
OR [pa-proc3-cd] LIKE '%FB%'


ORDER BY b.[pa-pt-name],[pa-proc3-date]