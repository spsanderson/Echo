USE [SMS]
GO

/*
***********************************************************************
File: sms_ptacct_v_encounters_for_reporting_SSI_Primary_Claim_Release_Date_wrapper_sp.sql

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

CREATE PROCEDURE dbo.c_sms_ptacct_v_encounters_for_reporting_SSI_Primary_Claim_Release_Date_wrapper_sp
AS

SET ANSI_NULLS ON
SET ANSI_WARNINGS ON

BEGIN

	EXECUTE dbo.c_sms_ptacct_v_encounters_for_reporting_SSI_Primary_Claim_Release_Date_sp

END