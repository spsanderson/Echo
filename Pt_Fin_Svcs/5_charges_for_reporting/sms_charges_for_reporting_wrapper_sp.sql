USE [SMS]
GO

/*
***********************************************************************
File: sms_charges_for_reporting_wrapper_sp.sql

Input Parameters:
	none

Tables/Views:
	none

Creates Table:
	none

Functions:
	none

Author: Steven P Sanderson II, MPH

Purpose/Description
	Wrapper stored procedure that runs dbo.c_sms_charges_for_reporting_sp

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

CREATE PROCEDURE dbo.c_sms_charges_for_reporting_wrapper_sp
AS

SET ANSI_NULLS ON
SET ANSI_WARNINGS ON

BEGIN

	EXECUTE dbo.c_sms_charges_for_reporting_sp

END