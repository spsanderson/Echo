/******
Initial Creation by:
Steven Sanderson, MPH - Manchu Technology Corp Inc.

FILE: rpt_group_charges_volume.sql

Input Parameters:
None

Purpose:
Get volume of patients, chargess, sum total of charges and ratios by reporting group

Tables/Views:
[dbo].[DSH_INSURANCE_TABLE_W_REPORT_GROUPS] AS RPTGRP
[DSH].[dbo].[DSH_Charges] AS CHARGES
[dbo].[Encounters_For_DSH] AS DSHENC

Functions:
None

Revision History:

Author	    Date	    Version	    Description
----	    ----	    ----	    ----
SSanderson	2019-02-18	v1	        Initial Creation

******/
SELECT RPTGRP.[REPORTING GROUP]
, CAST(DSHENC.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(DSHENC.[PA-PT-NO-SCD] AS VARCHAR) AS [PTNO_NUM]
--, RPTGRP.[PA-PT-NO-WOSCD]
--, RPTGRP.[PA-PT-NO-SCD]
--, RPTGRP.[pa-med-rec-no]
--, RPTGRP.[pa-acct-type]
--, RPTGRP.[PRIMARY-TYPE]
, DSHENC.ptacct_type
, SUM(ISNULL(CHARGES.[TOT-CHARGES], 0)) AS [TOTAL_CHARGES]
, SUM(ISNULL(CHARGES.[TOT-PROF-FEES], 0)) AS [TOTAL_PROF_FEES]

-- Tables
-- Encounters_for_DSH gets the base population of patients
FROM [dbo].[Encounters_For_DSH] AS DSHENC
-- Get the reporting group for a patient
LEFT OUTER JOIN [dbo].[DSH_INSURANCE_TABLE_W_REPORT_GROUPS] AS RPTGRP
ON DSHENC.[PA-PT-NO-WOSCD] = RPTGRP.[PA-PT-NO-WOSCD]
    AND DSHENC.[PA-PT-NO-SCD] = RPTGRP.[PA-PT-NO-SCD]
-- Left join the CHARGES TABLE
LEFT OUTER JOIN [DSH].[dbo].[DSH_Charges] AS CHARGES
ON RPTGRP.[PA-PT-NO-WOSCD] = CHARGES.[PA-PT-NO-WOSCD]
    AND RPTGRP.[PA-PT-NO-SCD] = CHARGES.[PA-PT-NO-SCD]

GROUP BY CAST(DSHENC.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(DSHENC.[PA-PT-NO-SCD] AS VARCHAR)
, RPTGRP.[REPORTING GROUP]
, DSHENC.ptacct_type

;