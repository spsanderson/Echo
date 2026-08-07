USE [SMS]
GO

--/****** Object:  StoredProcedure [dbo].[sp_Instamed_Yesterdays_Balances]    Script Date: 8/17/2020 2:51:57 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





---- =============================================
---- Author:		<Author:  Mathesie, Scott>
---- Create date: <August 2, 2020>
---- Description:	<Creates a Table Containing Patient Balances To Be Compared to A Table of Balances Generated Next Day In Order to Compare for Changed Balances to send to Instamed the Patient Online Payment Portal
---- =============================================



----CREATE PROCEDURE sp_Instamed_Yesterdays_Balances_1


----AS



/*Create Table Yesterdays_Pt_Balances_1*/


IF OBJECT_ID('SMS.dbo.Yesterdays_Pt_Balances_1', 'U') IS NOT NULL
  DROP TABLE [SMS].dbo.[Yesterdays_Pt_Balances_1] 
GO
;

CREATE TABLE [SMS].dbo.[Yesterdays_Pt_Balances_1]
(
[PA-PT-NO-WOSCD] DECIMAL(11,0) NOT NULL,
[PA-PT-NO-SCD] CHAR(1) NOT NULL,
[Pt_No] CHAR(12) NOT NULL,
[PA-PT-BAL] MONEY NULL

)

INSERT INTO [SMS].DBO.[Yesterdays_Pt_Balances_1]([PA-PT-NO-WOSCD],[PA-PT-NO-SCD],[Pt_No],[pa-pt-bal])

SELECT [PA-PT-NO-WOSCD],
[pa-pt-no-scd-1],
cast([pa-pt-no-woscd] as varchar) + CAST([pa-pt-no-scd-1] as varchar) as 'Pt_No',
isnull([pa-bal-pt-bal],0) as 'pa-pt-bal'


FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Active].dbo.[PatientDemographics] 

WHERE [pa-dunning-msg-lvl] >= '1'
AND [pa-bal-pt-bal] >= '0'
--and [pa-pt-no-woscd] = '502559'--8
--= '1005175193'--4




