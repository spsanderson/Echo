USE [SMS]
GO

/*
***********************************************************************
File: sms_payments_at_ins_level_for_reporting_table_insert_wrapper_sp.sql

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
	Wrapper stored procedure that runs c_sms_payments_at_ins_level_for_reporting_table_insert_sp

Revision History:
Date		Version		Description
----		----		----
2020-11-24	v1			Initial Creation
***********************************************************************
*/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[c_sms_payments_at_ins_level_for_reporting_table_insert_wrapper_sp]
AS

SET ANSI_NULLS ON
SET ANSI_WARNINGS ON

BEGIN

	EXECUTE dbo.c_sms_payments_at_ins_level_for_reporting_table_insert_sp 

END