--WARNING! ERRORS ENCOUNTERED DURING SQL PARSING!
/*DSH Project*/
USE [DSH];

/*Create Temp DSH Costs*/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

--/--------------------*/
DROP TABLE IF EXISTS [temp_DSH_Costs];
DROP TABLE IF EXISTS [temp_DSH_Costs2];
DROP TABLE IF EXISTS [2016_DSH_Costs];
GO

	SELECT a.[pa-pt-no-woscd],
		a.[PA-PT-NO-SCD],
		CAST(a.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(a.[PA-PT-NO-SCD] AS VARCHAR) AS 'PT-NO',
		A.[PA-UNIT-NO],
		A.[unit-date] AS 'UNIT-DATE',
		B.[PTACCT_TYPE] AS 'TYPE',
		A.[PA-DTL-TYPE-IND],
		CASE 
			-- when [PA-DTL-TYPE-IND] ='1' then 'Payments'
			-- when [PA-DTL-TYPE-IND] ='2'then 'Balance Transfer Payment' 
			--when [PA-DTL-TYPE-IND] ='3' then 'Adjustment'
			--  when [PA-DTL-TYPE-IND] ='4' then 'Balance Transfer Adj'
			--when [PA-DTL-TYPE-IND] ='5' then 'Statistical Charge'
			WHEN a.[PA-DTL-TYPE-IND] = '7'
				THEN 'Room Charge'
			WHEN a.[PA-DTL-TYPE-IND] = '8'
				THEN 'Ancillary Charge'
					--when [PA-DTL-TYPE-IND] ='9' then 'Late Stat Chg'
			WHEN a.[PA-DTL-TYPE-IND] = 'A'
				THEN 'Late Ancillary Chg'
			WHEN a.[PA-DTL-TYPE-IND] = 'B'
				THEN 'Late Room Chg'
			ELSE 'None'
			END AS Transaction_Type,
		A.[PA-DTL-SVC-CD],
		A.[PA-DTL-CDM-DESCRIPTION],
		A.[PA-DTL-CPT-CD],
		G.[CPT_H] AS 'CPT from CDM',
		--coalesce(A.[PA-DTL-CPT-CD],G.[CPT_H]) AS 'Adjusted CPT Code', /*for future reference*/
		CASE 
			WHEN len([PA-DTL-CPT-CD]) > '0'
				THEN A.[PA-DTL-CPT-CD]
			ELSE G.[CPT_H]
			END AS 'Adjusted CPT Code',
		A.[PA-DTL-REV-CD],
		G.[Rev_CD_(A) ] AS 'Rev Code from CDM',
		CASE 
			WHEN len([PA-DTL-REV-CD]) > '0'
				THEN A.[PA-DTL-REV-CD]
			ELSE G.[Rev_CD_(A) ]
			END AS 'Adjusted Rev Code',
		A.[PA-DTL-GL-NO],
		D.[CrAcctUnit],
		E.[ICR],
		CASE 
			WHEN a.[PA-DTL-TYPE-IND] IN ('7', 'B')
				THEN F.[R&B PER DIEM 2016]
			ELSE 0
			END AS 'PER DIEM',
		E.[Classification_for_2016_DSH],
		b.[PA-MED-REC-NO],
		Sum(A.[TOT-CHG-QTY]) AS 'SUM TOT-CHG-QTY',
		SUM(A.[TOT-CHARGES]) AS 'SUM OF TOT CHG',
		SUM(A.[TOT-PROF-FEES]) AS 'SUM OF TOT PROF FEES',
		SUM(A.[TOT-CHARGES]) + SUM(A.[TOT-PROF-FEES]) AS 'Sum_of_Chargesand_Prof_Fees'
	--SUM(H.[TOT-PAYMENTS]) AS 'SUM OF TOT PYMTS' (payments will be duplicated by encounter if pulled here)
	INTO [temp_DSH_Costs]
	FROM [dbo].[2016_DSH_Charges] a
	LEFT JOIN [dbo].[Encounters_For_DSH] b ON a.[pa-pt-no-woscd] = b.[pa-pt-no-woscd]
	LEFT JOIN [dbo].[Copy_of_CDM_18DEC_for_DSH] g ON A.[PA-DTL-SVC-CD] = G.[Service_Code]
	LEFT JOIN [dbo].[2017_GL_Key_Table] d ON A.[PA-DTL-GL-NO] = d.[GLKey]
	LEFT JOIN [dbo].[2017_ICR_Rollup_with_Room_and_Board_Classifications_for_DSH] E ON D.[CrAcctUnit] = E.[Cost_Center_wExtra_Zeros]
	LEFT JOIN [dbo].[2016_Per_Diem_for_DSH] F ON E.[ICR] = F.[ICR CC]
	--left join [dbo].[2016_DSH_Payments] H On a.[PA-PT-NO-WOSCD]= h.[pa-pt-no-woscd]
	GROUP BY a.[pa-pt-no-woscd],
		a.[PA-PT-NO-SCD],
		A.[PA-UNIT-NO],
		a.[unit-date],
		B.[PTACCT_TYPE],
		A.[PA-DTL-TYPE-IND],
		A.[PA-DTL-GL-NO],
		A.[PA-DTL-REV-CD],
		A.[PA-DTL-CPT-CD],
		A.[PA-DTL-SVC-CD],
		A.[PA-DTL-CDM-DESCRIPTION],
		G.[CPT_H],
		d.[CrAcctUnit],
		E.[ICR],
		E.[Classification_for_2016_DSH],
		b.[pa-med-rec-no],
		F.[R&B PER DIEM 2016],
		G.[Rev_CD_(A) ];

/*Add RCC*/
SELECT [pa-pt-no-woscd],
	[PA-PT-NO-SCD],
	[PT-NO],
	[PA-UNIT-NO],
	[UNIT-DATE],
	[TYPE],
	[PA-DTL-TYPE-IND],
	[Transaction_Type],
	[PA-DTL-SVC-CD],
	[PA-DTL-CDM-DESCRIPTION],
	[PA-DTL-CPT-CD],
	[CPT from CDM],
	[Adjusted CPT Code],
	[PA-DTL-REV-CD],
	[Rev Code from CDM],
	[Adjusted Rev Code],
	[PA-DTL-GL-NO],
	[CrAcctUnit],
	[ICR],
	[PER DIEM],
	[RCC],
	[Classification_for_2016_DSH],
	[PA-MED-REC-NO],
	[SUM TOT-CHG-QTY],
	[SUM OF TOT CHG],
	[SUM OF TOT PROF FEES],
	[Sum_of_Chargesand_Prof_Fees]
	--,[SUM OF TOT PYMTS]
	,
	CASE 
		WHEN [PA-DTL-TYPE-IND] IN ('8', 'A')
			THEN c.[RCC]
		ELSE 0
		END AS 'RCC_For_DSH'
INTO temp_DSH_Costs2
FROM [DSH].[dbo].[temp_DSH_Costs] a
LEFT JOIN [dbo].[2016_RCCs_for_DSH] c ON a.[Adjusted Rev Code] = c.[SORT_BY_REV_CODE];

/*Finalize the DSH Cost Table*/
SELECT COSTS.[pa-pt-no-woscd],
	COSTS.[PA-PT-NO-SCD],
	COSTS.[PT-NO],
	COSTS.[PA-UNIT-NO],
	COSTS.[UNIT-DATE],
	COSTS.[TYPE],
	COSTS.[PA-DTL-TYPE-IND],
	COSTS.[Transaction_Type],
	COSTS.[PA-DTL-SVC-CD],
	COSTS.[PA-DTL-CDM-DESCRIPTION],
	COSTS.[PA-DTL-CPT-CD],
	COSTS.[CPT from CDM],
	COSTS.[Adjusted CPT Code],
	COSTS.[PA-DTL-REV-CD],
	COSTS.[Rev Code from CDM],
	COSTS.[Adjusted Rev Code],
	COSTS.[PA-DTL-GL-NO],
	COSTS.[CrAcctUnit],
	COSTS.[ICR],
	COSTS.[SUM OF TOT CHG],
	COSTS.[SUM OF TOT PROF FEES],
	COSTS.[Sum_of_Chargesand_Prof_Fees]
	--,[SUM OF TOT PYMTS]
	,
	COSTS.[PER DIEM],
	COSTS.[RCC_For_DSH],
	round(CASE 
			WHEN COSTS.[RCC_For_DSH] > 0
				THEN COSTS.[RCC_For_DSH] * COSTS.[Sum_of_Chargesand_Prof_Fees]
			ELSE COSTS.[PER DIEM] * COSTS.[SUM TOT-CHG-QTY]
			END, 2) AS 'Cost',
	COSTS.[Classification_for_2016_DSH],
	COSTS.[PA-MED-REC-NO],
	COSTS.[SUM TOT-CHG-QTY],
	RPTGRP.[REPORTING GROUP]
INTO [2016_DSH_Costs]
FROM [DSH].[dbo].[temp_DSH_Costs2] AS COSTS 
LEFT OUTER JOIN DBO.[DSH_INSURANCE_TABLE_W_REPORT_GROUPS] AS RPTGRP
ON COSTS.[PA-PT-NO-WOSCD] = RPTGRP.[PA-PT-NO-WOSCD]
	AND COSTS.[PA-PT-NO-SCD] = RPTGRP.[PA-PT-NO-SCD]
