USE [ECHO_ARCHIVE];
 
  IF OBJECT_ID('tempdb.dbo.#PivotedDxs2', 'U') IS NOT NULL
  DROP TABLE #PivotedDxs2; 
----------------------------------------------------------------------------------------------------------------------------------------------------
/*Create Temp Table With Pivoted ICD-DXs*/


GO



CREATE TABLE #PivotedDxs2
(
[PA-PT-NO] VARCHAR(12) NOT NULL,
[ICD_1] CHAR(8)NULL,
[ICD_2] CHAR(8)NULL,
[ICD_3] CHAR(8)NULL,
[ICD_4] CHAR(8)NULL,
[ICD_5] CHAR(8)NULL,
[ICD_6] CHAR(8)NULL,
[ICD_7] CHAR(8)NULL,
[ICD_8] CHAR(8)NULL,
[ICD_9] CHAR(8)NULL,
[ICD_10]CHAR(8)NULL,
[ICD_11]CHAR(8)NULL,
[ICD_12]CHAR(8)NULL,
[ICD_13]CHAR(8)NULL,
[ICD_14]CHAR(8)NULL,
[ICD_15]CHAR(8)NULL,
[ICD_16]CHAR(8)NULL,
[ICD_17]CHAR(8)NULL,
[ICD_18]CHAR(8)NULL,
[ICD_19]CHAR(8)NULL,
[ICD_20]CHAR(8)NULL,
[ICD_21]CHAR(8)NULL,
[ICD_22]CHAR(8)NULL,
[ICD_23]CHAR(8)NULL,
[ICD_24]CHAR(8)NULL,
[ICD_25]CHAR(8)NULL
);

INSERT INTO #PivotedDXs2([PA-PT-NO],[ICD_1],[ICD_2],[ICD_3],[ICD_4],[ICD_5],[ICD_6],[ICD_7],[ICD_8],[ICD_9],[ICD_10],[ICD_11],[ICD_12],[ICD_13],[ICD_14],[ICD_15],[ICD_16],
[ICD_17],[ICD_18],[ICD_19],[ICD_20],[ICD_21],[ICD_22],[ICD_23],[ICD_24],[ICD_25])


SELECT [Pt_No],
[1] as [ICD_1],[2] as [ICD_2],[3] as [ICD_3],[4] AS [ICD_4],[5] AS [ICD_5],[6] AS [ICD_6],[7] AS [ICD_7],[8] AS [ICD_8],[9] AS [ICD_9],[10] AS [ICD_10],
[11] AS [ICD_11],[12] AS [ICD_12], [13] AS [ICD_13], [14] AS [ICD_14], [15] AS [ICD_15], [16] AS [ICD_16], [17] AS [ICD_17],[18] AS [ICD_18],[19] AS [ICD_19],
[20] AS [ICD_20],[21] AS [ICD_21], [22] AS [ICD_22], [23] AS [ICD_23], [24] AS [ICD_24],[25] AS [ICD_25]
--[pa-dx2-code]
 FROM
 
 (SELECT    CAST(a.[PA-PT-NO-WOSCD] as varchar) + CAST(a.[pa-pt-no-scd-1] as varchar) as 'Pt_No'
 --,a.[pa-pt-no-woscd]
 --,a.[pa-pt-no-scd-1]
,[PA-DX2-CODE]
--,[PA-DX2-TYPE1-TYPE2-CD]
,[PA-DX2-PRIO-NO]
--,[PA-DX2-CODING-SYS-IND]
--,[PA-DX2-PRESENT-ON-ADM-IND]
--,[PA-DX2-EFF-DATE]
FROM [Echo_Archive].[dbo].[DiagnosisInformation] A --left outer join [Echo_Active].[dbo].[PatientDemographics] B
--ON a.[pa-pt-no-woscd]=b.[pa-pt-no-woscd]

  where [pa-dx2-type1-type2-cd]='DF'
  AND [pa-dx2-coding-sys-ind]='0'
 -- AND b.[pa-hosp-svc] IN ('CTH','EPS')
    ) AS SourceTableA2

PIVOT
(
MAX([pa-dx2-code])
FOR [pa-dx2-prio-no] in ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12],[13],[14],[15],[16],[17],[18],[19],[20],[21],[22],[23],[24],[25])
) as PivotTableA2;
 

 --SELECT *

 --FROM dbo.[#PivotedDXs2]

 --ORDER BY [pa-pt-no]

 /*Create Temp Table Pivoted ICD Procedures*/


USE [Echo_ARCHIVE];

----------------------------------------------------------------------------------------------------------------------------------------------------



IF OBJECT_ID('tempdb.dbo.#PivotedICDPCS2', 'U') IS NOT NULL
  DROP TABLE #PivotedICDPCS2; 
GO

CREATE TABLE #PivotedICDPCS2
(
[PA-PT-NO] VARCHAR(12) NOT NULL,
[PCS_1] CHAR(8)NULL,
[PCS_2] CHAR(8)NULL,
[PCS_3] CHAR(8)NULL,
[PCS_4] CHAR(8)NULL,
[PCS_5] CHAR(8)NULL,
[PCS_6] CHAR(8)NULL,
[PCS_7] CHAR(8)NULL,
[PCS_8] CHAR(8)NULL,
[PCS_9] CHAR(8)NULL,
[PCS_10]CHAR(8)NULL,
[PCS_11]CHAR(8)NULL,
[PCS_12]CHAR(8)NULL,
[PCS_13]CHAR(8)NULL,
[PCS_14]CHAR(8)NULL,
[PCS_15]CHAR(8)NULL,
[PCS_16]CHAR(8)NULL,
[PCS_17]CHAR(8)NULL,
[PCS_18]CHAR(8)NULL,
[PCS_19]CHAR(8)NULL,
[PCS_20]CHAR(8)NULL,
[PCS_21]CHAR(8)NULL,
[PCS_22]CHAR(8)NULL,
[PCS_23]CHAR(8)NULL,
[PCS_24]CHAR(8)NULL,
[PCS_25]CHAR(8)NULL
);

INSERT INTO #PivotedICDPCS2([PA-PT-NO],[PCS_1],[PCS_2],[PCS_3],[PCS_4],[PCS_5],[PCS_6],[PCS_7],[PCS_8],[PCS_9],[PCS_10],[PCS_11],[PCS_12],[PCS_13],[PCS_14],[PCS_15],[PCS_16],
[PCS_17],[PCS_18],[PCS_19],[PCS_20],[PCS_21],[PCS_22],[PCS_23],[PCS_24],[PCS_25])


SELECT [Pt_No],--CAST([PA-PT-NO-WOSCD] as varchar) + CAST([pa-pt-no-scd-1] as varchar) as 'Pt_No',
[1] as [PCS_1],[2] as [PCS_2],[3] as [PCS_3],[4] AS [PCS_4],[5] AS [PCS_5],[6] AS [PCS_6],[7] AS [PCS_7],[8] AS [PCS_8],[9] AS [PCS_9],[10] AS [PCS_10],
[11] AS [PCS_11],[12] AS [PCS_12], [13] AS [PCS_13], [14] AS [PCS_14], [15] AS [PCS_15], [16] AS [PCS_16], [17] AS [PCS_17],[18] AS [PCS_18],[19] AS [PCS_19],
[20] AS [PCS_20],[21] AS [PCS_21], [22] AS [PCS_22], [23] AS [PCS_23], [24] AS [PCS_24],[25] AS [PCS_25]

 FROM
 
 (SELECT    CAST(a.[PA-PT-NO-WOSCD] as varchar) + CAST(a.[pa-pt-no-scd-1] as varchar) as 'Pt_No'
-- ,a.[pa-pt-no-woscd]
-- ,a.[pa-pt-no-scd-1]
--,[PA-PROC3-DATE]
,[PA-PROC3-CD]
--,[PA-PROC3-CD-TYPE]
,[PA-PROC3-PRTY]
--,[PA-PROC3-CD-MODF(1)]
--,[PA-PROC3-CD-MODF(2)]
--,[PA-PROC3-RESP-PARTY]
FROM [Echo_Archive].[dbo].[ProcedureInformation] A --left outer join [Echo_Active].[dbo].[PatientDemographics] B
--ON a.[pa-pt-no-woscd]=b.[pa-pt-no-woscd]

  where a.[pa-proc3-cd-type]='0'
    ) AS SourceTableA22

PIVOT
(
MAX([PA-PROC3-CD])
FOR [PA-PROC3-PRTY] in ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12],[13],[14],[15],[16],[17],[18],[19],[20],[21],[22],[23],[24],[25])
) as PivotTableA22;
 

 --SELECT *

 --FROM dbo.[#PivotedICDPCS]

 --ORDER BY [pa-pt-no]

 /****** Script for SelectTopNRows command from SSMS  ******/

USE [Echo_ARCHIVE];

----------------------------------------------------------------------------------------------------------------------------------------------------
/*Create Temp Table With Pivoted Charge CPTs*/


IF OBJECT_ID('tempdb.dbo.#PivotedChgCPTs2', 'U') IS NOT NULL
  DROP TABLE #PivotedChgCPTs2; 
GO

CREATE TABLE #PivotedChgCPTs2
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

INSERT INTO #PivotedChgCPTs2([PA-PT-NO],[CPT_1],[CPT_2],[CPT_3],[CPT_4],[CPT_5],[CPT_6],[CPT_7],[CPT_8],[CPT_9],[CPT_10],[CPT_11],[CPT_12],[CPT_13],[CPT_14],[CPT_15],[CPT_16],
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

FROM [Echo_Archive].[dbo].[DetailInformation] A --left outer join [Echo_Archive].[dbo].[PatientDemographics] B
--ON a.[pa-pt-no-woscd]=b.[pa-pt-no-woscd]

  where [pa-dtl-rev-cd] IN ('360','490','481','480')
  and [PA-DTL-CPT-CD] IS NOT NULL
  --AND b.[pa-hosp-svc] IN ('CTH','EPS')
    ) AS SourceTableA23

PIVOT
(
MAX([pa-dtl-cpt-cd])
FOR [RANK]in ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12],[13],[14],[15],[16],[17],[18],[19],[20],[21],[22],[23],[24],[25])
) as PivotTableA23;
 

 --SELECT *

 --FROM dbo.[#PivotedChgCPTs2]

 --ORDER BY [pa-pt-no]

 ---------------------------------------------------------------------------------------------------------------------------------------
 /*Create Temp Table With Billing Physician-Responsible Party for the Principal Procedure*/


IF OBJECT_ID('tempdb.dbo.#PrinProcDoc2', 'U') IS NOT NULL
  DROP TABLE #PrinProcDoc2; 
GO

CREATE TABLE #PrinProcDoc2
(

[PA-PT-NO] VARCHAR(12) NOT NULL,
[PA-PROC3-RESP-PARTY] CHAR(6) NULL

);

INSERT INTO #PrinProcDoc2 ([PA-PT-NO],[PA-PROC3-RESP-PARTY])
 SELECT (CAST([PA-PT-NO-WOSCD] AS VARCHAR)+CAST([PA-PT-NO-SCD-1] AS VARCHAR)) AS 'PA-PT-NO'
   ,[PA-PROC3-RESP-PARTY]
        
   
  FROM [Echo_Archive].[dbo].[ProcedureInformation]

  WHERE [pa-proc3-prty]='1' AND [pa-proc3-resp-party]<>'000000'

  GROUP BY [pa-pt-no-woscd],[pa-pt-no-scd-1],[PA-PROC3-RESP-PARTY]

 --------------------------------------------------------------------------------------------------------------------------------------

 --SELECT *
 --FROM DBO.[#PRINPROCDOC2]
 --ORDER BY [pa-pt-no]


 
 ----------------------------------------------------------------------------------------------------------------------------------------------------



IF OBJECT_ID('tempdb.dbo.#PivotedCodedCPT2', 'U') IS NOT NULL
  DROP TABLE #PivotedCodedCPT2; 
GO

CREATE TABLE #PivotedCodedCPT2
(
[PA-PT-NO] VARCHAR(12) NOT NULL,
[PCH_1] CHAR(12)NULL,
[PCH_2] CHAR(12)NULL,
[PCH_3] CHAR(12)NULL,
[PCH_4] CHAR(12)NULL,
[PCH_5] CHAR(12)NULL,
[PCH_6] CHAR(12)NULL,
[PCH_7] CHAR(12)NULL,
[PCH_8] CHAR(12)NULL,
[PCH_9] CHAR(12)NULL,
[PCH_10]CHAR(12)NULL,
[PCH_11]CHAR(12)NULL,
[PCH_12]CHAR(12)NULL,
[PCH_13]CHAR(12)NULL,
[PCH_14]CHAR(12)NULL,
[PCH_15]CHAR(12)NULL,
[PCH_16]CHAR(12)NULL,
[PCH_17]CHAR(12)NULL,
[PCH_18]CHAR(12)NULL,
[PCH_19]CHAR(12)NULL,
[PCH_20]CHAR(12)NULL,
[PCH_21]CHAR(12)NULL,
[PCH_22]CHAR(12)NULL,
[PCH_23]CHAR(12)NULL,
[PCH_24]CHAR(12)NULL,
[PCH_25]CHAR(12)NULL
);

INSERT INTO #PivotedCodedCPT2([PA-PT-NO],[PCH_1],[PCH_2],[PCH_3],[PCH_4],[PCH_5],[PCH_6],[PCH_7],[PCH_8],[PCH_9],[PCH_10],[PCH_11],[PCH_12],[PCH_13],[PCH_14],[PCH_15],[PCH_16],
[PCH_17],[PCH_18],[PCH_19],[PCH_20],[PCH_21],[PCH_22],[PCH_23],[PCH_24],[PCH_25])


SELECT [Pt_No],--CAST([PA-PT-NO-WOSCD] as varchar) + CAST([pa-pt-no-scd-1] as varchar) as 'Pt_No',
[1] as [PCH_1],[2] as [PCH_2],[3] as [PCH_3],[4] AS [PCH_4],[5] AS [PCH_5],[6] AS [PCH_6],[7] AS [PCH_7],[8] AS [PCH_8],[9] AS [PCH_9],[10] AS [PCH_10],
[11] AS [PCH_11],[12] AS [PCH_12], [13] AS [PCH_13], [14] AS [PCH_14], [15] AS [PCH_15], [16] AS [PCH_16], [17] AS [PCH_17],[18] AS [PCH_18],[19] AS [PCH_19],
[20] AS [PCH_20],[21] AS [PCH_21], [22] AS [PCH_22], [23] AS [PCH_23], [24] AS [PCH_24],[25] AS [PCH_25]

 FROM
 
 (SELECT    CAST(a.[PA-PT-NO-WOSCD] as varchar) + CAST(a.[pa-pt-no-scd-1] as varchar) as 'Pt_No'
-- ,a.[pa-pt-no-woscd]
-- ,a.[pa-pt-no-scd-1]
--,[PA-PROC3-DATE]
,CAST([PA-PROC3-CD] as varchar)+CAST([pa-proc3-cd-modf(1)] as varchar) as 'pa-proc3-cd'
--,[PA-PROC3-CD-TYPE]
,[PA-PROC3-PRTY]
--,[PA-PROC3-CD-MODF(1)]
--,[PA-PROC3-CD-MODF(2)]
--,[PA-PROC3-RESP-PARTY]
FROM [Echo_Archive].[dbo].[ProcedureInformation] A --left outer join [Echo_Active].[dbo].[PatientDemographics] B
--ON a.[pa-pt-no-woscd]=b.[pa-pt-no-woscd]

  where a.[pa-proc3-cd-type]='H'
    ) AS SourceTable2A2

PIVOT
(
MAX([PA-PROC3-CD])
FOR [PA-PROC3-PRTY] in ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12],[13],[14],[15],[16],[17],[18],[19],[20],[21],[22],[23],[24],[25])
) as PivotTable2A2;
 

 --SELECT *

 --FROM dbo.[#PivotedCodedCPT2]

 --ORDER BY [pa-pt-no]

 /****** Script for SelectTopNRows command from SSMS  ******/

 --------------------------------------------------------------------------------------------------------------------------------------
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
SELECT CAST([pa-pt-no-woscd] as varchar) +CAST([pa-pt-no-scd-1] as varchar) as 'PA-PT-NO',
SUM([pa-dtl-chg-amt]) as 'Total_Denials'
FROM [Echo_Archive].dbo.DetailInformation
WHERE [pa-dtl-svc-cd-woscd] IN ('21141','21142','21901','21905','23752','23754','29701','29705','21143','21144','21145','21146','21147','21148','21810','22750','23302','23303')
GROUP BY CAST([pa-pt-no-woscd] as varchar) +CAST([pa-pt-no-scd-1] as varchar)

---------------------------------------------------------------------------------------------------------------------------------------


USE [Echo_ACTIVE];
 --------------------------------------------------------------------------------------------------------------------------------------
 SELECT A.[pa-med-rec-no] as 'Medical_Record#',
 CAST(A.[PA-PT-NO-WOSCD] as varchar) + CAST(A.[pa-pt-no-scd-1] as varchar) as 'Patient_Control_Account#',
 A.[pa-pt-type] as 'Patient_Type',
 '' as 'User_Defined_Registration_Area',
CASE
WHEN a.[pa-acct-type] in ('0','6','7') THEN 'OP' --0=OP; 6=OP BAD DEBT; 7=OP HISTORIC
WHEN a.[pa-acct-type] in ('1','2','4','8') THEN 'IP'  --1=IP; 2=A/R; 4=I/P BAD DEBT; 8=I/P HISTORIC
ELSE ''
END as 'User_Defined_Patient_Type',
 A.[pa-hosp-svc] as 'Hospital_Service',
 A.[pa-adm-date] as 'Admit_Date',
 A.[pa-dsch-date] as 'Discharge_Date',
 A.[pa-atn-dr-name] as 'Attending_Physician_Name',
 CAST(A.[pa-adm-dr-no-woscd] as varchar) + CAST(A.[pa-adm-dr-no-scd] as varchar) as 'Admitting_Dr_No',
 C.[pa-proc3-resp-party] as 'Billing_Physician_No',
 '' as 'Emergency_Room_Physician_Name',
 B.[pa-ref-dr-cd1] as 'Referring/Ordering Physician_No',
 A.[pa-disch-dx-cd] as 'Primary_ICD-10_Diagnosis_Code',
D.[PCS_1] as 'Primary_ICD-10_Procedure_Code',
[ICD_1],[ICD_2],[ICD_3],[ICD_4],[ICD_5],[ICD_6],[ICD_7],[ICD_8],[ICD_9],[ICD_10],[ICD_11],[ICD_12],[ICD_13],[ICD_14],[ICD_15],[ICD_16],
[ICD_17],[ICD_18],[ICD_19],[ICD_20],[ICD_21],[ICD_22],[ICD_23],[ICD_24],[ICD_25],
[PCS_1],[PCS_2],[PCS_3],[PCS_4],[PCS_5],[PCS_6],[PCS_7],[PCS_8],[PCS_9],[PCS_10],[PCS_11],[PCS_12],[PCS_13],[PCS_14],[PCS_15],[PCS_16],
[PCS_17],[PCS_18],[PCS_19],[PCS_20],[PCS_21],[PCS_22],[PCS_23],[PCS_24],[PCS_25],
[PCH_1],[PCH_2],[PCH_3],[PCH_4],[PCH_5],[PCH_6],[PCH_7],[PCH_8],[PCH_9],[PCH_10],[PCH_11],[PCH_12],[PCH_13],[PCH_14],[PCH_15],[PCH_16],
[PCH_17],[PCH_18],[PCH_19],[PCH_20],[PCH_21],[PCH_22],[PCH_23],[PCH_24],[PCH_25],
[CPT_1],[CPT_2],[CPT_3],[CPT_4],[CPT_5],[CPT_6],[CPT_7],[CPT_8],[CPT_9],[CPT_10],[CPT_11],[CPT_12],[CPT_13],[CPT_14],[CPT_15],[CPT_16],
[CPT_17],[CPT_18],[CPT_19],[CPT_20],[CPT_21],[CPT_22],[CPT_23],[CPT_24],[CPT_25],
E.[pa-ins-co-cd] + CAST(e.[pa-ins-plan-no] as varchar) as 'Insurance_Plan_Code',
CASE
WHEN LEN(E.[pa-ins-pol-no])='0' THEN E.[pa-ins-subscr-ins-group-id]
ELSE E.[pa-ins-pol-no]
END as 'Insurance_Policy_Number',
'1' as 'Insurance_Priority',
J.[pa-drg-no-2] as 'State_NY_APR_DRG',
I.[pa-drg-no-2] as 'Federal_DRG',
A.[pa-bal-tot-chg-amt] as 'Total_Charges',
a.[pa-bal-final-bl-bal] as 'Total_Expected_Allowed_Amount',
(CAST(ISNULL(E.[pa-bal-ins-pay-amt],0) as money) + CAST(ISNULL(K.[pa-bal-ins-pay-amt],0) as money) + CAST(ISNULL(L.[pa-bal-ins-pay-amt],0) as money) + CAST(ISNULL(M.[pa-bal-ins-pay-amt],0) as money))+ CAST(ISNULL(a.[pa-bal-tot-pt-pay-amt],0) as money) as 'Total_Payment',
(CAST(ISNULL(E.[pa-bal-ins-adj-amt],0) as money) + CAST(ISNULL(K.[pa-bal-ins-adj-amt],0) as money) + CAST(ISNULL(L.[pa-bal-ins-adj-amt],0) as money) + CAST(ISNULL(M.[pa-bal-ins-adj-amt],0) as money))+ CAST(ISNULL(a.[pa-bal-tot-pt-adj-amt],0) as money) as 'Total_Adjustment',
N.[total-denials] as 'Total_Denials'
--(
--SELECT SUM(aa.[pa-dtl-chg-amt])
--FROM [Echo_Active].dbo.DetailInformation aa
--WHERE a.[pa-pt-no-woscd]=aa.[pa-pt-no-woscd] and aa.[pa-dtl-svc-cd-woscd] IN ('21141','21142','21901','21905','23752','23754','29701','29705','21143','21144','21145','21146','21147','21148','21810','22750','23302','23303')
--) as 'Total_Denials'





 FROM [Echo_Archive].dbo.PatientDemographics A left outer join [Echo_Archive].dbo.MiscellaneousInformation B
 ON a.[pa-pt-no-woscd]=b.[pa-pt-no-woscd]
 left outer join [Echo_Archive].dbo.[#PrinProcDoc2] C
 ON CAST(a.[pa-pt-no-woscd] as varchar) + CAST(a.[pa-pt-no-scd-1] as varchar) = c.[pa-pt-no]
 left outer join dbo.[#PivotedICDPCS2] D
 ON CAST(a.[pa-pt-no-woscd] as varchar) + CAST(a.[pa-pt-no-scd-1] as varchar) = D.[pa-pt-no]
 left outer join [Echo_Archive].dbo.[InsuranceInformation] E
 ON a.[pa-pt-no-woscd]=e.[pa-pt-no-woscd] AND e.[pa-ins-prty]='1'
 left outer join dbo.[#PivotedDXs2] F
 ON CAST(a.[pa-pt-no-woscd] as varchar) + CAST(a.[pa-pt-no-scd-1] as varchar) = F.[pa-pt-no]
 left outer join dbo.[#PivotedChgCPTs2] G
 ON CAST(a.[pa-pt-no-woscd] as varchar) + CAST(a.[pa-pt-no-scd-1] as varchar) = G.[pa-pt-no]
 left outer join dbo.[#PivotedCodedCPT2] H
 ON CAST(a.[pa-pt-no-woscd] as varchar) + CAST(a.[pa-pt-no-scd-1] as varchar) = H.[pa-pt-no]
 left outer join [Echo_Archive].dbo.[DRGInformation] I
 ON a.[pa-pt-no-woscd]=I.[pa-pt-no-woscd] and i.[pa-drg-seg-type]='3'---MS-DRG's
 left outer join [Echo_Archive].dbo.[DRGInformation] J
 ON a.[pa-pt-no-woscd]=J.[pa-pt-no-woscd] and J.[pa-drg-seg-type]='1'---APR-DRG's
left outer join [Echo_Archive].dbo.insuranceinformation K
ON a.[pa-pt-no-woscd]=K.[pa-pt-no-woscd] and K.[pa-ins-prty]='2'
left outer join [Echo_Archive].dbo.insuranceinformation L
ON a.[pa-pt-no-woscd]=L.[pa-pt-no-woscd] and L.[pa-ins-prty]='3'
left outer join [Echo_Archive].dbo.insuranceinformation M
ON a.[pa-pt-no-woscd]=M.[pa-pt-no-woscd] and M.[pa-ins-prty]='4'
left outer join dbo.[#DenialWriteoffs2] N
ON CAST(a.[pa-pt-no-woscd] as varchar) + CAST(a.[pa-pt-no-scd-1] as varchar) = N.[pa-pt-no]





 WHERE a.[pa-pt-no-woscd] IN

 (
 SELECT DISTINCT([pa-pt-no-woscd])
 FROM [Echo_Archive].dbo.DetailInformation
 WHERE [pa-dtl-gl-no] IN ('386','431','771','481')
 AND [pa-dtl-date] BETWEEN '2016-11-01 00:00:00.000' AND '2017-04-30 23:59:59.000'
 )
