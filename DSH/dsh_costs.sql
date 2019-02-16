/*DSH Project*/
 
Use [DSH];
 
/*Create Temp DSH Costs*/
 
SET ANSI_NULLS ON
GO
 
SET QUOTED_IDENTIFIER ON
GO
 
--------------------
DROP TABLE  IF EXISTS[temp_DSH_Costs];
DROP TABLE  IF EXISTS[temp_DSH_Costs2];
DROP TABLE  IF EXISTS[2016_DSH_Costs];
GO

SELECT a.[pa-pt-no-woscd]
, a.[PA-PT-NO-SCD]
, CAST(a.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(a.[PA-PT-NO-SCD] AS VARCHAR) AS 'PT-NO'
, A.[PA-UNIT-NO]
, A.[unit-date] as 'UNIT-DATE'
, B.[PTACCT_TYPE] AS 'TYPE'
, A.[PA-DTL-TYPE-IND]
, CASE
    when [PA-DTL-TYPE-IND] = '1' 
        then 'Payments'
    when [PA-DTL-TYPE-IND] = '2'
        then 'Balance Transfer Payment'  
    when [PA-DTL-TYPE-IND] = '3' 
        then 'Adjustment' 
    when [PA-DTL-TYPE-IND] = '4' 
        then 'Balance Transfer Adj' 
    when [PA-DTL-TYPE-IND] = '5' 
        then 'Statistical Charge'
    when [PA-DTL-TYPE-IND] = '7' 
        then 'Room Charge' 
    when [PA-DTL-TYPE-IND] = '8' 
        then 'Ancillary Charge' 
    when [PA-DTL-TYPE-IND] = '9' 
        then 'Late Stat Chg'
    when [PA-DTL-TYPE-IND] = 'A' 
        then 'Late Ancillary Chg'
    when [PA-DTL-TYPE-IND] = 'B' 
        then 'Late Room Chg' 
        else 'None' 
  END  as Transaction_Type
, A.[PA-DTL-SVC-CD]
, A.[PA-DTL-CDM-DESCRIPTION]
, A.[PA-DTL-CPT-CD]
, G.[CPT_H] as 'CPT from CDM'
--, coalesce(A.[PA-DTL-CPT-CD],G.[CPT_H]) AS 'Adjusted CPT Code', /*for future reference*/
, case
    when len([PA-DTL-CPT-CD]) > '0' 
        then A.[PA-DTL-CPT-CD] 
        else G.[CPT_H] 
  END as 'Adjusted CPT Code'
, A.[PA-DTL-REV-CD]
, G.[Rev_CD_(A) ] as 'Rev Code from CDM'
, case
    when len([PA-DTL-REV-CD]) > '0' 
        then A.[PA-DTL-REV-CD] 
        else G.[Rev_CD_(A) ] 
  END as 'Adjusted Rev Code'
, A.[PA-DTL-GL-NO]
, D.[CrAcctUnit]
, E.[ICR]
, CASE
    WHEN [PA-DTL-TYPE-IND] IN ('7','B') 
        THEN F.[R&B PER DIEM 2016] 
        ELSE 0 
  END AS 'PER DIEM'
, E.[Classification_for_2016_DSH]
, b.[PA-MED-REC-NO]
, Sum(A.[TOT-CHG-QTY]) AS 'SUM TOT-CHG-QTY'
, SUM(A.[TOT-CHARGES]) AS 'SUM OF TOT CHG'
, SUM(A.[TOT-PROF-FEES]) AS 'SUM OF TOT PROF FEES'
, round(
    (
        SUM(A.[TOT-CHARGES]) 
        +
        SUM(A.[TOT-PROF-FEES])
    )
    , 2
) as 'Sum_of_Chargesand_Prof_Fees'
 
INTO [temp_DSH_Costs]
 
FROM [dbo].[DSH_Charges] AS a 
left join [dbo].[Encounters_For_DSH] AS b
ON a.[pa-pt-no-woscd] = b.[pa-pt-no-woscd] 
left join [dbo].[Copy_of_CDM_18DEC_for_DSH] AS g 
ON A.[PA-DTL-SVC-CD] = G.[Service_Code] 
left join [dbo].[2017_GL_Key_Table] AS d 
ON A.[PA-DTL-GL-NO] = d.[GLKey] 
left join [dbo].[2017_ICR_Rollup_with_Room_and_Board_Classifications_for_DSH] AS E 
ON D.[CrAcctUnit] = E.[Cost_Center_wExtra_Zeros]
left join [dbo].[2016_Per_Diem_for_DSH] AS F 
ON E.[ICR] = F.[ICR CC] 

GROUP BY a.[pa-pt-no-woscd]
, a.[PA-PT-NO-SCD]
, A.[PA-UNIT-NO]
, a.[unit-date]
, B.[PTACCT_TYPE]
, A.[PA-DTL-TYPE-IND]
, A.[PA-DTL-GL-NO]
, A.[PA-DTL-REV-CD]
, A.[PA-DTL-CPT-CD]
, A.[PA-DTL-SVC-CD]
, A.[PA-DTL-CDM-DESCRIPTION]
, G.[CPT_H]
, d.[CrAcctUnit]
, E.[ICR]
, E.[Classification_for_2016_DSH]
, b.[pa-med-rec-no]
, F.[R&B PER DIEM 2016]
, G.[Rev_CD_(A)]
;
 
/*Add RCC*/
 
SELECT [pa-pt-no-woscd]
, [PA-PT-NO-SCD]
, [PT-NO]
, [PA-UNIT-NO]
, [UNIT-DATE]
, [TYPE]
, [PA-DTL-TYPE-IND]
, [Transaction_Type]
, [PA-DTL-SVC-CD]
, [PA-DTL-CDM-DESCRIPTION]
, [PA-DTL-CPT-CD]
, [CPT from CDM]
, [Adjusted CPT Code]
, [PA-DTL-REV-CD]
, [Rev Code from CDM]
, [Adjusted Rev Code]
, [PA-DTL-GL-NO]
, [CrAcctUnit]
, [ICR]
, [PER DIEM]
, [RCC]
, [Classification_for_2016_DSH]
, [PA-MED-REC-NO]
, [SUM TOT-CHG-QTY]
, [SUM OF TOT CHG]
, [SUM OF TOT PROF FEES]
, [Sum_of_Chargesand_Prof_Fees]
, CASE 
    WHEN [PA-DTL-TYPE-IND] IN ('8','A') 
        THEN c.[RCC] 
        ELSE 0 
  END AS 'RCC_For_DSH'
 
into temp_DSH_Costs2
 
FROM [DSH].[dbo].[temp_DSH_Costs] AS a
left join [dbo].[2016_RCCs_for_DSH] AS c 
ON a.[Adjusted Rev Code] = c.[SORT_BY_REV_CODE];
 
/*Finalize the DSH Cost Table*/

SELECT [pa-pt-no-woscd]
, [PA-PT-NO-SCD]
, [PT-NO]
, [PA-UNIT-NO]
, [UNIT-DATE]
, [TYPE]
, [PA-DTL-TYPE-IND]
, [Transaction_Type]
, [PA-DTL-SVC-CD]
, [PA-DTL-CDM-DESCRIPTION]
, [PA-DTL-CPT-CD]
, [CPT from CDM]
, [Adjusted CPT Code]
, [PA-DTL-REV-CD]
, [Rev Code from CDM]
, [Adjusted Rev Code]
, [PA-DTL-GL-NO]
, [CrAcctUnit]
, [ICR]
, [SUM OF TOT CHG]
, [SUM OF TOT PROF FEES]
, [Sum_of_Chargesand_Prof_Fees]
, [PER DIEM]
, [RCC_For_DSH]
, round(
    CASE
        WHEN [RCC_For_DSH] > 0 
            THEN ([RCC_For_DSH] * [Sum_of_Chargesand_Prof_Fees])
            ELSE ([PER DIEM] * [SUM TOT-CHG-QTY])
        END
        , 2
  ) AS 'Cost'
, [Classification_for_2016_DSH]
, [PA-MED-REC-NO]
, [SUM TOT-CHG-QTY]
     
into [2016_DSH_Costs]
 
FROM [DSH].[dbo].[temp_DSH_Costs2]