

WITH [PAIDDATES_CTE] ([pa-pt-no-woscd],[pa-pt-no-scd],[pa-dtl-type-ind],[pa-dtl-ins-co-cd],[pa-dtl-ins-plan-no],[pa-dtl-svc-cd-woscd],[pa-dtl-svc-cd-scd],[pa-dtl-chg-amt],[pa-dtl-date],[pa-initial-bill-date],[pa-fc],[pa-last-fc],[pa-pt-type],[Rank])

As 

(SELECT a.[pa-pt-no-woscd],
a.[PA-PT-NO-SCD-1],
a.[pa-dtl-type-ind],
a.[pa-dtl-ins-co-cd],
a.[pa-dtl-ins-plan-no],
a.[pa-dtl-svc-cd-woscd],
a.[pa-dtl-svc-cd-scd],
a.[pa-dtl-chg-amt],
a.[pa-dtl-date],
ISNULL(b.[pa-final-bill-date],b.[pa-op-first-ins-bl-date]) as 'Initial_Bill_Date',
b.[pa-fc],
b.[pa-last-fc],
b.[pa-pt-type],
RANK() OVER (PARTITION BY a.[pa-pt-no-woscd] ORDER BY a.[pa-dtl-date]) as 'Rank'

FROM [Echo_Archive].dbo.PatientDemographics b left join [Echo_Archive].dbo.DetailInformation a
ON a.[pa-pt-no-woscd]=b.[pa-pt-no-woscd]

WHERE a.[pa-dtl-type-ind]='1'
AND a.[pa-dtl-chg-amt]<> '0'
AND a.[pa-dtl-ins-co-cd] IN ('E','F')--No Fault & W/C
--AND b.[pa-last-fc] NOT IN ('3','5')
--AND b.[pa-fc] IN ('N','W')
AND a.[pa-dtl-date] > '12/31/2014'
--AND a.[pa-dtl-Date] > b.[pa-acct-bd-xfr-date]
--AND b.[pa-acct-bd-xfr-date] > '12/31/14'
AND b.[pa-unit-sts]='N'--'0' has units; '2' no units
--AND a.[pa-dtl-svc-cd-woscd]<> '10202'
)
,
[PAIDDATES2_CTE] ([pa-pt-no-woscd],[pa-pt-no-scd],[pa-dtl-type-ind],[pa-dtl-ins-co-cd],[pa-dtl-ins-plan-no],[pa-dtl-svc-cd-woscd],[pa-dtl-svc-cd-scd],[pa-dtl-chg-amt],[pa-dtl-date],[pa-initial-bill-date],[pa-fc],[pa-last-fc],[pa-pt-type],[Rank])

As 

(SELECT a.[pa-pt-no-woscd],
a.[PA-PT-NO-SCD-1],
a.[pa-dtl-type-ind],
a.[pa-dtl-ins-co-cd],
a.[pa-dtl-ins-plan-no],
a.[pa-dtl-svc-cd-woscd],
a.[pa-dtl-svc-cd-scd],
a.[pa-dtl-chg-amt],
a.[pa-dtl-date],
ISNULL(b.[pa-final-bill-date],b.[pa-op-first-ins-bl-date]) as 'Initial_Bill_Date',
b.[pa-fc],
b.[pa-last-fc],
b.[pa-pt-type],
RANK() OVER (PARTITION BY a.[pa-pt-no-woscd] ORDER BY a.[pa-dtl-date]) as 'Rank'

FROM [Echo_Active].dbo.PatientDemographics b left join [Echo_Active].dbo.DetailInformation a
ON a.[pa-pt-no-woscd]=b.[pa-pt-no-woscd]

WHERE a.[pa-dtl-type-ind]='1'
AND a.[pa-dtl-chg-amt]<> '0'
AND a.[pa-dtl-ins-co-cd] IN ('E','F')--No Fault & W/C
--AND b.[pa-last-fc] NOT IN ('3','5')
--AND b.[pa-fc] IN ('N','W')
AND a.[pa-dtl-date] > '12/31/2014'
--AND a.[pa-dtl-Date] > b.[pa-acct-bd-xfr-date]
--AND b.[pa-acct-bd-xfr-date] > '12/31/14'
AND b.[pa-unit-sts]='N'--'0' has units; '2' no units
--AND a.[pa-dtl-svc-cd-woscd]<> '10202'
)

SELECT [pa-pt-no-woscd],
[pa-pt-no-scd],
[pa-dtl-ins-co-cd],
[pa-dtl-date],
[pa-Initial-Bill-Date],
[Rank],
SUM([pa-dtl-chg-amt]) as 'Payments'

FROM PAIDDATES_CTE

--WHERE [pa-fc] IN ('N','W')
----AND [pa-dtl-date] > [pa-acct-bd-xfr-date]


GROUP BY [pa-pt-no-woscd],
[pa-pt-no-scd],
[pa-dtl-ins-co-cd],
[pa-dtl-date],
[Rank],
[pa-initial-bill-date]

HAVING SUM([pa-dtl-chg-amt])<> '0'

UNION



SELECT [pa-pt-no-woscd],
[pa-pt-no-scd],
[pa-dtl-ins-co-cd],
[pa-dtl-date],
[pa-initial-bill-date],
[Rank],
SUM([pa-dtl-chg-amt]) as 'Payments'

FROM PAIDDATES2_CTE

--WHERE [pa-fc] IN ('3','5')
--AND [pa-dtl-date]>[pa-acct-bd-xfr-date]


GROUP BY [pa-pt-no-woscd],
[pa-pt-no-scd],
[pa-dtl-ins-co-cd],
[pa-dtl-date],
[Rank],
[pa-initial-bill-date]

HAVING SUM([pa-dtl-chg-amt]) <> '0'