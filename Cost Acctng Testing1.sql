select a.[pa-pt-no-woscd],
a.[pa-pt-no-scd-1],
--a.[pa-component-id],
--a.[pa-user-text],
c.[pa-pt-type],
c.[pa-hosp-svc],
b.[pa-ins-co-cd],
b.[pa-ins-plan-no],
b.[pa-bal-ins-pay-amt],
c.[pa-bal-acct-bal],
c.[pa-acct-type],
d.[pa-drg-scheme],
d.[pa-drg-no-2],
d.[pa-drg-cost-weight-2],
d.[pa-drg-desc],
d.[pa-drg-rom-ind],
d.[pa-drg-soi-ind],
'ARCHIVE'



from dbo.[userdefined] a left outer join dbo.[insuranceinformation] b
ON a.[pa-pt-no-woscd]=b.[pa-pt-no-woscd] and b.[pa-ins-prty]='1'
left outer join dbo.[patientdemographics] c
ON a.[pa-pt-no-woscd]=c.[pa-pt-no-woscd]
left outer join dbo.[drginformation] d
on b.[pa-pt-no-woscd]=d.[pa-pt-no-woscd] and b.[pa-ins-co-cd]=d.[pa-drg-ins-co-cd] and b.[pa-ins-plan-no]=d.[PA-DRG-INS-PLAN-NO]


--where (([pa-component-id]='2C49VC24'
--and [pa-user-create-date] > '2016-12-31 23:59:59.000') OR
--WHERE (c.[pa-pt-type]='E' AND c.[pa-hosp-svc]='EMR') --OR 
--WHERE (c.[pa-hosp-svc] IN ('SDS','CTH','EPS'))
WHERE b.[pa-ins-co-cd]='D'
and b.[pa-bal-ins-pay-amt] < '0'
and c.[pa-bal-acct-bal] = '0'
and c.[pa-acct-type] IN ('2','8')
AND c.[pa-adm-date] > '2015-12-31 23:59:59.000'
AND b.[pa-pt-no-woscd] IN

(
SELECT DISTINCT([pa-pt-no-woscd])
FROM dbo.procedureinformation
where [pa-proc3-cd] IN ('10900ZC','10903ZC','10904ZC','10907ZC','10908ZC','10900ZC','10903ZC','10904ZC','10907ZC','10908ZC','0U7C7ZZ','3030VJ','3E033VJ','3E040VJ',
'3E043VJ','3E050VJ','3E053VJ','3E060VJ','3E063VJ','3E0DXGC','3E0P7GC','10D00Z0','10D00Z1','10D00Z2')
)
--(

--SELECT DISTINCT([pa-pt-no-woscd])
--FROM dbo.DetailInformation
--WHERE [pa-dtl-rev-cd] = '510' and [pa-dtl-chg-amt] > '0' 
--AND [pa-dtl-date] > '2016-12-31 23:59:59.000'
--)



GROUP BY a.[pa-pt-no-woscd],
a.[pa-pt-no-scd-1],
--a.[pa-component-id],
--a.[pa-user-text],
c.[pa-pt-type],
c.[pa-hosp-svc],
b.[pa-ins-co-cd],
b.[pa-ins-plan-no],
b.[pa-bal-ins-pay-amt],
c.[pa-bal-acct-bal],
c.[pa-acct-type],
d.[pa-drg-scheme],
d.[pa-drg-no-2],
d.[pa-drg-cost-weight-2],
d.[pa-drg-desc],
d.[pa-drg-rom-ind],
d.[pa-drg-soi-ind]



order by c.[pa-hosp-svc],a.[pa-pt-no-woscd]