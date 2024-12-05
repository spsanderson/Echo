/*
***********************************************************************
File: c_pay_scale_sp.sql

Input Parameters:
	None

Tables/Views:
	[ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].echo_active.dbo.accountcomments

Creates Table/View:
	#pay_scale_tbl
	#ps_cmnts_tbl
	SMS.dbo.c_pay_scale_tbl

Functions:
	None

Author: Steven P. Sanderson II, MPH

Department: Patient Financial Services

Purpose/Description
	Get the payscales applied to a patient's account and the dates they were applied.

Revision History:
Date		Version		Description
----		----		----
2024-11-22	v1			Initial Creation
***********************************************************************
*/

-- Create a new stored procedure called 'c_pay_scale_sp' in schema 'dbo'
-- Drop the stored procedure if it already exists
IF EXISTS (
SELECT *
	FROM INFORMATION_SCHEMA.ROUTINES
	WHERE SPECIFIC_SCHEMA = N'dbo'
	AND SPECIFIC_NAME = N'c_pay_scale_sp'
)
DROP PROCEDURE dbo.c_pay_scale_sp
GO
-- Create the stored procedure in the specified schema
CREATE PROCEDURE dbo.c_pay_scale_sp
AS
	-- SET NOCOUNT ON added to prevent extra result sets from interfering with SELECT statements.
	SET NOCOUNT ON;
	SET ANSI_WARNINGS OFF;

	IF NOT EXISTS (
		SELECT TOP 1 *
		FROM SYSOBJECTS
		WHERE NAME = 'c_pay_scale_tbl'
		AND XTYPE = 'U'
		)

	BEGIN
		-- SET NOCOUNT ON added to prevent extra result sets from interfering with SELECT statements.
		SET NOCOUNT ON;
		-- Create a temporary table to hold the pay scale numbers and their corresponding pay scale applied
		DROP TABLE IF EXISTS #pay_scale_tbl;
		CREATE TABLE #pay_scale_tbl (
			pay_scale_number INT,
			pay_scale_applied VARCHAR(10)
		);
		-- Create table sms.dbo.c_pay_scale_tbl
		-- Create a new table called 'c_pay_scale_tbl' in schema 'dbo'
		-- Drop the table if it already exists
		IF OBJECT_ID('SMS.dbo.c_pay_scale_tbl', 'U') IS NULL
		-- Create the table in the specified schema
		CREATE TABLE SMS.dbo.c_pay_scale_tbl
		(
			c_pay_scale_tblId INT NOT NULL PRIMARY KEY, -- primary key column
			pt_no VARCHAR(20) NOT NULL, -- patient number
			svc_date DATE, -- service date
			post_date DATE, -- post date
			smart_comment VARCHAR(255), -- smart comment
			pay_scale_applied VARCHAR(10), -- pay scale applied
			unit_number INT, -- unit number
			unit_date DATE, -- unit date
			event_number INT, -- event number
			next_svc_date DATE, -- next service date
			next_post_date DATE, -- next post date
			next_smart_comment VARCHAR(255), -- next smart comment
			next_pay_scale_applied VARCHAR(10), -- next pay scale applied
			next_event_number INT, -- next event number
			next_unit_number INT, -- next unit number
			next_unit_date DATE -- next unit date
		);

		INSERT INTO #pay_scale_tbl (pay_scale_number, pay_scale_applied)
		VALUES
			(12820, 'PS N'),
			(12901, 'PS #'),
			(13188, 'PS D'),
			(13230, 'PS D UNIT'),
			(13283, 'PS # UNITS'),
			(13424, 'PS I'),
			(13713, 'PS F'),
			(13752, 'PS G UNIT'),
			(14119, 'PS S'),
			(14146, 'PS E'),
			(14350, 'PS U'),
			(14416, 'PS Q'),
			(14423, 'PS B'),
			(14458, 'PS V'),
			(14462, 'PS T'),
			(14474, 'PS 2'),
			(14475, 'PS 3'),
			(14852, 'PS 9'),
			(15031, 'PS J UNIT'),
			(15172, 'PS Y'),
			(15805, 'PS P UNIT'),
			(15806, 'PS V UNIT');

		-- get the active pay scale comments
		DROP TABLE IF EXISTS #ps_cmnts_tbl;
		SELECT [pt_no] = CAST(CMNTS.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(CMNTS.[PA-PT-NO-SCD-1] AS VARCHAR),
			[svc_date] = CAST(CMNTS.[pa-smart-seg-create-date] AS DATE),
			[post_date] = CAST(CMNTS.[PA-SMART-DATE] AS DATE),
			[smart_comment] = CMNTS.[PA-SMART-COMMENT],
			[event_number] = ROW_NUMBER() OVER (
				PARTITION BY CAST(CMNTS.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(CMNTS.[PA-PT-NO-SCD-1] AS VARCHAR)
				ORDER BY CMNTS.[PA-SMART-DATE]
				)
		INTO #ps_cmnts_tbl
		FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].echo_active.dbo.accountcomments AS CMNTS
		WHERE (
			(
				CMNTS.[pa-smart-comment] LIKE 'PAY SCALE%[0-9][0-9][0-9][0-9][0-9]'
				AND RIGHT(CMNTS.[pa-smart-comment], 5) IN (SELECT pay_scale_number FROM #pay_scale_tbl)
			) 
			OR (
				CMNTS.[PA-SMART-COMMENT] LIKE 'PAY SCALE%[A-Z]'
			)
		)

		-- union archived pay scale comments
		UNION ALL

		SELECT [pt_no] = CAST(CMNTS.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(CMNTS.[PA-PT-NO-SCD-1] AS VARCHAR),
			[svc_date] = CAST(CMNTS.[pa-smart-seg-create-date] AS DATE),
			[post_date] = CAST(CMNTS.[PA-SMART-DATE] AS DATE),
			[smart_comment] = CMNTS.[PA-SMART-COMMENT],
			[event_number] = ROW_NUMBER() OVER (
				PARTITION BY CAST(CMNTS.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(CMNTS.[PA-PT-NO-SCD-1] AS VARCHAR)
				ORDER BY CMNTS.[PA-SMART-DATE]
				)
		FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].echo_archive.dbo.accountcomments AS CMNTS
		WHERE (
			(
				CMNTS.[pa-smart-comment] LIKE 'PAY SCALE%[0-9][0-9][0-9][0-9][0-9]'
				AND RIGHT(CMNTS.[pa-smart-comment], 5) IN (SELECT pay_scale_number FROM #pay_scale_tbl)
			) 
			OR (
				CMNTS.[PA-SMART-COMMENT] LIKE 'PAY SCALE%[A-Z]'
			)
		);

		-- get the next pay scale comment
		INSERT INTO SMS.dbo.c_pay_scale_tbl (pt_no, svc_date, post_date, smart_comment, pay_scale_applied, unit_number, unit_date, event_number, 
											next_svc_date, next_post_date, next_smart_comment, next_pay_scale_applied, next_unit_number, next_unit_date, 
											next_event_number)
		SELECT CMNTS.pt_no,
			CMNTS.svc_date,
			CMNTS.post_date,
			CMNTS.smart_comment,
			[pay_scale_applied] = CASE
				WHEN TRY_CAST(RIGHT(CMNTS.smart_comment, 5) AS INT) IS NOT NULL
					THEN (
						SELECT z.pay_scale_applied
						FROM #pay_scale_tbl AS Z
						WHERE Z.pay_scale_number = CAST(RIGHT(CMNTS.smart_comment, 5) AS INT)
					)
				ELSE 'PS # - Staff'
				END,
			[unit_number] = CASE
				WHEN PATINDEX('%UNIT [0-9][0-9]%', CMNTS.smart_comment) > 0
					THEN TRY_CAST(RIGHT(SUBSTRING(CMNTS.smart_comment, PATINDEX('%UNIT [0-9][0-9]%', CMNTS.smart_comment), 7), 2) AS INT)
				ELSE NULL
				END,
			[unit_date] = CASE 
				WHEN PATINDEX('%[0-9][0-9]/[0-9][0-9]/[0-9][0-9]%', CMNTS.smart_comment) > 0 THEN 
					TRY_CAST(SUBSTRING(
						CMNTS.smart_comment,
						PATINDEX('%[0-9][0-9]/[0-9][0-9]/[0-9][0-9]%', CMNTS.smart_comment), 
						8
					) AS DATE)
				ELSE NULL
				END,
			CMNTS.event_number,
			[next_svc_date] = NEXT_CMNT.svc_date,
			[next_post_date] = NEXT_CMNT.post_date,
			[next_smart_comment] = NEXT_CMNT.smart_comment,
			[next_pay_scale_applied] = CASE
				WHEN TRY_CAST(RIGHT(NEXT_CMNT.smart_comment, 5) AS INT) IS NOT NULL
					AND NEXT_CMNT.svc_date IS NOT NULL 
					THEN (
						SELECT z.pay_scale_applied
						FROM #pay_scale_tbl AS Z
						WHERE Z.pay_scale_number = CAST(RIGHT(NEXT_CMNT.smart_comment, 5) AS INT)
					)
				WHEN NEXT_CMNT.smart_comment IS NULL
					THEN NULL
				ELSE 'PS # - Staff'
				END,
			[next_unit_number] = CASE
				WHEN PATINDEX('%UNIT [0-9][0-9]%', NEXT_CMNT.smart_comment) > 0
					THEN TRY_CAST(RIGHT(SUBSTRING(NEXT_CMNT.smart_comment, PATINDEX('%UNIT [0-9][0-9]%', NEXT_CMNT.smart_comment), 7), 2) AS INT)
				ELSE NULL
				END,
			[next_unit_date] = CASE 
				WHEN PATINDEX('%[0-9][0-9]/[0-9][0-9]/[0-9][0-9]%', NEXT_CMNT.smart_comment) > 0 THEN 
					TRY_CAST(SUBSTRING(
						NEXT_CMNT.smart_comment,
						PATINDEX('%[0-9][0-9]/[0-9][0-9]/[0-9][0-9]%', NEXT_CMNT.smart_comment), 
						8
					) AS DATE)
				ELSE NULL
				END,
			[next_event_number] = NEXT_CMNT.event_number
		FROM #ps_cmnts_tbl AS CMNTS
		LEFT JOIN #ps_cmnts_tbl AS NEXT_CMNT ON CMNTS.pt_no = NEXT_CMNT.pt_no
			AND (
				CMNTS.event_number + 1 = NEXT_CMNT.event_number
				OR NEXT_CMNT.event_number IS NULL
			)
		ORDER BY CMNTS.pt_no, CMNTS.event_number;
	END
	ELSE BEGIN

		DROP TABLE IF EXISTS #pay_scale_tbl_b;
		CREATE TABLE #pay_scale_tbl_b (
			pay_scale_number INT,
			pay_scale_applied VARCHAR(10)
		);

		INSERT INTO #pay_scale_tbl_b (pay_scale_number, pay_scale_applied)
		VALUES
			(12820, 'PS N'),
			(12901, 'PS #'),
			(13188, 'PS D'),
			(13230, 'PS D UNIT'),
			(13283, 'PS # UNITS'),
			(13424, 'PS I'),
			(13713, 'PS F'),
			(13752, 'PS G UNIT'),
			(14119, 'PS S'),
			(14146, 'PS E'),
			(14350, 'PS U'),
			(14416, 'PS Q'),
			(14423, 'PS B'),
			(14458, 'PS V'),
			(14462, 'PS T'),
			(14474, 'PS 2'),
			(14475, 'PS 3'),
			(14852, 'PS 9'),
			(15031, 'PS J UNIT'),
			(15172, 'PS Y'),
			(15805, 'PS P UNIT'),
			(15806, 'PS V UNIT');
		
		DROP TABLE IF EXISTS #ps_cmnts_tbl_b;
		SELECT [pt_no] = CAST(CMNTS.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(CMNTS.[PA-PT-NO-SCD-1] AS VARCHAR),
			[svc_date] = CAST(CMNTS.[pa-smart-seg-create-date] AS DATE),
			[post_date] = CAST(CMNTS.[PA-SMART-DATE] AS DATE),
			[smart_comment] = CMNTS.[PA-SMART-COMMENT],
			[event_number] = ROW_NUMBER() OVER (
				PARTITION BY CAST(CMNTS.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(CMNTS.[PA-PT-NO-SCD-1] AS VARCHAR)
				ORDER BY CMNTS.[PA-SMART-DATE]
				)
		INTO #ps_cmnts_tbl_b
		FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].echo_active.dbo.accountcomments AS CMNTS
		WHERE (
			(
				CMNTS.[pa-smart-comment] LIKE 'PAY SCALE%[0-9][0-9][0-9][0-9][0-9]'
				AND RIGHT(CMNTS.[pa-smart-comment], 5) IN (SELECT pay_scale_number FROM #pay_scale_tbl_b)
			) 
			OR (
				CMNTS.[PA-SMART-COMMENT] LIKE 'PAY SCALE%[A-Z]'
			)
		)

		-- union archived pay scale comments
		UNION ALL

		SELECT [pt_no] = CAST(CMNTS.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(CMNTS.[PA-PT-NO-SCD-1] AS VARCHAR),
			[svc_date] = CAST(CMNTS.[pa-smart-seg-create-date] AS DATE),
			[post_date] = CAST(CMNTS.[PA-SMART-DATE] AS DATE),
			[smart_comment] = CMNTS.[PA-SMART-COMMENT],
			[event_number] = ROW_NUMBER() OVER (
				PARTITION BY CAST(CMNTS.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(CMNTS.[PA-PT-NO-SCD-1] AS VARCHAR)
				ORDER BY CMNTS.[PA-SMART-DATE]
				)
		FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].echo_archive.dbo.accountcomments AS CMNTS
		WHERE (
			(
				CMNTS.[pa-smart-comment] LIKE 'PAY SCALE%[0-9][0-9][0-9][0-9][0-9]'
				AND RIGHT(CMNTS.[pa-smart-comment], 5) IN (SELECT pay_scale_number FROM #pay_scale_tbl_b)
			) 
			OR (
				CMNTS.[PA-SMART-COMMENT] LIKE 'PAY SCALE%[A-Z]'
			)
		);

		INSERT INTO SMS.dbo.c_pay_scale_tbl (pt_no, svc_date, post_date, smart_comment, pay_scale_applied, unit_number, unit_date, event_number, 
											next_svc_date, next_post_date, next_smart_comment, next_pay_scale_applied, next_unit_number, next_unit_date, 
											next_event_number)
		SELECT CMNTS.pt_no,
			CMNTS.svc_date,
			CMNTS.post_date,
			CMNTS.smart_comment,
			[pay_scale_applied] = CASE
				WHEN TRY_CAST(RIGHT(CMNTS.smart_comment, 5) AS INT) IS NOT NULL
					THEN (
						SELECT z.pay_scale_applied
						FROM #pay_scale_tbl AS Z
						WHERE Z.pay_scale_number = CAST(RIGHT(CMNTS.smart_comment, 5) AS INT)
					)
				ELSE 'PS # - Staff'
				END,
			[unit_number] = CASE
				WHEN PATINDEX('%UNIT [0-9][0-9]%', CMNTS.smart_comment) > 0
					THEN TRY_CAST(RIGHT(SUBSTRING(CMNTS.smart_comment, PATINDEX('%UNIT [0-9][0-9]%', CMNTS.smart_comment), 7), 2) AS INT)
				ELSE NULL
				END,
			[unit_date] = CASE 
				WHEN PATINDEX('%[0-9][0-9]/[0-9][0-9]/[0-9][0-9]%', CMNTS.smart_comment) > 0 THEN 
					TRY_CAST(SUBSTRING(
						CMNTS.smart_comment,
						PATINDEX('%[0-9][0-9]/[0-9][0-9]/[0-9][0-9]%', CMNTS.smart_comment), 
						8
					) AS DATE)
				ELSE NULL
				END,
			CMNTS.event_number,
			[next_svc_date] = NEXT_CMNT.svc_date,
			[next_post_date] = NEXT_CMNT.post_date,
			[next_smart_comment] = NEXT_CMNT.smart_comment,
			[next_pay_scale_applied] = CASE
				WHEN TRY_CAST(RIGHT(NEXT_CMNT.smart_comment, 5) AS INT) IS NOT NULL
					AND NEXT_CMNT.svc_date IS NOT NULL 
					THEN (
						SELECT z.pay_scale_applied
						FROM #pay_scale_tbl AS Z
						WHERE Z.pay_scale_number = CAST(RIGHT(NEXT_CMNT.smart_comment, 5) AS INT)
					)
				WHEN NEXT_CMNT.smart_comment IS NULL
					THEN NULL
				ELSE 'PS # - Staff'
				END,
			[next_unit_number] = CASE
				WHEN PATINDEX('%UNIT [0-9][0-9]%', NEXT_CMNT.smart_comment) > 0
					THEN TRY_CAST(RIGHT(SUBSTRING(NEXT_CMNT.smart_comment, PATINDEX('%UNIT [0-9][0-9]%', NEXT_CMNT.smart_comment), 7), 2) AS INT)
				ELSE NULL
				END,
			[next_unit_date] = CASE 
				WHEN PATINDEX('%[0-9][0-9]/[0-9][0-9]/[0-9][0-9]%', NEXT_CMNT.smart_comment) > 0 THEN 
					TRY_CAST(SUBSTRING(
						NEXT_CMNT.smart_comment,
						PATINDEX('%[0-9][0-9]/[0-9][0-9]/[0-9][0-9]%', NEXT_CMNT.smart_comment), 
						8
					) AS DATE)
				ELSE NULL
				END,
			[next_event_number] = NEXT_CMNT.event_number
		FROM #ps_cmnts_tbl_b AS CMNTS
		LEFT JOIN #ps_cmnts_tbl_b AS NEXT_CMNT ON CMNTS.pt_no = NEXT_CMNT.pt_no
			AND (
				CMNTS.event_number + 1 = NEXT_CMNT.event_number
				OR NEXT_CMNT.event_number IS NULL
			)
		ORDER BY CMNTS.pt_no, CMNTS.event_number;
	END
GO
-- example to execute the stored procedure we just created
--EXECUTE dbo.c_pay_scale_sp 1 /*value_for_param1*/, 2 /*value_for_param2*/
--GO
