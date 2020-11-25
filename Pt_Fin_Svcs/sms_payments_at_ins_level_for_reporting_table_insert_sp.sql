USE [SMS]
GO

/*
***********************************************************************
File: sms_payments_at_ins_level_for_reporting_table_insert_sp.sql

Input Parameters:
	none

Tables/Views:
	dbo.Payments_For_Reporting_Ins_Plan_Level_ALT_A
    dbo.Payments_For_Reporting_Ins_Plan_Level_ALT_B
    dbo.Payments_For_Reporting_Ins_Plan_Level_ALT_C
    dbo.Payments_For_Reporting_Ins_Plan_Level_ALT_D

Creates Table:
	dbo.Payments_For_Reporting_Ins_Plan_Level_ALT

Functions:
	none	

Author: Steven P Sanderson II, MPH

Purpose/Description
	Get payments at the insurance level, union all tables together and
    insert into reporting table.

    This must be run with the following as predecessors:
    1. c_sms_payments_at_ins_level_for_reporting_a_wrapper_sp
    2. c_sms_payments_at_ins_level_for_reporting_b_wrapper_sp
    3. c_sms_payments_at_ins_level_for_reporting_c_wrapper_sp
    4. c_sms_payments_at_ins_level_for_reporintg_d_wrapper_sp

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

CREATE PROCEDURE dbo.c_sms_payments_at_ins_level_for_reporting_table_insert_sp
AS
SET ANSI_NULLS ON
SET ANSI_WARNINGS ON
SET QUOTED_IDENTIFIER ON

BEGIN
	SET NOCOUNT ON;

	-- IF THE TABLE EXISTS THEN TRUNCATE IT, ELSE BUILD IT
	IF OBJECT_ID('dbo.Payments_For_Reporting_Ins_Plan_Level_ALT', 'U') IS NOT NULL
		TRUNCATE TABLE dbo.Payments_For_Reporting_Ins_Plan_Level_ALT
	ELSE
		CREATE TABLE dbo.[Payments_For_Reporting_Ins_Plan_Level_ALT] (
			[PK] INT IDENTITY(1, 1) PRIMARY KEY NOT NULL,
			[PA-PT-NO-WOSCD] VARCHAR(11) NOT NULL,
			[PA-PT-NO-SCD] CHAR(1) NOT NULL,
			[PA-CTL-PAA-XFER-DATE] DATETIME NULL,
			[PT-NO] VARCHAR(50) NOT NULL,
			[PA-UNIT-NO] DECIMAL(4, 0) NULL,
			[unit-date] DATETIME NULL,
			[PA-DTL-UNIT-DATE] DATETIME NULL,
			[TYPE] CHAR(3) NULL,
			[PA-DTL-TYPE-IND] CHAR(1) NULL,
			[PA-DTL-HOSP-SVC] VARCHAR(50) NOT NULL,
			[PA-DTL-INS-CO-CD] CHAR(1) NULL,
			[PA-DTL-INS-PLAN-NO] DECIMAL(3, 0) NULL,
			[PA-DTL-GL-NO] CHAR(3) NULL,
			[PA-DTL-SVC-CD] CHAR(9) NULL,
			[PA-DTL-CDM-DESCRIPTION] VARCHAR(50) NULL,
			[PA-UNIT-STS] CHAR(5) NULL,
			[1ST-PAID-DATE] DATETIME NULL,
			[TOT-PAYMENTS] MONEY NULL
			);

	INSERT INTO dbo.Payments_For_Reporting_Ins_Plan_Level_ALT
	SELECT [PA-PT-NO-WOSCD],
		[PA-PT-NO-SCD],
		[PA-CTL-PAA-XFER-DATE],
		[PT-NO],
		[PA-UNIT-NO],
		[unit-date],
		[PA-DTL-UNIT-DATE],
		[TYPE],
		[PA-DTL-TYPE-IND],
		[PA-DTL-HOSP-SVC],
		[PA-DTL-INS-CO-CD],
		[PA-DTL-INS-PLAN-NO],
		[PA-DTL-GL-NO],
		[PA-DTL-SVC-CD],
		[PA-DTL-CDM-DESCRIPTION],
		[PA-UNIT-STS],
		[1ST-PAID-DATE],
		[TOT-PAYMENTS]
	FROM dbo.Payments_For_Reporting_Ins_Plan_Level_ALT_A
	
	UNION
	
	SELECT [PA-PT-NO-WOSCD],
		[PA-PT-NO-SCD],
		[PA-CTL-PAA-XFER-DATE],
		[PT-NO],
		[PA-UNIT-NO],
		[unit-date],
		[PA-DTL-UNIT-DATE],
		[TYPE],
		[PA-DTL-TYPE-IND],
		[PA-DTL-HOSP-SVC],
		[PA-DTL-INS-CO-CD],
		[PA-DTL-INS-PLAN-NO],
		[PA-DTL-GL-NO],
		[PA-DTL-SVC-CD],
		[PA-DTL-CDM-DESCRIPTION],
		[PA-UNIT-STS],
		[1ST-PAID-DATE],
		[TOT-PAYMENTS]
	FROM dbo.Payments_For_Reporting_Ins_Plan_Level_ALT_B
	
	UNION
	
	SELECT [PA-PT-NO-WOSCD],
		[PA-PT-NO-SCD],
		[PA-CTL-PAA-XFER-DATE],
		[PT-NO],
		[PA-UNIT-NO],
		[unit-date],
		[PA-DTL-UNIT-DATE],
		[TYPE],
		[PA-DTL-TYPE-IND],
		[PA-DTL-HOSP-SVC],
		[PA-DTL-INS-CO-CD],
		[PA-DTL-INS-PLAN-NO],
		[PA-DTL-GL-NO],
		[PA-DTL-SVC-CD],
		[PA-DTL-CDM-DESCRIPTION],
		[PA-UNIT-STS],
		[1ST-PAID-DATE],
		[TOT-PAYMENTS]
	FROM dbo.Payments_For_REporting_Ins_Plan_Level_ALT_C
	
	UNION
	
	SELECT [PA-PT-NO-WOSCD],
		[PA-PT-NO-SCD],
		[PA-CTL-PAA-XFER-DATE],
		[PT-NO],
		[PA-UNIT-NO],
		[unit-date],
		[PA-DTL-UNIT-DATE],
		[TYPE],
		[PA-DTL-TYPE-IND],
		[PA-DTL-HOSP-SVC],
		[PA-DTL-INS-CO-CD],
		[PA-DTL-INS-PLAN-NO],
		[PA-DTL-GL-NO],
		[PA-DTL-SVC-CD],
		[PA-DTL-CDM-DESCRIPTION],
		[PA-UNIT-STS],
		[1ST-PAID-DATE],
		[TOT-PAYMENTS]
	FROM dbo.Payments_For_Reporting_Ins_Plan_Level_ALT_D
END;


