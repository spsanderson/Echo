USE [SMS]
GO

/*
***********************************************************************
File: sms_ptacct_v_encounters_for_reporting_custom_insurance_sm_3_nonunit_wrapper_sp.sql

Input Parameters:
	None

Tables/Views:
	[SMS].dbo.[CUSTOM_INSURANCE_SM_ALT]

Creates Table:
	dbo.CUSTOM_INSURANCE_SM_3_NonUnit

Functions:
	none	

Author: Steven P Sanderson II, MPH

Purpose/Description
    Run in Batch 1
	Create patient account view dbo.CUSTOM_INSURANCE_SM_3_NonUnit

Revision History:
Date		Version		Description
----		----		----
2020-12-14	v1			Initial Creation
***********************************************************************
*/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE dbo.c_sms_ptacct_v_encounters_for_reporting_custom_insurance_sm_3_nonunit_wrapper_sp
AS

SET ANSI_NULLS ON
SET ANSI_WARNINGS ON

BEGIN

	EXECUTE dbo.c_sms_ptacct_v_encounters_for_reporting_custom_insurance_sm_3_nonunit_sp

END