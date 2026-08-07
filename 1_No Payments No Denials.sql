USE [SMS];

/**CREATE Temp Table to Rollup Payments To Encounter and Unit Level**/

IF OBJECT_ID('tempdb.dbo.#Payments_Rollup','U') IS NOT NULL
DROP TABLE #Payments_Rollup
GO

CREATE TABLE #Payments_Rollup

([PA-PT-NO-WOSCD] VARCHAR(11) NOT NULL,
[PA-PT-NO-SCD] CHAR(1) NOT NULL,
[PT-NO] CHAR(12) NOT NULL,
[PA-UNIT-NO] DECIMAL(4,0) NULL,
[UNIT-DATE] DATETIME NULL,
[TOTAL-PAYMENTS] MONEY NULL
);

INSERT INTO #Payments_Rollup([PA-PT-NO-WOSCD],[PA-PT-NO-SCD],[PT-NO],[PA-UNIT-NO],[UNIT-DATE],[TOTAL-PAYMENTS])

SELECT [PA-PT-NO-WOSCD],
[PA-PT-NO-SCD],
[PT-NO],
[PA-UNIT-NO],
[UNIT-DATE],
SUM([TOT-PAYMENTS]) AS 'TOTAL-PAYMENTS'

FROM dbo.[Payments_For_Reporting]

GROUP BY [PA-PT-NO-WOSCD],
[PA-PT-NO-SCD],
[PT-NO],
[PA-UNIT-NO],
[UNIT-DATE]


SELECT [pt_no],
--CAST([pt_no] as varchar) + CAST(COALESCE([pa-unit-date],[dsch_date],[admit_date]) as varchar),
a.[pa-unit-no],
a.[pa-pt-name],
a.[admit_date],
a.[dsch_date],
[pa-unit-date],
a.[tot_chgs],
COALESCE(b.[total-payments],c.[total-payments]) as 'Total_Payments'



FROM dbo.[Encounters_For_Reporting] a left outer join dbo.[#Payments_Rollup] b
ON a.[pt_no]=b.[pt-no] and a.[pa-unit-date] = b.[unit-date]
left outer join dbo.[#Payments_Rollup] c
ON a.[pt_no]=c.[pt-no] and a.[pa-unit-date] is null

where a.[balance] = '0'
AND a.[tot_chgs] > '0'
AND COALESCE(b.[total-payments],c.[total-payments]) = '0'
AND a.[pa-fc] NOT IN ('0','1','2','3','4','5','6','7','8','9')
and CAST(ltrim(rtrim([pt_no])) as varchar) + CAST(COALESCE([pa-unit-date],[dsch_date],[admit_date]) as varchar) NOT IN

(
SELECT DISTINCT(CAST(ltrim(rtrim([pa-pt-no])) as varchar)+CAST(coalesce([pa-unit-date],[pa-dsch-date])as varchar))

FROM dbo.[Denied_Encounter_Details]

GROUP BY [pa-pt-no],[pa-unit-date],[pa-dsch-date]




)
