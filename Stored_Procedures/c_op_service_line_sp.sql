USE [SMS]
GO 

SET QUOTED_IDENTIFIER ON
GO  

ALTER PROCEDURE dbo.c_op_service_line_sp
AS 

SET NOCOUNT ON;

/*
***********************************************************************
File: c_op_service_line_sp.sql

Input Parameters:
	None

Tables/Views:
	sms.dbo.charges_for_reporting
    echo.dbo.procedureinformation

Creates Table/View:
	dbo.c_op_service_line_tbl

Functions:
	NONE

Author: Steven P. Sanderson II, MPH

Department: Patient Financial Services

Purpose/Description
	Create a table for outpatient LIHN service line assignments

Revision History:
Date		Version		Description
----		----		----
2024-01-01	v1			Initial Creation
2024-03-21  v2			Added additional accounts missed from procedure table
***********************************************************************
*/

IF NOT EXISTS (
		SELECT TOP 1 *
		FROM SYSOBJECTS
		WHERE name = 'c_op_service_line_tbl'
			AND xtype = 'U'
		)
BEGIN
	CREATE TABLE dbo.c_op_service_line_tbl (
		pt_no VARCHAR(20) NOT NULL,
		px_cd VARCHAR(20) NULL,
		px_cd_scheme VARCHAR(20) NULL,
		service_line VARCHAR(256) NULL
		);

	/*
	Bariatric Surgery for Obesity Outpatient
	*/
    SELECT DISTINCT A.Pt_No,
        COALESCE(REPLACE(AP.[PA-PROC3-CD], '.', ''), REPLACE(ARP.[PA-PROC3-CD], '.', '')) AS [px_cd],
        COALESCE(AP.[PA-PROC3-CD-TYPE], ARP.[PA-PROC3-CD-TYPE]) AS [px_cd_scheme],
        'Bariatric Surgery for Obesity Outpatient' AS [SVC_LINE]
    INTO #BSOO
    FROM sms.dbo.Pt_Accounting_Reporting_ALT AS A
    LEFT JOIN [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Active].[dbo].[ProcedureInformation] AS AP ON A.PT_NO = CAST(AP.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(AP.[PA-PT-NO-SCD-1] AS VARCHAR)
    --AND AP.[PA-PROC3-PRTY] = '1'
    LEFT JOIN [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Archive].[dbo].[ProcedureInformation] AS ARP ON A.PT_NO = CAST(ARP.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(ARP.[PA-PT-NO-SCD-1] AS VARCHAR)
    --AND ARP.[PA-PROC3-PRTY] = '1'
    WHERE COALESCE(REPLACE(AP.[PA-PROC3-CD], '.', ''), REPLACE(ARP.[PA-PROC3-CD], '.', '')) IN ('4468', '4495', '43770', '43770')
        AND A.Acct_Type != 'IP'

    UNION ALL

    SELECT DISTINCT A.Pt_No,
        [PA-DTL-CPT-CD],
        [px_cd_scheme] = '',
        'Bariatric Surgery for Obesity Outpatient' AS [SVC_LINE]
    FROM SMS.DBO.Charges_For_Reporting AS A
    WHERE A.[PA-DTL-CPT-CD] IN ('4468', '4495', '43770', '43770')
        AND A.[TYPE] != 'IP'
    /*
	Cardiac Catheterization
	*/
    SELECT DISTINCT A.Pt_No,
        COALESCE(REPLACE(AP.[PA-PROC3-CD], '.', ''), REPLACE(ARP.[PA-PROC3-CD], '.', '')) AS [px_cd],
        COALESCE(AP.[PA-PROC3-CD-TYPE], ARP.[PA-PROC3-CD-TYPE]) AS [px_cd_scheme],
        'Cardiac Catheterization' AS [SVC_LINE]
    INTO #CC
    FROM sms.dbo.Pt_Accounting_Reporting_ALT AS A
    LEFT JOIN [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Active].[dbo].[ProcedureInformation] AS AP ON A.PT_NO = CAST(AP.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(AP.[PA-PT-NO-SCD-1] AS VARCHAR)
    --AND AP.[PA-PROC3-PRTY] = '1'
    LEFT JOIN [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Archive].[dbo].[ProcedureInformation] AS ARP ON A.PT_NO = CAST(ARP.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(ARP.[PA-PT-NO-SCD-1] AS VARCHAR)
    --AND ARP.[PA-PROC3-PRTY] = '1'
    WHERE COALESCE(REPLACE(AP.[PA-PROC3-CD], '.', ''), REPLACE(ARP.[PA-PROC3-CD], '.', '')) IN ('3721', '3722', '3723', '36013', '93451', '93452', '93456', '93457', '93458', '93549', '93460', '93461', '93462', '93560', '93531', '93532', '93533')
        AND A.Acct_Type != 'IP'

    UNION ALL

    SELECT DISTINCT A.Pt_No,
        [PA-DTL-CPT-CD],
        [px_cd_scheme] = '',
        'Cardiac Catheterization' AS [SVC_LINE]
    FROM SMS.DBO.Charges_For_Reporting AS A
    WHERE A.[PA-DTL-CPT-CD] IN ('3721', '3722', '3723', '36013', '93451', '93452', '93456', '93457', '93458', '93549', '93460', '93461', '93462', '93560', '93531', '93532', '93533')
    AND A.[TYPE] != 'IP'

	/*
	Cataract Removal
	*/
    SELECT DISTINCT A.Pt_No,
        COALESCE(REPLACE(AP.[PA-PROC3-CD], '.', ''), REPLACE(ARP.[PA-PROC3-CD], '.', '')) AS [px_cd],
        COALESCE(AP.[PA-PROC3-CD-TYPE], ARP.[PA-PROC3-CD-TYPE]) AS [px_cd_scheme],
        'Cataract Removal' AS [SVC_LINE]
    INTO #CR
    FROM sms.dbo.Pt_Accounting_Reporting_ALT AS A
    LEFT JOIN [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Active].[dbo].[ProcedureInformation] AS AP ON A.PT_NO = CAST(AP.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(AP.[PA-PT-NO-SCD-1] AS VARCHAR)
    --AND AP.[PA-PROC3-PRTY] = '1'
    LEFT JOIN [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Archive].[dbo].[ProcedureInformation] AS ARP ON A.PT_NO = CAST(ARP.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(ARP.[PA-PT-NO-SCD-1] AS VARCHAR)
    --AND ARP.[PA-PROC3-PRTY] = '1'
    WHERE COALESCE(REPLACE(AP.[PA-PROC3-CD], '.', ''), REPLACE(ARP.[PA-PROC3-CD], '.', '')) IN ('1311', '1319', '132', '133', '1341', '1342', '1343', '1351', '1359', '1364', '1365', '1366', '66820', '66821', '66830', '66840', '66850', '66852', '66920', '66930', '66940', '66982', '66983', '66984')
        AND A.Acct_Type != 'IP'

    UNION ALL

    SELECT DISTINCT A.Pt_No,
        [PA-DTL-CPT-CD],
        [px_cd_scheme] = '',
        'Cataract Removal' AS [SVC_LINE]
    FROM SMS.DBO.Charges_For_Reporting AS A
    WHERE A.[PA-DTL-CPT-CD] IN ('1311', '1319', '132', '133', '1341', '1342', '1343', '1351', '1359', '1364', '1365', '1366', '66820', '66821', '66830', '66840', '66850', '66852', '66920', '66930', '66940', '66982', '66983', '66984')
    AND A.[TYPE] != 'IP'

	/*
	Colonoscopy/Endoscopy
	*/
    SELECT DISTINCT A.Pt_No,
        COALESCE(REPLACE(AP.[PA-PROC3-CD], '.', ''), REPLACE(ARP.[PA-PROC3-CD], '.', '')) AS [px_cd],
        COALESCE(AP.[PA-PROC3-CD-TYPE], ARP.[PA-PROC3-CD-TYPE]) AS [px_cd_scheme],
        'Colonoscopy/Endoscopy' AS [SVC_LINE]
    INTO #CE
    FROM sms.dbo.Pt_Accounting_Reporting_ALT AS A
    LEFT JOIN [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Active].[dbo].[ProcedureInformation] AS AP ON A.PT_NO = CAST(AP.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(AP.[PA-PT-NO-SCD-1] AS VARCHAR)
    --AND AP.[PA-PROC3-PRTY] = '1'
    LEFT JOIN [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Archive].[dbo].[ProcedureInformation] AS ARP ON A.PT_NO = CAST(ARP.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(ARP.[PA-PT-NO-SCD-1] AS VARCHAR)
    --AND ARP.[PA-PROC3-PRTY] = '1'
    WHERE COALESCE(REPLACE(AP.[PA-PROC3-CD], '.', ''), REPLACE(ARP.[PA-PROC3-CD], '.', '')) IN ('4513', '4514', '4516', '4523', '4524', '4525', '4542', '4543', '43235', '43236', '43237', '43238', '43239', '43240', '43241', '43242', '43257', '43259', '44100', '44360', '44361', '44370', '44377', '44378', '44379', '44385', '44386', '45317', '45320', '45330', '45331', '45332', '45333', '45334', '45335', '45338', '45339', '45341', '45342', '45345', '45378', '45379', '45380', '45381', '45382', '45383', '45384', '45385', '45391', '45392', 'G0104', 'G0105', 'G0121', 'S0601')
        AND A.Acct_Type != 'IP'

    UNION ALL

    SELECT DISTINCT A.Pt_No,
        [PA-DTL-CPT-CD],
        [px_cd_scheme] = '',
        'Colonoscopy/Endoscopy' AS [SVC_LINE]
    FROM SMS.DBO.Charges_For_Reporting AS A
    WHERE A.[PA-DTL-CPT-CD] IN ('4513', '4514', '4516', '4523', '4524', '4525', '4542', '4543', '43235', '43236', '43237', '43238', '43239', '43240', '43241', '43242', '43257', '43259', '44100', '44360', '44361', '44370', '44377', '44378', '44379', '44385', '44386', '45317', '45320', '45330', '45331', '45332', '45333', '45334', '45335', '45338', '45339', '45341', '45342', '45345', '45378', '45379', '45380', '45381', '45382', '45383', '45384', '45385', '45391', '45392', 'G0104', 'G0105', 'G0121', 'S0601')
    AND A.[TYPE] != 'IP'

	/*
	Laparoscopic Cholecystectomy
	*/
    SELECT DISTINCT A.Pt_No,
        COALESCE(REPLACE(AP.[PA-PROC3-CD], '.', ''), REPLACE(ARP.[PA-PROC3-CD], '.', '')) AS [px_cd],
        COALESCE(AP.[PA-PROC3-CD-TYPE], ARP.[PA-PROC3-CD-TYPE]) AS [px_cd_scheme],
        'Laparoscopic Cholecystectomy' AS [SVC_LINE]
    INTO #LC
    FROM sms.dbo.Pt_Accounting_Reporting_ALT AS A
    LEFT JOIN [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Active].[dbo].[ProcedureInformation] AS AP ON A.PT_NO = CAST(AP.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(AP.[PA-PT-NO-SCD-1] AS VARCHAR)
    --AND AP.[PA-PROC3-PRTY] = '1'
    LEFT JOIN [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Archive].[dbo].[ProcedureInformation] AS ARP ON A.PT_NO = CAST(ARP.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(ARP.[PA-PT-NO-SCD-1] AS VARCHAR)
    --AND ARP.[PA-PROC3-PRTY] = '1'
    WHERE COALESCE(REPLACE(AP.[PA-PROC3-CD], '.', ''), REPLACE(ARP.[PA-PROC3-CD], '.', '')) IN ('5123', '5124', '47562', '47563', '47564')
        AND A.Acct_Type != 'IP'

    UNION ALL

    SELECT DISTINCT A.Pt_No,
        [PA-DTL-CPT-CD],
        [px_cd_scheme] = '',
        'Laparoscopic Cholecystectomy' AS [SVC_LINE]
    FROM SMS.DBO.Charges_For_Reporting AS A
    WHERE A.[PA-DTL-CPT-CD] IN ('5123', '5124', '47562', '47563', '47564')
    AND A.[TYPE] != 'IP'

	/*
	PTCA Outpatient
	*/
    SELECT DISTINCT A.Pt_No,
        COALESCE(REPLACE(AP.[PA-PROC3-CD], '.', ''), REPLACE(ARP.[PA-PROC3-CD], '.', '')) AS [px_cd],
        COALESCE(AP.[PA-PROC3-CD-TYPE], ARP.[PA-PROC3-CD-TYPE]) AS [px_cd_scheme],
        'PTCA Outpatient' AS [SVC_LINE]
    INTO #PTCAOP
    FROM sms.dbo.Pt_Accounting_Reporting_ALT AS A
    LEFT JOIN [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Active].[dbo].[ProcedureInformation] AS AP ON A.PT_NO = CAST(AP.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(AP.[PA-PT-NO-SCD-1] AS VARCHAR)
    --AND AP.[PA-PROC3-PRTY] = '1'
    LEFT JOIN [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Archive].[dbo].[ProcedureInformation] AS ARP ON A.PT_NO = CAST(ARP.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(ARP.[PA-PT-NO-SCD-1] AS VARCHAR)
    --AND ARP.[PA-PROC3-PRTY] = '1'
    WHERE COALESCE(REPLACE(AP.[PA-PROC3-CD], '.', ''), REPLACE(ARP.[PA-PROC3-CD], '.', '')) IN ('0066', '92920', '92924', '92928', '92933', '92937', '92941', '92943', 'C9600', 'C9602', 'C9604', 'C9606', 'C9607')
        AND A.Acct_Type != 'IP'

    UNION ALL

    SELECT DISTINCT A.Pt_No,
        [PA-DTL-CPT-CD],
        [px_cd_scheme] = '',
        'PTCA Outpatient' AS [SVC_LINE]
    FROM SMS.DBO.Charges_For_Reporting AS A
    WHERE A.[PA-DTL-CPT-CD] IN ('0066', '92920', '92924', '92928', '92933', '92937', '92941', '92943', 'C9600', 'C9602', 'C9604', 'C9606', 'C9607')
    AND A.[TYPE] != 'IP'

	/*
	General Outpatient
	*/
    SELECT DISTINCT A.Pt_No,
        COALESCE(REPLACE(AP.[PA-PROC3-CD], '.', ''), REPLACE(ARP.[PA-PROC3-CD], '.', '')) AS [px_cd],
        COALESCE(AP.[PA-PROC3-CD-TYPE], ARP.[PA-PROC3-CD-TYPE]) AS [px_cd_scheme],
        'General Outpatient' AS [SVC_LINE]
    INTO #GOP
    FROM sms.dbo.Pt_Accounting_Reporting_ALT AS A
    LEFT JOIN [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Active].[dbo].[ProcedureInformation] AS AP ON A.PT_NO = CAST(AP.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(AP.[PA-PT-NO-SCD-1] AS VARCHAR)
    --AND AP.[PA-PROC3-PRTY] = '1'
    LEFT JOIN [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Archive].[dbo].[ProcedureInformation] AS ARP ON A.PT_NO = CAST(ARP.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(ARP.[PA-PT-NO-SCD-1] AS VARCHAR)
    --AND ARP.[PA-PROC3-PRTY] = '1'
    WHERE A.Pt_No NOT IN (
            SELECT A.pt_no
            FROM #BSOO AS A
            )
        AND A.Pt_No NOT IN (
            SELECT B.pt_no
            FROM #CC AS B
            )
        AND A.Pt_No NOT IN (
            SELECT C.pt_no
            FROM #CE AS C
            )
        AND A.Pt_No NOT IN (
            SELECT D.pt_no
            FROM #CR AS D
            )
        AND A.Pt_No NOT IN (
            SELECT E.pt_no
            FROM #LC AS E
            )
        AND A.Pt_No NOT IN (
            SELECT F.pt_no
            FROM #PTCAOP AS F
            )
        AND A.Acct_Type != 'IP'


	/*
	Union all tables and take distinct records, account
	cannot have more than one line assignment
	*/
    SELECT DISTINCT (OPLINE.pt_no) AS pt_no,
        OPLINE.px_cd,
        OPLINE.px_cd_scheme,
        OPLINE.SVC_LINE AS [service_line],
        [RN] = ROW_NUMBER() OVER (
            PARTITION BY OPLINE.pt_no ORDER BY OPLINE.pt_no
            )
    INTO #TEMP_REC_A
    FROM (
        SELECT *
        FROM #BSOO AS A
        
        UNION
        
        SELECT *
        FROM #CC
        
        UNION
        
        SELECT *
        FROM #CE
        
        UNION
        
        SELECT *
        FROM #CR
        
        UNION
        
        SELECT *
        FROM #LC
        
        UNION
        
        SELECT *
        FROM #PTCAOP
        
        UNION
        
        SELECT *
        FROM #GOP
        ) AS OPLINE;

    INSERT INTO dbo.c_op_service_line_tbl (
        pt_no,
        px_cd,
        px_cd_scheme,
        service_line
        )
    SELECT A.pt_no,
        A.px_cd,
        A.px_cd_scheme,
        A.service_line
    FROM #TEMP_REC_A AS A
    WHERE A.RN = 1;

    DROP TABLE #BSOO,
        #CC,
        #CE,
        #CR,
        #LC,
        #PTCAOP,
        #TEMP_REC_A,
        #GOP;

	
END
ELSE
BEGIN
	
	/*
	Bariatric Surgery for Obesity Outpatient
	*/
    SELECT DISTINCT A.Pt_No,
        COALESCE(REPLACE(AP.[PA-PROC3-CD], '.', ''), REPLACE(ARP.[PA-PROC3-CD], '.', '')) AS [px_cd],
        COALESCE(AP.[PA-PROC3-CD-TYPE], ARP.[PA-PROC3-CD-TYPE]) AS [px_cd_scheme],
        'Bariatric Surgery for Obesity Outpatient' AS [SVC_LINE]
    INTO #BSOO2
    FROM sms.dbo.Pt_Accounting_Reporting_ALT AS A
    LEFT JOIN [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Active].[dbo].[ProcedureInformation] AS AP ON A.PT_NO = CAST(AP.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(AP.[PA-PT-NO-SCD-1] AS VARCHAR)
    --AND AP.[PA-PROC3-PRTY] = '1'
    LEFT JOIN [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Archive].[dbo].[ProcedureInformation] AS ARP ON A.PT_NO = CAST(ARP.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(ARP.[PA-PT-NO-SCD-1] AS VARCHAR)
    --AND ARP.[PA-PROC3-PRTY] = '1'
    WHERE COALESCE(REPLACE(AP.[PA-PROC3-CD], '.', ''), REPLACE(ARP.[PA-PROC3-CD], '.', '')) IN ('4468', '4495', '43770', '43770')
        AND A.Acct_Type != 'IP'

    UNION ALL

    SELECT DISTINCT A.Pt_No,
        [PA-DTL-CPT-CD],
        [px_cd_scheme] = '',
        'Bariatric Surgery for Obesity Outpatient' AS [SVC_LINE]
    FROM SMS.DBO.Charges_For_Reporting AS A
    WHERE A.[PA-DTL-CPT-CD] IN ('4468', '4495', '43770', '43770')
        AND A.[TYPE] != 'IP'

    /*
	Cardiac Catheterization
	*/
    SELECT DISTINCT A.Pt_No,
        COALESCE(REPLACE(AP.[PA-PROC3-CD], '.', ''), REPLACE(ARP.[PA-PROC3-CD], '.', '')) AS [px_cd],
        COALESCE(AP.[PA-PROC3-CD-TYPE], ARP.[PA-PROC3-CD-TYPE]) AS [px_cd_scheme],
        'Cardiac Catheterization' AS [SVC_LINE]
    INTO #CC2
    FROM sms.dbo.Pt_Accounting_Reporting_ALT AS A
    LEFT JOIN [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Active].[dbo].[ProcedureInformation] AS AP ON A.PT_NO = CAST(AP.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(AP.[PA-PT-NO-SCD-1] AS VARCHAR)
    --AND AP.[PA-PROC3-PRTY] = '1'
    LEFT JOIN [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Archive].[dbo].[ProcedureInformation] AS ARP ON A.PT_NO = CAST(ARP.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(ARP.[PA-PT-NO-SCD-1] AS VARCHAR)
    --AND ARP.[PA-PROC3-PRTY] = '1'
    WHERE COALESCE(REPLACE(AP.[PA-PROC3-CD], '.', ''), REPLACE(ARP.[PA-PROC3-CD], '.', '')) IN ('3721', '3722', '3723', '36013', '93451', '93452', '93456', '93457', '93458', '93549', '93460', '93461', '93462', '93560', '93531', '93532', '93533')
        AND A.Acct_Type != 'IP'
		
    UNION ALL

    SELECT DISTINCT A.Pt_No,
        [PA-DTL-CPT-CD],
        [px_cd_scheme] = '',
        'Cardiac Catheterization' AS [SVC_LINE]
    FROM SMS.DBO.Charges_For_Reporting AS A
    WHERE A.[PA-DTL-CPT-CD] IN ('3721', '3722', '3723', '36013', '93451', '93452', '93456', '93457', '93458', '93549', '93460', '93461', '93462', '93560', '93531', '93532', '93533')
    AND A.[TYPE] != 'IP'

	/*
	Cataract Removal
	*/
    SELECT DISTINCT A.Pt_No,
        COALESCE(REPLACE(AP.[PA-PROC3-CD], '.', ''), REPLACE(ARP.[PA-PROC3-CD], '.', '')) AS [px_cd],
        COALESCE(AP.[PA-PROC3-CD-TYPE], ARP.[PA-PROC3-CD-TYPE]) AS [px_cd_scheme],
        'Cataract Removal' AS [SVC_LINE]
    INTO #CR2
    FROM sms.dbo.Pt_Accounting_Reporting_ALT AS A
    LEFT JOIN [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Active].[dbo].[ProcedureInformation] AS AP ON A.PT_NO = CAST(AP.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(AP.[PA-PT-NO-SCD-1] AS VARCHAR)
    --AND AP.[PA-PROC3-PRTY] = '1'
    LEFT JOIN [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Archive].[dbo].[ProcedureInformation] AS ARP ON A.PT_NO = CAST(ARP.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(ARP.[PA-PT-NO-SCD-1] AS VARCHAR)
    --AND ARP.[PA-PROC3-PRTY] = '1'
    WHERE COALESCE(REPLACE(AP.[PA-PROC3-CD], '.', ''), REPLACE(ARP.[PA-PROC3-CD], '.', '')) IN ('1311', '1319', '132', '133', '1341', '1342', '1343', '1351', '1359', '1364', '1365', '1366', '66820', '66821', '66830', '66840', '66850', '66852', '66920', '66930', '66940', '66982', '66983', '66984')
        AND A.Acct_Type != 'IP'
	
    UNION ALL

    SELECT DISTINCT A.Pt_No,
        [PA-DTL-CPT-CD],
        [px_cd_scheme] = '',
        'Cataract Removal' AS [SVC_LINE]
    FROM SMS.DBO.Charges_For_Reporting AS A
    WHERE A.[PA-DTL-CPT-CD] IN ('1311', '1319', '132', '133', '1341', '1342', '1343', '1351', '1359', '1364', '1365', '1366', '66820', '66821', '66830', '66840', '66850', '66852', '66920', '66930', '66940', '66982', '66983', '66984')
    AND A.[TYPE] != 'IP'

	/*
	Colonoscopy/Endoscopy
	*/
    SELECT DISTINCT A.Pt_No,
        COALESCE(REPLACE(AP.[PA-PROC3-CD], '.', ''), REPLACE(ARP.[PA-PROC3-CD], '.', '')) AS [px_cd],
        COALESCE(AP.[PA-PROC3-CD-TYPE], ARP.[PA-PROC3-CD-TYPE]) AS [px_cd_scheme],
        'Colonoscopy/Endoscopy' AS [SVC_LINE]
    INTO #CE2
    FROM sms.dbo.Pt_Accounting_Reporting_ALT AS A
    LEFT JOIN [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Active].[dbo].[ProcedureInformation] AS AP ON A.PT_NO = CAST(AP.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(AP.[PA-PT-NO-SCD-1] AS VARCHAR)
    --AND AP.[PA-PROC3-PRTY] = '1'
    LEFT JOIN [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Archive].[dbo].[ProcedureInformation] AS ARP ON A.PT_NO = CAST(ARP.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(ARP.[PA-PT-NO-SCD-1] AS VARCHAR)
    --AND ARP.[PA-PROC3-PRTY] = '1'
    WHERE COALESCE(REPLACE(AP.[PA-PROC3-CD], '.', ''), REPLACE(ARP.[PA-PROC3-CD], '.', '')) IN ('4513', '4514', '4516', '4523', '4524', '4525', '4542', '4543', '43235', '43236', '43237', '43238', '43239', '43240', '43241', '43242', '43257', '43259', '44100', '44360', '44361', '44370', '44377', '44378', '44379', '44385', '44386', '45317', '45320', '45330', '45331', '45332', '45333', '45334', '45335', '45338', '45339', '45341', '45342', '45345', '45378', '45379', '45380', '45381', '45382', '45383', '45384', '45385', '45391', '45392', 'G0104', 'G0105', 'G0121', 'S0601')
        AND A.Acct_Type != 'IP'
	
    UNION ALL

    SELECT DISTINCT A.Pt_No,
        [PA-DTL-CPT-CD],
        [px_cd_scheme] = '',
        'Colonoscopy/Endoscopy' AS [SVC_LINE]
    FROM SMS.DBO.Charges_For_Reporting AS A
    WHERE A.[PA-DTL-CPT-CD] IN ('4513', '4514', '4516', '4523', '4524', '4525', '4542', '4543', '43235', '43236', '43237', '43238', '43239', '43240', '43241', '43242', '43257', '43259', '44100', '44360', '44361', '44370', '44377', '44378', '44379', '44385', '44386', '45317', '45320', '45330', '45331', '45332', '45333', '45334', '45335', '45338', '45339', '45341', '45342', '45345', '45378', '45379', '45380', '45381', '45382', '45383', '45384', '45385', '45391', '45392', 'G0104', 'G0105', 'G0121', 'S0601')
    AND A.[TYPE] != 'IP'

	/*
	Laparoscopic Cholecystectomy
	*/
    SELECT DISTINCT A.Pt_No,
        COALESCE(REPLACE(AP.[PA-PROC3-CD], '.', ''), REPLACE(ARP.[PA-PROC3-CD], '.', '')) AS [px_cd],
        COALESCE(AP.[PA-PROC3-CD-TYPE], ARP.[PA-PROC3-CD-TYPE]) AS [px_cd_scheme],
        'Laparoscopic Cholecystectomy' AS [SVC_LINE]
    INTO #LC2
    FROM sms.dbo.Pt_Accounting_Reporting_ALT AS A
    LEFT JOIN [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Active].[dbo].[ProcedureInformation] AS AP ON A.PT_NO = CAST(AP.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(AP.[PA-PT-NO-SCD-1] AS VARCHAR)
    --AND AP.[PA-PROC3-PRTY] = '1'
    LEFT JOIN [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Archive].[dbo].[ProcedureInformation] AS ARP ON A.PT_NO = CAST(ARP.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(ARP.[PA-PT-NO-SCD-1] AS VARCHAR)
    --AND ARP.[PA-PROC3-PRTY] = '1'
    WHERE COALESCE(REPLACE(AP.[PA-PROC3-CD], '.', ''), REPLACE(ARP.[PA-PROC3-CD], '.', '')) IN ('5123', '5124', '47562', '47563', '47564')
        AND A.Acct_Type != 'IP'
	
    UNION ALL

    SELECT DISTINCT A.Pt_No,
        [PA-DTL-CPT-CD],
        [px_cd_scheme] = '',
        'Laparoscopic Cholecystectomy' AS [SVC_LINE]
    FROM SMS.DBO.Charges_For_Reporting AS A
    WHERE A.[PA-DTL-CPT-CD] IN ('5123', '5124', '47562', '47563', '47564')
    AND A.[TYPE] != 'IP'

	/*
	PTCA Outpatient
	*/
    SELECT DISTINCT A.Pt_No,
        COALESCE(REPLACE(AP.[PA-PROC3-CD], '.', ''), REPLACE(ARP.[PA-PROC3-CD], '.', '')) AS [px_cd],
        COALESCE(AP.[PA-PROC3-CD-TYPE], ARP.[PA-PROC3-CD-TYPE]) AS [px_cd_scheme],
        'PTCA Outpatient' AS [SVC_LINE]
    INTO #PTCAOP2
    FROM sms.dbo.Pt_Accounting_Reporting_ALT AS A
    LEFT JOIN [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Active].[dbo].[ProcedureInformation] AS AP ON A.PT_NO = CAST(AP.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(AP.[PA-PT-NO-SCD-1] AS VARCHAR)
    --AND AP.[PA-PROC3-PRTY] = '1'
    LEFT JOIN [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Archive].[dbo].[ProcedureInformation] AS ARP ON A.PT_NO = CAST(ARP.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(ARP.[PA-PT-NO-SCD-1] AS VARCHAR)
    --AND ARP.[PA-PROC3-PRTY] = '1'
    WHERE COALESCE(REPLACE(AP.[PA-PROC3-CD], '.', ''), REPLACE(ARP.[PA-PROC3-CD], '.', '')) IN ('0066', '92920', '92924', '92928', '92933', '92937', '92941', '92943', 'C9600', 'C9602', 'C9604', 'C9606', 'C9607')
        AND A.Acct_Type != 'IP'
	
    UNION ALL

    SELECT DISTINCT A.Pt_No,
        [PA-DTL-CPT-CD],
        [px_cd_scheme] = '',
        'PTCA Outpatient' AS [SVC_LINE]
    FROM SMS.DBO.Charges_For_Reporting AS A
    WHERE A.[PA-DTL-CPT-CD] IN ('0066', '92920', '92924', '92928', '92933', '92937', '92941', '92943', 'C9600', 'C9602', 'C9604', 'C9606', 'C9607')
    AND A.[TYPE] != 'IP'

	/*
	General Outpatient
	*/
    SELECT DISTINCT A.Pt_No,
        COALESCE(REPLACE(AP.[PA-PROC3-CD], '.', ''), REPLACE(ARP.[PA-PROC3-CD], '.', '')) AS [px_cd],
        COALESCE(AP.[PA-PROC3-CD-TYPE], ARP.[PA-PROC3-CD-TYPE]) AS [px_cd_scheme],
        'General Outpatient' AS [SVC_LINE]
    INTO #GOP2
    FROM sms.dbo.Pt_Accounting_Reporting_ALT AS A
    LEFT JOIN [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Active].[dbo].[ProcedureInformation] AS AP ON A.PT_NO = CAST(AP.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(AP.[PA-PT-NO-SCD-1] AS VARCHAR)
    --AND AP.[PA-PROC3-PRTY] = '1'
    LEFT JOIN [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Archive].[dbo].[ProcedureInformation] AS ARP ON A.PT_NO = CAST(ARP.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(ARP.[PA-PT-NO-SCD-1] AS VARCHAR)
    --AND ARP.[PA-PROC3-PRTY] = '1'
    WHERE A.Pt_No NOT IN (
            SELECT A.pt_no
            FROM #BSOO2 AS A
            )
        AND A.Pt_No NOT IN (
            SELECT B.pt_no
            FROM #CC2 AS B
            )
        AND A.Pt_No NOT IN (
            SELECT C.pt_no
            FROM #CE2 AS C
            )
        AND A.Pt_No NOT IN (
            SELECT D.pt_no
            FROM #CR2 AS D
            )
        AND A.Pt_No NOT IN (
            SELECT E.pt_no
            FROM #LC2 AS E
            )
        AND A.Pt_No NOT IN (
            SELECT F.pt_no
            FROM #PTCAOP2 AS F
            )
        AND A.Acct_Type != 'IP'

	UNION ALL

	SELECT DISTINCT A.Pt_No,
        [PA-DTL-CPT-CD] AS [px_cd],
        [px_cd_scheme] = '',
        'General Outpatient' AS [SVC_LINE]
    FROM SMS.DBO.Charges_For_Reporting AS A
    WHERE A.Pt_No NOT IN (
            SELECT A.pt_no
            FROM #BSOO2 AS A
            )
        AND A.Pt_No NOT IN (
            SELECT B.pt_no
            FROM #CC2 AS B
            )
        AND A.Pt_No NOT IN (
            SELECT C.pt_no
            FROM #CE2 AS C
            )
        AND A.Pt_No NOT IN (
            SELECT D.pt_no
            FROM #CR2 AS D
            )
        AND A.Pt_No NOT IN (
            SELECT E.pt_no
            FROM #LC2 AS E
            )
        AND A.Pt_No NOT IN (
            SELECT F.pt_no
            FROM #PTCAOP2 AS F
            )
        AND A.[Type] != 'IP'


	/*
	Union all tables and take distinct records, account
	cannot have more than one line assignment
	*/
    SELECT DISTINCT (OPLINE.pt_no) AS pt_no,
        OPLINE.px_cd,
        OPLINE.px_cd_scheme,
        OPLINE.SVC_LINE AS [service_line],
        [RN] = ROW_NUMBER() OVER (
            PARTITION BY OPLINE.pt_no ORDER BY OPLINE.pt_no
            )
    INTO #TEMP_REC_B
    FROM (
        SELECT *
        FROM #BSOO2 AS A
        
        UNION
        
        SELECT *
        FROM #CC2
        
        UNION
        
        SELECT *
        FROM #CE2
        
        UNION
        
        SELECT *
        FROM #CR2
        
        UNION
        
        SELECT *
        FROM #LC2
        
        UNION
        
        SELECT *
        FROM #PTCAOP2
        
        UNION
        
        SELECT *
        FROM #GOP2
        ) AS OPLINE
    WHERE OPLINE.Pt_No NOT IN (
            SELECT DISTINCT PT_NO
            FROM dbo.c_op_service_line_tbl
            );

    INSERT INTO dbo.c_op_service_line_tbl (
        pt_no,
        px_cd,
        px_cd_scheme,
        service_line
        )
    SELECT A.pt_no,
        A.px_cd,
        A.px_cd_scheme,
        A.service_line
    FROM #TEMP_REC_B AS A
    WHERE A.RN = 1;

    DROP TABLE #BSOO2,
        #CC2,
        #CE2,
        #CR2,
        #LC2,
        #PTCAOP2,
        #TEMP_REC_B,
        #GOP2;


END;
