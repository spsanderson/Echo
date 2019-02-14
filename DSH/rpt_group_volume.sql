/******
Initial Creation by:
Steven Sanderson, MPH - Manchu Technology Corp Inc.

FILE: rpt_group_volume.sql

Input Parameters:
None

Purpose:
Get volume of reporting group

Tables/Views:
[dbo].[DSH_INSURANCE_TABLE_W_REPORT_GROUPS]

Functions:
None

Revision History:

Author	Date	Version	Description
----	----	----	----
SSanderson	2019-02-13	v1	Initial Creation

******/
SELECT [REPORTING GROUP]
, COUNT([REPORTING GROUP])
FROM [dbo].[DSH_INSURANCE_TABLE_W_REPORT_GROUPS]
GROUP BY [REPORTING GROUP]

UNION

SELECT 'TOTAL'
, COUNT(*)
FROM DBO.DSH_INSURANCE_TABLE_W_REPORT_GROUPS
;