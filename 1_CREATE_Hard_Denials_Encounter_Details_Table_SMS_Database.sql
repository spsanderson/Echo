/*Create Table W Denied_Encounter_Details*/
USE [SMS]



IF OBJECT_ID('SMS.dbo.Denied_Encounter_Details','U') IS NOT NULL
DROP TABLE [Denied_Encounter_Details]
GO

CREATE TABLE [Denied_Encounter_Details]

([PA-PT-NO] CHAR(12) NOT NULL,
[PA-PT-NO-WOSCD] CHAR(11) NOT NULL,
[PA-PT-NO-SCD] CHAR(1) NOT NULL,
[PA-DSCH-DATE] DATETIME NULL,
[PA-UNIT-DATE] DATETIME NULL,
[PA-DTL-POST-DATE] DATETIME NULL,
[PA-DTL-SVC-CD] CHAR(9) NULL,
[PA-DTL-TECHNICAL-DESC] CHAR(35) NULL,
[PA-DTL-CHGS] MONEY NULL
);

INSERT INTO [Denied_Encounter_Details]([PA-PT-NO],[PA-PT-NO-WOSCD],[PA-PT-NO-SCD],[PA-DSCH-DATE],[PA-UNIT-DATE],[PA-DTL-POST-DATE],[PA-DTL-SVC-CD],[PA-DTL-TECHNICAL-DESC],[PA-DTL-CHGS])
	  
  

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

select CAST(a.[pa-pt-no-woscd] as varchar) + CAST(a.[pa-pt-no-scd-1] as varchar) as 'PA-PT-NO',
a.[pa-pt-no-woscd],
a.[pa-pt-no-scd-1] as 'PA-PT-NO-SCD',
CASE WHEN b.[pa-acct-type]<> 1 THEN COALESCE(c.[pa-unit-date],b.[pa-dsch-date],b.[pa-adm-date])
ELSE b.[pa-dsch-date]
END as 'Dsch_Date',
c.[pa-unit-date],
a.[pa-dtl-post-date],
CAST(a.[pa-dtl-svc-cd-woscd] as varchar) + CAST(a.[pa-dtl-svc-cd-scd] as varchar) as 'PA-DTL-SVC-CD',
a.[pa-dtl-technical-desc],
SUM(a.[pa-dtl-chg-amt]) as [PA-DTL-CHGS]




FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Active].dbo.[DetailInformation] a INNER join [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Active].dbo.[PatientDemographics] b
ON a.[pa-pt-no-woscd]=b.[pa-pt-no-woscd] and b.[pa-unit-sts]<>'U'
left outer join [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Active].dbo.[UnitizedAccounts] c
ON a.[pa-pt-no-woscd]=c.[pa-pt-no-woscd]


WHERE a.[pa-dtl-svc-cd-woscd] IN ('21141','21142','21901','21905','23752','23754','29701','29705','21143','21144','21145','21146','21147','21148','21810','22750','23302','23303',--Rev Integrity Denial Codes
'20375','20525','21130','21140','21742','21910','21915','22210','2220','22626','22330','22636','23756','23840','24109','29101','23750','29001','29101','28701','28801')
--AND a.[pa-dtl-post-date] > '2012-06-30 00:00:00.000'
--AND a.[pa-dtl-post-date] < '2017-07-01 00:00:00.000'

GROUP BY a.[pa-pt-no-woscd],a.[pa-pt-no-scd-1],b.[pa-acct-type], c.[pa-unit-date],a.[pa-dtl-post-date],b.[pa-dsch-date],b.[pa-adm-date],a.[pa-dtl-svc-cd-woscd],a.[pa-dtl-svc-cd-scd], a.[pa-dtl-technical-desc]

UNION

select CAST(a.[pa-pt-no-woscd] as varchar) + CAST(a.[pa-pt-no-scd-1] as varchar) as 'PA-PT-NO',
a.[pa-pt-no-woscd],
a.[pa-pt-no-scd-1] as 'PA-PT-NO-SCD',
CASE WHEN b.[pa-acct-type]<> 1 THEN COALESCE(c.[pa-unit-date],b.[pa-dsch-date],b.[pa-adm-date])
ELSE b.[pa-dsch-date]
END as 'Dsch_Date',
c.[pa-unit-date],
a.[pa-dtl-post-date],
CAST(a.[pa-dtl-svc-cd-woscd] as varchar) + CAST(a.[pa-dtl-svc-cd-scd] as varchar) as 'PA-DTL-SVC-CD',
a.[pa-dtl-technical-desc],
SUM(a.[pa-dtl-chg-amt]) as [PA-DTL-CHGS]




FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Active].dbo.[DetailInformation] a INNER join [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Active].dbo.[PatientDemographics] b
ON a.[pa-pt-no-woscd]=b.[pa-pt-no-woscd] and b.[pa-unit-sts]='U'  
left outer join [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Active].dbo.[UnitizedAccounts] c
ON a.[pa-pt-no-woscd]=c.[pa-pt-no-woscd] and a.[pa-dtl-unit-date]=c.[pa-unit-date]


WHERE a.[pa-dtl-svc-cd-woscd] IN ('21141','21142','21901','21905','23752','23754','29701','29705','21143','21144','21145','21146','21147','21148','21810','22750','23302','23303',--Rev Integrity Denial Codes
'20375','20525','21130','21140','21742','21910','21915','22210','2220','22626','22330','22636','23756','23840','24109','29101','23750','29001','29101','28701','28801')
--AND a.[pa-dtl-post-date] > '2012-06-30 00:00:00.000'
--AND a.[pa-dtl-post-date] < '2017-07-01 00:00:00.000'

GROUP BY a.[pa-pt-no-woscd],a.[pa-pt-no-scd-1],b.[pa-acct-type], c.[pa-unit-date],a.[pa-dtl-post-date],b.[pa-dsch-date],b.[pa-adm-date],a.[pa-dtl-svc-cd-woscd],a.[pa-dtl-svc-cd-scd], a.[pa-dtl-technical-desc]

UNION

select CAST(a.[pa-pt-no-woscd] as varchar) + CAST(a.[pa-pt-no-scd-1] as varchar) as 'PA-PT-NO',
a.[pa-pt-no-woscd],
a.[pa-pt-no-scd-1] as 'PA-PT-NO-SCD',
CASE WHEN b.[pa-acct-type]<> 1 THEN COALESCE(c.[pa-unit-date],b.[pa-dsch-date],b.[pa-adm-date])
ELSE b.[pa-dsch-date]
END as 'Dsch_Date',
c.[pa-unit-date],
a.[pa-dtl-post-date],
CAST(a.[pa-dtl-svc-cd-woscd] as varchar) + CAST(a.[pa-dtl-svc-cd-scd] as varchar) as 'PA-DTL-SVC-CD',
a.[pa-dtl-technical-desc],
SUM(a.[pa-dtl-chg-amt])




FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Archive].dbo.[DetailInformation] a INNER join [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Archive].dbo.[PatientDemographics] b
ON a.[pa-pt-no-woscd]=b.[pa-pt-no-woscd] and b.[pa-unit-sts]<>'U'
left outer join [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Archive].dbo.[UnitizedAccounts] c
ON a.[pa-pt-no-woscd]=c.[pa-pt-no-woscd]


WHERE a.[pa-dtl-svc-cd-woscd] IN ('21141','21142','21901','21905','23752','23754','29701','29705','21143','21144','21145','21146','21147','21148','21810','22750','23302','23303',--Rev Integrity Denial Codes
'20375','20525','21130','21140','21742','21910','21915','22210','2220','22626','22330','22636','23756','23840','24109','29101','23750','29001','29101','28701','28801')
--AND a.[pa-dtl-post-date] > '2012-06-30 00:00:00.000'
--AND a.[pa-dtl-post-date] < '2017-07-01 00:00:00.000'

GROUP BY a.[pa-pt-no-woscd],a.[pa-pt-no-scd-1],b.[pa-acct-type], c.[pa-unit-date],a.[pa-dtl-post-date],b.[pa-dsch-date],b.[pa-adm-date],a.[pa-dtl-svc-cd-woscd],a.[pa-dtl-svc-cd-scd], a.[pa-dtl-technical-desc]

UNION

select CAST(a.[pa-pt-no-woscd] as varchar) + CAST(a.[pa-pt-no-scd-1] as varchar) as 'PA-PT-NO',
a.[pa-pt-no-woscd],
a.[pa-pt-no-scd-1] as 'PA-PT-NO-SCD',
CASE WHEN b.[pa-acct-type]<> 1 THEN COALESCE(c.[pa-unit-date],b.[pa-dsch-date],b.[pa-adm-date])
ELSE b.[pa-dsch-date]
END as 'Dsch_Date',
c.[pa-unit-date],
a.[pa-dtl-post-date],
CAST(a.[pa-dtl-svc-cd-woscd] as varchar) + CAST(a.[pa-dtl-svc-cd-scd] as varchar) as 'PA-DTL-SVC-CD',
a.[pa-dtl-technical-desc],
SUM(a.[pa-dtl-chg-amt])




FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Archive].dbo.[DetailInformation] a INNER join [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Archive].dbo.[PatientDemographics] b
ON a.[pa-pt-no-woscd]=b.[pa-pt-no-woscd] and b.[pa-unit-sts]='U'  
left outer join [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Archive].dbo.[UnitizedAccounts] c
ON a.[pa-pt-no-woscd]=c.[pa-pt-no-woscd] and a.[pa-dtl-unit-date]=c.[pa-unit-date]


WHERE a.[pa-dtl-svc-cd-woscd] IN ('21141','21142','21901','21905','23752','23754','29701','29705','21143','21144','21145','21146','21147','21148','21810','22750','23302','23303',--Rev Integrity Denial Codes
'20375','20525','21130','21140','21742','21910','21915','22210','2220','22626','22330','22636','23756','23840','24109','29101','23750','29001','29101','28701','28801')
--AND a.[pa-dtl-post-date] > '2012-06-30 00:00:00.000'
--AND a.[pa-dtl-post-date] < '2017-07-01 00:00:00.000'

GROUP BY a.[pa-pt-no-woscd],a.[pa-pt-no-scd-1],b.[pa-acct-type], c.[pa-unit-date],a.[pa-dtl-post-date],b.[pa-dsch-date],b.[pa-adm-date],a.[pa-dtl-svc-cd-woscd],a.[pa-dtl-svc-cd-scd], a.[pa-dtl-technical-desc]
SELECT *


FROM [SMS].DBO.[Denied_Encounter_Details]

--where [pa-pt-no-woscd] = '1010643740'