/****** Script for SelectTopNRows command from SSMS  ******/

USE [Echo_ACTIVE];

----------------------------------------------------------------------------------------------------------------------------------------------------
/*Create Temp Table With Pivoted Charge CPTs*/


IF OBJECT_ID('tempdb.dbo.#PivotedChgCPTs', 'U') IS NOT NULL
  DROP TABLE #PivotedChgCPTs; 
GO

CREATE TABLE #PivotedChgCPTs
(
[PA-PT-NO] VARCHAR(12) NOT NULL,
[CPT_1] CHAR(8)NULL,

[CPT_2] CHAR(8)NULL,

[CPT_3] CHAR(8)NULL,

[CPT_4] CHAR(8)NULL,

[CPT_5] CHAR(8)NULL,

[CPT_6] CHAR(8)NULL,

[CPT_7] CHAR(8)NULL,

[CPT_8] CHAR(8)NULL,

[CPT_9] CHAR(8)NULL,

[CPT_10] CHAR(8)NULL,

[CPT_11] CHAR(8)NULL,

[CPT_12] CHAR(8)NULL,

[CPT_13] CHAR(8)NULL,

[CPT_14] CHAR(8)NULL,

[CPT_15] CHAR(8)NULL,

[CPT_16] CHAR(8)NULL,

[CPT_17] CHAR(8)NULL,

[CPT_18] CHAR(8)NULL,

[CPT_19] CHAR(8)NULL,

[CPT_20] CHAR(8)NULL,

[CPT_21] CHAR(8)NULL,

[CPT_22] CHAR(8)NULL,

[CPT_23] CHAR(8)NULL,

[CPT_24] CHAR(8)NULL,

[CPT_25] CHAR(8)NULL,


);

INSERT INTO #PivotedChgCPTs([PA-PT-NO],[CPT_1],[CPT_2],[CPT_3],[CPT_4],[CPT_5],[CPT_6],[CPT_7],[CPT_8],[CPT_9],[CPT_10],[CPT_11],[CPT_12],[CPT_13],[CPT_14],[CPT_15],[CPT_16],
[CPT_17],[CPT_18],[CPT_19],[CPT_20],[CPT_21],[CPT_22],[CPT_23],[CPT_24],[CPT_25])


SELECT CAST([PA-PT-NO-WOSCD] as varchar) + CAST([pa-pt-no-scd-1] as varchar) as 'Pt_No',
[1] AS [CPT_1],[2] AS [CPT_2],[3] AS [CPT_3],[4] AS [CPT_4],[5] AS [CPT_5],[6] AS [CPT_6],[7] AS [CPT_7],[8] AS [CPT_8],[9] AS [CPT_9],[10] AS [CPT_10],[11] AS [CPT_11],[12] AS [CPT_12],[13] AS [CPT_13],[14] AS [CPT_14],[15] AS [CPT_15],[16] AS [CPT_16],
[17] AS [CPT_17],[18] AS [CPT_18],[19] AS [CPT_19],[20] AS [CPT_20],[21] AS [CPT_21],[22] AS [CPT_22],[23] AS [CPT_23],[24] AS [CPT_24],[25] AS [CPT_25]
 
 FROM
 
 (SELECT    CAST(a.[PA-PT-NO-WOSCD] as varchar) + CAST(a.[pa-pt-no-scd-1] as varchar) as 'Pt_No'
 ,a.[pa-pt-no-woscd]
 ,a.[pa-pt-no-scd-1]
 --,a.[pa-dtl-rev-cd]
 ,a.[pa-dtl-cpt-cd]
-- ,a.[pa-dtl-proc-cd-modf(1)]
-- ,a.[pa-dtl-description]
-- ,a.[pa-dtl-technical-desc]
--,[pa-dtl-svc-cd-woscd]
--,[pa-dtl-svc-cd-scd]
,RANK() OVER (PARTITION BY a.[pa-pt-no-woscd] ORDER BY a.[pa-dtl-cpt-cd] asc) as 'Rank'

FROM [Echo_Active].[dbo].[DetailInformation] A left outer join [Echo_Active].[dbo].[PatientDemographics] B
ON a.[pa-pt-no-woscd]=b.[pa-pt-no-woscd]

  where [pa-dtl-rev-cd] IN ('360','490','481','480')
  and [PA-DTL-CPT-CD] IS NOT NULL
  --AND b.[pa-hosp-svc] IN ('CTH','EPS')
    ) AS SourceTable3

PIVOT
(
MAX([pa-dtl-cpt-cd])
FOR [RANK]in ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12],[13],[14],[15],[16],[17],[18],[19],[20],[21],[22],[23],[24],[25])
) as PivotTable;
 

 SELECT *

 FROM dbo.[#PivotedChgCPTs]



------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------

