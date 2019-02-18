USE [Echo_SBU_PA]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

SET NOCOUNT ON;
SET ANSI_WARNINGS OFF;

/*
File Name:
	c_AR_Aged_sp.sql

Parameters:
	None

Tables/Views:

Functions:

Table/View Creations:
	dbo.c_AR_Aged_Rpt_Tbl

Author:
	Steven P Sanderson II, MPH
	Manchu Technology Corp.
	spsanderson@gmail.com

Description/Purpose:
Accounts Receivable - get open AR and age of account. Make a monthly snapshot

Date		Version		Description
----		----		----
2018-11-13	v1			Initial Creation
*/

CREATE PROCEDURE dbo.c_AR_Aged_sp
AS

IF NOT EXISTS(
	SELECT TOP 1 *
	FROM SYSOBJECTS
	WHERE NAME = 'c_AR_Aged_Rpt_Tbl'
	AND xtype = 'U'
)

BEGIN

SELECT TOP 1 a.*
, c.*
, a.[PA-PT-NO-WOSCD]
, a.[PA-CTL-PAA-XFER-DATE]
FROM [Echo_Archive].[dbo].[PatientDemographics] AS A
LEFT OUTER JOIN [Echo_Archive].dbo.unitizedaccounts AS b
ON a.[pa-pt-no-woscd] = b.[pa-pt-no-woscd] 
	AND a.[pa-pt-no-scd] = b.[pa-pt-no-scd-1]
LEFT OUTER JOIN [Echo_Active].dbo.insuranceinformation AS c
ON a.[pa-pt-no-woscd] = c.[pa-pt-no-woscd] 
	AND c.[pa-ins-prty] = '1'
	AND a.[PA-CTL-PAA-XFER-DATE] = C.[PA-CTL-PAA-XFER-DATE]
	AND A.[PA-CTL-PAA-PREV-ACCT-TYPE] = C.[PA-CTL-PAA-PREV-ACCT-TYPE]
LEFT OUTER JOIN [Echo_Active].dbo.insuranceinformation AS d
ON a.[pa-pt-no-woscd] = d.[pa-pt-no-woscd] 
	AND d.[pa-ins-prty] = '2'
	AND A.[PA-CTL-PAA-XFER-DATE] = D.[PA-CTL-PAA-XFER-DATE]
	AND A.[PA-CTL-PAA-PREV-ACCT-TYPE] = D.[PA-CTL-PAA-PREV-ACCT-TYPE]
LEFT OUTER JOIN [Echo_Active].dbo.insuranceinformation AS e
ON a.[pa-pt-no-woscd] = e.[pa-pt-no-woscd] 
	AND e.[pa-ins-prty] = '3'
	AND A.[PA-CTL-PAA-XFER-DATE] = E.[PA-CTL-PAA-XFER-DATE]
	AND A.[PA-CTL-PAA-PREV-ACCT-TYPE] = E.[PA-CTL-PAA-PREV-ACCT-TYPE]
LEFT OUTER JOIN [Echo_Active].dbo.insuranceinformation AS f
ON a.[pa-pt-no-woscd] = f.[pa-pt-no-woscd] 
	AND f.[pa-ins-prty] = '4'
	AND A.[PA-CTL-PAA-XFER-DATE] = F.[PA-CTL-PAA-XFER-DATE]
	AND A.[PA-CTL-PAA-PREV-ACCT-TYPE] = F.[PA-CTL-PAA-PREV-ACCT-TYPE]

ORDER BY A.[PA-REC-CREATE-DATE] DESC

END

ELSE BEGIN

END