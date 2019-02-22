USE Echo_SBU_PA
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



/*
File Name:
    c_AR_Aged_sp.sql

Parameters:
    None

Tables/Views:
    [Echo_Archive].[dbo].[PatientDemographics] AS A
    [echo_archive].dbo.insuranceinformation

Functions:
    None

Table/View Creations:
    dbo.c_AR_Aged_Rpt_Tbl

Author:
    Steven P Sanderson II, MPH
    Manchu Technology Corp.
    spsanderson@gmail.com

Description/Purpose:
    Accounts Receivable - get open AR and age of account. Make a monthly snapshot

Date        Version        Description
----        ----        ----
2018-11-13    v1            Initial Creation
*/

CREATE PROCEDURE [dbo].[c_AR_Aged_sp] AS 

SET NOCOUNT ON;
SET ANSI_WARNINGS OFF;

BEGIN

    IF NOT EXISTS(
        SELECT TOP 1 *
        FROM SYSOBJECTS
        WHERE NAME = 'c_AR_Aged_Rpt_Tbl'
        AND xtype = 'U'
    )

    CREATE TABLE dbo.c_AR_Aged_Rpt_Tbl (
        PK INT IDENTITY(1, 1) PRIMARY KEY NOT NULL

    )
    
    SELECT A.[PA-MED-REC-NO]
    , A.[PA-PT-NAME] 
    , A.[PA-PT-NO-WOSCD]
    , A.[PA-PT-NO-SCD]
    , CAST(A.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(A.[PA-PT-NO-SCD] AS VARCHAR) AS [PTNO_NUM]
    , A.[PA-PT-NO-SCD-1]
    , A.[PA-BAL-ACCT-BAL]
    , A.[PA-BAL-PT-BAL]
    , A.[PA-BAL-TOT-CHG-AMT]
    , A.[PA-BAL-TOT-INS-BAL]
    , A.[PA-BAL-TOT-PT-PAY-AMT]
    , A.[PA-BAL-TOT-PT-ADJ-AMT]
    , A.[PA-HOSP-SVC]
    , A.[PA-ACCT-BD-XFR-DATE]
    , C.*
    , D.*
    , E.*
    , F.*

    FROM [Echo_Archive].[dbo].[PatientDemographics] AS A
    LEFT OUTER JOIN [echo_archive].dbo.insuranceinformation AS C
    ON a.[pa-pt-no-woscd] = c.[pa-pt-no-woscd]
        AND A.[PA-PT-NO-SCD] = C.[PA-PT-NO-SCD-1]
        AND c.[pa-ins-prty] = '1'
        AND a.[PA-CTL-PAA-XFER-DATE] = C.[PA-CTL-PAA-XFER-DATE]
        AND A.[PA-CTL-PAA-PREV-ACCT-TYPE] = C.[PA-CTL-PAA-PREV-ACCT-TYPE]
        AND A.[PA-ACCT-TYPE] = C.[PA-ACCT-TYPE]
        AND A.[PA-ACCT-SUB-TYPE] = C.[PA-ACCT-SUB-TYPE]
    LEFT OUTER JOIN [echo_archive].dbo.insuranceinformation AS D
    ON a.[pa-pt-no-woscd] = d.[pa-pt-no-woscd]
        AND A.[PA-PT-NO-SCD] = D.[PA-PT-NO-SCD-1]
        AND d.[pa-ins-prty] = '2'
        AND A.[PA-CTL-PAA-XFER-DATE] = D.[PA-CTL-PAA-XFER-DATE]
        AND A.[PA-CTL-PAA-PREV-ACCT-TYPE] = D.[PA-CTL-PAA-PREV-ACCT-TYPE]
        AND A.[PA-ACCT-TYPE] = D.[PA-ACCT-TYPE]
        AND A.[PA-ACCT-SUB-TYPE] = D.[PA-ACCT-SUB-TYPE]
    LEFT OUTER JOIN [echo_archive].dbo.insuranceinformation AS E
    ON a.[pa-pt-no-woscd] = e.[pa-pt-no-woscd]
        AND A.[PA-PT-NO-SCD] = E.[PA-PT-NO-SCD-1]
        AND e.[pa-ins-prty] = '3'
        AND A.[PA-CTL-PAA-XFER-DATE] = E.[PA-CTL-PAA-XFER-DATE]
        AND A.[PA-CTL-PAA-PREV-ACCT-TYPE] = E.[PA-CTL-PAA-PREV-ACCT-TYPE]
        AND A.[PA-ACCT-TYPE] = E.[PA-ACCT-TYPE]
        AND A.[PA-ACCT-SUB-TYPE] = E.[PA-ACCT-SUB-TYPE]
    LEFT OUTER JOIN [echo_archive].dbo.insuranceinformation AS F
    ON a.[pa-pt-no-woscd] = f.[pa-pt-no-woscd]
        AND A.[PA-PT-NO-SCD] = F.[PA-PT-NO-SCD-1]
        AND f.[pa-ins-prty] = '4'
        AND A.[PA-CTL-PAA-XFER-DATE] = F.[PA-CTL-PAA-XFER-DATE]
        AND A.[PA-CTL-PAA-PREV-ACCT-TYPE] = F.[PA-CTL-PAA-PREV-ACCT-TYPE]
        AND A.[PA-ACCT-TYPE] = F.[PA-ACCT-TYPE]
        AND A.[PA-ACCT-SUB-TYPE] = F.[PA-ACCT-SUB-TYPE]

    --WHERE A.[PA-PT-NO-WOSCD] = '289299'

    ORDER BY A.[PA-REC-CREATE-DATE] DESC

END

--ELSE BEGIN

--END
;