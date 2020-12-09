USE [SMS]
GO

/*
***********************************************************************
File: sms_ptacct_v_encounters_for_reporting_SSI_Primary_Claim_Release_Date_sp.sql

Input Parameters:
	None

Tables/Views:
	dbo.[Encounters_For_Reporting_NonUnit]
    [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Active].dbo.[AccountComments]

Creates Table:
	dbo.SSI_Primary_Claim_Release_Date

Functions:
	none	

Author: Steven P Sanderson II, MPH

Purpose/Description
    Run in Batch 2
	Create patient account view dbo.SSI_Primary_Claim_Release_Date

Revision History:
Date		Version		Description
----		----		----
2020-12-08	v1			Initial Creation
***********************************************************************
*/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE dbo.c_sms_ptacct_v_encounters_for_reporting_SSI_Primary_Claim_Release_Date_sp
AS
SET ANSI_NULLS ON
SET ANSI_WARNINGS ON
SET QUOTED_IDENTIFIER ON

BEGIN
	SET NOCOUNT ON;

	IF OBJECT_ID('dbo.SSI_Primary_Claim_Release_Date', 'U') IS NOT NULL
		TRUNCATE TABLE dbo.SSI_Primary_Claim_Release_Date
	ELSE
		CREATE TABLE dbo.SSI_Primary_Claim_Release_Date (
			[PK] INT IDENTITY(1, 1) PRIMARY KEY NOT NULL,
			[Pt_No] VARCHAR(14) NOT NULL,
			[PA_Ctl_PAA_Xfer_Date] DATETIME NULL,
			[SSI_Last_Ins_Bill_Date] DATETIME NULL,
			[Rank] VARCHAR(4) NULL
			);

	INSERT INTO dbo.[#SSI_Primary_Claim_Release_Date] (
		[Pt_No],
		[PA_Ctl_PAA_Xfer_Date],
		[SSI_Last_Ins_Bill_Date],
		[Rank]
		)
	SELECT a.[Pt_No],
		a.[PA-CTL-PAA-XFER-DATE],
		b.[pa-smart-date] AS 'SSI_Last_Ins_Bill_Date',
		RANK() OVER (
			PARTITION BY b.[pa-pt-no-woscd] ORDER BY b.[pa-smart-date] DESC
			) AS 'Rank'
	FROM dbo.[#Encounters_For_Reporting_NonUnit] a
	LEFT OUTER JOIN [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Active].dbo.[AccountComments] b ON a.[pa-pt-no-woscd] = b.[pa-pt-no-woscd]
		AND a.[PA-CTL-PAA-XFER-DATE] = b.[pa-ctl-paa-xfer-date]
	WHERE RIGHT(RTRIM(b.[pa-smart-comment]), 3) IN ('PEH', 'PLH')
	
	UNION
	
	SELECT a.[Pt_No],
		a.[PA-CTL-PAA-XFER-DATE],
		b.[pa-smart-date] AS 'SSI_Last_Ins_Bill_Date',
		RANK() OVER (
			PARTITION BY b.[pa-pt-no-woscd] ORDER BY b.[pa-smart-date] DESC
			) AS 'Rank'
	FROM dbo.[#Encounters_For_Reporting_NonUnit] a
	LEFT OUTER JOIN [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Archive].dbo.[AccountComments] b ON a.[pa-pt-no-woscd] = b.[pa-pt-no-woscd]
		AND a.[PA-CTL-PAA-XFER-DATE] = b.[pa-ctl-paa-xfer-date]
	WHERE RIGHT(RTRIM(b.[pa-smart-comment]), 3) IN ('PEH', 'PLH')
END
GO








