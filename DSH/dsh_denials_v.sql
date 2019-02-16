USE [DSH]
GO
 
/****** Object:  View [dbo].[DSH_Denials_V]    Script Date: 2/12/2019 7:23:35 PM ******/
SET ANSI_NULLS ON
GO
 
SET QUOTED_IDENTIFIER ON
GO
 
 
/****** Script for SelectTopNRows command from SSMS  ******/
CREATE VIEW [dbo].[DSH_Denials_V] as
 
SELECT [TYPE]
, [PA-DTL-GL-NO]
, [PA-DTL-SVC-CD]
, [PA-DTL-CDM-DESCRIPTION]
, SUM([TOT-CHG-QTY]) as 'Tot_Qty'
, SUM([TOT-CHARGES]) as 'Tot_Chgs'

FROM [DSH].[dbo].[2016 Allowances_For_DSH_Encounters]
 
WHERE LEFT([pa-dtl-svc-cd],5) IN (
    '21141','21142','21901','21905','23752','23754','29701','29705',
    '21143','21144','21145','21146','21147','21148','21810','22750',
    '23302','23303',--Rev Integrity Denial Codes
    '20375','20525','21130','21140','21742','21910','21915','22210',
    '2220','22626','22330','22636','23756','23840','24109','29101',
    '23750','29001','29101'
    )
 
GROUP BY [TYPE]
, [PA-DTL-GL-NO]
, [PA-DTL-SVC-CD]
, [PA-DTL-CDM-DESCRIPTION]

HAVING SUM([tot-charges]) <> '0'

-- ORDER BY [type],[pa-dtl-svc-cd]