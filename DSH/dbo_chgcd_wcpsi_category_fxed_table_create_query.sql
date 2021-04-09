-- make new table dbo.ChgCd_wCPSI_Category_Fixed to correct for the 
-- missing zero (0) before the single digits 1-9
-- this corrects the join issue in the query that creates the
-- dbo.[SHH_DSH_CHARGES] table
SELECT [CPSI_CODE] = CASE
	WHEN [CPSI_CODE] = '1'
		THEN '01'
	WHEN [CPSI_CODE] = '2'
		THEN '02'
	WHEN [CPSI_CODE] = '3'
		THEN '03'
	WHEN [CPSI_CODE] = '4'
		THEN '04'
	WHEN [CPSI_CODE] = '5'
		THEN '05'
	WHEN [CPSI_CODE] = '6'
		THEN '06'
	WHEN [CPSI_CODE] = '7'
		THEN '07'
	WHEN [CPSI_CODE] = '8'
		THEN '08'
	WHEN [CPSI_CODE] = '9'
		THEN '09'
	ELSE [CPSI_CODE]
	END,
	UB92_HOSP,
	[DESCRIPTION],
	[NPAT#],
	[OUTPAT#],
	[CPSI_Category]
INTO [dbo].[ChgCd_wCPSI_Category_Fixed]
FROM [dbo].[ChgCd_wCPSI_Category]