/******
Initial Creation by:
Steven Sanderson, MPH - Manchu Technology Corp Inc.

FILE: rpt_group_costs_volume.sql

Input Parameters:
None

Purpose:
Get volume of patients, cost, sum total of denied cash and ratios by reporting group

Tables/Views:
[dbo].[DSH_INSURANCE_TABLE_W_REPORT_GROUPS] AS RPTGRP
[dbo].[2016_DSH_Costs] AS COSTS
[dbo].[Encounters_For_DSH] AS DSHENC

Functions:
None

Revision History:

Author	    Date	    Version	    Description
----	    ----	    ----	    ----
SSanderson	2019-02-13	v1	        Initial Creation

******/

SELECT RPTGRP.[REPORTING GROUP],
	CAST(DSHENC.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(DSHENC.[PA-PT-NO-SCD] AS VARCHAR) AS [PTNO_NUM]
	--, RPTGRP.[PA-PT-NO-WOSCD]
	--, RPTGRP.[PA-PT-NO-SCD]
	--, RPTGRP.[pa-med-rec-no]
	--, RPTGRP.[pa-acct-type]
	--, RPTGRP.[PRIMARY-TYPE]
	,
	DSHENC.ptacct_type,
	SUM(ISNULL(COSTS.[SUM OF TOT CHG], 0)) AS [TOTAL_CHARGES],
	SUM(ISNULL(COSTS.[SUM OF TOT PROF FEES], 0)) AS [TOTAL_PROF_FEES],
	SUM(ISNULL(COSTS.[Sum_of_Chargesand_Prof_Fees], 0)) AS [TOTAL_CHGS_FEES],
	SUM(ISNULL(COSTS.[Cost], 0)) AS [TOTAL_COST]
-- Tables
-- Encounters_for_DSH gets the base population of patients
FROM [dbo].[Encounters_For_DSH] AS DSHENC
-- Get the reporting group for a patient
LEFT OUTER JOIN [dbo].[DSH_INSURANCE_TABLE_W_REPORT_GROUPS] AS RPTGRP 
ON DSHENC.[PA-PT-NO-WOSCD] = RPTGRP.[PA-PT-NO-WOSCD]
	AND DSHENC.[PA-PT-NO-SCD] = RPTGRP.[PA-PT-NO-SCD]
-- Left join the COSTS TABLE
LEFT OUTER JOIN [dbo].[2016_DSH_Costs] AS COSTS 
ON DSHENC.[PA-PT-NO-SCD] = COSTS.[PA-PT-NO-WOSCD]
	AND DSHENC.[PA-PT-NO-SCD] = COSTS.[PA-PT-NO-SCD]

GROUP BY CAST(DSHENC.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(DSHENC.[PA-PT-NO-SCD] AS VARCHAR),
	RPTGRP.[REPORTING GROUP],
	DSHENC.ptacct_type;
