
----------------------------------------------------------------------------------------------------------------------------------------------------
/*Create Temp Table W Last Active Ins Plan Based Upon MRN Match*/
IF OBJECT_ID('tempdb.dbo.#LastActiveIns','U') IS NOT NULL
DROP TABLE #LastActiveIns;
GO

CREATE TABLE #LastActiveIns

(
[PA-MED-REC-NO] CHAR(20) NOT NULL,
[PA-INS-CD] CHAR(6) NULL,
[PA-LAST-INS-PAY-DATE] DATETIME NULL,
[PA-BAL-INS-PAY-AMT] MONEY NULL,
[INSURED-ENCOUNTER] CHAR(20),
[INS-RANK] CHAR(15) NULL
);

INSERT INTO #LastActiveIns([pa-med-rec-no],[pa-ins-cd],[pa-last-ins-pay-date],[pa-bal-ins-pay-amt],[insured-encounter],[ins-rank])




SELECT [pa-med-rec-no],
[PA-INS-CD],
[pa-last-ins-pay-date],
[pa-bal-ins-pay-amt],
[INSURED-ENCOUNTER],
RANK() OVER (PARTITION BY [pa-med-rec-no] order by [pa-last-ins-pay-date] desc,[INSURED-ENCOUNTER] asc) as 'INS-RANK' 
FROM
(
SELECT a.[pa-med-rec-no],
b.[pa-ins-co-cd] + CAST(b.[pa-ins-plan-no] as varchar) as 'PA-INS-CD',
b.[pa-last-ins-pay-date],
b.[pa-bal-ins-pay-amt],
CAST(b.[pa-pt-no-woscd] as varchar) + CAST(b.[pa-pt-no-scd-1] as varchar) as 'INSURED-ENCOUNTER'
FROM [Echo_Active].dbo.[PatientDemographics] a left outer join [Echo_Active].dbo.[insuranceinformation]b
ON a.[pa-pt-no-woscd]=b.[pa-pt-no-woscd]
where B.[PA-BAL-INS-PAY-AMT] < '0'

UNION 

SELECT a.[pa-med-rec-no],
b.[pa-ins-co-cd] + CAST(b.[pa-ins-plan-no] as varchar) as 'PA-INS-CD',
b.[pa-last-ins-pay-date],
b.[pa-bal-ins-pay-amt],
CAST(b.[pa-pt-no-woscd] as varchar) + CAST(b.[pa-pt-no-scd-1] as varchar) as 'INSURED-ENCOUNTER'
FROM [Echo_Archive].dbo.[PatientDemographics] a left outer join [Echo_Archive].dbo.[insuranceinformation]b
ON a.[pa-pt-no-woscd]=b.[pa-pt-no-woscd]
where B.[PA-BAL-INS-PAY-AMT] < '0'
) AS TABLEA 
;
--------------------------------------------------------------------------------------------------------------------------------------------------

/*Create Temp Table to Capture Active Bad Debt Unit Recoveries*/
IF OBJECT_ID('tempdb.dbo.#BadDebtRecoveriesUnits','U') IS NOT NULL
DROP TABLE #BadDebtRecoveriesUnits;
GO

CREATE TABLE #BadDebtRecoveriesUnits

(
[PA-PT-NO] CHAR(12) NOT NULL,
[PA-DTL-UNIT-DATE] DATETIME NULL,
[BD-RECOVERY] MONEY NULL
);

INSERT INTO #BadDebtRecoveriesUnits([PA-PT-NO],[PA-DTL-UNIT-DATE],[BD-RECOVERY])


Select CAST([pa-pt-no-woscd] as varchar) + CAST([pa-pt-no-scd-1] as varchar) as 'Pa-Pt-No',
[pa-dtl-unit-date],
ISNULL(SUM([pa-dtl-chg-amt]),0) as 'BD-RECOVERY'

FROM [Echo_Active].dbo.[DetailInformation]

WHERE [pa-dtl-type-ind]='1'
AND [pa-dtl-fc] IN ('0','1','2','3','4','5','6','7','8','9')

GROUP BY CAST([pa-pt-no-woscd] as varchar) + CAST([pa-pt-no-scd-1] as varchar),
[pa-dtl-unit-date];
------------------------------------------------------------------------------------------------------------------------------------------------
/*Create Temp Table to Capture Archive Bad Debt Unit Recoveries*/
IF OBJECT_ID('tempdb.dbo.#BadDebtRecoveriesUnitsA','U') IS NOT NULL
DROP TABLE #BadDebtRecoveriesUnitsA;
GO

CREATE TABLE #BadDebtRecoveriesUnitsA

(
[PA-PT-NO] CHAR(12) NOT NULL,
[PA-DTL-UNIT-DATE] DATETIME NULL,
[BD-RECOVERY] MONEY NULL
);

INSERT INTO #BadDebtRecoveriesUnitsA([PA-PT-NO],[PA-DTL-UNIT-DATE],[BD-RECOVERY])


Select CAST([pa-pt-no-woscd] as varchar) + CAST([pa-pt-no-scd-1] as varchar) as 'Pa-Pt-No',
[pa-dtl-unit-date],
ISNULL(SUM([pa-dtl-chg-amt]),0) as 'BD-RECOVERY'

FROM [Echo_Archive].dbo.[DetailInformation]

WHERE [pa-dtl-type-ind]='1'
AND [pa-dtl-fc] IN ('0','1','2','3','4','5','6','7','8','9')

GROUP BY CAST([pa-pt-no-woscd] as varchar) + CAST([pa-pt-no-scd-1] as varchar),
[pa-dtl-unit-date];

-------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------

/*Create Temp Table to Capture Active Bad Debt Unit Recoveries*/
IF OBJECT_ID('tempdb.dbo.#BadDebtRecoveries','U') IS NOT NULL
DROP TABLE #BadDebtRecoveries;
GO

CREATE TABLE #BadDebtRecoveries

(
[PA-PT-NO] CHAR(12) NOT NULL,
[BD-RECOVERY] MONEY NULL
);

INSERT INTO #BadDebtRecoveries([PA-PT-NO],[BD-RECOVERY])


Select CAST([pa-pt-no-woscd] as varchar) + CAST([pa-pt-no-scd-1] as varchar) as 'Pa-Pt-No',
ISNULL(SUM([pa-dtl-chg-amt]),0) as 'BD-RECOVERY'

FROM [Echo_Active].dbo.[DetailInformation]

WHERE [pa-dtl-type-ind]='1'
AND [pa-dtl-fc] IN ('0','1','2','3','4','5','6','7','8','9')

GROUP BY CAST([pa-pt-no-woscd] as varchar) + CAST([pa-pt-no-scd-1] as varchar)
------------------------------------------------------------------------------------------------------------------------------------------------
/*Create Temp Table to Capture Archive Bad Debt Unit Recoveries*/
IF OBJECT_ID('tempdb.dbo.#BadDebtRecoveriesA','U') IS NOT NULL
DROP TABLE #BadDebtRecoveriesA;
GO

CREATE TABLE #BadDebtRecoveriesA

(
[PA-PT-NO] CHAR(12) NOT NULL,
[BD-RECOVERY] MONEY NULL
);

INSERT INTO #BadDebtRecoveriesA([PA-PT-NO],[BD-RECOVERY])


Select CAST([pa-pt-no-woscd] as varchar) + CAST([pa-pt-no-scd-1] as varchar) as 'Pa-Pt-No',
ISNULL(SUM([pa-dtl-chg-amt]),0) as 'BD-RECOVERY'

FROM [Echo_Archive].dbo.[DetailInformation]

WHERE [pa-dtl-type-ind]='1'
AND [pa-dtl-fc] IN ('0','1','2','3','4','5','6','7','8','9')

GROUP BY CAST([pa-pt-no-woscd] as varchar) + CAST([pa-pt-no-scd-1] as varchar)

-------------------------------------------------------------------------------------------------------------------------------------------

/*Create Temp Table of Active Amounts Paid by Encounter, Unit, Payer*/

IF OBJECT_ID('tempdb.dbo.#PaymtsByUnitIns','U') IS NOT NULL
DROP TABLE #PaymtsByUnitIns;
GO

CREATE TABLE #PaymtsByUnitIns

(
[PA-PT-NO] CHAR(12) NOT NULL,
[PA-DTL-UNIT-DATE] DATETIME NULL,
[PA-DTL-INS-CO-CD] CHAR(1) NULL,
[PA-DTL-INS-PLAN-NO]  DECIMAL(3,0) NULL,
[TOT-PYMTS] MONEY NULL
);

INSERT INTO #PAYMTSBYUNITINS([PA-PT-NO],[PA-DTL-UNIT-DATE],[PA-DTL-INS-CO-CD],[PA-DTL-INS-PLAN-NO],[TOT-PYMTS])


Select CAST([pa-pt-no-woscd] as varchar) + CAST([pa-pt-no-scd-1] as varchar) as 'Pa-Pt-No',
[pa-dtl-unit-date],
[pa-dtl-ins-co-cd],
[pa-dtl-ins-plan-no],
ISNULL(SUM([pa-dtl-chg-amt]),0) as 'Tot-Pymts'

FROM [Echo_Active].dbo.[DetailInformation]

WHERE [pa-dtl-type-ind]='1'


GROUP BY CAST([pa-pt-no-woscd] as varchar) + CAST([pa-pt-no-scd-1] as varchar),
[pa-dtl-unit-date],
[pa-dtl-ins-co-cd],
[pa-dtl-ins-plan-no];

---------------------------------------------------------------------------------------------------------------------------------------------------

/*Create Temp Table of Archive Amounts Paid by Encounter, Unit, Payer*/

IF OBJECT_ID('tempdb.dbo.#PaymtsByUnitInsA','U') IS NOT NULL
DROP TABLE #PaymtsByUnitInsA;
GO

CREATE TABLE #PaymtsByUnitInsA

(
[PA-PT-NO] CHAR(12) NOT NULL,
[PA-DTL-UNIT-DATE] DATETIME NULL,
[PA-DTL-INS-CO-CD] CHAR(1) NULL,
[PA-DTL-INS-PLAN-NO]  DECIMAL(3,0) NULL,
[TOT-PYMTS] MONEY NULL
);

INSERT INTO #PAYMTSBYUNITINSA([PA-PT-NO],[PA-DTL-UNIT-DATE],[PA-DTL-INS-CO-CD],[PA-DTL-INS-PLAN-NO],[TOT-PYMTS])


Select CAST([pa-pt-no-woscd] as varchar) + CAST([pa-pt-no-scd-1] as varchar) as 'Pa-Pt-No',
[pa-dtl-unit-date],
[pa-dtl-ins-co-cd],
[pa-dtl-ins-plan-no],
ISNULL(SUM([pa-dtl-chg-amt]),0) as 'Tot-Pymts'

FROM [Echo_Archive].dbo.[DetailInformation]

WHERE [pa-dtl-type-ind]='1'


GROUP BY CAST([pa-pt-no-woscd] as varchar) + CAST([pa-pt-no-scd-1] as varchar),
[pa-dtl-unit-date],
[pa-dtl-ins-co-cd],
[pa-dtl-ins-plan-no];

----------------------------------------------------------------------------------------------------------------------------------------------------

/*Create Temp Table With Active Last Ins Payment Date*/


IF OBJECT_ID('tempdb.dbo.#LastPaymentDates', 'U') IS NOT NULL
  DROP TABLE #LastPaymentDates; 
GO

CREATE TABLE #LastPaymentDates
(
[PA-PT-NO-WOSCD] DECIMAL(11,0) NOT NULL, 
[PA-PT-NO-SCD] CHAR(1) NOT NULL,
[PA-INS-PRTY] DECIMAL(1,0) NULL,
[PA-INS-PLAN] CHAR(10) NULL,
[PA-LAST-INS-PAY-DATE] DATETIME NULL,
[LAST-INS-PAY-AMT] MONEY NULL, 
[RANK1] CHAR(3) NULL
);

INSERT INTO #LastPaymentDates([PA-PT-NO-WOSCD],[PA-PT-NO-SCD],[PA-INS-PRTY],[PA-INS-PLAN],[PA-LAST-INS-PAY-DATE],[LAST-INS-PAY-AMT],[RANK1])

SELECT A.[PA-PT-NO-WOSCD],
A.[PA-PT-NO-SCD-1],
B.[PA-INS-PRTY],
(LTRIM(RTRIM(B.[pa-ins-co-cd])) + CAST(LTRIM(RTRIM(B.[pa-ins-plan-no])) as char)) AS 'PA-INS-PLAN',
B.[PA-LAST-INS-PAY-DATE],
B.[PA-BAL-INS-PAY-AMT],
RANK() OVER (PARTITION BY A.[PA-PT-NO-WOSCD] ORDER BY B.[PA-LAST-INS-PAY-DATE] DESC) AS 'RANK1'

FROM [ECHO_ACTIVE].DBO.PATIENTDEMOGRAPHICS A LEFT OUTER JOIN DBO.INSURANCEINFORMATION B
ON A.[PA-PT-NO-WOSCD]=B.[PA-PT-NO-WOSCD] 

WHERE [PA-BAL-INS-PAY-AMT]<> '0';
------------------------------------------------------------------------------------------------------------------------------------------------------


/*Create Temp Table With Archive Last Ins Payment Date*/


IF OBJECT_ID('tempdb.dbo.#LastPaymentDatesA', 'U') IS NOT NULL
  DROP TABLE #LastPaymentDatesA; 
GO

CREATE TABLE #LastPaymentDatesA
(
[PA-PT-NO-WOSCD] DECIMAL(11,0) NOT NULL,
[PA-PT-NO-SCD] CHAR(1) NOT NULL,
[PA-INS-PRTY] DECIMAL(1,0) NULL,
[PA-INS-PLAN] CHAR(10) NULL,
[PA-LAST-INS-PAY-DATE] DATETIME NULL,
[LAST-INS-PAY-AMT] MONEY NULL, 
[RANK1] CHAR(3) NULL
);

INSERT INTO #LastPaymentDatesA([PA-PT-NO-WOSCD],[PA-PT-NO-SCD],[PA-INS-PRTY],[PA-INS-PLAN],[PA-LAST-INS-PAY-DATE],[LAST-INS-PAY-AMT],[RANK1])

SELECT A.[PA-PT-NO-WOSCD],
A.[PA-PT-NO-SCD-1],
B.[PA-INS-PRTY],
(LTRIM(RTRIM(B.[pa-ins-co-cd])) + CAST(LTRIM(RTRIM(B.[pa-ins-plan-no])) as char)) AS 'PA-INS-PLAN',
B.[PA-LAST-INS-PAY-DATE],
B.[PA-BAL-INS-PAY-AMT],
RANK() OVER (PARTITION BY A.[PA-PT-NO-WOSCD] ORDER BY B.[PA-LAST-INS-PAY-DATE] DESC) AS 'RANK1'

FROM [ECHO_ARCHIVE].DBO.PATIENTDEMOGRAPHICS A LEFT OUTER JOIN DBO.INSURANCEINFORMATION B
ON A.[PA-PT-NO-WOSCD]=B.[PA-PT-NO-WOSCD] 

WHERE [PA-BAL-INS-PAY-AMT]<> '0';



------------------------------------------------------------------------------------------------------------------------------------------------------
 /*Create Active Jzanus Denied Placement Temp Table*/

 IF OBJECT_ID('tempdb.dbo.#JzanusDenied','U') IS NOT NULL
 DROP TABLE #JzanusDenied;

 GO

 CREATE TABLE #JzanusDenied
(

[PA-PT-NO] VARCHAR(12) NOT NULL,
[JZANUS-IND] money null,
[jzanus-comment] varchar(50) null
);

------------------------------------------------------------------------------------------------------------------------------------------------------
 /*Create Archive Jzanus Denied Placement Temp Table*/

 IF OBJECT_ID('tempdb.dbo.#JzanusDeniedA','U') IS NOT NULL
 DROP TABLE #JzanusDeniedA;

 GO

 CREATE TABLE #JzanusDeniedA
(

[PA-PT-NO] VARCHAR(12) NOT NULL,
[JZANUS-IND] money null,
[jzanus-comment] varchar(50) null
);




INSERT INTO #JzanusDeniedA ([PA-PT-NO],[JZANUS-IND],[JZANUS-COMMENT])
SELECT CAST([pa-pt-no-woscd] as varchar) +CAST([pa-pt-no-scd-1] as varchar) as 'PA-PT-NO',
MAX([pa-smart-svc-cd-woscd]) as 'Jzanus-Ind',
[pa-smart-comment] as 'Jzanus-Comment'
FROM [Echo_Archive].dbo.AccountComments
WHERE [pa-smart-svc-cd-woscd] = '200'
GROUP BY CAST([pa-pt-no-woscd] as varchar) +CAST([pa-pt-no-scd-1] as varchar),[pa-smart-comment];

GO
----------------------------------------------------------------------------------------------------------------------------------------------------

SELECT (cast(a.[PA-PT-NO-WOSCD] AS VARCHAR) + cast(a.[PA-PT-NO-SCD-1] AS VARCHAR)) AS 'Pt_No'
,b.[PA-UNIT-NO]
,a.[pa-med-rec-no] as 'MRN'
,a.[pa-pt-name]
,v.[pa-nad-zip-cd2] as 'Pt_Zip'
,v.[pa-nad-city-name] as 'Pt_City'
,COALESCE(DATEADD(DAY,1,EOMONTH(b.[pa-unit-date],-1)),a.[pa-adm-date]) as 'Admit_Date'
,CASE WHEN a.[pa-acct-type]<> 1 THEN COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date])
ELSE a.[pa-dsch-date]
END as 'Dsch_Date'
,b.[pa-unit-date]
,CASE 
WHEN a.[pa-acct-type]<>'1' THEN datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),getdate()) 
ELSE ''
END as 'Age_From_Discharge'
,CASE
WHEN a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),getdate()) between '0' and '30' THEN '1_0-30'
WHEN a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),getdate()) between '31' and '60' THEN '2_31-60'
WHEN a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),getdate()) between '61' and '90' THEN '3_61-90'
WHEN a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),getdate()) between '91' and '120' THEN '4_91-120'
WHEN a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),getdate()) between '121' and '150' THEN '5_121-150'
WHEN a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),getdate()) between '151' and '180' THEN '6_151-180'
WHEN a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),getdate()) between '181' and '210' THEN '7_181-210'
WHEN a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),getdate()) between '211' and '240' THEN '8_211-240'
WHEN a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),getdate()) between '240' and '364' THEN '9_240-364'
WHEN a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),getdate()) between '365' and '729' THEN '10_365-729(1-2YRS)'
WHEN a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),getdate()) between '730' and '1094' THEN '11_730-1094(2-3YRS)'
WHEN a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),getdate()) between '1095' and '1459' THEN '12_1095-1459(3-4YRS)'
WHEN a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),getdate()) between '1460' and '1824' THEN '13_1460-1824(4-5YRS)'
WHEN a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),getdate()) between '1825' and '2189' THEN '14_1825-2189(5-6YRS)'
WHEN a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),getdate()) >= '2190' THEN '15_2190+(6YRS+)'
WHEN a.[pa-acct-type]= 1 THEN 'In House/DNFB'
ELSE ''
END as 'Age_Bucket'
,CASE 
WHEN b.[pa-unit-no] is null and a.[pa-acct-type]<>'1' THEN datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),a.[pa-acct-bd-xfr-date]) 
WHEN b.[pa-unit-no] is not null and a.[pa-acct-type]<>'1' THEN datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),b.[pa-unit-xfr-bd-date]) 
ELSE ''
END as 'Age_At_BD_Referral'
,CASE
WHEN a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),b.[pa-unit-xfr-bd-date]) between '0' and '30' THEN '1_0-30'
WHEN a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),b.[pa-unit-xfr-bd-date]) between '31' and '60' THEN '2_31-60'
WHEN a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),b.[pa-unit-xfr-bd-date]) between '61' and '90' THEN '3_61-90'
WHEN a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),b.[pa-unit-xfr-bd-date]) between '91' and '120' THEN '4_91-120'
WHEN a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),b.[pa-unit-xfr-bd-date]) between '121' and '150' THEN '5_121-150'
WHEN a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),b.[pa-unit-xfr-bd-date]) between '151' and '180' THEN '6_151-180'
WHEN a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),b.[pa-unit-xfr-bd-date]) between '181' and '210' THEN '7_181-210'
WHEN a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),b.[pa-unit-xfr-bd-date]) between '211' and '240' THEN '8_211-240'
WHEN a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),b.[pa-unit-xfr-bd-date]) between '240' and '364' THEN '9_240-364'
WHEN a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),b.[pa-unit-xfr-bd-date]) between '365' and '729' THEN '10_365-729(1-2YRS)'
WHEN a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),b.[pa-unit-xfr-bd-date]) between '730' and '1094' THEN '11_730-1094(2-3YRS)'
WHEN a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),b.[pa-unit-xfr-bd-date]) between '1095' and '1459' THEN '12_1095-1459(3-4YRS)'
WHEN a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),b.[pa-unit-xfr-bd-date]) between '1460' and '1824' THEN '13_1460-1824(4-5YRS)'
WHEN a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),b.[pa-unit-xfr-bd-date]) between '1825' and '2189' THEN '14_1825-2189(5-6YRS)'
WHEN a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),b.[pa-unit-xfr-bd-date]) >= '2190' THEN '15_2190+(6YRS+)'
WHEN b.[pa-unit-no] is null AND a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),a.[pa-acct-bd-xfr-date]) between '0' and '30' THEN '1_0-30'
WHEN b.[pa-unit-no] is null and a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),a.[pa-acct-bd-xfr-date]) between '31' and '60' THEN '2_31-60'
WHEN b.[pa-unit-no] is null and a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),a.[pa-acct-bd-xfr-date]) between '61' and '90' THEN '3_61-90'
WHEN b.[pa-unit-no] is null and a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),a.[pa-acct-bd-xfr-date]) between '91' and '120' THEN '4_91-120'
WHEN b.[pa-unit-no] is null and a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),a.[pa-acct-bd-xfr-date]) between '121' and '150' THEN '5_121-150'
WHEN b.[pa-unit-no] is null and a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),a.[pa-acct-bd-xfr-date]) between '151' and '180' THEN '6_151-180'
WHEN b.[pa-unit-no] is null and a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),a.[pa-acct-bd-xfr-date]) between '181' and '210' THEN '7_181-210'
WHEN b.[pa-unit-no] is null and a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),a.[pa-acct-bd-xfr-date]) between '211' and '240' THEN '8_211-240'
WHEN b.[pa-unit-no] is null and a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),a.[pa-acct-bd-xfr-date]) between '240' and '364' THEN '9_240-364'
WHEN b.[pa-unit-no] is null and a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),a.[pa-acct-bd-xfr-date]) between '365' and '729' THEN '10_365-729(1-2YRS)'
WHEN b.[pa-unit-no] is null and a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),a.[pa-acct-bd-xfr-date]) between '730' and '1094' THEN '11_730-1094(2-3YRS)'
WHEN b.[pa-unit-no] is null and a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),a.[pa-acct-bd-xfr-date]) between '1095' and '1459' THEN '12_1095-1459(3-4YRS)'
WHEN b.[pa-unit-no] is null and a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),a.[pa-acct-bd-xfr-date]) between '1460' and '1824' THEN '13_1460-1824(4-5YRS)'
WHEN b.[pa-unit-no] is null and a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),a.[pa-acct-bd-xfr-date]) between '1825' and '2189' THEN '14_1825-2189(5-6YRS)'
WHEN b.[pa-unit-no] is null and a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),a.[pa-acct-bd-xfr-date]) >= '2190' THEN '15_2190+(6YRS+)'
WHEN a.[pa-acct-type]= 1 THEN 'In House/DNFB'
ELSE ''
END as 'Age_At_BD_Xfr_Bucket'
,a.[pa-acct-type]
,CASE
WHEN b.[pa-unit-no] IS NULL THEN a.[pa-acct-bd-xfr-date]
ELSE b.[pa-unit-xfr-bd-date]
END as 'Bad_Debt_Xfr_Date'
,COALESCE(b.[pa-unit-op-first-ins-bl-date],a.[pa-final-bill-date],a.[pa-op-first-ins-bl-date]) as '1st_Bl_Date'
,COALESCE((b.[pa-unit-ins1-bal] + b.[pa-unit-ins2-bal] + b.[pa-unit-ins3-bal]+b.[pa-unit-ins4-bal]+b.[pa-unit-pt-bal]),a.[pa-bal-acct-bal]) as 'Balance'
,COALESCE(b.[pa-unit-pt-bal],a.[pa-bal-pt-bal]) as 'Pt_Balance'
,COALESCE(b.[pa-unit-tot-chg-amt],a.[pa-bal-tot-chg-amt]) as 'Tot_Chgs'
,CASE
WHEN b.[pa-unit-no] is null THEN a.[pa-bal-tot-pt-pay-amt] 
ELSE ISNULL(t.[TOT-PYMTS],0)
END as 'Pt-Pymts'
,CASE
WHEN a.[pa-acct-type] in ('0','6','7') THEN 'OP' --0=OP; 6=OP BAD DEBT; 7=OP HISTORIC
WHEN a.[pa-acct-type] in ('1','2','4','8') THEN 'IP'  --1=IP; 2=A/R; 4=I/P BAD DEBT; 8=I/P HISTORIC
ELSE ''
END AS 'PtAcct_Type'
,CASE
WHEN a.[pa-acct-type] in ('6','4') THEN 'Bad Debt'
WHEN a.[pa-dsch-date] is not null and a.[pa-acct-type]='1' THEN 'DNFB'
WHEN a.[pa-acct-type] = '1' THEN 'Inhouse'
ELSE 'A/R'
END as 'File'
,a.[pa-fc] as 'FC'
,CASE
WHEN a.[pa-fc]='1' THEN 'Bad Debt Medicaid Pending'
WHEN a.[pa-fc] in ('2','6') THEN 'Bad Debt AG'
WHEN a.[pa-fc]='3' THEN 'MCS'
WHEN a.[pa-fc]='4' THEN 'Bad Debt AG Legal'
WHEN a.[pa-fc]='5' THEN 'Bad Debt POM'
WHEN a.[pa-fc]='8' THEN 'Bad Debt AG Exchange Plans'
WHEN a.[pa-fc]='9' THEN 'Kopp-Bad Debt'
WHEN a.[pa-fc]='A' THEN 'Commercial'
WHEN a.[pa-fc]='B' THEN 'Blue Cross'
WHEN a.[pa-fc]='C' THEN 'Champus'
WHEN a.[pa-fc]='D' THEN 'Medicaid'
WHEN a.[pa-fc]='E' THEN 'Employee Health Svc'
WHEN a.[pa-fc]='G' THEN 'Contract Accts'
WHEN a.[pa-fc]='H' THEN 'Medicare HMO'
WHEN a.[pa-fc]='I' THEN 'Balance After Ins'
WHEN a.[pa-fc]='J' THEN 'Managed Care'
WHEN a.[pa-fc]='K' THEN 'Pending Medicaid'
WHEN a.[pa-fc]='M' THEN 'Medicare'
WHEN a.[pa-fc]='N' THEN 'No-Fault'
WHEN a.[pa-fc]='P' THEN 'Self Pay'
WHEN a.[pa-fc]='R' THEN 'Aergo Commercial'
WHEN a.[pa-fc]='T' THEN 'RTR WC NF'
WHEN a.[pa-fc]='S' THEN 'Special Billing'
WHEN a.[pa-fc]='U' THEN 'Medicaid Mgd Care'
WHEN a.[pa-fc]='V' THEN 'First Source'
WHEN a.[pa-fc]='W' THEN 'Workers Comp'
WHEN a.[pa-fc]='X' THEN 'Control Accts'
WHEN a.[pa-fc]='Y' THEN 'MCS'
WHEN a.[pa-fc]='Z' THEN 'Unclaimed Credits'
ELSE ''
END as 'FC_Description'
,a.[pa-hosp-svc]
,CASE
WHEN a.[PA-HOSP-SVC]='ABC' THEN 'Ambulatory Breast Care'
WHEN a.[PA-HOSP-SVC]='ABD' THEN 'ACC Breast Diagnosis'
WHEN a.[PA-HOSP-SVC]='ACA' THEN 'Amb Care Admit'
WHEN a.[PA-HOSP-SVC]='ACP' THEN 'Amb Cancer Provider'
WHEN a.[PA-HOSP-SVC]='ACU' THEN 'Discontinued AIDS'
WHEN a.[PA-HOSP-SVC]='ALG' THEN 'Allergy'
WHEN a.[PA-HOSP-SVC]='ALL' THEN 'Allergy Rhematology'
WHEN a.[PA-HOSP-SVC]='ALS' THEN 'Amotroph Ltl Sclsis'
WHEN a.[PA-HOSP-SVC]='AND' THEN 'Andrology Lab'
WHEN a.[PA-HOSP-SVC]='ANT' THEN 'Antepartum Testing'
WHEN a.[PA-HOSP-SVC]='AOI' THEN ' Apnea Of Infancy'
WHEN a.[PA-HOSP-SVC]='APN' THEN 'Ambulatory Pain'
WHEN a.[PA-HOSP-SVC]='APP' THEN 'Ambulatory Pain Proc'
WHEN a.[PA-HOSP-SVC]='APV' THEN 'Adult Patient Visit'
WHEN a.[PA-HOSP-SVC]='ARI' THEN 'Ambulatory MRI'
WHEN a.[PA-HOSP-SVC]='ARP' THEN 'Anal Rectal Phsyiol'
WHEN a.[PA-HOSP-SVC]='ARY' THEN 'Ambulatory X-Ray'
WHEN a.[PA-HOSP-SVC]='ASC' THEN 'Ambulatory Surgery Center'
WHEN a.[PA-HOSP-SVC]='AUC' THEN 'Adult Urgent Care'
WHEN a.[PA-HOSP-SVC]='AUD' THEN 'Audiology'
WHEN a.[PA-HOSP-SVC]='AUT' THEN 'Autopsy'
WHEN a.[PA-HOSP-SVC]='AXP' THEN 'ACC Radiology Procedure'
WHEN a.[PA-HOSP-SVC]='BCK' THEN 'Back School'
WHEN a.[PA-HOSP-SVC]='BKO' THEN 'Back Other'
WHEN a.[PA-HOSP-SVC]='BLD' THEN 'MODQ'
WHEN a.[PA-HOSP-SVC]='BMD' THEN 'Osteoporosis'
WHEN a.[PA-HOSP-SVC]='BMT' THEN 'Bone Marow Trns'
WHEN a.[PA-HOSP-SVC]='BNL' THEN 'Brkhaven Nat Lab'
WHEN a.[PA-HOSP-SVC]='BRE' THEN 'Breast Center'
WHEN a.[PA-HOSP-SVC]='BRN' THEN 'Burn Center'
WHEN a.[PA-HOSP-SVC]='BRP' THEN 'Breast Procedure'
WHEN a.[PA-HOSP-SVC]='BRS' THEN 'Breast Surgery'
WHEN a.[PA-HOSP-SVC]='BUR' THEN 'Burn Unit For OPBC'
WHEN a.[PA-HOSP-SVC]='CAD' THEN 'Cardiology IP'
WHEN a.[PA-HOSP-SVC]='CAM' THEN 'Comp Alternative Med'
WHEN a.[PA-HOSP-SVC]='CAR' THEN 'Cardiology OP'
WHEN a.[PA-HOSP-SVC]='CCF' THEN 'Cleft Cranial Facial'
WHEN a.[PA-HOSP-SVC]='CCL' THEN 'Cody Center Life'
WHEN a.[PA-HOSP-SVC]='CCP' THEN 'Cody Center Patients'
WHEN a.[PA-HOSP-SVC]='CCU' THEN 'Coron ICU'
WHEN a.[PA-HOSP-SVC]='CDT' THEN 'Cardiothoracic'
WHEN a.[PA-HOSP-SVC]='CDY' THEN 'Cardiology'
WHEN a.[PA-HOSP-SVC]='COL' THEN 'Colo-rectal Oncology'
WHEN a.[PA-HOSP-SVC]='COU' THEN 'Anticoagulation'
WHEN a.[PA-HOSP-SVC]='CPT' THEN 'Cath Pre-Testing'
WHEN a.[PA-HOSP-SVC]='CPU' THEN 'Chest Pain Unit'
WHEN a.[PA-HOSP-SVC]='CRB' THEN 'Cardiac Rehab'
WHEN a.[PA-HOSP-SVC]='CRC' THEN 'GREC Grant OP'
WHEN a.[PA-HOSP-SVC]='CRD' THEN 'Cardiology Testing'
WHEN a.[PA-HOSP-SVC]='CRS' THEN 'Colorectal Surgery'
WHEN a.[PA-HOSP-SVC]='CRU' THEN 'GREC Grant IP'
WHEN a.[PA-HOSP-SVC]='CSA' THEN 'Ambulance'
WHEN a.[PA-HOSP-SVC]='CSS' THEN 'Short Stay Cardiac'
WHEN a.[PA-HOSP-SVC]='CTD' THEN 'Cadaver Donor'
WHEN a.[PA-HOSP-SVC]='CTH' THEN 'Cardiac Catheterization'
WHEN a.[PA-HOSP-SVC]='CTP' THEN 'Child Tech Park'
WHEN a.[PA-HOSP-SVC]='CUC' THEN 'Cardiac Urgent Care'
WHEN a.[PA-HOSP-SVC]='CVC' THEN 'Cerebrovascular Center'
WHEN a.[PA-HOSP-SVC]='CVU' THEN 'Cardio ICU'
WHEN a.[PA-HOSP-SVC]='CYT' THEN 'Cytogenics'
WHEN a.[PA-HOSP-SVC]='DBM' THEN 'Donor Bone Marrow'
WHEN a.[PA-HOSP-SVC]='DDP' THEN 'Development Disab Pt'
WHEN a.[PA-HOSP-SVC]='DEN' THEN 'Dental'
WHEN a.[PA-HOSP-SVC]='DER' THEN 'Dermatology'
WHEN a.[PA-HOSP-SVC]='DIA' THEN 'Dialysis'
WHEN a.[PA-HOSP-SVC]='DIB' THEN 'Diabetes OPD'
WHEN a.[PA-HOSP-SVC]='DIH' THEN 'Home Dialysis'
WHEN a.[PA-HOSP-SVC]='DIS' THEN 'Disaster Patient'
WHEN a.[PA-HOSP-SVC]='DNT' THEN 'Dental'
WHEN a.[PA-HOSP-SVC]='DOF' THEN 'Dialysis Outside Fac'
WHEN a.[PA-HOSP-SVC]='DON' THEN 'Dental Oncology'
WHEN a.[PA-HOSP-SVC]='DPA' THEN 'Dental Pathology'
WHEN a.[PA-HOSP-SVC]='DPC' THEN 'Dermatology Procedure'
WHEN a.[PA-HOSP-SVC]='DRM' THEN 'Dermatology Module'
WHEN a.[PA-HOSP-SVC]='DUV' THEN 'Dermatology UV Therapy'
WHEN a.[PA-HOSP-SVC]='ECG' THEN 'ECG'
WHEN a.[PA-HOSP-SVC]='ECT' THEN 'Electroconvulsive Therapy'
WHEN a.[PA-HOSP-SVC]='EDA' THEN 'ED Admission'
WHEN a.[PA-HOSP-SVC]='EDT' THEN 'ED Admissions/Billing'
WHEN a.[PA-HOSP-SVC]='EEC' THEN 'EECP Treatments'
WHEN a.[PA-HOSP-SVC]='EEG' THEN 'OPEG'
WHEN a.[PA-HOSP-SVC]='EHS' THEN 'Emp Health Svc'
WHEN a.[PA-HOSP-SVC]='ELC' THEN 'Amb Lung Cancer Eval'
WHEN a.[PA-HOSP-SVC]='ELI' THEN 'Eastern Long Island Hosp'
WHEN a.[PA-HOSP-SVC]='EMD' THEN 'Emergency Dental'
WHEN a.[PA-HOSP-SVC]='EMR' THEN 'Emergency'
WHEN a.[PA-HOSP-SVC]='EMS' THEN 'Emergency Med Serv'
WHEN a.[PA-HOSP-SVC]='EMT' THEN 'Ambulance'
WHEN a.[PA-HOSP-SVC]='ENC' THEN 'Endocrinology'
WHEN a.[PA-HOSP-SVC]='END' THEN 'Endocrine'
WHEN a.[PA-HOSP-SVC]='ENO' THEN 'Endoscopy'
WHEN a.[PA-HOSP-SVC]='ENT' THEN 'ENT'
WHEN a.[PA-HOSP-SVC]='EOB' THEN 'ED Observation'
WHEN a.[PA-HOSP-SVC]='EPS' THEN 'EP Lab'
WHEN a.[PA-HOSP-SVC]='EPX' THEN 'Emergency Spec Proc'
WHEN a.[PA-HOSP-SVC]='ESS' THEN 'Endoscopic Swallow Study'
WHEN a.[PA-HOSP-SVC]='EYE' THEN 'Eye'
WHEN a.[PA-HOSP-SVC]='FAM' THEN 'Family Medicine OP'
WHEN a.[PA-HOSP-SVC]='FMD' THEN 'Family Medicine IP'
WHEN a.[PA-HOSP-SVC]='FMN' THEN 'Family Med Newborn'
WHEN a.[PA-HOSP-SVC]='FMO' THEN 'Family Medicine Obs'
WHEN a.[PA-HOSP-SVC]='FMP' THEN 'Family Medicine Patchogue'
WHEN a.[PA-HOSP-SVC]='FNA' THEN 'Fine Needle Aspiration'
WHEN a.[PA-HOSP-SVC]='FOB' THEN 'FOB Family Med Obs'
WHEN a.[PA-HOSP-SVC]='FPD' THEN 'FPD Family Med Ped'
WHEN a.[PA-HOSP-SVC]='GAS' THEN 'Gastroenterology'
WHEN a.[PA-HOSP-SVC]='GEN' THEN 'General Medicine'
WHEN a.[PA-HOSP-SVC]='GER' THEN 'Geriatrics'
WHEN a.[PA-HOSP-SVC]='GFL' THEN 'Gift of Life'
WHEN a.[PA-HOSP-SVC]='GMA' THEN 'Gen Med Team A'
WHEN a.[PA-HOSP-SVC]='GMB' THEN 'Gen Med Team B'
WHEN a.[PA-HOSP-SVC]='GMC' THEN 'Gen Med Team C'
WHEN a.[PA-HOSP-SVC]='GMD' THEN 'Gen Med Team D'
WHEN a.[PA-HOSP-SVC]='GME' THEN 'Gen Med Team E'
WHEN a.[PA-HOSP-SVC]='GMF' THEN 'Gen Med Team F'
WHEN a.[PA-HOSP-SVC]='GMG' THEN 'Gen Med Team G'
WHEN a.[PA-HOSP-SVC]='GMH' THEN 'Gen Med Team H'
WHEN a.[PA-HOSP-SVC]='GMK' THEN 'Gen Med Team K'
WHEN a.[PA-HOSP-SVC]='GMW' THEN 'Gen Med Team W'
WHEN a.[PA-HOSP-SVC]='GMX' THEN 'Gen Med Flex'
WHEN a.[PA-HOSP-SVC]='GMY' THEN 'Gen Med Team Y'
WHEN a.[PA-HOSP-SVC]='GMZ' THEN 'Gen Med Team Z'
WHEN a.[PA-HOSP-SVC]='GNC' THEN 'Gyn-Oncology'
WHEN a.[PA-HOSP-SVC]='GNE' THEN 'Gynecology OP'
WHEN a.[PA-HOSP-SVC]='GNO' THEN 'Gynecology OP'
WHEN a.[PA-HOSP-SVC]='GNP' THEN 'Gyn Patchogue'
WHEN a.[PA-HOSP-SVC]='GON' THEN 'Ancology'
WHEN a.[PA-HOSP-SVC]='GSG' THEN 'General Surgery'
WHEN a.[PA-HOSP-SVC]='GSR' THEN 'General Surgery Red'
WHEN a.[PA-HOSP-SVC]='GST' THEN 'Gastroenterology'
WHEN a.[PA-HOSP-SVC]='GSW' THEN 'General Surgery White'
WHEN a.[PA-HOSP-SVC]='GSX' THEN 'General Surgery X'
WHEN a.[PA-HOSP-SVC]='GYN' THEN 'Gynecology'
WHEN a.[PA-HOSP-SVC]='HEM' THEN 'Hematology OP'
WHEN a.[PA-HOSP-SVC]='HMA' THEN 'Hematology IP'
WHEN a.[PA-HOSP-SVC]='HND' THEN 'Hand Surgery'
WHEN a.[PA-HOSP-SVC]='HOB' THEN 'Hospital Observation'
WHEN a.[PA-HOSP-SVC]='HSC' THEN 'Health Screening Cnt'
WHEN a.[PA-HOSP-SVC]='HTY' THEN 'Hand Therapy'
WHEN a.[PA-HOSP-SVC]='ICD' THEN 'Islandia Cardiology'
WHEN a.[PA-HOSP-SVC]='IGM' THEN 'Islandia General Med'
WHEN a.[PA-HOSP-SVC]='IGN' THEN 'Gyn Islip'
WHEN a.[PA-HOSP-SVC]='IMM' THEN 'IMM AIDS O/P'
WHEN a.[PA-HOSP-SVC]='IMU' THEN 'Discontinued AIDS I/P'
WHEN a.[pa-hosp-svc]='IND' THEN 'Infectious Diseases'
WHEN a.[pa-hosp-svc]='INF' THEN 'Infections Diseases'
WHEN a.[pa-hosp-svc]='INJ' THEN 'Injection'
WHEN a.[pa-hosp-svc]='IOB' THEN 'OB Islip'
WHEN a.[pa-hosp-svc]='IPD' THEN 'Peds Islip'
WHEN a.[pa-hosp-svc]='IPS' THEN 'Psych ER Observation'
WHEN a.[pa-hosp-svc]='IRC' THEN 'Intervent Rad Clinic'
WHEN a.[pa-hosp-svc]='ISC' THEN 'Islandia Congestive'
WHEN a.[pa-hosp-svc]='KAC' THEN 'Medicaid Anesth Pain'
WHEN a.[pa-hosp-svc]='KFM' THEN 'Medicaid Family Medicine'
WHEN a.[pa-hosp-svc]='KGY' THEN 'Medicaid Gynecology'
WHEN a.[pa-hosp-svc]='KMC' THEN 'Medicaid Cardiology'
WHEN a.[pa-hosp-svc]='KMG' THEN 'Medicaid Gastroenterology'
WHEN a.[pa-hosp-svc]='KMR' THEN 'Medicaid General Med'
WHEN a.[pa-hosp-svc]='KMS' THEN 'Medicaid Med Special'
WHEN a.[pa-hosp-svc]='KNE' THEN 'Medicaid Neurology'
WHEN a.[pa-hosp-svc]='KOB' THEN 'Medicaid Obstetrics'
WHEN a.[pa-hosp-svc]='KOP' THEN 'MEdicaid Opthamology'
WHEN a.[pa-hosp-svc]='KPC' THEN 'Medicaid Ped Cody Ct'
WHEN a.[pa-hosp-svc]='KPI' THEN 'Medicaid Ped Islip'
WHEN a.[pa-hosp-svc]='KPM' THEN 'Medicaid Ped E Moriches'
WHEN a.[pa-hosp-svc]='KPN' THEN 'Medicaid Pain'
WHEN a.[pa-hosp-svc]='KPP' THEN 'Medicaid Pain Procedure'
WHEN a.[pa-hosp-svc]='KPT' THEN 'Medicaid Ped Tech Park'
WHEN a.[pa-hosp-svc]='KPY' THEN 'Medicaid Psychiatry'
WHEN a.[pa-hosp-svc]='KSG' THEN 'Medicaid Surgery Service'
WHEN a.[pa-hosp-svc]='KUR' THEN 'Medicaid Urology'
WHEN a.[pa-hosp-svc]='LAB' THEN 'Lab Specimens'
WHEN a.[pa-hosp-svc]='LAD' THEN 'Labor and Delivery'
WHEN a.[pa-hosp-svc]='LCC' THEN 'Life Center at HB'
WHEN a.[pa-hosp-svc]='LCE' THEN 'Lung Cancer Eval'
WHEN a.[pa-hosp-svc]='LGD' THEN 'Lou Gehrigs Disease'
WHEN a.[pa-hosp-svc]='LID' THEN 'LIVH Day Care'
WHEN a.[pa-hosp-svc]='LIQ' THEN 'LI Queens Med Group'
WHEN a.[pa-hosp-svc]='LIV' THEN 'LI Vet Home'
WHEN a.[pa-hosp-svc]='LLT' THEN 'Leukemia Lymp Trnplt'
WHEN a.[pa-hosp-svc]='LRD' THEN 'Liv Rel Donor'
WHEN a.[pa-hosp-svc]='LSA' THEN 'LSARD'
WHEN a.[pa-hosp-svc]='LVD' THEN 'Left Ventric Ass Dev'
WHEN a.[pa-hosp-svc]='LYM' THEN 'Lymphedema Therapy'
WHEN a.[pa-hosp-svc]='MAS' THEN 'Maternity Amb Surgery'
WHEN a.[pa-hosp-svc]='MCU' THEN 'Medical ICU'
WHEN a.[pa-hosp-svc]='MEM' THEN 'Med East Moriches'
WHEN a.[pa-hosp-svc]='MET' THEN 'MTU O/P Research'
WHEN a.[pa-hosp-svc]='MIU' THEN 'Medical ICU 2'
WHEN a.[pa-hosp-svc]='MOL' THEN 'Med Oncology IP'
WHEN a.[pa-hosp-svc]='MON' THEN 'Med Oncology OP'
WHEN a.[pa-hosp-svc]='MOP' THEN 'Medical Oncology Proc'
WHEN a.[pa-hosp-svc]='MOT' THEN 'Motility Lab'
WHEN a.[pa-hosp-svc]='MPC' THEN 'Med Procedure'
WHEN a.[pa-hosp-svc]='MRI' THEN 'MRI'
WHEN a.[pa-hosp-svc]='MSC' THEN 'Misc Income'
WHEN a.[pa-hosp-svc]='MSS' THEN 'Short Stay Medicine'
WHEN a.[pa-hosp-svc]='MST' THEN 'Massage Therapy'
WHEN a.[pa-hosp-svc]='MTU' THEN 'Metabolic Treatment'
WHEN a.[pa-hosp-svc]='MUC' THEN 'Maternity Urgent Care'
WHEN a.[pa-hosp-svc]='NBN' THEN 'Non Burn'
WHEN a.[pa-hosp-svc]='NBS' THEN 'Neck, Back, Spine'
WHEN a.[pa-hosp-svc]='NCU' THEN 'Neurosurgical ICU'
WHEN a.[pa-hosp-svc]='NEP' THEN 'Nephrology OP'
WHEN a.[pa-hosp-svc]='NER' THEN 'Neurology'
WHEN a.[pa-hosp-svc]='NES' THEN 'Neurosurgery'
WHEN a.[pa-hosp-svc]='NEU' THEN 'Neurology'
WHEN a.[pa-hosp-svc]='NEW' THEN 'Newborn'
WHEN a.[pa-hosp-svc]='NEY' THEN 'Neurology OP'
WHEN a.[pa-hosp-svc]='NMD' THEN 'NAtional Marrow Donor'
WHEN a.[pa-hosp-svc]='NNU' THEN 'Neonatal ICU'
WHEN a.[pa-hosp-svc]='NOP' THEN 'Nutrition OP'
WHEN a.[pa-hosp-svc]='NPH' THEN 'Nephrology IP'
WHEN a.[pa-hosp-svc]='NPT' THEN 'Neuro Psycholog Test'
WHEN a.[pa-hosp-svc]='NPY' THEN 'Nephrology OP'
WHEN a.[pa-hosp-svc]='NSO' THEN 'Neurosurgery Oncology'
WHEN a.[pa-hosp-svc]='NSP' THEN 'Neuro Special Proced'
WHEN a.[pa-hosp-svc]='NSY' THEN 'Tech PArk Neurosurg'
WHEN a.[pa-hosp-svc]='NTF' THEN 'Nutrit Target Fitnes'
WHEN a.[pa-hosp-svc]='NTN' THEN 'Nutritional Svcs OP'
WHEN a.[pa-hosp-svc]='NTR' THEN 'Non Transplant'
WHEN a.[pa-hosp-svc]='NUS' THEN 'Neurosurgery IP'
WHEN a.[pa-hosp-svc]='NVB' THEN 'Non-Viable Births'
WHEN a.[pa-hosp-svc]='OBE' THEN 'Obstetrics'
WHEN a.[pa-hosp-svc]='OBP' THEN 'OB Patchogue'
WHEN a.[pa-hosp-svc]='OBS' THEN 'Obstetrics IP'
WHEN a.[pa-hosp-svc]='OBT' THEN 'Obstetrics OP'
WHEN a.[pa-hosp-svc]='OCC' THEN 'Occupational Therapy'
WHEN a.[pa-hosp-svc]='OCM' THEN 'Occupational Med'
WHEN a.[pa-hosp-svc]='ODM' THEN 'Dermatology-Oncology'
WHEN a.[pa-hosp-svc]='OEM' THEN 'Outpat East Moriches'
WHEN a.[pa-hosp-svc]='OGN' THEN 'Amb Gyn Oncology'
WHEN a.[pa-hosp-svc]='OLL' THEN 'OP Leukemia Lymphoma'
WHEN a.[pa-hosp-svc]='OLR' THEN 'Otolaryngology'
WHEN a.[pa-hosp-svc]='OMH' THEN 'Ofc of Mental Health'
WHEN a.[pa-hosp-svc]='ONC' THEN 'Amb Surgic Oncolog'
WHEN a.[pa-hosp-svc]='OPH' THEN 'Opthamology'
WHEN a.[pa-hosp-svc]='ORC' THEN 'Orthoped Surg Oncol'
WHEN a.[pa-hosp-svc]='ORG' THEN 'Organ Retrieval'
WHEN a.[pa-hosp-svc]='ORT' THEN 'Orthopedics'
WHEN a.[pa-hosp-svc]='OSR' THEN 'Ortho Surgery'
WHEN a.[pa-hosp-svc]='OTH' THEN 'Orthopedics'
WHEN a.[pa-hosp-svc]='OTP' THEN 'Tech Park Orthopedic'
WHEN a.[pa-hosp-svc]='OUR' THEN 'Amb Urology Oncology'
WHEN a.[pa-hosp-svc]='OUT' THEN 'OP Lab Testing'
WHEN a.[pa-hosp-svc]='PAT' THEN 'Preadmit Test'
WHEN a.[pa-hosp-svc]='PCH' THEN 'OP Psychiatry'
WHEN a.[pa-hosp-svc]='PCT' THEN 'Pediatric Cardiac IP'
WHEN a.[pa-hosp-svc]='PCU' THEN 'Pediatric ICU'
WHEN a.[pa-hosp-svc]='PCY' THEN 'OP Child Psych'
WHEN a.[pa-hosp-svc]='PDP' THEN 'OP Peds Patchogue'
WHEN a.[pa-hosp-svc]='PDS' THEN 'OP Pediatrics'
WHEN a.[pa-hosp-svc]='PEA' THEN 'Psych ER'
WHEN a.[pa-hosp-svc]='PED' THEN 'IP Pediatrics'
WHEN a.[pa-hosp-svc]='PEM' THEN 'Peds East Moriches'
WHEN a.[pa-hosp-svc]='PES' THEN 'Psych ER'
WHEN a.[pa-hosp-svc]='PET' THEN 'Psych Ed Admit/Bill'
WHEN a.[pa-hosp-svc]='PFM' THEN 'TP Family Med'
WHEN a.[pa-hosp-svc]='PFT' THEN 'OPPF'
WHEN a.[pa-hosp-svc]='PGM' THEN 'TP General Med'
WHEN a.[pa-hosp-svc]='PGY' THEN 'TP OB/Gyn Med'
WHEN a.[pa-hosp-svc]='PHO' THEN 'IP Ped Hematology/Oncology'
WHEN a.[pa-hosp-svc]='PHU' THEN 'Ped Hematology Int C'
WHEN a.[pa-hosp-svc]='PHY' THEN 'Physical Therapy'
WHEN a.[pa-hosp-svc]='PIC' THEN 'IP Pulmonary Inter Care'
WHEN a.[pa-hosp-svc]='PIM' THEN 'OP Ped AIDS Visit'
WHEN a.[pa-hosp-svc]='PIN' THEN 'Pediatric Trasfus/Infus'
WHEN a.[pa-hosp-svc]='PLB' THEN 'OP Ped Pulmonary'
WHEN a.[pa-hosp-svc]='PLM' THEN 'IP Pulmonary'
WHEN a.[pa-hosp-svc]='PLY' THEN 'OP Pulmonary'
WHEN a.[pa-hosp-svc]='PMA' THEN 'Pain Management Anes'
WHEN a.[pa-hosp-svc]='PMM' THEN 'Ped AIDS OP'
WHEN a.[pa-hosp-svc]='PMU' THEN 'IP Discontinued Ped Aid'
WHEN a.[pa-hosp-svc]='PMX' THEN 'Prive Med Team X'
WHEN a.[pa-hosp-svc]='PNC' THEN 'Pain Clinic'
WHEN a.[pa-hosp-svc]='POB' THEN 'TP OB/GYN Med'
WHEN a.[pa-hosp-svc]='POC' THEN 'Pediatric Oncology Consult'
WHEN a.[pa-hosp-svc]='POL' THEN 'Pool Mntn Prog'
WHEN a.[pa-hosp-svc]='PON' THEN 'Pediatric Oncology'
WHEN a.[pa-hosp-svc]='POP' THEN 'Psychiatry Outpt'
WHEN a.[pa-hosp-svc]='PPC' THEN 'Patchogue PC'
WHEN a.[pa-hosp-svc]='PPG' THEN 'Pain Program'
WHEN a.[pa-hosp-svc]='PPR' THEN 'Pharmaceutic Proveng'
WHEN a.[pa-hosp-svc]='PPV' THEN 'Ped Physician Visit'
WHEN a.[pa-hosp-svc]='PPY' THEN 'IP Pediatric Psych'
WHEN a.[pa-hosp-svc]='PRS' THEN 'Plastic&Reconstruct Surgry'
WHEN a.[pa-hosp-svc]='PRT' THEN 'Pre-Transplant'
WHEN a.[pa-hosp-svc]='PSD' THEN 'Day Psych'
WHEN a.[pa-hosp-svc]='PSG' THEN 'IP Pediatric Surgery'
WHEN a.[pa-hosp-svc]='PSP' THEN 'Pediatric Special Procedures'
WHEN a.[pa-hosp-svc]='PSR' THEN 'Pediatric Surgery OP'
WHEN a.[pa-hosp-svc]='PSS' THEN 'Pediatric Short Stay OP'
WHEN a.[pa-hosp-svc]='PST' THEN 'Pre-Surgical Test'
WHEN a.[pa-hosp-svc]='PSY' THEN 'IP Psychiatry'
WHEN a.[pa-hosp-svc]='PTP' THEN 'Peds Tech Park'
WHEN a.[pa-hosp-svc]='PTR' THEN 'Post Transplant'
WHEN a.[pa-hosp-svc]='PUC' THEN 'OP Ped Urgent Care'
WHEN a.[pa-hosp-svc]='PUL' THEN 'OP Pulmonary'
WHEN a.[pa-hosp-svc]='RAD' THEN 'Radiation IP'
WHEN a.[pa-hosp-svc]='RAN' THEN 'Radiology Anesthesia OP'
WHEN a.[pa-hosp-svc]='RAS' THEN 'Research Anesthesia OP'
WHEN a.[pa-hosp-svc]='RCA' THEN 'Research Cancer OP'
WHEN a.[pa-hosp-svc]='RCM' THEN 'Radiology Commack OP'
WHEN a.[pa-hosp-svc]='RCP' THEN 'Research Child Psych OP'
WHEN a.[pa-hosp-svc]='RCV' THEN 'Rad Consult Visit'
WHEN a.[pa-hosp-svc]='RDA' THEN 'Rad Onc Amb Cancer Center'
WHEN a.[pa-hosp-svc]='RDM' THEN 'Research Dermatology'
WHEN a.[pa-hosp-svc]='RDO' THEN 'OP Rad Oncology'
WHEN a.[pa-hosp-svc]='REH' THEN 'IP Rehab'
WHEN a.[pa-hosp-svc]='RFM' THEN 'Research Family Medicine'
WHEN a.[pa-hosp-svc]='RHU' THEN 'Rheumatology'
WHEN a.[pa-hosp-svc]='RHY' THEN 'Rheumatology'
WHEN a.[pa-hosp-svc]='RIS' THEN 'IP Radiology Inverventional Svc'
WHEN a.[pa-hosp-svc]='RME' THEN 'Research Medicine'
WHEN a.[pa-hosp-svc]='RNE' THEN 'Research Neurology'
WHEN a.[pa-hosp-svc]='RNS' THEN 'Research Neurosurgery'
WHEN a.[pa-hosp-svc]='ROG' THEN 'Research OB/GYN'
WHEN a.[pa-hosp-svc]='ROP' THEN 'Research Opthamology'
WHEN a.[pa-hosp-svc]='ROR' THEN 'Research Orthopedics'
WHEN a.[pa-hosp-svc]='RPC' THEN 'OP Radiology Procedure'
WHEN a.[pa-hosp-svc]='RPE' THEN 'Research Pediatrics'
WHEN a.[pa-hosp-svc]='RPF' THEN 'Research Pulmonary Function'
WHEN a.[pa-hosp-svc]='RPM' THEN 'Research Preventative Medicine'
WHEN a.[pa-hosp-svc]='RPS' THEN 'Research Psych'
WHEN a.[pa-hosp-svc]='RRC' THEN 'Risk Reduction Center'
WHEN a.[pa-hosp-svc]='RRD' THen 'Research Radiology'
WHEN a.[pa-hosp-svc]='RSH' THEN 'Research'
WHEN a.[pa-hosp-svc]='RSR' THEN 'Research Surgery'
WHEN a.[pa-hosp-svc]='RTP' THEN 'Referred to TP'
WHEN a.[pa-hosp-svc]='RTR' THEN 'IP Recipient'
WHEN a.[pa-hosp-svc]='RUM' THEN 'IP Reheumatology'
WHEN a.[pa-hosp-svc]='RUR' THEN 'OP Research Urology'
WHEN a.[pa-hosp-svc]='SAT' THEN 'Satellite Lab'
WHEN a.[pa-hosp-svc]='SBC' Then 'Survivor Breast Center'
WHEN a.[pa-hosp-svc]='SBR' THEN 'OP Stony Brook Radiology'
WHEN a.[pa-hosp-svc]='SBS' THEN 'Skull Based Sur'
WHEN a.[pa-hosp-svc]='SCT' THEN 'Stem Cell Transplant'
WHEN a.[pa-hosp-svc]='SCU' THEN 'Surgical ICU'
WHEN a.[pa-hosp-svc]='SDA' THEN 'SDS Admit OP'
WHEN a.[pa-hosp-svc]='SDO' THEN 'Sleep Disorders'
WHEN a.[pa-hosp-svc]='SDS' THEN 'Amb Surgery'
WHEN a.[pa-hosp-svc]='SDZ' THEN 'Sleep Disorder Study'
WHEN a.[pa-hosp-svc]='SED' THEN 'OP Sedation'
WHEN a.[pa-hosp-svc]='SGP' THEN 'OP Surgery Ped'
WHEN a.[pa-hosp-svc]='SGY' THEN 'OP Surgery'
WHEN a.[pa-hosp-svc]='SHH' THEN 'OP Southampton'
WHEN a.[pa-hosp-svc]='SKL' THEN 'Skull'
WHEN a.[pa-hosp-svc]='SLM' THEN 'OP Sleep Medicine'
WHEN a.[pa-hosp-svc]='SLP' THEN 'Speech Lang Path'
WHEN a.[pa-hosp-svc]='SON' THEN 'Surgical Oncology'
WHEN a.[pa-hosp-svc]='SOP' THEN 'OP Surg Oncology Procedure'
WHEN a.[pa-hosp-svc]='SPC' THEN 'Special Surgery'
WHEN a.[pa-hosp-svc]='SPF' THEN 'Surgical Pathology FNA'
WHEN a.[pa-hosp-svc]='SPP' THEN 'Sched Preadmit Proc'
WHEN a.[pa-hosp-svc]='SPS' THEN 'Stony Brook Psych OP'
WHEN a.[pa-hosp-svc]='SRG' THEN 'Outpatient Surgery'
WHEN a.[pa-hosp-svc]='SRP' THEN 'Surgery Patchogue'
WHEN a.[pa-hosp-svc]='SRY' THEN 'Spine X-Ray'
WHEN a.[pa-hosp-svc]='SSD' THEN 'Surgical Step Down'
WHEN a.[pa-hosp-svc]='SSG' THEN 'Sleep Surgery OP'
WHEN a.[pa-hosp-svc]='SSS' THEN 'Short Stay Surgery OP'
WHEN a.[pa-hosp-svc]='STU' THEN 'SHSC'
WHEN a.[pa-hosp-svc]='STY' THEN 'Spine Therapy OP'
WHEN a.[pa-hosp-svc]='SWS' THEN 'Social Worker OP'
WHEN a.[pa-hosp-svc]='TCU' THEN 'Trauma Adult IC'
WHEN a.[pa-hosp-svc]='TEE' THEN 'Transesophageal Echo'
WHEN a.[pa-hosp-svc]='TEG' THEN 'T.P. Elect Encarogram'
WHEN a.[pa-hosp-svc]='TGS' THEN 'Tech Park Gastroenterology'
WHEN a.[pa-hosp-svc]='TIP' THEN 'Transfusion/Infusion'
WHEN a.[pa-hosp-svc]='TIS' THEN 'OP Tissue Types'
WHEN a.[pa-hosp-svc]='TNS' THEN 'Trauma Neurosurgery'
WHEN a.[pa-hosp-svc]='TOR' THEN 'Trauma Orthopedics'
WHEN a.[pa-hosp-svc]='TPD' THEN 'Trauma Pediatrics'
WHEN a.[pa-hosp-svc]='TPL' THEN 'Tech Park Plast Surg'
WHEN a.[pa-hosp-svc]='TPN' THEN 'Tech Park Pain'
WHEN a.[pa-hosp-svc]='TPS' THEN 'Tech Park Psych'
WHEN a.[pa-hosp-svc]='TPT' THEN 'Tech Park Therapy'
WHEN a.[pa-hosp-svc]='TPU' THEN 'Trauma Ped I.C.'
WHEN a.[pa-hosp-svc]='TSB' THEN 'Trauma Surgery Blue'
WHEN a.[pa-hosp-svc]='TSG' THEN 'Trauma Surgery Green'
WHEN a.[pa-hosp-svc]='TSR' THEN 'Trauma Surgery'
WHEN a.[pa-hosp-svc]='TST' THEN 'Prod Testing Service'
WHEN a.[pa-hosp-svc]='TTS' THEN 'Transplant Test Svc'
WHEN a.[pa-hosp-svc]='TUR' THEN 'Urology'
WHEN a.[pa-hosp-svc]='ULT' THEN 'Unrelat Living Donor IP'
WHEN a.[pa-hosp-svc]='URL' THEN 'Urology'
WHEN a.[pa-hosp-svc]='URO' THEN 'Urology'
WHEN a.[pa-hosp-svc]='URP' THEN 'Urology Patchogue'
WHEN a.[pa-hosp-svc]='VAS' THEN 'Vascular'
WHEN a.[pa-hosp-svc]='VCL' THEN 'Virtual Colonoscopy'
WHEN a.[pa-hosp-svc]='VPL' THEN 'Pulmonary Vent IP'
WHEN a.[pa-hosp-svc]='VSG' THEN 'Vascular Surgery'
WHEN a.[pa-hosp-svc]='VSP' THEN 'Vascular Special Procedure OP'
WHEN a.[pa-hosp-svc]='WLS' THEN 'Weight Loss Surgery IP'
WHEN a.[pa-hosp-svc]='XPC' THEN 'Radiology Procedures OP'
WHEN a.[pa-hosp-svc]='XRY' THEN 'X-Ray'
WHEN a.[pa-hosp-svc]='YOG' THEN 'Yoga Instruction'
WHEN a.[pa-hosp-svc]='ZOO' THEN 'Outpatient Offsite'
ELSE ''
END AS 'Hosp Svc Description'
,a.[pa-acct-sub-type]  --D=Discharged; I=In House
,(c.[pa-ins-co-cd] + CAST(c.[pa-ins-plan-no] as varchar)) as 'Ins1_Cd'
,(d.[pa-ins-co-cd] + CAST(d.[pa-ins-plan-no] as varchar)) as 'Ins2_Cd'
,(e.[pa-ins-co-cd] + CAST(e.[pa-ins-plan-no] as varchar)) as 'Ins3_Cd' 
,(f.[pa-ins-co-cd] + CAST(f.[pa-ins-plan-no] as varchar)) as 'Ins4_Cd'
,a.[pa-disch-dx-cd]
,a.[pa-disch-dx-cd-type]
,a.[pa-disch-dx-date]
,a.[PA-PROC-CD-TYPE(1)]
,a.[PA-PROC-CD(1)]
,a.[PA-PROC-DATE(1)]
,a.[pa-proc-prty(1)]
,a.[PA-PROC-CD-TYPE(2)]
,a.[PA-PROC-CD(2)]
,a.[PA-PROC-DATE(2)]
,a.[pa-proc-prty(2)]
,a.[PA-PROC-CD-TYPE(3)]
,a.[PA-PROC-CD(3)]
,a.[PA-PROC-DATE(3)]
,a.[pa-proc-prty(3)]
,CASE
WHEN b.[pa-unit-no] is null THEN c.[pa-bal-ins-pay-amt]
ELSE ISNULL(p.[tot-pymts],0)
END  as 'Pyr1_Pay_Amt'
,CASE
WHEN b.[pa-unit-no] is null THEN d.[pa-bal-ins-pay-amt]
ELSE ISNULL(q.[tot-pymts],0)
END  as 'Pyr2_Pay_Amt'
,CASE
WHEN b.[pa-unit-no] is null THEN e.[pa-bal-ins-pay-amt]
ELSE ISNULL(r.[tot-pymts],0)
END  as 'Pyr3_Pay_Amt'
,CASE
WHEN b.[pa-unit-no] is null THEN f.[pa-bal-ins-pay-amt]
ELSE ISNULL(s.[tot-pymts],0)
END  as 'Pyr4_Pay_Amt'
,c.[pa-last-ins-bl-date] as 'Pyr1_Last_Ins_Bl_Date'
,d.[pa-last-ins-bl-date] as 'Pyr2_Last_Ins_Bl_Date'
,e.[pa-last-ins-bl-date] as 'Pyr3_Last_Ins_Bl_Date'
,f.[pa-last-ins-bl-date] as 'Pyr4_Last_Ins_Bl_Date'
,
CASE
WHEN b.[pa-unit-no] IS NULL THEN (CAST(ISNULL(c.[pa-bal-ins-pay-amt],0) as money) + CAST(ISNULL(d.[pa-bal-ins-pay-amt],0) as money) + CAST(ISNULL(e.[pa-bal-ins-pay-amt],0) as money) + CAST(ISNULL(f.[pa-bal-ins-pay-amt],0) as money)) 
ELSE (CAST(ISNULL(p.[tot-pymts],0) as money) + CAST(ISNULL(q.[tot-pymts],0) as money) + CAST(ISNULL(r.[tot-pymts],0) as money) + CAST(ISNULL(s.[tot-pymts],0) as money))
END as 'Ins_Pay_Amt'
,
CASE
WHEN b.[pa-unit-no] IS NULL THEN (CAST(ISNULL(c.[pa-bal-ins-pay-amt],0) as money) + CAST(ISNULL(d.[pa-bal-ins-pay-amt],0) as money) + CAST(ISNULL(e.[pa-bal-ins-pay-amt],0) as money) + CAST(ISNULL(f.[pa-bal-ins-pay-amt],0) as money))+ CAST(ISNULL(a.[pa-bal-tot-pt-pay-amt],0) as money) 
ELSE (CAST(ISNULL(p.[tot-pymts],0) as money) + CAST(ISNULL(q.[tot-pymts],0) as money) + CAST(ISNULL(r.[tot-pymts],0) as money) + CAST(ISNULL(s.[tot-pymts],0) as money))+ CAST(ISNULL(t.[tot-pymts],0) as money) 
END as 'Tot_Pay_Amt'
,a.[pa-last-fc-cng-date]
--,h.[pa-cwi-seg-create-date] as 'CW_Post_Date'
--,(h.[pa-cwi-pyr-co-cd] + CAST([pa-cwi-pyr-plan-no] as varchar)) as 'CWI_Pyr_Cd'
--,h.[pa-cwi-last-wklst-id] as 'CW_Last_Worklist'
----,CASE
----WHEN h.[pa-cwi-last-actv-date]='1900-01-01 00:00:00.000' THEN ''
----ELSE 
--,h.[pa-cwi-last-actv-date] 
----END AS 'CW_Last_Activty_Date'
--,h.[pa-cwi-last-actv-cd] as 'CW_Last_Actvity_Cd'
--,h.[pa-cwi-last-actv-coll-id] as 'CW_Last_Collector_ID'
--,h.[pa-cwi-next-fol-date] as 'CW_Next_Followup_Date'
--,h.[pa-cwi-next-wklst-id] as 'CW_Next_Wrklst_ID'
,a.[pa-pt-representative] as 'Rep_Code'
,a.[pa-resp-cd] as 'Resp_Code'
,a.[pa-cr-rating] as 'Credit Rating'
,a.[pa-courtesy-allow]
,a.[pa-last-actv-date] as 'Last_Charge_Svc_Date'
,a.[pa-last-pt-pay-date]
,c.[pa-last-ins-pay-date]
,a.[pa-no-of-cwi] as 'No_Of_CW_Segments'
,a.[pa-pay-scale]
,a.[pa-stmt-cd]
,j.[pa-ins-prty]
,j.[pa-ins-plan]
,j.[pa-last-ins-pay-date]
,j.[last-ins-pay-amt]
,k.[jzanus-comment]
,l.[PA-NAD-FIRST-OR-ORGZ-CNTC]
,l.[PA-NAD-LAST-OR-ORGZ-NAME]
,CAST(m.[pa-pt-no-woscd] as varchar) + CAST(m.[pa-pt-no-scd-1] as varchar)
,m.[pa-user-text] as 'Moms_Pt_No'
,n.[pa-ins-co-cd]
,n.[pa-ins-plan-no] 
,o.[pa-ins-co-cd]
,o.[pa-ins-plan-no] 
,CASE
WHEN b.[pa-unit-no] is null then ISNULL(x.[bd-recovery],0)
ELSE ISNULL(u.[BD-RECOVERY],0)
END as 'Bad_Debt_Recoveries'
,CASE
WHEN a.[pa-acct-bd-xfr-date] is not null and b.[pa-unit-no] is NULL THEN (a.[pa-bal-acct-bal]-a.[pa-bal-posted-since-xfr-bd]) 
WHEN b.[pa-unit-xfr-bd-date] is not null THEN ((ISNULL(b.[pa-unit-ins1-bal],0) + ISNULL(b.[pa-unit-ins2-bal],0) + ISNULL(b.[pa-unit-ins3-bal],0)+ISNULL(b.[pa-unit-ins4-bal],0)+ISNULL(b.[pa-unit-pt-bal],0))-ISNULL(u.[BD-RECOVERY],0)) 
ELSE '0'
END AS  'BD_WO_Amount'
,w.*
,'ACTIVE' as 'Source'



FROM [Echo_Active].dbo.PatientDemographics a left outer join [Echo_Active].dbo.unitizedaccounts b
ON a.[pa-pt-no-woscd]=b.[pa-pt-no-woscd] and a.[pa-pt-no-scd-1]=b.[pa-pt-no-scd-1] 
left outer join [Echo_Active].dbo.insuranceinformation c
ON a.[pa-pt-no-woscd]=c.[pa-pt-no-woscd] and c.[pa-ins-prty]='1'
left outer join [Echo_Active].dbo.insuranceinformation d
ON a.[pa-pt-no-woscd]=d.[pa-pt-no-woscd] and d.[pa-ins-prty]='2'
left outer join [Echo_Active].dbo.insuranceinformation e
ON a.[pa-pt-no-woscd]=e.[pa-pt-no-woscd] and e.[pa-ins-prty]='3'
left outer join [Echo_Active].dbo.insuranceinformation f
ON a.[pa-pt-no-woscd]=f.[pa-pt-no-woscd] and f.[pa-ins-prty]='4'
left outer join [Echo_Active].dbo.diagnosisinformation g
ON a.[pa-pt-no-woscd]=g.[pa-pt-no-woscd] and g.[pa-dx2-prio-no]='1' and g.[pa-dx2-type1-type2-cd]='DF'
left outer join dbo.[#LastPaymentDates] j
ON a.[pa-pt-no-woscd]=j.[pa-pt-no-woscd] and j.[rank1]='1'
left outer join dbo.[#JzanusDenied] k
ON (CAST(a.[pa-pt-no-woscd] as varchar)+CAST(a.[pa-pt-no-scd-1] as varchar))=k.[pa-pt-no] 
left outer join dbo.[NADInformation] l
ON a.[pa-pt-no-woscd]=l.[pa-pt-no-woscd] and l.[pa-nad-cd]='PTGAR'
left outer join [Echo_Active].dbo.[UserDefined] m
ON a.[pa-pt-no-woscd]=m.[pa-pt-no-woscd] and m.[pa-component-id]='2C49PTNO'
left outer join [Echo_Active].dbo.[insuranceinformation] n
ON CAST(SUBSTRING(m.[pa-user-text],2,10) as varchar)=CAST(n.[pa-pt-no-woscd] as varchar) and n.[pa-ins-prty]='1'
left outer join [Echo_Archive].dbo.[insuranceinformation] o
ON CAST(SUBSTRING(m.[pa-user-text],2,10) as varchar)=CAST(o.[pa-pt-no-woscd] as varchar) and o.[pa-ins-prty]='1'
LEFT OUTER JOIN DBO.[#PaymtsByUnitIns] p
ON CAST(b.[pa-pt-no-woscd] as varchar) + CAST(b.[pa-pt-no-scd-1] as varchar)=p.[pa-pt-no] AND b.[pa-unit-date]=p.[pa-dtl-unit-date] AND c.[pa-ins-co-cd]=p.[pa-dtl-ins-co-cd] AND c.[pa-ins-plan-no]=p.[pa-dtl-ins-plan-no]
LEFT OUTER JOIN DBO.[#PaymtsByUnitIns] q
ON CAST(b.[pa-pt-no-woscd] as varchar) + CAST(b.[pa-pt-no-scd-1] as varchar)=q.[pa-pt-no] AND b.[pa-unit-date]=q.[pa-dtl-unit-date] AND d.[pa-ins-co-cd]=q.[pa-dtl-ins-co-cd] AND d.[pa-ins-plan-no]=q.[pa-dtl-ins-plan-no]
LEFT OUTER JOIN DBO.[#PaymtsByUnitIns] r
ON CAST(b.[pa-pt-no-woscd] as varchar) + CAST(b.[pa-pt-no-scd-1] as varchar)=r.[pa-pt-no] AND b.[pa-unit-date]=r.[pa-dtl-unit-date] AND e.[pa-ins-co-cd]=r.[pa-dtl-ins-co-cd] AND e.[pa-ins-plan-no]=r.[pa-dtl-ins-plan-no]
LEFT OUTER JOIN DBO.[#PaymtsByUnitIns] s
ON CAST(b.[pa-pt-no-woscd] as varchar) + CAST(b.[pa-pt-no-scd-1] as varchar)=s.[pa-pt-no] AND b.[pa-unit-date]=s.[pa-dtl-unit-date] AND f.[pa-ins-co-cd]=s.[pa-dtl-ins-co-cd] AND f.[pa-ins-plan-no]=s.[pa-dtl-ins-plan-no]
LEFT OUTER JOIN DBO.[#PaymtsByUnitIns] t
ON CAST(b.[pa-pt-no-woscd] as varchar) + CAST(b.[pa-pt-no-scd-1] as varchar)=t.[pa-pt-no] AND b.[pa-unit-date]=t.[pa-dtl-unit-date] AND t.[pa-dtl-ins-co-cd] =''
LEFT OUTER JOIN DBO.[#BadDebtRecoveriesUnits] u
ON CAST(a.[pa-pt-no-woscd] as varchar) + CAST(a.[pa-pt-no-scd-1] as varchar)=u.[pa-pt-no] AND b.[pa-unit-date]=u.[pa-dtl-unit-date]
LEFT OUTER JOIN [Echo_Active].DBO.NADInformation v
ON a.[pa-pt-no-woscd]=v.[pa-pt-no-woscd] AND v.[pa-nad-cd]='PTADD'
left outer join dbo.[#LastActiveIns] w
ON a.[pa-med-rec-no]=w.[pa-med-rec-no] and w.[ins-rank]='1'
LEFT OUTER JOIN DBO.[#BadDebtRecoveries] X
ON CAST(a.[pa-pt-no-woscd] as varchar) + CAST(a.[pa-pt-no-scd-1] as varchar)=x.[pa-pt-no] 
--left outer join 
--(SELECT [pa-pt-no-woscd],[pa-cwi-seg-create-date],[pa-cwi-pyr-co-cd],[pa-cwi-pyr-plan-no],[pa-cwi-last-wklst-id],[pa-cwi-last-dmnd-fol-date],[pa-cwi-last-actv-date],[pa-cwi-last-actv-cd],[pa-cwi-last-actv-coll-id],[pa-cwi-next-fol-date],[pa-cwi-next-wklst-id]
--FROM dbo.CollectorWorkStation aa
--WHERE [pa-cwi-seg-create-date]=(select max([pa-cwi-seg-create-date]) FROM dbo.CollectorWorkStation bb WHERE aa.[pa-pt-no-woscd]=bb.[pa-pt-no-woscd])
--) h
--ON a.[pa-pt-no-woscd]=h.[pa-pt-no-woscd]
 

--left outer join dbo.detailinformation c
--ON a.[pa-pt-no-woscd]=c.[pa-pt-no-woscd] and a.[pa-pt-no-scd]=c.[pa-pt-no-scd-1]

WHERE 
---(a.[pa-pt-representative] is not null AND not(a.[pa-pt-representative] IN ('','000'))
--a.[pa-acct-type] NOT IN ('4','6')
 --AND a.[pa-op-first-ins-bl-date] > '5/26/2017'
--((b.[pa-unit-no] is null and a.[pa-acct-bd-xfr-date] BETWEEN '2015-01-01 00:00:00.000' AND '2017-05-31 23:59:59.000')
--OR (b.[pa-unit-no] is not null and b.[pa-unit-xfr-bd-date] BETWEEN '2015-01-01 00:00:00.000' AND '2017-05-31 23:59:59.000'))
 --COALESCE(DATEADD(DAY,1,EOMONTH(b.[pa-unit-date],-1)),a.[pa-adm-date])  BETWEEN '2016-01-01 00:00:00.000' AND '2016-12-31 23:59:59.000'
  (c.[pa-ins-co-cd]='H' OR c.[pa-ins-co-cd] is null)
 AND w.[pa-ins-cd] IS NOT NULL
 AND COALESCE(b.[pa-unit-tot-chg-amt],a.[pa-bal-tot-chg-amt]) <> '0'
 AND a.[pa-acct-type] IN ('0','1','2')
 --AND c.[pa-ins-plan-no]='1'

--AND COALESCE(ISNULL(c.[pa-bal-ins-pay-amt],0)+ ISNULL(d.[pa-bal-ins-pay-amt],0) + ISNULL(e.[pa-bal-ins-pay-amt],0) + ISNULL(f.[pa-bal-ins-pay-amt],0)+ ISNULL(a.[pa-bal-tot-pt-pay-amt],0),a.[pa-bal-acct-bal])<> '0'
--AND COALESCE((b.[pa-unit-ins1-bal] + b.[pa-unit-ins2-bal] + b.[pa-unit-ins3-bal]+b.[pa-unit-ins4-bal]+b.[pa-unit-pt-bal]),a.[pa-bal-acct-bal]) <> '0')
--AND a.[pa-pt-representative] NOT IN ('530','531','532')
--AND a.[pa-fc] IN ('0','1','2','3','4','5','6','7','8','9')
--AND a.[pa-pt-type]='B'
--AND a.[pa-fc] NOT IN ('V','Y')
--AND a.[pa-pt-no-woscd]='1009394875'
----a.[pa-fc]='D'
----AND a.[pa-acct-type]='0'--(a.[pa-acct-type] NOT IN ('4','6','7','8')--Active A/R; Excludes Bad Debt & Historic
--a.[pa-acct-type] IN ('6','4')--('0','2')--,'7','8') --AND --('0','2','7','8') AND 
--AND a.[pa-fc]='9'
--and a.[pa-fc] IN ('V','Y')
--AND c.[pa-ins-co-cd]='M'
--AND (d.[pa-ins-co-cd]='A' OR e.[pa-ins-co-cd]='A' OR f.[pa-ins-co-cd]='A')
--AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),getdate()) > '240'
--AND c.[pa-ins-co-cd]='L'
--AND c.[pa-ins-plan-no]='76'
--AND COALESCE((b.[pa-unit-ins1-bal] + b.[pa-unit-ins2-bal] + b.[pa-unit-ins3-bal]+b.[pa-unit-ins4-bal]+b.[pa-unit-pt-bal]),a.[pa-bal-acct-bal]) > '99999.99'
AND COALESCE((b.[pa-unit-ins1-bal] + b.[pa-unit-ins2-bal] + b.[pa-unit-ins3-bal]+b.[pa-unit-ins4-bal]+b.[pa-unit-pt-bal]),a.[pa-bal-acct-bal]) <> '0.00'
--AND LEFT(a.[pa-pt-no-woscd],5)<>'99999'
--AND a.[PA-PT-NO-WOSCD]='1006669858'
--WHERE a.[pa-pt-no-woscd] in ('01010920323','01010876959','01010892099','01010902101','01010917335')
--WHERE [pa-unit-sts]='2'

--ORDER BY COALESCE(ISNULL(c.[pa-bal-ins-pay-amt],0)+ ISNULL(d.[pa-bal-ins-pay-amt],0) + ISNULL(e.[pa-bal-ins-pay-amt],0) + ISNULL(f.[pa-bal-ins-pay-amt],0)+ ISNULL(a.[pa-bal-tot-pt-pay-amt],0),a.[pa-bal-acct-bal]) desc--a.[pa-bal-acct-bal] desc 

UNION




----------------------------------------------------------------------------------------------------------------------------------------------------


--/*Create Temp Table W Last Active Ins Plan Based Upon MRN Match*/
--IF OBJECT_ID('tempdb.dbo.#LastActiveInsA','U') IS NOT NULL
--DROP TABLE #LastActiveInsA;
--GO

--CREATE TABLE #LastActiveInsA

--(
--[PA-MED-REC-NO] CHAR(12) NOT NULL,
--[PA-INS-CD] CHAR(4) NULL,
--[PA-LAST-INS-PAY-DATE] DATETIME NULL,
--[PA-BAL-INS-PAY-AMT] MONEY NULL,
--[INS-RANK] CHAR(3) NULL,
--[INSURED-ENCOUNTER] CHAR(13)
--);

--INSERT INTO #LastActiveInsA([pa-med-rec-no],[pa-ins-cd],[pa-last-ins-pay-date],[pa-bal-ins-pay-amt],[ins-rank],[insured-encounter])

--SELECT a.[pa-med-rec-no],
--b.[pa-ins-co-cd] + CAST(b.[pa-ins-plan-no] as varchar) as 'PA-INS-CD',
--b.[pa-last-ins-pay-date],
--b.[pa-bal-ins-pay-amt],
--RANK() OVER (PARTITION BY a.[pa-med-rec-no] order by b.[pa-last-ins-pay-date] desc,b.[pa-pt-no-woscd] asc) as 'INS-RANK',
--CAST(b.[pa-pt-no-woscd] as varchar) + CAST(b.[pa-pt-no-scd-1] as varchar) as 'INSURED-ENCOUNTER'

--FROM dbo.[PatientDemographics] a left outer join dbo.[insuranceinformation]b
--ON a.[pa-pt-no-woscd]=b.[pa-pt-no-woscd]

--where B.[PA-BAL-INS-PAY-AMT] < '0'
--;



SELECT (cast(a.[PA-PT-NO-WOSCD] AS VARCHAR) + cast(a.[PA-PT-NO-SCD-1] AS VARCHAR)) AS 'Pt_No'
,b.[PA-UNIT-NO]
,a.[pa-med-rec-no] as 'MRN'
,a.[pa-pt-name]
,v.[pa-nad-zip-cd2] as 'Pt_Zip'
,v.[pa-nad-city-name] as 'Pt_City'
,COALESCE(DATEADD(DAY,1,EOMONTH(b.[pa-unit-date],-1)),a.[pa-adm-date]) as 'Admit_Date'
,CASE WHEN a.[pa-acct-type]<> 1 THEN COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date])
ELSE a.[pa-dsch-date]
END as 'Dsch_Date'
,b.[pa-unit-date]
,CASE 
WHEN a.[pa-acct-type]<>'1' THEN datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),getdate()) 
ELSE ''
END as 'Age_From_Discharge'
,CASE
WHEN a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),getdate()) between '0' and '30' THEN '1_0-30'
WHEN a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),getdate()) between '31' and '60' THEN '2_31-60'
WHEN a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),getdate()) between '61' and '90' THEN '3_61-90'
WHEN a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),getdate()) between '91' and '120' THEN '4_91-120'
WHEN a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),getdate()) between '121' and '150' THEN '5_121-150'
WHEN a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),getdate()) between '151' and '180' THEN '6_151-180'
WHEN a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),getdate()) between '181' and '210' THEN '7_181-210'
WHEN a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),getdate()) between '211' and '240' THEN '8_211-240'
WHEN a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),getdate()) between '240' and '364' THEN '9_240-364'
WHEN a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),getdate()) between '365' and '729' THEN '10_365-729(1-2YRS)'
WHEN a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),getdate()) between '730' and '1094' THEN '11_730-1094(2-3YRS)'
WHEN a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),getdate()) between '1095' and '1459' THEN '12_1095-1459(3-4YRS)'
WHEN a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),getdate()) between '1460' and '1824' THEN '13_1460-1824(4-5YRS)'
WHEN a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),getdate()) between '1825' and '2189' THEN '14_1825-2189(5-6YRS)'
WHEN a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),getdate()) >= '2190' THEN '15_2190+(6YRS+)'
WHEN a.[pa-acct-type]= 1 THEN 'In House/DNFB'ELSE ''
END as 'Age_Bucket'
,CASE 
WHEN b.[pa-unit-no] is null and a.[pa-acct-type]<>'1' THEN datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),a.[pa-acct-bd-xfr-date]) 
WHEN b.[pa-unit-no] is not null and a.[pa-acct-type]<>'1' THEN datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),b.[pa-unit-xfr-bd-date]) ELSE ''
END as 'Age_At_BD_Referral'
,CASE
WHEN a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),b.[pa-unit-xfr-bd-date]) between '0' and '30' THEN '1_0-30'
WHEN a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),b.[pa-unit-xfr-bd-date]) between '31' and '60' THEN '2_31-60'
WHEN a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),b.[pa-unit-xfr-bd-date]) between '61' and '90' THEN '3_61-90'
WHEN a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),b.[pa-unit-xfr-bd-date]) between '91' and '120' THEN '4_91-120'
WHEN a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),b.[pa-unit-xfr-bd-date]) between '121' and '150' THEN '5_121-150'
WHEN a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),b.[pa-unit-xfr-bd-date]) between '151' and '180' THEN '6_151-180'
WHEN a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),b.[pa-unit-xfr-bd-date]) between '181' and '210' THEN '7_181-210'
WHEN a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),b.[pa-unit-xfr-bd-date]) between '211' and '240' THEN '8_211-240'
WHEN a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),b.[pa-unit-xfr-bd-date]) between '240' and '364' THEN '9_240-364'
WHEN a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),b.[pa-unit-xfr-bd-date]) between '365' and '729' THEN '10_365-729(1-2YRS)'
WHEN a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),b.[pa-unit-xfr-bd-date]) between '730' and '1094' THEN '11_730-1094(2-3YRS)'
WHEN a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),b.[pa-unit-xfr-bd-date]) between '1095' and '1459' THEN '12_1095-1459(3-4YRS)'
WHEN a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),b.[pa-unit-xfr-bd-date]) between '1460' and '1824' THEN '13_1460-1824(4-5YRS)'
WHEN a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),b.[pa-unit-xfr-bd-date]) between '1825' and '2189' THEN '14_1825-2189(5-6YRS)'
WHEN a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),b.[pa-unit-xfr-bd-date]) >= '2190' THEN '15_2190+(6YRS+)'
WHEN b.[pa-unit-no] is null AND a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),a.[pa-acct-bd-xfr-date]) between '0' and '30' THEN '1_0-30'
WHEN b.[pa-unit-no] is null and a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),a.[pa-acct-bd-xfr-date]) between '31' and '60' THEN '2_31-60'
WHEN b.[pa-unit-no] is null and a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),a.[pa-acct-bd-xfr-date]) between '61' and '90' THEN '3_61-90'
WHEN b.[pa-unit-no] is null and a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),a.[pa-acct-bd-xfr-date]) between '91' and '120' THEN '4_91-120'
WHEN b.[pa-unit-no] is null and a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),a.[pa-acct-bd-xfr-date]) between '121' and '150' THEN '5_121-150'
WHEN b.[pa-unit-no] is null and a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),a.[pa-acct-bd-xfr-date]) between '151' and '180' THEN '6_151-180'
WHEN b.[pa-unit-no] is null and a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),a.[pa-acct-bd-xfr-date]) between '181' and '210' THEN '7_181-210'
WHEN b.[pa-unit-no] is null and a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),a.[pa-acct-bd-xfr-date]) between '211' and '240' THEN '8_211-240'
WHEN b.[pa-unit-no] is null and a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),a.[pa-acct-bd-xfr-date]) between '240' and '364' THEN '9_240-364'
WHEN b.[pa-unit-no] is null and a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),a.[pa-acct-bd-xfr-date]) between '365' and '729' THEN '10_365-729(1-2YRS)'
WHEN b.[pa-unit-no] is null and a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),a.[pa-acct-bd-xfr-date]) between '730' and '1094' THEN '11_730-1094(2-3YRS)'
WHEN b.[pa-unit-no] is null and a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),a.[pa-acct-bd-xfr-date]) between '1095' and '1459' THEN '12_1095-1459(3-4YRS)'
WHEN b.[pa-unit-no] is null and a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),a.[pa-acct-bd-xfr-date]) between '1460' and '1824' THEN '13_1460-1824(4-5YRS)'
WHEN b.[pa-unit-no] is null and a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),a.[pa-acct-bd-xfr-date]) between '1825' and '2189' THEN '14_1825-2189(5-6YRS)'
WHEN b.[pa-unit-no] is null and a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),a.[pa-acct-bd-xfr-date]) >= '2190' THEN '15_2190+(6YRS+)'
WHEN a.[pa-acct-type]= 1 THEN 'In House/DNFB'
ELSE ''
END as 'Age_At_BD_Xfr_Bucket'
,a.[pa-acct-type]
,CASE
WHEN b.[pa-unit-no] IS NULL THEN a.[pa-acct-bd-xfr-date]
ELSE b.[pa-unit-xfr-bd-date]
END as 'Bad_Debt_Xfr_Date'
,COALESCE(b.[pa-unit-op-first-ins-bl-date],a.[pa-final-bill-date],a.[pa-op-first-ins-bl-date]) as '1st_Bl_Date'
,COALESCE((b.[pa-unit-ins1-bal] + b.[pa-unit-ins2-bal] + b.[pa-unit-ins3-bal]+b.[pa-unit-ins4-bal]+b.[pa-unit-pt-bal]),a.[pa-bal-acct-bal]) as 'Balance'
,COALESCE(b.[pa-unit-pt-bal],a.[pa-bal-pt-bal]) as 'Pt_Balance'
,COALESCE(b.[pa-unit-tot-chg-amt],a.[pa-bal-tot-chg-amt]) as 'Tot_Chgs'
,CASE
WHEN b.[pa-unit-no] is null THEN a.[pa-bal-tot-pt-pay-amt] 
ELSE ISNULL(t.[TOT-PYMTS],0)
END as 'Pt-Pymts'
,CASE
WHEN a.[pa-acct-type] in ('0','6','7') THEN 'OP' --0=OP; 6=OP BAD DEBT; 7=OP HISTORIC
WHEN a.[pa-acct-type] in ('1','2','4','8') THEN 'IP'  --1=IP; 2=A/R; 4=I/P BAD DEBT; 8=I/P HISTORIC
ELSE ''
END AS 'PtAcct_Type'
,CASE
WHEN a.[pa-acct-type] in ('6','4') THEN 'Bad Debt'
WHEN a.[pa-dsch-date] is not null and a.[pa-acct-type]='1' THEN 'DNFB'
WHEN a.[pa-acct-type] = '1' THEN 'Inhouse'
ELSE 'A/R'
END as 'File'
,a.[pa-fc] as 'FC'
,CASE
WHEN a.[pa-fc]='1' THEN 'Bad Debt Medicaid Pending'
WHEN a.[pa-fc] in ('2','6') THEN 'Bad Debt AG'
WHEN a.[pa-fc]='3' THEN 'MCS'
WHEN a.[pa-fc]='4' THEN 'Bad Debt AG Legal'
WHEN a.[pa-fc]='5' THEN 'Bad Debt POM'
WHEN a.[pa-fc]='8' THEN 'Bad Debt AG Exchange Plans'
WHEN a.[pa-fc]='9' THEN 'Kopp-Bad Debt'
WHEN a.[pa-fc]='A' THEN 'Commercial'
WHEN a.[pa-fc]='B' THEN 'Blue Cross'
WHEN a.[pa-fc]='C' THEN 'Champus'
WHEN a.[pa-fc]='D' THEN 'Medicaid'
WHEN a.[pa-fc]='E' THEN 'Employee Health Svc'
WHEN a.[pa-fc]='G' THEN 'Contract Accts'
WHEN a.[pa-fc]='H' THEN 'Medicare HMO'
WHEN a.[pa-fc]='I' THEN 'Balance After Ins'
WHEN a.[pa-fc]='J' THEN 'Managed Care'
WHEN a.[pa-fc]='K' THEN 'Pending Medicaid'
WHEN a.[pa-fc]='M' THEN 'Medicare'
WHEN a.[pa-fc]='N' THEN 'No-Fault'
WHEN a.[pa-fc]='P' THEN 'Self Pay'
WHEN a.[pa-fc]='R' THEN 'Aergo Commercial'
WHEN a.[pa-fc]='T' THEN 'RTR WC NF'
WHEN a.[pa-fc]='S' THEN 'Special Billing'
WHEN a.[pa-fc]='U' THEN 'Medicaid Mgd Care'
WHEN a.[pa-fc]='V' THEN 'First Source'
WHEN a.[pa-fc]='W' THEN 'Workers Comp'
WHEN a.[pa-fc]='X' THEN 'Control Accts'
WHEN a.[pa-fc]='Y' THEN 'MCS'
WHEN a.[pa-fc]='Z' THEN 'Unclaimed Credits'
ELSE ''
END as 'FC_Description'
,a.[pa-hosp-svc]
,CASE
WHEN a.[PA-HOSP-SVC]='ABC' THEN 'Ambulatory Breast Care'
WHEN a.[PA-HOSP-SVC]='ABD' THEN 'ACC Breast Diagnosis'
WHEN a.[PA-HOSP-SVC]='ACA' THEN 'Amb Care Admit'
WHEN a.[PA-HOSP-SVC]='ACP' THEN 'Amb Cancer Provider'
WHEN a.[PA-HOSP-SVC]='ACU' THEN 'Discontinued AIDS'
WHEN a.[PA-HOSP-SVC]='ALG' THEN 'Allergy'
WHEN a.[PA-HOSP-SVC]='ALL' THEN 'Allergy Rhematology'
WHEN a.[PA-HOSP-SVC]='ALS' THEN 'Amotroph Ltl Sclsis'
WHEN a.[PA-HOSP-SVC]='AND' THEN 'Andrology Lab'
WHEN a.[PA-HOSP-SVC]='ANT' THEN 'Antepartum Testing'
WHEN a.[PA-HOSP-SVC]='AOI' THEN ' Apnea Of Infancy'
WHEN a.[PA-HOSP-SVC]='APN' THEN 'Ambulatory Pain'
WHEN a.[PA-HOSP-SVC]='APP' THEN 'Ambulatory Pain Proc'
WHEN a.[PA-HOSP-SVC]='APV' THEN 'Adult Patient Visit'
WHEN a.[PA-HOSP-SVC]='ARI' THEN 'Ambulatory MRI'
WHEN a.[PA-HOSP-SVC]='ARP' THEN 'Anal Rectal Phsyiol'
WHEN a.[PA-HOSP-SVC]='ARY' THEN 'Ambulatory X-Ray'
WHEN a.[PA-HOSP-SVC]='ASC' THEN 'Ambulatory Surgery Center'
WHEN a.[PA-HOSP-SVC]='AUC' THEN 'Adult Urgent Care'
WHEN a.[PA-HOSP-SVC]='AUD' THEN 'Audiology'
WHEN a.[PA-HOSP-SVC]='AUT' THEN 'Autopsy'
WHEN a.[PA-HOSP-SVC]='AXP' THEN 'ACC Radiology Procedure'
WHEN a.[PA-HOSP-SVC]='BCK' THEN 'Back School'
WHEN a.[PA-HOSP-SVC]='BKO' THEN 'Back Other'
WHEN a.[PA-HOSP-SVC]='BLD' THEN 'MODQ'
WHEN a.[PA-HOSP-SVC]='BMD' THEN 'Osteoporosis'
WHEN a.[PA-HOSP-SVC]='BMT' THEN 'Bone Marow Trns'
WHEN a.[PA-HOSP-SVC]='BNL' THEN 'Brkhaven Nat Lab'
WHEN a.[PA-HOSP-SVC]='BRE' THEN 'Breast Center'
WHEN a.[PA-HOSP-SVC]='BRN' THEN 'Burn Center'
WHEN a.[PA-HOSP-SVC]='BRP' THEN 'Breast Procedure'
WHEN a.[PA-HOSP-SVC]='BRS' THEN 'Breast Surgery'
WHEN a.[PA-HOSP-SVC]='BUR' THEN 'Burn Unit For OPBC'
WHEN a.[PA-HOSP-SVC]='CAD' THEN 'Cardiology IP'
WHEN a.[PA-HOSP-SVC]='CAM' THEN 'Comp Alternative Med'
WHEN a.[PA-HOSP-SVC]='CAR' THEN 'Cardiology OP'
WHEN a.[PA-HOSP-SVC]='CCF' THEN 'Cleft Cranial Facial'
WHEN a.[PA-HOSP-SVC]='CCL' THEN 'Cody Center Life'
WHEN a.[PA-HOSP-SVC]='CCP' THEN 'Cody Center Patients'
WHEN a.[PA-HOSP-SVC]='CCU' THEN 'Coron ICU'
WHEN a.[PA-HOSP-SVC]='CDT' THEN 'Cardiothoracic'
WHEN a.[PA-HOSP-SVC]='CDY' THEN 'Cardiology'
WHEN a.[PA-HOSP-SVC]='COL' THEN 'Colo-rectal Oncology'
WHEN a.[PA-HOSP-SVC]='COU' THEN 'Anticoagulation'
WHEN a.[PA-HOSP-SVC]='CPT' THEN 'Cath Pre-Testing'
WHEN a.[PA-HOSP-SVC]='CPU' THEN 'Chest Pain Unit'
WHEN a.[PA-HOSP-SVC]='CRB' THEN 'Cardiac Rehab'
WHEN a.[PA-HOSP-SVC]='CRC' THEN 'GREC Grant OP'
WHEN a.[PA-HOSP-SVC]='CRD' THEN 'Cardiology Testing'
WHEN a.[PA-HOSP-SVC]='CRS' THEN 'Colorectal Surgery'
WHEN a.[PA-HOSP-SVC]='CRU' THEN 'GREC Grant IP'
WHEN a.[PA-HOSP-SVC]='CSA' THEN 'Ambulance'
WHEN a.[PA-HOSP-SVC]='CSS' THEN 'Short Stay Cardiac'
WHEN a.[PA-HOSP-SVC]='CTD' THEN 'Cadaver Donor'
WHEN a.[PA-HOSP-SVC]='CTH' THEN 'Cardiac Catheterization'
WHEN a.[PA-HOSP-SVC]='CTP' THEN 'Child Tech Park'
WHEN a.[PA-HOSP-SVC]='CUC' THEN 'Cardiac Urgent Care'
WHEN a.[PA-HOSP-SVC]='CVC' THEN 'Cerebrovascular Center'
WHEN a.[PA-HOSP-SVC]='CVU' THEN 'Cardio ICU'
WHEN a.[PA-HOSP-SVC]='CYT' THEN 'Cytogenics'
WHEN a.[PA-HOSP-SVC]='DBM' THEN 'Donor Bone Marrow'
WHEN a.[PA-HOSP-SVC]='DDP' THEN 'Development Disab Pt'
WHEN a.[PA-HOSP-SVC]='DEN' THEN 'Dental'
WHEN a.[PA-HOSP-SVC]='DER' THEN 'Dermatology'
WHEN a.[PA-HOSP-SVC]='DIA' THEN 'Dialysis'
WHEN a.[PA-HOSP-SVC]='DIB' THEN 'Diabetes OPD'
WHEN a.[PA-HOSP-SVC]='DIH' THEN 'Home Dialysis'
WHEN a.[PA-HOSP-SVC]='DIS' THEN 'Disaster Patient'
WHEN a.[PA-HOSP-SVC]='DNT' THEN 'Dental'
WHEN a.[PA-HOSP-SVC]='DOF' THEN 'Dialysis Outside Fac'
WHEN a.[PA-HOSP-SVC]='DON' THEN 'Dental Oncology'
WHEN a.[PA-HOSP-SVC]='DPA' THEN 'Dental Pathology'
WHEN a.[PA-HOSP-SVC]='DPC' THEN 'Dermatology Procedure'
WHEN a.[PA-HOSP-SVC]='DRM' THEN 'Dermatology Module'
WHEN a.[PA-HOSP-SVC]='DUV' THEN 'Dermatology UV Therapy'
WHEN a.[PA-HOSP-SVC]='ECG' THEN 'ECG'
WHEN a.[PA-HOSP-SVC]='ECT' THEN 'Electroconvulsive Therapy'
WHEN a.[PA-HOSP-SVC]='EDA' THEN 'ED Admission'
WHEN a.[PA-HOSP-SVC]='EDT' THEN 'ED Admissions/Billing'
WHEN a.[PA-HOSP-SVC]='EEC' THEN 'EECP Treatments'
WHEN a.[PA-HOSP-SVC]='EEG' THEN 'OPEG'
WHEN a.[PA-HOSP-SVC]='EHS' THEN 'Emp Health Svc'
WHEN a.[PA-HOSP-SVC]='ELC' THEN 'Amb Lung Cancer Eval'
WHEN a.[PA-HOSP-SVC]='ELI' THEN 'Eastern Long Island Hosp'
WHEN a.[PA-HOSP-SVC]='EMD' THEN 'Emergency Dental'
WHEN a.[PA-HOSP-SVC]='EMR' THEN 'Emergency'
WHEN a.[PA-HOSP-SVC]='EMS' THEN 'Emergency Med Serv'
WHEN a.[PA-HOSP-SVC]='EMT' THEN 'Ambulance'
WHEN a.[PA-HOSP-SVC]='ENC' THEN 'Endocrinology'
WHEN a.[PA-HOSP-SVC]='END' THEN 'Endocrine'
WHEN a.[PA-HOSP-SVC]='ENO' THEN 'Endoscopy'
WHEN a.[PA-HOSP-SVC]='ENT' THEN 'ENT'
WHEN a.[PA-HOSP-SVC]='EOB' THEN 'ED Observation'
WHEN a.[PA-HOSP-SVC]='EPS' THEN 'EP Lab'
WHEN a.[PA-HOSP-SVC]='EPX' THEN 'Emergency Spec Proc'
WHEN a.[PA-HOSP-SVC]='ESS' THEN 'Endoscopic Swallow Study'
WHEN a.[PA-HOSP-SVC]='EYE' THEN 'Eye'
WHEN a.[PA-HOSP-SVC]='FAM' THEN 'Family Medicine OP'
WHEN a.[PA-HOSP-SVC]='FMD' THEN 'Family Medicine IP'
WHEN a.[PA-HOSP-SVC]='FMN' THEN 'Family Med Newborn'
WHEN a.[PA-HOSP-SVC]='FMO' THEN 'Family Medicine Obs'
WHEN a.[PA-HOSP-SVC]='FMP' THEN 'Family Medicine Patchogue'
WHEN a.[PA-HOSP-SVC]='FNA' THEN 'Fine Needle Aspiration'
WHEN a.[PA-HOSP-SVC]='FOB' THEN 'FOB Family Med Obs'
WHEN a.[PA-HOSP-SVC]='FPD' THEN 'FPD Family Med Ped'
WHEN a.[PA-HOSP-SVC]='GAS' THEN 'Gastroenterology'
WHEN a.[PA-HOSP-SVC]='GEN' THEN 'General Medicine'
WHEN a.[PA-HOSP-SVC]='GER' THEN 'Geriatrics'
WHEN a.[PA-HOSP-SVC]='GFL' THEN 'Gift of Life'
WHEN a.[PA-HOSP-SVC]='GMA' THEN 'Gen Med Team A'
WHEN a.[PA-HOSP-SVC]='GMB' THEN 'Gen Med Team B'
WHEN a.[PA-HOSP-SVC]='GMC' THEN 'Gen Med Team C'
WHEN a.[PA-HOSP-SVC]='GMD' THEN 'Gen Med Team D'
WHEN a.[PA-HOSP-SVC]='GME' THEN 'Gen Med Team E'
WHEN a.[PA-HOSP-SVC]='GMF' THEN 'Gen Med Team F'
WHEN a.[PA-HOSP-SVC]='GMG' THEN 'Gen Med Team G'
WHEN a.[PA-HOSP-SVC]='GMH' THEN 'Gen Med Team H'
WHEN a.[PA-HOSP-SVC]='GMK' THEN 'Gen Med Team K'
WHEN a.[PA-HOSP-SVC]='GMW' THEN 'Gen Med Team W'
WHEN a.[PA-HOSP-SVC]='GMX' THEN 'Gen Med Flex'
WHEN a.[PA-HOSP-SVC]='GMY' THEN 'Gen Med Team Y'
WHEN a.[PA-HOSP-SVC]='GMZ' THEN 'Gen Med Team Z'
WHEN a.[PA-HOSP-SVC]='GNC' THEN 'Gyn-Oncology'
WHEN a.[PA-HOSP-SVC]='GNE' THEN 'Gynecology OP'
WHEN a.[PA-HOSP-SVC]='GNO' THEN 'Gynecology OP'
WHEN a.[PA-HOSP-SVC]='GNP' THEN 'Gyn Patchogue'
WHEN a.[PA-HOSP-SVC]='GON' THEN 'Ancology'
WHEN a.[PA-HOSP-SVC]='GSG' THEN 'General Surgery'
WHEN a.[PA-HOSP-SVC]='GSR' THEN 'General Surgery Red'
WHEN a.[PA-HOSP-SVC]='GST' THEN 'Gastroenterology'
WHEN a.[PA-HOSP-SVC]='GSW' THEN 'General Surgery White'
WHEN a.[PA-HOSP-SVC]='GSX' THEN 'General Surgery X'
WHEN a.[PA-HOSP-SVC]='GYN' THEN 'Gynecology'
WHEN a.[PA-HOSP-SVC]='HEM' THEN 'Hematology OP'
WHEN a.[PA-HOSP-SVC]='HMA' THEN 'Hematology IP'
WHEN a.[PA-HOSP-SVC]='HND' THEN 'Hand Surgery'
WHEN a.[PA-HOSP-SVC]='HOB' THEN 'Hospital Observation'
WHEN a.[PA-HOSP-SVC]='HSC' THEN 'Health Screening Cnt'
WHEN a.[PA-HOSP-SVC]='HTY' THEN 'Hand Therapy'
WHEN a.[PA-HOSP-SVC]='ICD' THEN 'Islandia Cardiology'
WHEN a.[PA-HOSP-SVC]='IGM' THEN 'Islandia General Med'
WHEN a.[PA-HOSP-SVC]='IGN' THEN 'Gyn Islip'
WHEN a.[PA-HOSP-SVC]='IMM' THEN 'IMM AIDS O/P'
WHEN a.[PA-HOSP-SVC]='IMU' THEN 'Discontinued AIDS I/P'
WHEN a.[pa-hosp-svc]='IND' THEN 'Infectious Diseases'
WHEN a.[pa-hosp-svc]='INF' THEN 'Infections Diseases'
WHEN a.[pa-hosp-svc]='INJ' THEN 'Injection'
WHEN a.[pa-hosp-svc]='IOB' THEN 'OB Islip'
WHEN a.[pa-hosp-svc]='IPD' THEN 'Peds Islip'
WHEN a.[pa-hosp-svc]='IPS' THEN 'Psych ER Observation'
WHEN a.[pa-hosp-svc]='IRC' THEN 'Intervent Rad Clinic'
WHEN a.[pa-hosp-svc]='ISC' THEN 'Islandia Congestive'
WHEN a.[pa-hosp-svc]='KAC' THEN 'Medicaid Anesth Pain'
WHEN a.[pa-hosp-svc]='KFM' THEN 'Medicaid Family Medicine'
WHEN a.[pa-hosp-svc]='KGY' THEN 'Medicaid Gynecology'
WHEN a.[pa-hosp-svc]='KMC' THEN 'Medicaid Cardiology'
WHEN a.[pa-hosp-svc]='KMG' THEN 'Medicaid Gastroenterology'
WHEN a.[pa-hosp-svc]='KMR' THEN 'Medicaid General Med'
WHEN a.[pa-hosp-svc]='KMS' THEN 'Medicaid Med Special'
WHEN a.[pa-hosp-svc]='KNE' THEN 'Medicaid Neurology'
WHEN a.[pa-hosp-svc]='KOB' THEN 'Medicaid Obstetrics'
WHEN a.[pa-hosp-svc]='KOP' THEN 'MEdicaid Opthamology'
WHEN a.[pa-hosp-svc]='KPC' THEN 'Medicaid Ped Cody Ct'
WHEN a.[pa-hosp-svc]='KPI' THEN 'Medicaid Ped Islip'
WHEN a.[pa-hosp-svc]='KPM' THEN 'Medicaid Ped E Moriches'
WHEN a.[pa-hosp-svc]='KPN' THEN 'Medicaid Pain'
WHEN a.[pa-hosp-svc]='KPP' THEN 'Medicaid Pain Procedure'
WHEN a.[pa-hosp-svc]='KPT' THEN 'Medicaid Ped Tech Park'
WHEN a.[pa-hosp-svc]='KPY' THEN 'Medicaid Psychiatry'
WHEN a.[pa-hosp-svc]='KSG' THEN 'Medicaid Surgery Service'
WHEN a.[pa-hosp-svc]='KUR' THEN 'Medicaid Urology'
WHEN a.[pa-hosp-svc]='LAB' THEN 'Lab Specimens'
WHEN a.[pa-hosp-svc]='LAD' THEN 'Labor and Delivery'
WHEN a.[pa-hosp-svc]='LCC' THEN 'Life Center at HB'
WHEN a.[pa-hosp-svc]='LCE' THEN 'Lung Cancer Eval'
WHEN a.[pa-hosp-svc]='LGD' THEN 'Lou Gehrigs Disease'
WHEN a.[pa-hosp-svc]='LID' THEN 'LIVH Day Care'
WHEN a.[pa-hosp-svc]='LIQ' THEN 'LI Queens Med Group'
WHEN a.[pa-hosp-svc]='LIV' THEN 'LI Vet Home'
WHEN a.[pa-hosp-svc]='LLT' THEN 'Leukemia Lymp Trnplt'
WHEN a.[pa-hosp-svc]='LRD' THEN 'Liv Rel Donor'
WHEN a.[pa-hosp-svc]='LSA' THEN 'LSARD'
WHEN a.[pa-hosp-svc]='LVD' THEN 'Left Ventric Ass Dev'
WHEN a.[pa-hosp-svc]='LYM' THEN 'Lymphedema Therapy'
WHEN a.[pa-hosp-svc]='MAS' THEN 'Maternity Amb Surgery'
WHEN a.[pa-hosp-svc]='MCU' THEN 'Medical ICU'
WHEN a.[pa-hosp-svc]='MEM' THEN 'Med East Moriches'
WHEN a.[pa-hosp-svc]='MET' THEN 'MTU O/P Research'
WHEN a.[pa-hosp-svc]='MIU' THEN 'Medical ICU 2'
WHEN a.[pa-hosp-svc]='MOL' THEN 'Med Oncology IP'
WHEN a.[pa-hosp-svc]='MON' THEN 'Med Oncology OP'
WHEN a.[pa-hosp-svc]='MOP' THEN 'Medical Oncology Proc'
WHEN a.[pa-hosp-svc]='MOT' THEN 'Motility Lab'
WHEN a.[pa-hosp-svc]='MPC' THEN 'Med Procedure'
WHEN a.[pa-hosp-svc]='MRI' THEN 'MRI'
WHEN a.[pa-hosp-svc]='MSC' THEN 'Misc Income'
WHEN a.[pa-hosp-svc]='MSS' THEN 'Short Stay Medicine'
WHEN a.[pa-hosp-svc]='MST' THEN 'Massage Therapy'
WHEN a.[pa-hosp-svc]='MTU' THEN 'Metabolic Treatment'
WHEN a.[pa-hosp-svc]='MUC' THEN 'Maternity Urgent Care'
WHEN a.[pa-hosp-svc]='NBN' THEN 'Non Burn'
WHEN a.[pa-hosp-svc]='NBS' THEN 'Neck, Back, Spine'
WHEN a.[pa-hosp-svc]='NCU' THEN 'Neurosurgical ICU'
WHEN a.[pa-hosp-svc]='NEP' THEN 'Nephrology OP'
WHEN a.[pa-hosp-svc]='NER' THEN 'Neurology'
WHEN a.[pa-hosp-svc]='NES' THEN 'Neurosurgery'
WHEN a.[pa-hosp-svc]='NEU' THEN 'Neurology'
WHEN a.[pa-hosp-svc]='NEW' THEN 'Newborn'
WHEN a.[pa-hosp-svc]='NEY' THEN 'Neurology OP'
WHEN a.[pa-hosp-svc]='NMD' THEN 'NAtional Marrow Donor'
WHEN a.[pa-hosp-svc]='NNU' THEN 'Neonatal ICU'
WHEN a.[pa-hosp-svc]='NOP' THEN 'Nutrition OP'
WHEN a.[pa-hosp-svc]='NPH' THEN 'Nephrology IP'
WHEN a.[pa-hosp-svc]='NPT' THEN 'Neuro Psycholog Test'
WHEN a.[pa-hosp-svc]='NPY' THEN 'Nephrology OP'
WHEN a.[pa-hosp-svc]='NSO' THEN 'Neurosurgery Oncology'
WHEN a.[pa-hosp-svc]='NSP' THEN 'Neuro Special Proced'
WHEN a.[pa-hosp-svc]='NSY' THEN 'Tech PArk Neurosurg'
WHEN a.[pa-hosp-svc]='NTF' THEN 'Nutrit Target Fitnes'
WHEN a.[pa-hosp-svc]='NTN' THEN 'Nutritional Svcs OP'
WHEN a.[pa-hosp-svc]='NTR' THEN 'Non Transplant'
WHEN a.[pa-hosp-svc]='NUS' THEN 'Neurosurgery IP'
WHEN a.[pa-hosp-svc]='NVB' THEN 'Non-Viable Births'
WHEN a.[pa-hosp-svc]='OBE' THEN 'Obstetrics'
WHEN a.[pa-hosp-svc]='OBP' THEN 'OB Patchogue'
WHEN a.[pa-hosp-svc]='OBS' THEN 'Obstetrics IP'
WHEN a.[pa-hosp-svc]='OBT' THEN 'Obstetrics OP'
WHEN a.[pa-hosp-svc]='OCC' THEN 'Occupational Therapy'
WHEN a.[pa-hosp-svc]='OCM' THEN 'Occupational Med'
WHEN a.[pa-hosp-svc]='ODM' THEN 'Dermatology-Oncology'
WHEN a.[pa-hosp-svc]='OEM' THEN 'Outpat East Moriches'
WHEN a.[pa-hosp-svc]='OGN' THEN 'Amb Gyn Oncology'
WHEN a.[pa-hosp-svc]='OLL' THEN 'OP Leukemia Lymphoma'
WHEN a.[pa-hosp-svc]='OLR' THEN 'Otolaryngology'
WHEN a.[pa-hosp-svc]='OMH' THEN 'Ofc of Mental Health'
WHEN a.[pa-hosp-svc]='ONC' THEN 'Amb Surgic Oncolog'
WHEN a.[pa-hosp-svc]='OPH' THEN 'Opthamology'
WHEN a.[pa-hosp-svc]='ORC' THEN 'Orthoped Surg Oncol'
WHEN a.[pa-hosp-svc]='ORG' THEN 'Organ Retrieval'
WHEN a.[pa-hosp-svc]='ORT' THEN 'Orthopedics'
WHEN a.[pa-hosp-svc]='OSR' THEN 'Ortho Surgery'
WHEN a.[pa-hosp-svc]='OTH' THEN 'Orthopedics'
WHEN a.[pa-hosp-svc]='OTP' THEN 'Tech Park Orthopedic'
WHEN a.[pa-hosp-svc]='OUR' THEN 'Amb Urology Oncology'
WHEN a.[pa-hosp-svc]='OUT' THEN 'OP Lab Testing'
WHEN a.[pa-hosp-svc]='PAT' THEN 'Preadmit Test'
WHEN a.[pa-hosp-svc]='PCH' THEN 'OP Psychiatry'
WHEN a.[pa-hosp-svc]='PCT' THEN 'Pediatric Cardiac IP'
WHEN a.[pa-hosp-svc]='PCU' THEN 'Pediatric ICU'
WHEN a.[pa-hosp-svc]='PCY' THEN 'OP Child Psych'
WHEN a.[pa-hosp-svc]='PDP' THEN 'OP Peds Patchogue'
WHEN a.[pa-hosp-svc]='PDS' THEN 'OP Pediatrics'
WHEN a.[pa-hosp-svc]='PEA' THEN 'Psych ER'
WHEN a.[pa-hosp-svc]='PED' THEN 'IP Pediatrics'
WHEN a.[pa-hosp-svc]='PEM' THEN 'Peds East Moriches'
WHEN a.[pa-hosp-svc]='PES' THEN 'Psych ER'
WHEN a.[pa-hosp-svc]='PET' THEN 'Psych Ed Admit/Bill'
WHEN a.[pa-hosp-svc]='PFM' THEN 'TP Family Med'
WHEN a.[pa-hosp-svc]='PFT' THEN 'OPPF'
WHEN a.[pa-hosp-svc]='PGM' THEN 'TP General Med'
WHEN a.[pa-hosp-svc]='PGY' THEN 'TP OB/Gyn Med'
WHEN a.[pa-hosp-svc]='PHO' THEN 'IP Ped Hematology/Oncology'
WHEN a.[pa-hosp-svc]='PHU' THEN 'Ped Hematology Int C'
WHEN a.[pa-hosp-svc]='PHY' THEN 'Physical Therapy'
WHEN a.[pa-hosp-svc]='PIC' THEN 'IP Pulmonary Inter Care'
WHEN a.[pa-hosp-svc]='PIM' THEN 'OP Ped AIDS Visit'
WHEN a.[pa-hosp-svc]='PIN' THEN 'Pediatric Trasfus/Infus'
WHEN a.[pa-hosp-svc]='PLB' THEN 'OP Ped Pulmonary'
WHEN a.[pa-hosp-svc]='PLM' THEN 'IP Pulmonary'
WHEN a.[pa-hosp-svc]='PLY' THEN 'OP Pulmonary'
WHEN a.[pa-hosp-svc]='PMA' THEN 'Pain Management Anes'
WHEN a.[pa-hosp-svc]='PMM' THEN 'Ped AIDS OP'
WHEN a.[pa-hosp-svc]='PMU' THEN 'IP Discontinued Ped Aid'
WHEN a.[pa-hosp-svc]='PMX' THEN 'Prive Med Team X'
WHEN a.[pa-hosp-svc]='PNC' THEN 'Pain Clinic'
WHEN a.[pa-hosp-svc]='POB' THEN 'TP OB/GYN Med'
WHEN a.[pa-hosp-svc]='POC' THEN 'Pediatric Oncology Consult'
WHEN a.[pa-hosp-svc]='POL' THEN 'Pool Mntn Prog'
WHEN a.[pa-hosp-svc]='PON' THEN 'Pediatric Oncology'
WHEN a.[pa-hosp-svc]='POP' THEN 'Psychiatry Outpt'
WHEN a.[pa-hosp-svc]='PPC' THEN 'Patchogue PC'
WHEN a.[pa-hosp-svc]='PPG' THEN 'Pain Program'
WHEN a.[pa-hosp-svc]='PPR' THEN 'Pharmaceutic Proveng'
WHEN a.[pa-hosp-svc]='PPV' THEN 'Ped Physician Visit'
WHEN a.[pa-hosp-svc]='PPY' THEN 'IP Pediatric Psych'
WHEN a.[pa-hosp-svc]='PRS' THEN 'Plastic&Reconstruct Surgry'
WHEN a.[pa-hosp-svc]='PRT' THEN 'Pre-Transplant'
WHEN a.[pa-hosp-svc]='PSD' THEN 'Day Psych'
WHEN a.[pa-hosp-svc]='PSG' THEN 'IP Pediatric Surgery'
WHEN a.[pa-hosp-svc]='PSP' THEN 'Pediatric Special Procedures'
WHEN a.[pa-hosp-svc]='PSR' THEN 'Pediatric Surgery OP'
WHEN a.[pa-hosp-svc]='PSS' THEN 'Pediatric Short Stay OP'
WHEN a.[pa-hosp-svc]='PST' THEN 'Pre-Surgical Test'
WHEN a.[pa-hosp-svc]='PSY' THEN 'IP Psychiatry'
WHEN a.[pa-hosp-svc]='PTP' THEN 'Peds Tech Park'
WHEN a.[pa-hosp-svc]='PTR' THEN 'Post Transplant'
WHEN a.[pa-hosp-svc]='PUC' THEN 'OP Ped Urgent Care'
WHEN a.[pa-hosp-svc]='PUL' THEN 'OP Pulmonary'
WHEN a.[pa-hosp-svc]='RAD' THEN 'Radiation IP'
WHEN a.[pa-hosp-svc]='RAN' THEN 'Radiology Anesthesia OP'
WHEN a.[pa-hosp-svc]='RAS' THEN 'Research Anesthesia OP'
WHEN a.[pa-hosp-svc]='RCA' THEN 'Research Cancer OP'
WHEN a.[pa-hosp-svc]='RCM' THEN 'Radiology Commack OP'
WHEN a.[pa-hosp-svc]='RCP' THEN 'Research Child Psych OP'
WHEN a.[pa-hosp-svc]='RCV' THEN 'Rad Consult Visit'
WHEN a.[pa-hosp-svc]='RDA' THEN 'Rad Onc Amb Cancer Center'
WHEN a.[pa-hosp-svc]='RDM' THEN 'Research Dermatology'
WHEN a.[pa-hosp-svc]='RDO' THEN 'OP Rad Oncology'
WHEN a.[pa-hosp-svc]='REH' THEN 'IP Rehab'
WHEN a.[pa-hosp-svc]='RFM' THEN 'Research Family Medicine'
WHEN a.[pa-hosp-svc]='RHU' THEN 'Rheumatology'
WHEN a.[pa-hosp-svc]='RHY' THEN 'Rheumatology'
WHEN a.[pa-hosp-svc]='RIS' THEN 'IP Radiology Inverventional Svc'
WHEN a.[pa-hosp-svc]='RME' THEN 'Research Medicine'
WHEN a.[pa-hosp-svc]='RNE' THEN 'Research Neurology'
WHEN a.[pa-hosp-svc]='RNS' THEN 'Research Neurosurgery'
WHEN a.[pa-hosp-svc]='ROG' THEN 'Research OB/GYN'
WHEN a.[pa-hosp-svc]='ROP' THEN 'Research Opthamology'
WHEN a.[pa-hosp-svc]='ROR' THEN 'Research Orthopedics'
WHEN a.[pa-hosp-svc]='RPC' THEN 'OP Radiology Procedure'
WHEN a.[pa-hosp-svc]='RPE' THEN 'Research Pediatrics'
WHEN a.[pa-hosp-svc]='RPF' THEN 'Research Pulmonary Function'
WHEN a.[pa-hosp-svc]='RPM' THEN 'Research Preventative Medicine'
WHEN a.[pa-hosp-svc]='RPS' THEN 'Research Psych'
WHEN a.[pa-hosp-svc]='RRC' THEN 'Risk Reduction Center'
WHEN a.[pa-hosp-svc]='RRD' THen 'Research Radiology'
WHEN a.[pa-hosp-svc]='RSH' THEN 'Research'
WHEN a.[pa-hosp-svc]='RSR' THEN 'Research Surgery'
WHEN a.[pa-hosp-svc]='RTP' THEN 'Referred to TP'
WHEN a.[pa-hosp-svc]='RTR' THEN 'IP Recipient'
WHEN a.[pa-hosp-svc]='RUM' THEN 'IP Reheumatology'
WHEN a.[pa-hosp-svc]='RUR' THEN 'OP Research Urology'
WHEN a.[pa-hosp-svc]='SAT' THEN 'Satellite Lab'
WHEN a.[pa-hosp-svc]='SBC' Then 'Survivor Breast Center'
WHEN a.[pa-hosp-svc]='SBR' THEN 'OP Stony Brook Radiology'
WHEN a.[pa-hosp-svc]='SBS' THEN 'Skull Based Sur'
WHEN a.[pa-hosp-svc]='SCT' THEN 'Stem Cell Transplant'
WHEN a.[pa-hosp-svc]='SCU' THEN 'Surgical ICU'
WHEN a.[pa-hosp-svc]='SDA' THEN 'SDS Admit OP'
WHEN a.[pa-hosp-svc]='SDO' THEN 'Sleep Disorders'
WHEN a.[pa-hosp-svc]='SDS' THEN 'Amb Surgery'
WHEN a.[pa-hosp-svc]='SDZ' THEN 'Sleep Disorder Study'
WHEN a.[pa-hosp-svc]='SED' THEN 'OP Sedation'
WHEN a.[pa-hosp-svc]='SGP' THEN 'OP Surgery Ped'
WHEN a.[pa-hosp-svc]='SGY' THEN 'OP Surgery'
WHEN a.[pa-hosp-svc]='SHH' THEN 'OP Southampton'
WHEN a.[pa-hosp-svc]='SKL' THEN 'Skull'
WHEN a.[pa-hosp-svc]='SLM' THEN 'OP Sleep Medicine'
WHEN a.[pa-hosp-svc]='SLP' THEN 'Speech Lang Path'
WHEN a.[pa-hosp-svc]='SON' THEN 'Surgical Oncology'
WHEN a.[pa-hosp-svc]='SOP' THEN 'OP Surg Oncology Procedure'
WHEN a.[pa-hosp-svc]='SPC' THEN 'Special Surgery'
WHEN a.[pa-hosp-svc]='SPF' THEN 'Surgical Pathology FNA'
WHEN a.[pa-hosp-svc]='SPP' THEN 'Sched Preadmit Proc'
WHEN a.[pa-hosp-svc]='SPS' THEN 'Stony Brook Psych OP'
WHEN a.[pa-hosp-svc]='SRG' THEN 'Outpatient Surgery'
WHEN a.[pa-hosp-svc]='SRP' THEN 'Surgery Patchogue'
WHEN a.[pa-hosp-svc]='SRY' THEN 'Spine X-Ray'
WHEN a.[pa-hosp-svc]='SSD' THEN 'Surgical Step Down'
WHEN a.[pa-hosp-svc]='SSG' THEN 'Sleep Surgery OP'
WHEN a.[pa-hosp-svc]='SSS' THEN 'Short Stay Surgery OP'
WHEN a.[pa-hosp-svc]='STU' THEN 'SHSC'
WHEN a.[pa-hosp-svc]='STY' THEN 'Spine Therapy OP'
WHEN a.[pa-hosp-svc]='SWS' THEN 'Social Worker OP'
WHEN a.[pa-hosp-svc]='TCU' THEN 'Trauma Adult IC'
WHEN a.[pa-hosp-svc]='TEE' THEN 'Transesophageal Echo'
WHEN a.[pa-hosp-svc]='TEG' THEN 'T.P. Elect Encarogram'
WHEN a.[pa-hosp-svc]='TGS' THEN 'Tech Park Gastroenterology'
WHEN a.[pa-hosp-svc]='TIP' THEN 'Transfusion/Infusion'
WHEN a.[pa-hosp-svc]='TIS' THEN 'OP Tissue Types'
WHEN a.[pa-hosp-svc]='TNS' THEN 'Trauma Neurosurgery'
WHEN a.[pa-hosp-svc]='TOR' THEN 'Trauma Orthopedics'
WHEN a.[pa-hosp-svc]='TPD' THEN 'Trauma Pediatrics'
WHEN a.[pa-hosp-svc]='TPL' THEN 'Tech Park Plast Surg'
WHEN a.[pa-hosp-svc]='TPN' THEN 'Tech Park Pain'
WHEN a.[pa-hosp-svc]='TPS' THEN 'Tech Park Psych'
WHEN a.[pa-hosp-svc]='TPT' THEN 'Tech Park Therapy'
WHEN a.[pa-hosp-svc]='TPU' THEN 'Trauma Ped I.C.'
WHEN a.[pa-hosp-svc]='TSB' THEN 'Trauma Surgery Blue'
WHEN a.[pa-hosp-svc]='TSG' THEN 'Trauma Surgery Green'
WHEN a.[pa-hosp-svc]='TSR' THEN 'Trauma Surgery'
WHEN a.[pa-hosp-svc]='TST' THEN 'Prod Testing Service'
WHEN a.[pa-hosp-svc]='TTS' THEN 'Transplant Test Svc'
WHEN a.[pa-hosp-svc]='TUR' THEN 'Urology'
WHEN a.[pa-hosp-svc]='ULT' THEN 'Unrelat Living Donor IP'
WHEN a.[pa-hosp-svc]='URL' THEN 'Urology'
WHEN a.[pa-hosp-svc]='URO' THEN 'Urology'
WHEN a.[pa-hosp-svc]='URP' THEN 'Urology Patchogue'
WHEN a.[pa-hosp-svc]='VAS' THEN 'Vascular'
WHEN a.[pa-hosp-svc]='VCL' THEN 'Virtual Colonoscopy'
WHEN a.[pa-hosp-svc]='VPL' THEN 'Pulmonary Vent IP'
WHEN a.[pa-hosp-svc]='VSG' THEN 'Vascular Surgery'
WHEN a.[pa-hosp-svc]='VSP' THEN 'Vascular Special Procedure OP'
WHEN a.[pa-hosp-svc]='WLS' THEN 'Weight Loss Surgery IP'
WHEN a.[pa-hosp-svc]='XPC' THEN 'Radiology Procedures OP'
WHEN a.[pa-hosp-svc]='XRY' THEN 'X-Ray'
WHEN a.[pa-hosp-svc]='YOG' THEN 'Yoga Instruction'
WHEN a.[pa-hosp-svc]='ZOO' THEN 'Outpatient Offsite'
ELSE ''
END AS 'Hosp Svc Description'
,a.[pa-acct-sub-type]  --D=Discharged; I=In House
,(c.[pa-ins-co-cd] + CAST(c.[pa-ins-plan-no] as varchar)) as 'Ins1_Cd'
,(d.[pa-ins-co-cd] + CAST(d.[pa-ins-plan-no] as varchar)) as 'Ins2_Cd'
,(e.[pa-ins-co-cd] + CAST(e.[pa-ins-plan-no] as varchar)) as 'Ins3_Cd' 
,(f.[pa-ins-co-cd] + CAST(f.[pa-ins-plan-no] as varchar)) as 'Ins4_Cd'
,a.[pa-disch-dx-cd]
,a.[pa-disch-dx-cd-type]
,a.[pa-disch-dx-date]
,a.[PA-PROC-CD-TYPE(1)]
,a.[PA-PROC-CD(1)]
,a.[PA-PROC-DATE(1)]
,a.[pa-proc-prty(1)]
,a.[PA-PROC-CD-TYPE(2)]
,a.[PA-PROC-CD(2)]
,a.[PA-PROC-DATE(2)]
,a.[pa-proc-prty(2)]
,a.[PA-PROC-CD-TYPE(3)]
,a.[PA-PROC-CD(3)]
,a.[PA-PROC-DATE(3)]
,a.[pa-proc-prty(3)]
,CASE
WHEN b.[pa-unit-no] is null THEN c.[pa-bal-ins-pay-amt]
ELSE ISNULL(p.[tot-pymts],0)
END  as 'Pyr1_Pay_Amt'
,CASE
WHEN b.[pa-unit-no] is null THEN d.[pa-bal-ins-pay-amt]
ELSE ISNULL(q.[tot-pymts],0)
END  as 'Pyr2_Pay_Amt'
,CASE
WHEN b.[pa-unit-no] is null THEN e.[pa-bal-ins-pay-amt]
ELSE ISNULL(r.[tot-pymts],0)
END  as 'Pyr3_Pay_Amt'
,CASE
WHEN b.[pa-unit-no] is null THEN f.[pa-bal-ins-pay-amt]
ELSE ISNULL(s.[tot-pymts],0)
END  as 'Pyr4_Pay_Amt'
,c.[pa-last-ins-bl-date] as 'Pyr1_Last_Ins_Bl_Date'
,d.[pa-last-ins-bl-date] as 'Pyr2_Last_Ins_Bl_Date'
,e.[pa-last-ins-bl-date] as 'Pyr3_Last_Ins_Bl_Date'
,f.[pa-last-ins-bl-date] as 'Pyr4_Last_Ins_Bl_Date'
,
CASE
WHEN b.[pa-unit-no] IS NULL THEN (CAST(ISNULL(c.[pa-bal-ins-pay-amt],0) as money) + CAST(ISNULL(d.[pa-bal-ins-pay-amt],0) as money) + CAST(ISNULL(e.[pa-bal-ins-pay-amt],0) as money) + CAST(ISNULL(f.[pa-bal-ins-pay-amt],0) as money)) 
ELSE (CAST(ISNULL(p.[tot-pymts],0) as money) + CAST(ISNULL(q.[tot-pymts],0) as money) + CAST(ISNULL(r.[tot-pymts],0) as money) + CAST(ISNULL(s.[tot-pymts],0) as money))
END as 'Ins_Pay_Amt'
,
CASE
WHEN b.[pa-unit-no] IS NULL THEN (CAST(ISNULL(c.[pa-bal-ins-pay-amt],0) as money) + CAST(ISNULL(d.[pa-bal-ins-pay-amt],0) as money) + CAST(ISNULL(e.[pa-bal-ins-pay-amt],0) as money) + CAST(ISNULL(f.[pa-bal-ins-pay-amt],0) as money))+ CAST(ISNULL(a.[pa-bal-tot-pt-pay-amt],0) as money) 
ELSE (CAST(ISNULL(p.[tot-pymts],0) as money) + CAST(ISNULL(q.[tot-pymts],0) as money) + CAST(ISNULL(r.[tot-pymts],0) as money) + CAST(ISNULL(s.[tot-pymts],0) as money))+ CAST(ISNULL(t.[tot-pymts],0) as money) 
END as 'Tot_Pay_Amt'
,a.[pa-last-fc-cng-date]
--,h.[pa-cwi-seg-create-date] as 'CW_Post_Date'
--,(h.[pa-cwi-pyr-co-cd] + CAST([pa-cwi-pyr-plan-no] as varchar)) as 'CWI_Pyr_Cd'
--,h.[pa-cwi-last-wklst-id] as 'CW_Last_Worklist'
----,CASE
----WHEN h.[pa-cwi-last-actv-date]='1900-01-01 00:00:00.000' THEN ''
----ELSE 
--,h.[pa-cwi-last-actv-date] 
----END AS 'CW_Last_Activty_Date'
--,h.[pa-cwi-last-actv-cd] as 'CW_Last_Actvity_Cd'
--,h.[pa-cwi-last-actv-coll-id] as 'CW_Last_Collector_ID'
--,h.[pa-cwi-next-fol-date] as 'CW_Next_Followup_Date'
--,h.[pa-cwi-next-wklst-id] as 'CW_Next_Wrklst_ID'
,a.[pa-pt-representative] as 'Rep_Code'
,a.[pa-resp-cd] as 'Resp_Code'
,a.[pa-cr-rating] as 'Credit Rating'
,a.[pa-courtesy-allow]
,a.[pa-last-actv-date] as 'Last_Charge_Svc_Date'
,a.[pa-last-pt-pay-date]
,c.[pa-last-ins-pay-date]
,a.[pa-no-of-cwi] as 'No_Of_CW_Segments'
,a.[pa-pay-scale]
,a.[pa-stmt-cd]
,j.[pa-ins-prty]
,j.[pa-ins-plan]
,j.[pa-last-ins-pay-date]
,j.[last-ins-pay-amt]
,k.[jzanus-comment]
,l.[PA-NAD-FIRST-OR-ORGZ-CNTC]
,l.[PA-NAD-LAST-OR-ORGZ-NAME]
,CAST(m.[pa-pt-no-woscd] as varchar) + CAST(m.[pa-pt-no-scd-1] as varchar)
,m.[pa-user-text] as 'Moms_Pt_No'
,n.[pa-ins-co-cd]
,n.[pa-ins-plan-no] 
,o.[pa-ins-co-cd]
,o.[pa-ins-plan-no] 
,CASE
WHEN b.[pa-unit-no] is null then ISNULL(x.[BD-RECOVERY],0)
ELSE ISNULL(u.[BD-RECOVERY],0)
END as 'Bad_Debt_Recoveries'
,CASE
WHEN a.[pa-acct-bd-xfr-date] is not null and b.[pa-unit-no] is NULL THEN (a.[pa-bal-acct-bal]-a.[pa-bal-posted-since-xfr-bd]) 
WHEN b.[pa-unit-xfr-bd-date] is not null THEN ((ISNULL(b.[pa-unit-ins1-bal],0) + ISNULL(b.[pa-unit-ins2-bal],0) + ISNULL(b.[pa-unit-ins3-bal],0)+ISNULL(b.[pa-unit-ins4-bal],0)+ISNULL(b.[pa-unit-pt-bal],0))-ISNULL(u.[BD-RECOVERY],0)) 
ELSE '0'
END AS  'BD_WO_Amount'
--,CASE
--WHEN a.[pa-acct-bd-xfr-date] is not null AND b.[pa-unit-no] is NULL THEN COALESCE((b.[pa-unit-ins1-bal] + b.[pa-unit-ins2-bal] + b.[pa-unit-ins3-bal]+b.[pa-unit-ins4-bal]+b.[pa-unit-pt-bal])-u.[BD-RECOVERY],(a.[pa-bal-acct-bal]-a.[pa-bal-posted-since-xfr-bd])) 
--WHEN b.[pa-unit-xfr-bd-date] is not null THEN COALESCE((b.[pa-unit-ins1-bal] + b.[pa-unit-ins2-bal] + b.[pa-unit-ins3-bal]+b.[pa-unit-ins4-bal]+b.[pa-unit-pt-bal])-u.[BD-RECOVERY],(a.[pa-bal-acct-bal]-a.[pa-bal-posted-since-xfr-bd])) 
--ELSE '0'
--END AS  'BD_WO_Amount'
,w.*
,'ARCHIVE' as 'Source'


FROM [Echo_Archive].dbo.PatientDemographics a left outer join [Echo_Archive].dbo.unitizedaccounts b
ON a.[pa-pt-no-woscd]=b.[pa-pt-no-woscd] and a.[pa-pt-no-scd-1]=b.[pa-pt-no-scd-1] 
left outer join [Echo_Archive].dbo.insuranceinformation c
ON a.[pa-pt-no-woscd]=c.[pa-pt-no-woscd] and c.[pa-ins-prty]='1'
left outer join [Echo_Archive].dbo.insuranceinformation d
ON a.[pa-pt-no-woscd]=d.[pa-pt-no-woscd] and d.[pa-ins-prty]='2'
left outer join [Echo_Archive].dbo.insuranceinformation e
ON a.[pa-pt-no-woscd]=e.[pa-pt-no-woscd] and e.[pa-ins-prty]='3'
left outer join [Echo_Archive].dbo.insuranceinformation f
ON a.[pa-pt-no-woscd]=f.[pa-pt-no-woscd] and f.[pa-ins-prty]='4'
left outer join [Echo_Archive].dbo.diagnosisinformation g
ON a.[pa-pt-no-woscd]=g.[pa-pt-no-woscd] and g.[pa-dx2-prio-no]='1' and g.[pa-dx2-type1-type2-cd]='DF'
left outer join dbo.[#LastPaymentDatesA] j
ON a.[pa-pt-no-woscd]=j.[pa-pt-no-woscd] and j.[rank1]='1'
left outer join dbo.[#JzanusDeniedA] k
ON (CAST(a.[pa-pt-no-woscd] as varchar)+CAST(a.[pa-pt-no-scd-1] as varchar))=k.[pa-pt-no] 
left outer join [Echo_Archive].dbo.[NADInformation] l
ON a.[pa-pt-no-woscd]=l.[pa-pt-no-woscd] and l.[pa-nad-cd]='PTGAR'
left outer join [Echo_Archive].dbo.[UserDefined] m
ON a.[pa-pt-no-woscd]=m.[pa-pt-no-woscd] and m.[pa-component-id]='2C49PTNO'
left outer join [Echo_Active].dbo.[insuranceinformation] n
ON CAST(SUBSTRING(m.[pa-user-text],2,10) as varchar)=CAST(n.[pa-pt-no-woscd] as varchar) and n.[pa-ins-prty]='1'
left outer join [Echo_Archive].dbo.[insuranceinformation] o
ON CAST(SUBSTRING(m.[pa-user-text],2,10) as varchar)=CAST(o.[pa-pt-no-woscd] as varchar) and o.[pa-ins-prty]='1'
LEFT OUTER JOIN DBO.[#PaymtsByUnitInsA] p
ON CAST(b.[pa-pt-no-woscd] as varchar) + CAST(b.[pa-pt-no-scd-1] as varchar)=p.[pa-pt-no] AND b.[pa-unit-date]=p.[pa-dtl-unit-date] AND c.[pa-ins-co-cd]=p.[pa-dtl-ins-co-cd] AND c.[pa-ins-plan-no]=p.[pa-dtl-ins-plan-no]
LEFT OUTER JOIN DBO.[#PaymtsByUnitInsA] q
ON CAST(b.[pa-pt-no-woscd] as varchar) + CAST(b.[pa-pt-no-scd-1] as varchar)=q.[pa-pt-no] AND b.[pa-unit-date]=q.[pa-dtl-unit-date] AND d.[pa-ins-co-cd]=q.[pa-dtl-ins-co-cd] AND d.[pa-ins-plan-no]=q.[pa-dtl-ins-plan-no]
LEFT OUTER JOIN DBO.[#PaymtsByUnitInsA] r
ON CAST(b.[pa-pt-no-woscd] as varchar) + CAST(b.[pa-pt-no-scd-1] as varchar)=r.[pa-pt-no] AND b.[pa-unit-date]=r.[pa-dtl-unit-date] AND e.[pa-ins-co-cd]=r.[pa-dtl-ins-co-cd] AND e.[pa-ins-plan-no]=r.[pa-dtl-ins-plan-no]
LEFT OUTER JOIN DBO.[#PaymtsByUnitInsA] s
ON CAST(b.[pa-pt-no-woscd] as varchar) + CAST(b.[pa-pt-no-scd-1] as varchar)=s.[pa-pt-no] AND b.[pa-unit-date]=s.[pa-dtl-unit-date] AND f.[pa-ins-co-cd]=s.[pa-dtl-ins-co-cd] AND f.[pa-ins-plan-no]=s.[pa-dtl-ins-plan-no]
LEFT OUTER JOIN DBO.[#PaymtsByUnitInsA] t
ON CAST(b.[pa-pt-no-woscd] as varchar) + CAST(b.[pa-pt-no-scd-1] as varchar)=t.[pa-pt-no] AND b.[pa-unit-date]=t.[pa-dtl-unit-date] AND t.[pa-dtl-ins-co-cd] =''
LEFT OUTER JOIN DBO.[#BadDebtRecoveriesUnitsA] u
ON CAST(a.[pa-pt-no-woscd] as varchar) + CAST(a.[pa-pt-no-scd-1] as varchar)=u.[pa-pt-no] AND b.[pa-unit-date]=u.[pa-dtl-unit-date]
LEFT OUTER JOIN [Echo_Archive].DBO.NADInformation v
ON a.[pa-pt-no-woscd]=v.[pa-pt-no-woscd] AND v.[pa-nad-cd]='PTADD'
left outer join dbo.[#LastActiveIns] w
ON a.[pa-med-rec-no]=w.[pa-med-rec-no] and w.[ins-rank]='1'
LEFT OUTER JOIN DBO.[#BadDebtRecoveriesA] X
ON CAST(a.[pa-pt-no-woscd] as varchar) + CAST(a.[pa-pt-no-scd-1] as varchar)=x.[pa-pt-no] 



--left outer join 
--(SELECT [pa-pt-no-woscd],[pa-cwi-seg-create-date],[pa-cwi-pyr-co-cd],[pa-cwi-pyr-plan-no],[pa-cwi-last-wklst-id],[pa-cwi-last-dmnd-fol-date],[pa-cwi-last-actv-date],[pa-cwi-last-actv-cd],[pa-cwi-last-actv-coll-id],[pa-cwi-next-fol-date],[pa-cwi-next-wklst-id]
--FROM dbo.CollectorWorkStation aa
--WHERE [pa-cwi-seg-create-date]=(select max([pa-cwi-seg-create-date]) FROM dbo.CollectorWorkStation bb WHERE aa.[pa-pt-no-woscd]=bb.[pa-pt-no-woscd])
--) h
--ON a.[pa-pt-no-woscd]=h.[pa-pt-no-woscd]
 
--left outer join dbo.detailinformation c
--ON a.[pa-pt-no-woscd]=c.[pa-pt-no-woscd] and a.[pa-pt-no-scd]=c.[pa-pt-no-scd-1]

WHERE 
---(a.[pa-pt-representative] is not null AND not(a.[pa-pt-representative] IN ('','000'))
--a.[pa-acct-type] NOT IN ('4','6')
 --AND a.[pa-op-first-ins-bl-date] > '5/26/2017'
 (c.[pa-ins-co-cd]='H' OR c.[pa-ins-co-cd] is null)
 AND w.[pa-ins-cd] IS NOT NULL
 AND COALESCE(b.[pa-unit-tot-chg-amt],a.[pa-bal-tot-chg-amt]) <> '0'
 AND COALESCE((b.[pa-unit-ins1-bal] + b.[pa-unit-ins2-bal] + b.[pa-unit-ins3-bal]+b.[pa-unit-ins4-bal]+b.[pa-unit-pt-bal]),a.[pa-bal-acct-bal]) <> '0.00'
 AND a.[pa-acct-type] IN ('0','1','2')
--((b.[pa-unit-no] is null and a.[pa-acct-bd-xfr-date] BETWEEN '2015-01-01 00:00:00.000' AND '2017-05-31 23:59:59.000')
--OR (b.[pa-unit-no] is not null and b.[pa-unit-xfr-bd-date] BETWEEN '2015-01-01 00:00:00.000' AND '2017-05-31 23:59:59.000'))


ORDER BY a.[pa-pt-name]

--SELECT *


--FROM dbo.[#BadDebtRecoveries]
--order by [pa-pt-no]

--WHERE [pa-pt-no]='10097436447'
------AND [pa-dtl-ins-co-cd]=''


--select *

--from DBO.[#LastActiveIns] 

--select *

--from dbo.[#paymtsbyunitinsa]