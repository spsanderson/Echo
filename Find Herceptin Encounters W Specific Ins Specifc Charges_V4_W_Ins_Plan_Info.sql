/****** Script for SelectTopNRows command from SSMS  ******/
 
 
 /*Create Denial Writeoff Temp Table*/

 IF OBJECT_ID('tempdb.dbo.#DenialWriteoffs2','U') IS NOT NULL
 DROP TABLE #DenialWriteoffs2;

 GO

 CREATE TABLE #DenialWriteoffs2
(

[PA-PT-NO] VARCHAR(12) NOT NULL,
[TOTAL-DENIALS] money null
);

INSERT INTO #DenialWriteoffs2 ([PA-PT-NO],[TOTAL-DENIALS])
(
SELECT CAST([pa-pt-no-woscd] as varchar) +CAST([pa-pt-no-scd-1] as varchar) as 'PA-PT-NO',
SUM([pa-dtl-chg-amt]) as 'Total_Denials'
FROM [Echo_Archive].dbo.DetailInformation
WHERE [pa-dtl-svc-cd-woscd] IN ('21141','21142','21901','21905','23752','23754','29701','29705','21143','21144','21145','21146','21147','21148','21810','22750','23302','23303')
GROUP BY CAST([pa-pt-no-woscd] as varchar) +CAST([pa-pt-no-scd-1] as varchar)

UNION

SELECT CAST([pa-pt-no-woscd] as varchar) +CAST([pa-pt-no-scd-1] as varchar) as 'PA-PT-NO',
SUM([pa-dtl-chg-amt]) as 'Total_Denials'
FROM [Echo_Active].dbo.DetailInformation
WHERE [pa-dtl-svc-cd-woscd] IN ('21141','21142','21901','21905','23752','23754','29701','29705','21143','21144','21145','21146','21147','21148','21810','22750','23302','23303')
GROUP BY CAST([pa-pt-no-woscd] as varchar) +CAST([pa-pt-no-scd-1] as varchar)
)
---------------------------------------------------------------------------------------------------------------------------------------------------------


SELECT CAST(A.[PA-PT-NO-WOSCD] as varchar) + CAST(A.[pa-pt-no-scd-1] as varchar) as 'Patient_Control_Account#',
[pa-dtl-gl-no] as 'Department_Code',
b.[pa-ins-co-cd],
b.[pa-ins-plan-no],
--[pa-dtl-type-ind],
CAST([pa-dtl-svc-cd-woscd] as varchar) + CAST([pa-dtl-svc-cd-scd] as varchar) as 'Service_Code',
[pa-dtl-technical-desc] as 'Serivce_Code_Description',
--[pa-dtl-date] as 'Date_Of_Service',
--[pa-dtl-post-date] as 'Posting_Date',
SUM([pa-dtl-chg-qty]) as 'Charge_Quantity',
SUM([pa-dtl-chg-amt]) as 'Charge_Amount',
(CAST(ISNULL(b.[pa-bal-ins-pay-amt],0) as money) + CAST(ISNULL(c.[pa-bal-ins-pay-amt],0) as money) + CAST(ISNULL(d.[pa-bal-ins-pay-amt],0) as money) + CAST(ISNULL(e.[pa-bal-ins-pay-amt],0) as money))+ CAST(ISNULL(f.[pa-bal-tot-pt-pay-amt],0) as money) as 'Tot_Pay_Amt',
g.[TOTAL-DENIALS]

 
 FROM [Echo_Active].[dbo].[DetailInformation] a left outer join [Echo_Active].[dbo].[InsuranceInformation] b
 ON a.[pa-pt-no-woscd]=b.[pa-pt-no-woscd] AND b.[pa-ins-prty]='1'
 left outer join [Echo_Active].[dbo].[InsuranceInformation] c
 ON a.[pa-pt-no-woscd]=c.[pa-pt-no-woscd] and c.[pa-ins-prty]='2'
 left outer join [Echo_Active].[dbo].[InsuranceInformation] d
 ON a.[pa-pt-no-woscd]=d.[pa-pt-no-woscd] and d.[pa-ins-prty]='3'
 left outer join [Echo_Active].[dbo].[InsuranceInformation] e
 ON a.[pa-pt-no-woscd]=e.[pa-pt-no-woscd] and e.[pa-ins-prty]='4'
 left outer join [Echo_Active].[dbo].[PatientDemographics] f
 ON a.[pa-pt-no-woscd]=f.[pa-pt-no-woscd] 
 left outer join [dbo].[#DenialWriteoffs2] g
 ON CAST(a.[pa-pt-no-woscd] as varchar) + CAST(a.[pa-pt-no-scd-1] as varchar)=g.[pa-pt-no]

WHERE [pa-dtl-type-ind] IN ('8','A')
AND [pa-dtl-chg-amt] <> '0'
AND [pa-dtl-svc-cd-woscd]='4157005'
AND f.[pa-acct-type]='0'
--AND b.[pa-ins-co-cd]='M'
--AND a.[pa-dtl-rev-cd] IN ('810','811','812','813')
AND a.[pa-dtl-date] BETWEEN '2015-01-01 00:00:00.000' AND '2017-04-30 23:59:59.000'
--AND a.[pa-dtl-hosp-svc]='RTR'
--AND a.[pa-dtl-gl-no]='741'
--AND b.[pa-hosp-cd]='RTR'

 -- AND a.[pa-dtl-svc-cd-woscd] = '4730002'
 --AND a.[pa-pt-no-woscd] IN

 --(
 --SELECT DISTINCT([pa-pt-no-woscd])
 --FROM [Echo_Active].dbo.DetailInformation
 --WHERE [pa-dtl-svc-cd-woscd] IN ('4730002')
 --AND [pa-dtl-date] BETWEEN '2015-01-01 00:00:00.000' AND '2017-06-01 23:59:59.000'
 --)

 GROUP BY CAST(A.[PA-PT-NO-WOSCD] as varchar) + CAST(A.[pa-pt-no-scd-1] as varchar) ,
[pa-dtl-gl-no] ,
b.[pa-ins-co-cd],
b.[pa-ins-plan-no],
[pa-dtl-type-ind],
CAST([pa-dtl-svc-cd-woscd] as varchar) + CAST([pa-dtl-svc-cd-scd] as varchar) ,
[pa-dtl-technical-desc] ,
--[pa-dtl-date] as 'Date_Of_Service',
--[pa-dtl-post-date] as 'Posting_Date',
(CAST(ISNULL(b.[pa-bal-ins-pay-amt],0) as money) + CAST(ISNULL(c.[pa-bal-ins-pay-amt],0) as money) + CAST(ISNULL(d.[pa-bal-ins-pay-amt],0) as money) + CAST(ISNULL(e.[pa-bal-ins-pay-amt],0) as money))+ CAST(ISNULL(f.[pa-bal-tot-pt-pay-amt],0) as money) ,
g.[TOTAL-DENIALS]



 UNION

 SELECT CAST(A.[PA-PT-NO-WOSCD] as varchar) + CAST(A.[pa-pt-no-scd-1] as varchar) as 'Patient_Control_Account#',
[pa-dtl-gl-no] as 'Department_Code',
b.[pa-ins-co-cd],
b.[pa-ins-plan-no],
--[pa-dtl-type-ind],
CAST([pa-dtl-svc-cd-woscd] as varchar) + CAST([pa-dtl-svc-cd-scd] as varchar) as 'Service_Code',
[pa-dtl-technical-desc] as 'Serivce_Code_Description',
--[pa-dtl-date] as 'Date_Of_Service',
--[pa-dtl-post-date] as 'Posting_Date',
SUM([pa-dtl-chg-qty]) as 'Charge_Quantity',
SUM([pa-dtl-chg-amt]) as 'Charge_Amount',
(CAST(ISNULL(b.[pa-bal-ins-pay-amt],0) as money) + CAST(ISNULL(c.[pa-bal-ins-pay-amt],0) as money) + CAST(ISNULL(d.[pa-bal-ins-pay-amt],0) as money) + CAST(ISNULL(e.[pa-bal-ins-pay-amt],0) as money))+ CAST(ISNULL(f.[pa-bal-tot-pt-pay-amt],0) as money) as 'Tot_Pay_Amt',
g.[TOTAL-DENIALS]
 
 FROM [Echo_Archive].[dbo].[DetailInformation] a left outer join [Echo_Archive].[dbo].[InsuranceInformation] b
 ON a.[pa-pt-no-woscd]=b.[pa-pt-no-woscd] AND b.[pa-ins-prty]='1'
 left outer join [Echo_Archive].[dbo].[InsuranceInformation] c
 ON a.[pa-pt-no-woscd]=c.[pa-pt-no-woscd] and c.[pa-ins-prty]='2'
 left outer join [Echo_Archive].[dbo].[InsuranceInformation] d
 ON a.[pa-pt-no-woscd]=d.[pa-pt-no-woscd] and d.[pa-ins-prty]='3'
 left outer join [Echo_Archive].[dbo].[InsuranceInformation] e
 ON a.[pa-pt-no-woscd]=e.[pa-pt-no-woscd] and e.[pa-ins-prty]='4'
 left outer join [Echo_Archive].[dbo].[PatientDemographics] f
 ON a.[pa-pt-no-woscd]=f.[pa-pt-no-woscd] 
left outer join [dbo].[#DenialWriteoffs2] g
 ON CAST(a.[pa-pt-no-woscd] as varchar) + CAST(a.[pa-pt-no-scd-1] as varchar)=g.[pa-pt-no]


 WHERE [pa-dtl-type-ind] IN ('8','A')
 AND [pa-dtl-chg-amt] <> '0'
 AND [pa-dtl-svc-cd-woscd]='4157005'
 AND f.[pa-acct-type] = '0'
 --AND b.[pa-ins-co-cd]='M'
 --AND a.[pa-dtl-rev-cd] IN ('810','811','812','813')
 AND a.[pa-dtl-date] BETWEEN '2015-01-01 00:00:00.000' AND '2017-04-30 23:59:59.000'
 --AND a.[pa-dtl-hosp-svc]='RTR'
 --AND a.[pa-dtl-gl-no]='741'
 --AND b.[pa-hosp-cd]='RTR'
 --AND a.[pa-dtl-svc-cd-woscd] = '4730002'
 --AND a.[pa-pt-no-woscd] IN

 --(
 --SELECT DISTINCT([pa-pt-no-woscd])
 --FROM [Echo_Archive].dbo.DetailInformation
 --WHERE [pa-dtl-svc-cd-woscd] IN ('4730001')
 --AND [pa-dtl-date] BETWEEN '2015-01-01 00:00:00.000' AND '2017-06-01 23:59:59.000'
 --)

  GROUP BY CAST(A.[PA-PT-NO-WOSCD] as varchar) + CAST(A.[pa-pt-no-scd-1] as varchar) ,
[pa-dtl-gl-no] ,
b.[pa-ins-co-cd],
b.[pa-ins-plan-no],
[pa-dtl-type-ind],
CAST([pa-dtl-svc-cd-woscd] as varchar) + CAST([pa-dtl-svc-cd-scd] as varchar) ,
[pa-dtl-technical-desc] ,
--[pa-dtl-date] as 'Date_Of_Service',
--[pa-dtl-post-date] as 'Posting_Date',
(CAST(ISNULL(b.[pa-bal-ins-pay-amt],0) as money) + CAST(ISNULL(c.[pa-bal-ins-pay-amt],0) as money) + CAST(ISNULL(d.[pa-bal-ins-pay-amt],0) as money) + CAST(ISNULL(e.[pa-bal-ins-pay-amt],0) as money))+ CAST(ISNULL(f.[pa-bal-tot-pt-pay-amt],0) as money) ,
g.[TOTAL-DENIALS]


 --ORDER BY CAST(A.[PA-PT-NO-WOSCD] as varchar) + CAST(A.[pa-pt-no-scd-1] as varchar), [pa-dtl-date],[pa-dtl-svc-cd-woscd]