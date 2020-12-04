USE [SMS]
GO

/*
***********************************************************************
File: sms_ptacct_v_encounters_for_reporting_open_unit_sp.sql

Input Parameters:
	None

Tables/Views:
	dbo.ERS_Denials
	dbo.Encounters_For_Reporting

Creates Table:
	dbo.encounters_for_reporting_open_unit

Functions:
	none	

Author: Steven P Sanderson II, MPH

Purpose/Description
	Create patient account view dbo.encounters_for_reporting_open_unit

Revision History:
Date		Version		Description
----		----		----
2020-12-03	v1			Initial Creation
***********************************************************************
*/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE dbo.c_sms_ptacct_v_encounters_for_reporting_open_unit_sp
AS
SET ANSI_NULLS ON
SET ANSI_WARNINGS ON
SET QUOTED_IDENTIFIER ON

BEGIN
	SET NOCOUNT ON;

	-- Unit 0 (Open Unit Accounts)
    IF OBJECT_ID('dbo.encounters_for_reporting_open_unit', 'U') IS NOT NULL
		TRUNCATE TABLE dbo.encounters_for_reporting_open_unit
	ELSE
		CREATE TABLE dbo.encounters_for_reporting_open_unit (
			[PK] INT IDENTITY(1, 1) PRIMARY KEY NOT NULL,
			[PA-PT-NO-WOSCD] VARCHAR(100),
			[PA-PT-NO-SCD] VARCHAR(100),
			[PT_NO] VARCHAR(100),
			[PA-UNIT-STS] VARCHAR(100),
			[FILE_TYPE] VARCHAR,
			[PA-CTL-PAA-XFER-DATE] SMALLDATETIME,
			[PA-UNIT-NO] VARCHAR(100),
			[PA-MED-REC-NO] VARCHAR(100),
			[PA-PT-NAME] VARCHAR(100),
			[ADMIT_DATE] SMALLDATETIME,
			[DSCH_DATE] SMALLDATETIME,
			[PA-UNIT-DATE] SMALLDATETIME,
			[START_UNIT_DATE] SMALLDATETIME,
			[END_UNIT_DATE] SMALLDATETIME,
			[PA-ACCT-TYPE] VARCHAR(100),
			[1ST_BL_DATE] SMALLDATETIME,
			[BALANCE] MONEY,
			[PT_BALANCE] MONEY,
			[TOT_CHGS] MONEY,
			[PA-BAL-TOT-PT-PAY-AMT] MONEY,
			[PTACCT_TYPE] VARCHAR(100),
			[PA-FC] VARCHAR(100),
			[FC_DESCRIPTION] VARCHAR(100),
			[PA-HOSP-SVC] VARCHAR(100),
			[PA-ACCT-SUB-TYPE] VARCHAR(100),
			[PA-PT-REPRESENTATIVE] VARCHAR(100),
			[PA-PAY-SCALE] VARCHAR(100),
			[PA-CR-RATING] VARCHAR(100),
			[PA-RESP-CD] VARCHAR(100),
			[DENIAL-IND] VARCHAR(100)
			)

	INSERT INTO dbo.encounters_for_reporting_open_unit (
		[PA-PT-NO-WOSCD],
		[PA-PT-NO-SCD],
		[PT_NO],
		[PA-UNIT-STS],
		[FILE_TYPE],
		[PA-CTL-PAA-XFER-DATE],
		[PA-UNIT-NO],
		[PA-MED-REC-NO],
		[PA-PT-NAME],
		[ADMIT_DATE],
		[DSCH_DATE],
		[PA-UNIT-DATE],
		[START_UNIT_DATE],
		[END_UNIT_DATE],
		[PA-ACCT-TYPE],
		[1ST_BL_DATE],
		[BALANCE],
		[PT_BALANCE],
		[TOT_CHGS],
		[PA-BAL-TOT-PT-PAY-AMT],
		[PTACCT_TYPE],
		[PA-FC],
		[FC_DESCRIPTION],
		[PA-HOSP-SVC],
		[PA-ACCT-SUB-TYPE],
		[PA-PT-REPRESENTATIVE],
		[PA-PAY-SCALE],
		[PA-CR-RATING],
		[PA-RESP-CD],
		[DENIAL-IND]
		)
	SELECT A.[PA-PT-NO-WOSCD],
		A.[PA-PT-NO-SCD],
		A.[PT_NO],
		A.[PA-UNIT-STS],
		A.[FILE_TYPE],
		A.[PA-CTL-PAA-XFER-DATE],
		A.[PA-UNIT-NO],
		A.[PA-MED-REC-NO],
		A.[PA-PT-NAME],
		A.[ADMIT_DATE],
		A.[DSCH_DATE],
		A.[PA-UNIT-DATE],
		A.[START_UNIT_DATE],
		A.[END_UNIT_DATE],
		A.[PA-ACCT-TYPE],
		A.[1ST_BL_DATE],
		A.[BALANCE],
		A.[PT_BALANCE],
		A.[TOT_CHGS],
		A.[PA-BAL-TOT-PT-PAY-AMT],
		A.[PTACCT_TYPE],
		A.[PA-FC],
		A.[FC_DESCRIPTION],
		A.[PA-HOSP-SVC],
		A.[PA-ACCT-SUB-TYPE],
		A.[PA-PT-REPRESENTATIVE],
		A.[PA-PAY-SCALE],
		A.[PA-CR-RATING],
		A.[PA-RESP-CD],
		[DENIAL-IND] = (
			SELECT DISTINCT ZZZ.[DENIAL_IND]
			FROM DBO.ERS_Denials AS ZZZ
			WHERE A.PT_NO = ZZZ.PT_NO
			)
	FROM [SMS].dbo.[Encounters_For_Reporting] AS A
	WHERE [PA-UNIT-NO] = '0'
END
GO


