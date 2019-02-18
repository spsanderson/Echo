/******
Initial Creation by:
Steven Sanderson, MPH - Manchu Technology Corp Inc.

FILE: rpt_group_denials_volume.sql

Input Parameters:
None

Purpose:
Get volume of patients, denials, sum total of denied cash and ratios by reporting group

Tables/Views:
[dbo].[DSH_INSURANCE_TABLE_W_REPORT_GROUPS] AS RPTGRP
[DSH].[dbo].[DSH_Denials_Detail] AS Denials

Functions:
None

Revision History:

Author	    Date	    Version	    Description
----	    ----	    ----	    ----
SSanderson	2019-02-13	v1	        Initial Creation

******/
SELECT RPTGRP.[REPORTING GROUP]
, CAST(DSHENC.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(DSHENC.[PA-PT-NO-SCD] AS VARCHAR) AS [PTNO_NUM]
--, RPTGRP.[PA-PT-NO-WOSCD]
--, RPTGRP.[PA-PT-NO-SCD]
--, RPTGRP.[pa-med-rec-no]
--, RPTGRP.[pa-acct-type]
--, RPTGRP.[PRIMARY-TYPE]
, DSHENC.ptacct_type
, Denials.[PA-DTL-CDM-DESCRIPTION]
, SUM(ISNULL(DENIALS.[TOT-CHARGES], 0)) AS [DENIALS_TOTAL_CHARGES]
, SUM(ISNULL(DENIALS.[TOT-PROF-FEES], 0)) AS [DENIALS_TOTAL_PROF_FEES]

-- Tables
-- Encounters_for_DSH gets the base population of patients
FROM [dbo].[Encounters_For_DSH] AS DSHENC
-- Get the reporting group for a patient
LEFT OUTER JOIN [dbo].[DSH_INSURANCE_TABLE_W_REPORT_GROUPS] AS RPTGRP
ON DSHENC.[PA-PT-NO-WOSCD] = RPTGRP.[PA-PT-NO-WOSCD]
    AND DSHENC.[PA-PT-NO-SCD] = RPTGRP.[PA-PT-NO-SCD]
-- Left join the denails table (needs de-duplication) to pull in denaisl if exists
LEFT OUTER JOIN [dbo].[DSH_Denials_Detail] AS Denials
ON RPTGRP.[PA-PT-NO-WOSCD] = DENIALS.[PA-PT-NO-WOSCD]
    AND RPTGRP.[PA-PT-NO-SCD] = DENIALS.[PA-PT-NO-SCD]

GROUP BY CAST(DSHENC.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(DSHENC.[PA-PT-NO-SCD] AS VARCHAR)
, RPTGRP.[REPORTING GROUP]
, DSHENC.ptacct_type
, Denials.[PA-DTL-CDM-DESCRIPTION]
, DENIALS.[TOT-CHARGES]
, DENIALS.[TOT-PROF-FEES]
;

--SELECT TOP 1 *
--FROM DBO.DSH_INSURANCE_TABLE_W_REPORT_GROUPS
--;

-- THIS TABLE NEEDS TO BE DE-DUPLICATED, SEE EXAMPLE BELOW, THIS IS INFLATING NUMBERS
SELECT  *
FROM [dbo].[DSH_Denials_Detail]
WHERE [PA-PT-NO-WOSCD] = '1008150011'
AND [PA-PT-NO-SCD] = '7'
ORDER BY [UNIT-DATE]