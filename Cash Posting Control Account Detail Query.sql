/****** Script for SelectTopNRows command from SSMS  ******/
SELECT CAST([PA-PT-NO-WOSCD] as varchar) + CAST([PA-PT-NO-SCD-1] as varchar) as 'Pt_No'
      ,[PA-REC-TP-IND]
      ,[PA-DTL-DATE]
      ,CAST([PA-DTL-SVC-CD-WOSCD] as varchar) + CAST([PA-DTL-SVC-CD-SCD] as varchar) as 'Payment_Code'
      ,[PA-DTL-POST-DATE]
      ,[PA-DTL-BATCH-NO]
      ,[PA-DTL-BATCH-SEQ-NO]
      ,[PA-DTL-CHG-AMT]
      ,[PA-DTL-INS-CO-CD]
      ,[PA-DTL-INS-PLAN-NO]
      ,[PA-DTL-TYPE-IND]
      ,[PA-DTL-DESCRIPTION]
      ,[PA-DTL-TECHNICAL-DESC]
      ,[PA-DTL-GL-NO]
      ,[PA-DTL-SEG-CREATE-DATE]
      ,[PA-DTL-CDM-DESCRIPTION]
     
      ,[PA-DTL-OVER-DX-CODING-SYS-IND]
  FROM [Echo_Active].[dbo].[DetailInformation]

   WHERE LEFT([pa-pt-no-woscd],5)='99999'
   AND [pa-pt-no-woscd]<>'99999001301'

   ORDER BY [pa-dtl-post-date], [pa-dtl-batch-no],[pa-dtl-batch-seq-no]