/*
***********************************************************************
File: c_tableau_oamcomb_dashboard_v.sql

Input Parameters:
	None

Tables/Views:
	[Swarm].[DBO].[OAMCOMB ]
	[Swarm].[DBO].[CDM]
	[SMS].[DBO].[c_tableau_insurance_tbl]
	[SMS].[DBO].[revenue_cycle_employee_listing]

Creates Table/View:
	dbo.c_tableau_oamcomb_dashboard_v

Functions:
	None

Author: Casey Delaney

Department: Patient Financial Services

Purpose/Description
	OAMCOMB Initial Tableau Dashboard View

Revision History:
Date		Version		Description
----		----		----
2023-10-24	v1			Initial Creation
2023-10-26	v2			lag_days column
2023-11-01	v3			svc_type and user_system_posted name updates
2023-11-06	v4			Ins_Plan, payer_name, payer_org, product_class
2023-11-09	v5			Added user_dept and description
2023-11-14	v6			User_dept case statements and rev_status
2023-12-22	v7			Added PFS0 EMUE IDs
2024-01-12	v8			Updated User IDs
***********************************************************************
*/

USE [SMS]

IF EXISTS (
    SELECT
        *
    FROM
        sys.views
        JOIN sys.schemas ON sys.views.schema_id = sys.schemas.schema_id
    WHERE
        sys.schemas.name = N'dbo'
        AND sys.views.name = N'c_tableau_oamcomb_dashboard_v'
) DROP VIEW dbo.c_tableau_oamcomb_dashboard_v;
GO


CREATE VIEW dbo.c_tableau_oamcomb_dashboard_v AS -- body of the view
SELECT
    OAM.[Encounter Number] AS pt_no,
    OAM.[Unit] AS unit_no,
    OAM.[PA_File] AS pa_file,
    [description] = CASE
        WHEN OAM.[PA_File] = 'A' THEN 'A/R'
        WHEN OAM.[PA_File] = 'B' THEN 'Bad Debt'
        WHEN OAM.[PA_File] = 'I' THEN 'Inpatient (Not final billed)'
        WHEN OAM.[PA_File] = 'O' THEN 'Outpatient (ACCT)'
    END,
    OAM.[Batch_No] AS batch_no,
    OAM.[USER_BATCH_ID] AS user_batch_id,
    OAM.[Service Code] AS svc_cd,
    OAM.[Pt_Type] AS pt_type,
    OAM.[FC] AS fc,
	[control_acc] = CASE
		WHEN OAM.[FC] = 'X' THEN 'Y'
		ELSE 'N'
	END,
    REV.[Status] as [rev_status],
    OAM.[USER_ID] AS [user_id],
	[user_dept] = CASE
        WHEN LEFT(OAM.[User_ID], 5) in ('RGUTH') THEN 'Randy Guthrie'
		WHEN REV.[Status] = 'Inactive' THEN 'User_Inactive'
        ELSE CASE
            WHEN OAM.[USER_ID] in ('DIVANS', 'ECUNNI') THEN 'IT'
			WHEN OAM.[USER_ID] in ('INSTMD', 'REFUND', 'MANUAL', 'ERSMAN') THEN 'EMUE'
            WHEN LEFT(OAM.[User_ID], 4) in ('SCRP', 'PFS0') THEN 'EMUE'
			WHEN LEFT(OAM.[User_ID], 5) in ('CHASE') THEN 'EMUE'
			WHEN LEFT(OAM.[User_ID], 3) in ('ERS') THEN 'System'
			WHEN OAM.[USER_ID] in ('SMATHE', 'EPISTO', 'KDESPO', 'TINSIN') THEN 'PFS Management'
			WHEN OAM.[USER_ID] in ('CMCCOR', 'VKEEGA') THEN 'Analyst Team'
            WHEN OAM.[USER_ID] in ('BTORR1') THEN 'Account Management'
            WHEN OAM.[USER_ID] in ('GABRAH', 'KJEZEW', 'PCHHAB', 'SLUO', 'TAPOLO') THEN 'Cash Management'
            WHEN OAM.[USER_ID] in ('ABUDZI') THEN 'Customer Service'
            WHEN OAM.[USER_ID] in ('BCOMPT', 'LMOORE', 'REGHAR', 'SWILMO', 'WMOSS') THEN 'Denials & Appeals'
            WHEN OAM.[USER_ID] in ('AKUMAR') THEN 'Governmental Billing'
            WHEN OAM.[USER_ID] in ('AMEDIN','ATANKS','BDUMEN','BWILL1','BBRANN','CKALUZ','CJACO1','ADAS','ALADHA','ARIOS','EUCEDA','HJIN',
										'DCOWAN','SJONES','SHERNA','ADONN1') THEN 'Non-Governmental Billing'
            WHEN OAM.[USER_ID] in ('AABRAM','CARD','CRAMOS','CARMST','DDIXON','DVANDE','MTANEL','GPATE1','KHEYWA',
										'LJACK1','MNATIO','SKAMIN','TTERRY','CBERRY') THEN 'Non-Governmental Follow Up'
            ELSE REV.[USER_DEPT]
        END
    END,
    OAM.[Posted_Amt],
    OAM.[Ins_Plan],
    TI.[payer_name],
    TI.[payer_organization],
    TI.[product_class],
    CAST(OAM.SVC_DATE AS DATE) AS svc_date,
    CAST(OAM.Post_Date AS DATE) AS post_date,
    DATEDIFF(day, CAST(OAM.SVC_DATE AS DATE), CAST(OAM.Post_Date AS DATE)) AS lag_days,
    OAM.[Tran_Type_1],
    OAM.[Tran_Type_2],
    CDM.[Technical Description],
    [svc_type] = CASE
        WHEN LEFT(OAM.[Service Code], 1) = '5' THEN 'Xfer'
        WHEN CDM.[Svc Type] = 'AR Adjustment' THEN 'Adjustment'
        WHEN CDM.[Svc Type] = 'AR Payment' THEN 'Payment'
        ELSE CDM.[Svc Type]
    END,
    CDM.[General Description],
	CDM.[HOSP],
    [user_system_posted] = CASE
		WHEN OAM.[USER_ID] in ('INSTMD', 'REFUND', 'MANUAL', 'ERSMAN') THEN 'EMUE'
		WHEN LEFT(OAM.[User_ID], 4) in ('SCRP', 'PFS0') THEN 'EMUE'
		WHEN LEFT(OAM.[User_ID], 5) in ('CHASE') THEN 'EMUE'
		WHEN LEFT(OAM.[User_ID], 5) in ('RGUTH') THEN 'Randy Guthrie'
        WHEN LEFT(OAM.[User_ID], 3) = 'ERS' THEN 'System' 
        ELSE 'Manual'
    END,
	ALT.SP_RunDateTime
FROM
    Swarm.DBO.[OAMCOMB ] AS OAM
    LEFT JOIN SWARM.DBO.CDM AS CDM ON OAM.[Service Code] = CDM.[Service Code]
    LEFT JOIN SMS.DBO.c_tableau_insurance_tbl AS TI ON OAM.[Ins_Plan] = TI.[code]
    LEFT JOIN SMS.DBO.revenue_cycle_employee_listing AS REV ON OAM.[user_id] = REV.[USER_ID]
	LEFT JOIN SMS.DBO.Pt_Accounting_Reporting_ALT AS ALT ON OAM.[Encounter Number] = ALT.Pt_No
WHERE
    Post_Date >= '2021-01-01'
    AND OAM.Posted_Amt != 0;
GO