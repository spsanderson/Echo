USE [SMS]
GO 

SET QUOTED_IDENTIFIER ON
GO  

CREATE PROCEDURE dbo.c_ip_service_line_sp
AS 

SET NOCOUNT ON;

/*
***********************************************************************
File: c_ip_service_line_sp.sql

Input Parameters:
	None

Tables/Views:
	sms.dbo.pt_accounting_reporting_alt
    sms.dbo.c_dx_cc_mapping_tbl
    sms.dbo.c_px_cc_mapping_tbl
    [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Active].[dbo].[ProcedureInformation]
    [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Archive].[dbo].[ProcedureInformation]

Creates Table/View:
	dbo.c_ip_service_line_tbl

Functions:
	NONE

Author: Steven P. Sanderson II, MPH

Department: Patient Financial Services

Purpose/Description
Creates a table that contains the service line for each patient account.

Revision History:
Date		Version		Description
----		----		----
2024-01-08	v1			Initial Creation
***********************************************************************
*/

IF NOT EXISTS (
		SELECT TOP 1 *
		FROM SYSOBJECTS
		WHERE name = 'c_ip_service_line_tbl'
			AND xtype = 'U'
		)
BEGIN
	CREATE TABLE dbo.c_ip_service_line_tbl (
		PT_NO VARCHAR(20) NOT NULL,
		discharge_dx VARCHAR(10) NULL,
		dx_cc_code VARCHAR(10) NULL,
		prim_px_cd VARCHAR(10) NULL,
		px_cc_code VARCHAR(10) NULL,
		service_line VARCHAR(50) NULL
		);

	INSERT INTO dbo.c_ip_service_line_tbl (
		PT_NO,
		discharge_dx,
		dx_cc_code,
		prim_px_cd,
		px_cc_code,
		service_line
		)
	SELECT A.PT_NO,
		REPLACE(A.[PA-DISCH-DX-CD], '.', '') AS [discharge_dx],
		DX_CC.CC_Code AS [dx_cc_code],
		COALESCE(REPLACE(ARP.[PA-PROC3-CD], '.', ''), REPLACE(AP.[PA-PROC3-CD], '.', '')) AS [prim_px_cd],
		PX_CC.CC_Code AS [px_cc_code],
		[service_line] = CASE 
			WHEN A.ap_drg_no IN ('896', '897')
				AND DX_CC.CC_Code = 'DX_660'
				THEN 'Alcohol Abuse' -- good
			WHEN A.ap_drg_no IN ('231', '232', '233', '234', '235', '236')
				THEN 'CABG' -- good
			WHEN A.ap_drg_no IN ('34', '35', '36', '37', '38', '39')
				AND PX_CC.CC_Code IN ('PX_51', 'PX_59')
				THEN 'Carotid Endarterectomy' -- good
			WHEN A.ap_drg_no IN ('602', '603')
				AND DX_CC.CC_Code IN ('DX_197')
				THEN 'Cellulitis' -- good
			WHEN --A.ap_drg_no IN ('286', '287', '313')
				-- edited 3/22/2016 sps due to new LIHN guidelines
				A.ap_drg_no IN ('313')
				AND DX_CC.CC_Code IN ('DX_102')
				THEN 'Chest Pain' -- good
			WHEN A.ap_drg_no IN ('291', '292', '293')
				AND DX_CC.CC_Code IN ('DX_108', 'DX_99')
				THEN 'CHF' -- good
			WHEN A.ap_drg_no IN ('190', '191', '192')
				AND DX_CC.CC_Code IN ('DX_127', 'DX_128')
				THEN 'COPD' -- good
			WHEN A.ap_drg_no IN ('765', '766')
				THEN 'C-Section' -- good
			WHEN A.ap_drg_no IN ('61', '62', '63', '64', '65', '66')
				THEN 'CVA' -- good
			WHEN A.ap_drg_no IN ('619', '620', '621')
				AND PX_CC.CC_Code IN ('PX_74')
				THEN 'Bariatric Surgery For Obesity' -- update this
			WHEN A.ap_drg_no IN ('377', ' 378', '379')
				THEN 'GI Hemorrhage' -- good
			WHEN A.ap_drg_no IN ('739', '740', '741', '742', '743')
				AND PX_CC.CC_Code IN ('PX_124')
				THEN 'Hysterectomy' -- good
			WHEN A.ap_drg_no IN ('469', '470')
				AND PX_CC.CC_Code IN ('PX_152', 'PX_153')
				-- Exclusions
				AND DX_CC.CC_Code NOT IN ('DX_237', 'DX_238', 'DX_230', 'DX_229', 'DX_226', 'DX_225', 'DX_231', 'DX_207')
				THEN 'Joint Replacement' -- good
			WHEN A.ap_drg_no IN ('417', '418', '419')
				THEN 'Laparoscopic Cholecystectomy' -- good
			WHEN A.ap_drg_no IN ('582', '583', '584', '585')
				AND PX_CC.CC_Code IN ('PX_167')
				THEN 'Mastectomy' -- good
			WHEN A.ap_drg_no IN ('280', '281', '282', '283', '284', '285')
				THEN 'MI' -- good
			WHEN A.ap_drg_no IN ('795')
				AND DX_CC.CC_Code IN ('DX_218')
				THEN 'Normal Newborn' -- good
			WHEN A.ap_drg_no IN ('193', '194', '195')
				THEN 'Pneumonia' -- good
			WHEN A.ap_drg_no IN ('881', '885')
				AND DX_CC.CC_Code IN ('DX_657')
				THEN 'Major Depression/Bipolar Affective Disorders' -- good
			WHEN A.ap_drg_no IN ('885')
				AND DX_CC.CC_Code IN ('DX_659')
				THEN 'Schizophrenia' -- good
			WHEN A.ap_drg_no IN ('246', '247', '248', '249', '250', '251')
				AND PX_CC.CC_Code IN ('PX_45')
				THEN 'PTCA' -- good
			WHEN A.ap_drg_no IN ('945', '946')
				THEN 'Rehab' -- good
			WHEN A.ap_drg_no IN ('312')
				THEN 'Syncope' -- good
			WHEN A.ap_drg_no IN ('67', '68', '69')
				THEN 'TIA' -- good
			WHEN A.ap_drg_no IN ('774', '775')
				THEN 'Vaginal Delivery' -- good
			WHEN A.ap_drg_no IN ('216', '217', '218', '219', '220', '221', '266', '267')
				THEN 'Valve Procedure' -- good
			WHEN A.ap_drg_no BETWEEN '1'
					AND '8'
				OR A.ap_drg_no BETWEEN '10'
					AND '14'
				OR A.ap_drg_no IN ('16', '17')
				OR A.ap_drg_no BETWEEN '20'
					AND '42'
				OR A.ap_drg_no BETWEEN '113'
					AND '117'
				OR A.ap_drg_no BETWEEN '129'
					AND '139'
				OR A.ap_drg_no BETWEEN '163'
					AND '168'
				OR A.ap_drg_no BETWEEN '215'
					AND '265'
				OR A.ap_drg_no BETWEEN '326'
					AND '358'
				OR A.ap_drg_no BETWEEN '405'
					AND '425'
				OR A.ap_drg_no BETWEEN '453'
					AND '519'
				OR A.ap_drg_no = '520'
				OR A.ap_drg_no BETWEEN '570'
					AND '585'
				OR A.ap_drg_no BETWEEN '614'
					AND '630'
				OR A.ap_drg_no BETWEEN '652'
					AND '675'
				OR A.ap_drg_no BETWEEN '707'
					AND '718'
				OR A.ap_drg_no BETWEEN '734'
					AND '750'
				OR A.ap_drg_no BETWEEN '765'
					AND '780'
				OR A.ap_drg_no BETWEEN '782'
					AND '804'
				OR A.ap_drg_no BETWEEN '820'
					AND '830'
				OR A.ap_drg_no BETWEEN '853'
					AND '858'
				OR A.ap_drg_no = '876'
				OR A.ap_drg_no BETWEEN '901'
					AND '909'
				OR A.ap_drg_no BETWEEN '927'
					AND '929'
				OR A.ap_drg_no BETWEEN '939'
					AND '941'
				OR A.ap_drg_no BETWEEN '955'
					AND '959'
				OR A.ap_drg_no BETWEEN '969'
					AND '970'
				OR A.ap_drg_no BETWEEN '981'
					AND '989'
				THEN 'Surgical' -- good 
			ELSE 'Medical' -- good
			END
	FROM DBO.Pt_Accounting_Reporting_ALT AS A
	LEFT JOIN SMS.DBO.c_dx_cc_mapping_tbl AS DX_CC ON REPLACE(A.[PA-DISCH-DX-CD], '.', '') = DX_CC.ICDCode
	LEFT JOIN [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Active].[dbo].[ProcedureInformation] AS AP ON A.PT_NO = CAST(AP.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(AP.[PA-PT-NO-SCD-1] AS VARCHAR)
		AND AP.[PA-PROC3-PRTY] = '1'
	LEFT JOIN [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Archive].[dbo].[ProcedureInformation] AS ARP ON A.PT_NO = CAST(ARP.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(ARP.[PA-PT-NO-SCD-1] AS VARCHAR)
		AND ARP.[PA-PROC3-PRTY] = '1'
	LEFT JOIN DBO.c_px_cc_mapping_tbl AS PX_CC ON COALESCE(REPLACE(ARP.[PA-PROC3-CD], '.', ''), REPLACE(AP.[PA-PROC3-CD], '.', '')) = PX_CC.ICDCode
	WHERE ACCT_TYPE = 'IP'
		AND A.AP_DRG_Scheme IS NOT NULL
		AND LEFT(A.AP_DRG_SCHEME, 2) = 'MC'
END
ELSE
BEGIN
	INSERT INTO dbo.c_ip_service_line_tbl (
		PT_NO,
		discharge_dx,
		dx_cc_code,
		prim_px_cd,
		px_cc_code,
		service_line
		)
	SELECT A.PT_NO,
		REPLACE(A.[PA-DISCH-DX-CD], '.', '') AS [discharge_dx],
		DX_CC.CC_Code AS [dx_cc_code],
		COALESCE(REPLACE(ARP.[PA-PROC3-CD], '.', ''), REPLACE(AP.[PA-PROC3-CD], '.', '')) AS [prim_px_cd],
		PX_CC.CC_Code AS [px_cc_code],
		[service_line] = CASE 
			WHEN A.ap_drg_no IN ('896', '897')
				AND DX_CC.CC_Code = 'DX_660'
				THEN 'Alcohol Abuse' -- good
			WHEN A.ap_drg_no IN ('231', '232', '233', '234', '235', '236')
				THEN 'CABG' -- good
			WHEN A.ap_drg_no IN ('34', '35', '36', '37', '38', '39')
				AND PX_CC.CC_Code IN ('PX_51', 'PX_59')
				THEN 'Carotid Endarterectomy' -- good
			WHEN A.ap_drg_no IN ('602', '603')
				AND DX_CC.CC_Code IN ('DX_197')
				THEN 'Cellulitis' -- good
			WHEN --A.ap_drg_no IN ('286', '287', '313')
				-- edited 3/22/2016 sps due to new LIHN guidelines
				A.ap_drg_no IN ('313')
				AND DX_CC.CC_Code IN ('DX_102')
				THEN 'Chest Pain' -- good
			WHEN A.ap_drg_no IN ('291', '292', '293')
				AND DX_CC.CC_Code IN ('DX_108', 'DX_99')
				THEN 'CHF' -- good
			WHEN A.ap_drg_no IN ('190', '191', '192')
				AND DX_CC.CC_Code IN ('DX_127', 'DX_128')
				THEN 'COPD' -- good
			WHEN A.ap_drg_no IN ('765', '766')
				THEN 'C-Section' -- good
			WHEN A.ap_drg_no IN ('61', '62', '63', '64', '65', '66')
				THEN 'CVA' -- good
			WHEN A.ap_drg_no IN ('619', '620', '621')
				AND PX_CC.CC_Code IN ('PX_74')
				THEN 'Bariatric Surgery For Obesity' -- update this
			WHEN A.ap_drg_no IN ('377', ' 378', '379')
				THEN 'GI Hemorrhage' -- good
			WHEN A.ap_drg_no IN ('739', '740', '741', '742', '743')
				AND PX_CC.CC_Code IN ('PX_124')
				THEN 'Hysterectomy' -- good
			WHEN A.ap_drg_no IN ('469', '470')
				AND PX_CC.CC_Code IN ('PX_152', 'PX_153')
				-- Exclusions
				AND DX_CC.CC_Code NOT IN ('DX_237', 'DX_238', 'DX_230', 'DX_229', 'DX_226', 'DX_225', 'DX_231', 'DX_207')
				THEN 'Joint Replacement' -- good
			WHEN A.ap_drg_no IN ('417', '418', '419')
				THEN 'Laparoscopic Cholecystectomy' -- good
			WHEN A.ap_drg_no IN ('582', '583', '584', '585')
				AND PX_CC.CC_Code IN ('PX_167')
				THEN 'Mastectomy' -- good
			WHEN A.ap_drg_no IN ('280', '281', '282', '283', '284', '285')
				THEN 'MI' -- good
			WHEN A.ap_drg_no IN ('795')
				AND DX_CC.CC_Code IN ('DX_218')
				THEN 'Normal Newborn' -- good
			WHEN A.ap_drg_no IN ('193', '194', '195')
				THEN 'Pneumonia' -- good
			WHEN A.ap_drg_no IN ('881', '885')
				AND DX_CC.CC_Code IN ('DX_657')
				THEN 'Major Depression/Bipolar Affective Disorders' -- good
			WHEN A.ap_drg_no IN ('885')
				AND DX_CC.CC_Code IN ('DX_659')
				THEN 'Schizophrenia' -- good
			WHEN A.ap_drg_no IN ('246', '247', '248', '249', '250', '251')
				AND PX_CC.CC_Code IN ('PX_45')
				THEN 'PTCA' -- good
			WHEN A.ap_drg_no IN ('945', '946')
				THEN 'Rehab' -- good
			WHEN A.ap_drg_no IN ('312')
				THEN 'Syncope' -- good
			WHEN A.ap_drg_no IN ('67', '68', '69')
				THEN 'TIA' -- good
			WHEN A.ap_drg_no IN ('774', '775')
				THEN 'Vaginal Delivery' -- good
			WHEN A.ap_drg_no IN ('216', '217', '218', '219', '220', '221', '266', '267')
				THEN 'Valve Procedure' -- good
			WHEN A.ap_drg_no BETWEEN '1'
					AND '8'
				OR A.ap_drg_no BETWEEN '10'
					AND '14'
				OR A.ap_drg_no IN ('16', '17')
				OR A.ap_drg_no BETWEEN '20'
					AND '42'
				OR A.ap_drg_no BETWEEN '113'
					AND '117'
				OR A.ap_drg_no BETWEEN '129'
					AND '139'
				OR A.ap_drg_no BETWEEN '163'
					AND '168'
				OR A.ap_drg_no BETWEEN '215'
					AND '265'
				OR A.ap_drg_no BETWEEN '326'
					AND '358'
				OR A.ap_drg_no BETWEEN '405'
					AND '425'
				OR A.ap_drg_no BETWEEN '453'
					AND '519'
				OR A.ap_drg_no = '520'
				OR A.ap_drg_no BETWEEN '570'
					AND '585'
				OR A.ap_drg_no BETWEEN '614'
					AND '630'
				OR A.ap_drg_no BETWEEN '652'
					AND '675'
				OR A.ap_drg_no BETWEEN '707'
					AND '718'
				OR A.ap_drg_no BETWEEN '734'
					AND '750'
				OR A.ap_drg_no BETWEEN '765'
					AND '780'
				OR A.ap_drg_no BETWEEN '782'
					AND '804'
				OR A.ap_drg_no BETWEEN '820'
					AND '830'
				OR A.ap_drg_no BETWEEN '853'
					AND '858'
				OR A.ap_drg_no = '876'
				OR A.ap_drg_no BETWEEN '901'
					AND '909'
				OR A.ap_drg_no BETWEEN '927'
					AND '929'
				OR A.ap_drg_no BETWEEN '939'
					AND '941'
				OR A.ap_drg_no BETWEEN '955'
					AND '959'
				OR A.ap_drg_no BETWEEN '969'
					AND '970'
				OR A.ap_drg_no BETWEEN '981'
					AND '989'
				THEN 'Surgical' -- good 
			ELSE 'Medical' -- good
			END
	FROM DBO.Pt_Accounting_Reporting_ALT AS A
	LEFT JOIN SMS.DBO.c_dx_cc_mapping_tbl AS DX_CC ON REPLACE(A.[PA-DISCH-DX-CD], '.', '') = DX_CC.ICDCode
	LEFT JOIN [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Active].[dbo].[ProcedureInformation] AS AP ON A.PT_NO = CAST(AP.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(AP.[PA-PT-NO-SCD-1] AS VARCHAR)
		AND AP.[PA-PROC3-PRTY] = '1'
	LEFT JOIN [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Archive].[dbo].[ProcedureInformation] AS ARP ON A.PT_NO = CAST(ARP.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(ARP.[PA-PT-NO-SCD-1] AS VARCHAR)
		AND ARP.[PA-PROC3-PRTY] = '1'
	LEFT JOIN DBO.c_px_cc_mapping_tbl AS PX_CC ON COALESCE(REPLACE(ARP.[PA-PROC3-CD], '.', ''), REPLACE(AP.[PA-PROC3-CD], '.', '')) = PX_CC.ICDCode
	WHERE ACCT_TYPE = 'IP'
		AND A.AP_DRG_Scheme IS NOT NULL
		AND LEFT(A.AP_DRG_SCHEME, 2) = 'MC'
		AND NOT EXISTS (
			SELECT 1
			FROM dbo.c_ip_service_line_tbl AS T
			WHERE T.PT_NO = A.PT_NO
		)
END;
