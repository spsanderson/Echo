/*
1_pt_acct_v_query_new_w_custom_insurance.sql
*/

--STEP1: RUN U:\Echo\1_CREATE_Encounters For Reporting_SMS_Database_W_Linked_Server_References_NEW_02-03-2020.sql

--STEP2: RUN U:\Echo\1_CREATE_Unit Partitions Table_W_Linked_Server_References_Query.sql*****IGNORE

--STEP3: RUN U:\Echo\1_CREATE_Payments_At_Ins_Plan_Level_For_Reporting_W_Linked_Server_References.sql

--STEP4: RUN U:\Echo\Create Custom Insurance Table_SM_VERSION_9.sql

 

 

---------------------------------------------------------------------------------------------------------------------------------------------------------

 

--/*Create ERS Denials Table*/

 

--IF OBJECT_ID('[SMS].dbo.[ERS_DenIals]','U') IS NOT NULL
--DROP TABLE [SMS].dbo.[ERS_Denials];
--GO
--CREATE TABLE [SMS].dbo.[ERS_Denials]
--(
--[PA-PT-NO-WOSCD] VARCHAR(12) NOT NULL,
--[PA-PT-NO-SCD] VARCHAR(1) NOT NULL,
--[PT_NO] VARCHAR(13) NOT NULL,
--[PA-CTL-PAA-XFER-DATE] DATETIME NULL,
--[UNIT_DATE] DATETIME NULL,
--[DENIAL_IND] CHAR(1) NULL
--)
--;
--INSERT INTO [SMS].dbo.[ERS_Denials]([PA-PT-NO-WOSCD],[PA-PT-NO-SCD],[PT_NO],[PA-CTL-PAA-XFER-DATE],[UNIT_DATE],[DENIAL_IND])
--  SELECT [PA-PT-NO-WOSCD],
--  [PA-PT-NO-SCD-1] AS 'PA-PT-NO-SCD',
--  CAST([PA-PT-NO-WOSCD] AS VARCHAR) + CAST([PA-PT-NO-SCD-1] AS VARCHAR) AS 'PT_NO',
--  [pa-ctl-paa-xfer-date],
--  [PA-DTL-UNIT-DATE] AS 'UNIT_DATE',
--  'Y' as 'DENIAL_IND'
--  FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Active].dbo.[DetailInformation] A
--  WHERE [pa-dtl-svc-cd-woscd] IN ('80003', '80004', '80012', '80013', '80017', '80018', '80020', '80022', '80024', '80028', '80031', '80046', '80047', '80050', '80057', '80060', '80063', '80067', '80068', '80070',
--  '80072', '80077', '80078', '80092', '80096', '80099', '80107', '80112', '80120', '80140', '81003', '81005', '82001', '82002', '82003', '82006', '82007', '82008', '82009', '82010', '82011', '82012', '82013',
--  '82014', '82015', '82016', '82017', '82018', '82019', '82020', '82021', '82022', '82023', '82024', '82025', '82026', '82027', '82028', '82029', '82030', '82031', '82032', '82033', '82333', '83001', '83002', '83003',
--  '83004', '83005', '85000', '85002', '85003', '85005', '86000', '86001', '86002', '86003', '86004', '86005', '86006', '86007', '86008', '86009', '86010', '86011', '86012', '86013')
--  GROUP BY [PA-PT-NO-WOSCD] , [PA-PT-NO-SCD-1], [PA-CTL-PAA-XFER-DATE], [PA-DTL-UNIT-DATE]
--  UNION
--  SELECT [PA-PT-NO-WOSCD],
--  [PA-PT-NO-SCD-1] AS 'PA-PT-NO-SCD',
--  CAST([PA-PT-NO-WOSCD] AS VARCHAR) + CAST([PA-PT-NO-SCD-1] AS VARCHAR) AS 'PT_NO',
--  [pa-ctl-paa-xfer-date],
--  [PA-DTL-UNIT-DATE] AS 'UNIT_DATE',
--  'Y' as 'DENIAL_IND'
--  FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Archive].dbo.[DetailInformation] A
--  WHERE [pa-dtl-svc-cd-woscd] IN ('80003', '80004', '80012', '80013', '80017', '80018', '80020', '80022', '80024', '80028', '80031', '80046', '80047', '80050', '80057', '80060', '80063', '80067', '80068', '80070',
--  '80072', '80077', '80078', '80092', '80096', '80099', '80107', '80112', '80120', '80140', '81003', '81005', '82001', '82002', '82003', '82006', '82007', '82008', '82009', '82010', '82011', '82012', '82013',
--  '82014', '82015', '82016', '82017', '82018', '82019', '82020', '82021', '82022', '82023', '82024', '82025', '82026', '82027', '82028', '82029', '82030', '82031', '82032', '82033', '82333', '83001', '83002', '83003',
--  '83004', '83005', '85000', '85002', '85003', '85005', '86000', '86001', '86002', '86003', '86004', '86005', '86006', '86007', '86008', '86009', '86010', '86011', '86012', '86013')
--   GROUP BY [PA-PT-NO-WOSCD] , [PA-PT-NO-SCD-1], [PA-CTL-PAA-XFER-DATE], [PA-DTL-UNIT-DATE]
--  GO


;

 

--SELECT * FROM [SMS].dbo.[ERS_Denials]

 

--USE [Echo_ACTIVE];

------------------------------------------------------------------------------------------------------------------------------------------------------

 

/*Create Encounters for Reporting Non-Unit_Preliminary*/

IF OBJECT_ID('tempdb.dbo.#Encounters_For_Reporting_NonUnit_A','U') IS NOT NULL
DROP TABLE #Encounters_For_Reporting_NonUnit_A;
GO

SELECT *
INTO [#Encounters_For_Reporting_NonUnit_A]
FROM [SMS].dbo.[Encounters_For_Reporting]
WHERE [pa-unit-no] IS NULL
--AND [pt_no] = '10128434528'

/*Create Encounters for Reporting Non-Unit*/

IF OBJECT_ID('tempdb.dbo.[#Encounters_For_Reporting_NonUnit]','U') IS NOT NULL
DROP TABLE dbo.[#Encounters_For_Reporting_NonUnit];
GO

SELECT a.*,
	b.[Denial_Ind]
INTO dbo.[#Encounters_For_Reporting_NonUnit]
FROM [#Encounters_For_Reporting_NonUnit_A] AS a
LEFT OUTER JOIN [SMS].dbo.[ERS_Denials] b ON a.[pa-pt-no-woscd] = b.[pa-pt-no-woscd]
WHERE a.[pa-unit-no] IS NULL
--AND [pt_no] = '10128434528'
GROUP BY a.[PA-PT-NO-WOSCD],
	a.[PA-PT-NO-SCD],
	a.[PT_NO],
	[PA-UNIT-STS],
	[FILE_TYPE],
	a.[PA-CTL-PAA-XFER-DATE],
	[pa-unit-no],
	[pa-med-rec-no],
	[pa-pt-name],
	[admit_date],
	[dsch_date],
	[pa-unit-date],
	[start_unit_date],
	[end_unit_date],
	[pa-acct-type],
	[1st_bl_date],
	[balance],
	[pt_balance],
	[tot_chgs],
	[pa-bal-tot-pt-pay-amt],
	[ptacct_type],
	[pa-fc],
	[fc_description],
	[pa-hosp-svc],
	[pa-acct-sub-type],
	[pa-pt-representative],
	b.[Denial_ind],
	a.[pa-pay-scale]
GO

--SELECT * from [SMS].dbo.[Encounters_For_Reporting_NonUnit]
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

/*Create Encounters for Reporting Unit*/

IF OBJECT_ID('tempdb.dbo.#Encounters_For_Reporting_Unit','U') IS NOT NULL
DROP TABLE #Encounters_For_Reporting_Unit;
GO

SELECT *
INTO [#Encounters_For_Reporting_Unit]
FROM [SMS].dbo.[Encounters_For_Reporting]
WHERE [pa-unit-no] IS NOT NULL
--AND [pt_no] = '10128434528'

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

/*Create Encounters for Reporting Unit*/

IF OBJECT_ID('tempdb.dbo.#Encounters_For_Reporting_Open_Unit','U') IS NOT NULL
DROP TABLE #Encounters_For_Reporting_Open_Unit;
GO

SELECT *
INTO [#Encounters_For_Reporting_Open_Unit]
FROM [SMS].dbo.[Encounters_For_Reporting]
WHERE [pa-unit-no] = '0'
	--AND [pt_no] = '10128434528'
	--SELECT *  FROM #Encounters_For_Reporting_Open_Unit
	--WHERE [Tot_Chgs] > '0'
GO

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

/*Create ERS Denials Table*/

------------

 

/****** Script for SelectTopNRows command from SSMS  ******/

 

/*Create ERS_Denials Table*/

--IF OBJECT_ID('tempdb.dbo.#ERS_Denials','U') IS NOT NULL
--DROP TABLE #ERS_Denials;
--GO
--CREATE TABLE dbo.[#ERS_Denials]
--(
--[PA-PT-NO-WOSCD] VARCHAR(12) NOT NULL,
--[PA-PT-NO-SCD-1] VARCHAR(1) NOT NULL,
--[PT_NO] VARCHAR(13) NOT NULL,
--[PA-CTL-PAA-XFER-DATE] DATETIME NULL,
--[UNIT_DATE] DATETIME NULL,
--[DENIAL_IND] CHAR(1) NULL
--)
--;
--INSERT INTO dbo.[#ERS_Denials]
--  SELECT b.[PA-PT-NO-WOSCD],
--  b.[PA-PT-NO-SCD],
--  CAST(b.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(b.[PA-PT-NO-SCD] AS VARCHAR) AS 'PT_NO',
--  b.[pa-ctl-paa-xfer-date],
--  [PA-UNIT-DATE] AS 'UNIT_DATE',
--  'Y' as 'DENIAL_IND'
--  FROM [#Encounters_For_Reporting_Unit] b inner join [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Active].dbo.[DetailInformation] A
--  ON b.[pa-pt-no-woscd] =a.[pa-pt-no-woscd] and b.[pa-ctl-paa-xfer-date]=a.[pa-ctl-paa-xfer-date] and b.[pa-unit-date] = a.[pa-dtl-unit-date]
--  WHERE (a.[pa-dtl-svc-cd-woscd] IN ('80003', '80004', '80012', '80013', '80017', '80018', '80020', '80022', '80024', '80028', '80031', '80046', '80047', '80050', '80057', '80060', '80063', '80067', '80068', '80070',
--  '80072', '80077', '80078', '80092', '80096', '80099', '80107', '80112', '80120', '80140', '81003', '81005', '82001', '82002', '82003', '82006', '82007', '82008', '82009', '82010', '82011', '82012', '82013',
--  '82014', '82015', '82016', '82017', '82018', '82019', '82020', '82021', '82022', '82023', '82024', '82025', '82026', '82027', '82028', '82029', '82030', '82031', '82032', '82033', '82333', '83001', '83002', '83003',
--  '83004', '83005', '85000', '85002', '85003', '85005', '86000', '86001', '86002', '86003', '86004', '86005', '86006', '86007', '86008', '86009', '86010', '86011', '86012', '86013')
--  AND b.[pa-unit-sts] = 'U')
--  GROUP BY b.[PA-PT-NO-WOSCD] , b.[PA-PT-NO-SCD], b.[PA-CTL-PAA-XFER-DATE], b.[PA-UNIT-DATE]
-- UNION
--  SELECT A.[PA-PT-NO-WOSCD],
--  A.[PA-PT-NO-SCD-1],
--  CAST(A.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(A.[PA-PT-NO-SCD-1] AS VARCHAR) AS 'PT_NO',
--  a.[pa-ctl-paa-xfer-date],
--  [PA-DTL-UNIT-DATE] AS 'UNIT_DATE',
--  'Y' as 'DENIAL_IND'
-- FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Archive].dbo.[DetailInformation] A INNER JOIN [#Encounters_For_Reporting_Unit] b
--  ON a.[pa-pt-no-woscd] =b.[pa-pt-no-woscd] and a.[pa-ctl-paa-xfer-date]=b.[pa-ctl-paa-xfer-date] and a.[pa-dtl-unit-date] = b.[pa-unit-date]
--  WHERE ([pa-dtl-svc-cd-woscd] IN ('80003', '80004', '80012', '80013', '80017', '80018', '80020', '80022', '80024', '80028', '80031', '80046', '80047', '80050', '80057', '80060', '80063', '80067', '80068', '80070',
--  '80072', '80077', '80078', '80092', '80096', '80099', '80107', '80112', '80120', '80140', '81003', '81005', '82001', '82002', '82003', '82006', '82007', '82008', '82009', '82010', '82011', '82012', '82013',
--  '82014', '82015', '82016', '82017', '82018', '82019', '82020', '82021', '82022', '82023', '82024', '82025', '82026', '82027', '82028', '82029', '82030', '82031', '82032', '82033', '82333', '83001', '83002', '83003',
--  '83004', '83005', '85000', '85002', '85003', '85005', '86000', '86001', '86002', '86003', '86004', '86005', '86006', '86007', '86008', '86009', '86010', '86011', '86012', '86013')
--  AND b.[pa-unit-sts] = 'U')
--  GROUP BY A.[PA-PT-NO-WOSCD] , A.[PA-PT-NO-SCD-1], A.[PA-CTL-PAA-XFER-DATE], A.[PA-DTL-UNIT-DATE]
--  UNION
--   SELECT A.[PA-PT-NO-WOSCD],
--  A.[PA-PT-NO-SCD-1],
--  CAST(A.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(A.[PA-PT-NO-SCD-1] AS VARCHAR) AS 'PT_NO',
--  a.[pa-ctl-paa-xfer-date],
--  NULL as 'UNIT_DATE',
--  'Y' as 'DENIAL_IND'
--  FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Active].dbo.[DetailInformation] A INNER JOIN [#Encounters_For_Reporting_NonUnit] B
--  ON a.[pa-pt-no-woscd] =b.[pa-pt-no-woscd] and a.[pa-ctl-paa-xfer-date]=b.[pa-ctl-paa-xfer-date]
--  WHERE (a.[pa-dtl-svc-cd-woscd] IN ('80003', '80004', '80012', '80013', '80017', '80018', '80020', '80022', '80024', '80028', '80031', '80046', '80047', '80050', '80057', '80060', '80063', '80067', '80068', '80070',
--  '80072', '80077', '80078', '80092', '80096', '80099', '80107', '80112', '80120', '80140', '81003', '81005', '82001', '82002', '82003', '82006', '82007', '82008', '82009', '82010', '82011', '82012', '82013',
--  '82014', '82015', '82016', '82017', '82018', '82019', '82020', '82021', '82022', '82023', '82024', '82025', '82026', '82027', '82028', '82029', '82030', '82031', '82032', '82033', '82333', '83001', '83002', '83003',
--  '83004', '83005', '85000', '85002', '85003', '85005', '86000', '86001', '86002', '86003', '86004', '86005', '86006', '86007', '86008', '86009', '86010', '86011', '86012', '86013')
--  AND b.[pa-unit-sts] <> 'U')
--  GROUP BY A.[PA-PT-NO-WOSCD] , A.[PA-PT-NO-SCD-1], A.[PA-CTL-PAA-XFER-DATE]
--  UNION
--   SELECT A.[PA-PT-NO-WOSCD],
--  A.[PA-PT-NO-SCD-1],
--  CAST(A.[PA-PT-NO-WOSCD] AS VARCHAR) + CAST(A.[PA-PT-NO-SCD-1] AS VARCHAR) AS 'PT_NO',
--  a.[pa-ctl-paa-xfer-date],
--  NULL as 'UNIT_DATE',
--  'Y' as 'DENIAL_IND'
--  FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Archive].dbo.[DetailInformation] A INNER JOIN [#Encounters_For_Reporting_NonUnit] B
--  ON a.[pa-pt-no-woscd] =b.[pa-pt-no-woscd] and a.[pa-ctl-paa-xfer-date]=b.[pa-ctl-paa-xfer-date]
--  WHERE (a.[pa-dtl-svc-cd-woscd] IN ('80003', '80004', '80012', '80013', '80017', '80018', '80020', '80022', '80024', '80028', '80031', '80046', '80047', '80050', '80057', '80060', '80063', '80067', '80068', '80070',
--  '80072', '80077', '80078', '80092', '80096', '80099', '80107', '80112', '80120', '80140', '81003', '81005', '82001', '82002', '82003', '82006', '82007', '82008', '82009', '82010', '82011', '82012', '82013',
--  '82014', '82015', '82016', '82017', '82018', '82019', '82020', '82021', '82022', '82023', '82024', '82025', '82026', '82027', '82028', '82029', '82030', '82031', '82032', '82033', '82333', '83001', '83002', '83003',
--  '83004', '83005', '85000', '85002', '85003', '85005', '86000', '86001', '86002', '86003', '86004', '86005', '86006', '86007', '86008', '86009', '86010', '86011', '86012', '86013')
--  AND b.[pa-unit-sts] <> 'U')
--  GROUP BY A.[PA-PT-NO-WOSCD] , A.[PA-PT-NO-SCD-1], A.[PA-CTL-PAA-XFER-DATE]
--  GO
--  SELECT * FROM [#ERS_Denials]
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------SELECT PT_NO,
------COUNT([pa-pt-no-woscd])
------FROM [SMS].dbo.[Encounters_For_Reporting]
------WHERE [tot_chgs] <> '0'
------AND [pa-unit-no] is not null
------GROUP BY [Pt_No]
/*Create Temp Table With Emblem Claim Nos*/
--IF OBJECT_ID('tempdb.dbo.#Emblem_Claim_Nos','U') IS NOT NULL
--DROP TABLE #Emblem_Claim_Nos;
--GO
--/*Create Temp Table With Last Emblem Claim No*/
--SELECT [pa-pt-no-woscd],
--[pa-smart-date],
--substring([pa-smart-comment],19,9) as 'Empire_Last_Claim_No',
--RANK() OVER (PARTITION BY [pa-pt-no-woscd] ORDER BY [pa-smart-date] desc) as 'Rank'
--INTO #Emblem_Claim_Nos
--FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Active].dbo.[AccountComments]
--WHERE [pa-smart-comment] like '%GHI         ICN%' OR [pa-smart-comment] like '%HIP         ICN%'
--group by [pa-pt-no-woscd],
--[pa-smart-date],
--substring([pa-smart-comment],19,9)


 

------------------------------------------------------------------------------------------------------------------------------------------------------

IF OBJECT_ID('tempdb.dbo.#CUSTOM_INSURANCE_SM_3_NonUnit','U') IS NOT NULL
DROP TABLE #CUSTOM_INSURANCE_SM_3_NonUnit;
GO

SELECT *
INTO #CUSTOM_INSURANCE_SM_3_NonUnit
FROM [SMS].dbo.[CUSTOM_INSURANCE_SM_ALT] --_3]
WHERE (
		[pa-unit-date] IS NULL
		OR [pa-unit-no] = '0'
		)
	--AND [pa-pt-no-woscd] = '1012843452')


 

 

------------------------------------------------------------------------------------------------------------------------------------------------------

IF OBJECT_ID('tempdb.dbo.#SSI_Primary_Claim_Release_Date','U') IS NOT NULL
DROP TABLE #SSI_Primary_Claim_Release_Date;
GO

CREATE TABLE dbo.[#SSI_Primary_Claim_Release_Date] (
	[Pt_No] VARCHAR(14) NOT NULL,
	[PA_Ctl_PAA_Xfer_Date] DATETIME NULL,
	[SSI_Last_Ins_Bill_Date] DATETIME NULL,
	[Rank] VARCHAR(4) NULL
	);

INSERT INTO dbo.[#SSI_Primary_Claim_Release_Date] (
	[Pt_No],
	[PA_Ctl_PAA_Xfer_Date],
	[SSI_Last_Ins_Bill_Date],
	[Rank]
	)
SELECT a.[Pt_No],
	a.[PA-CTL-PAA-XFER-DATE],
	b.[pa-smart-date] AS 'SSI_Last_Ins_Bill_Date',
	RANK() OVER (
		PARTITION BY b.[pa-pt-no-woscd] ORDER BY b.[pa-smart-date] DESC
		) AS 'Rank'
FROM dbo.[#Encounters_For_Reporting_NonUnit] a
LEFT OUTER JOIN [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Active].dbo.[AccountComments] b ON a.[pa-pt-no-woscd] = b.[pa-pt-no-woscd]
	AND a.[PA-CTL-PAA-XFER-DATE] = b.[pa-ctl-paa-xfer-date]
WHERE RIGHT(RTRIM(b.[pa-smart-comment]), 3) IN ('PEH', 'PLH')

UNION

SELECT a.[Pt_No],
	a.[PA-CTL-PAA-XFER-DATE],
	b.[pa-smart-date] AS 'SSI_Last_Ins_Bill_Date',
	RANK() OVER (
		PARTITION BY b.[pa-pt-no-woscd] ORDER BY b.[pa-smart-date] DESC
		) AS 'Rank'
FROM dbo.[#Encounters_For_Reporting_NonUnit] a
LEFT OUTER JOIN [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Archive].dbo.[AccountComments] b ON a.[pa-pt-no-woscd] = b.[pa-pt-no-woscd]
	AND a.[PA-CTL-PAA-XFER-DATE] = b.[pa-ctl-paa-xfer-date]
WHERE RIGHT(RTRIM(b.[pa-smart-comment]), 3) IN ('PEH', 'PLH')

-------------------------------------------------------------------------------------------------------------------------------------------------------

 

/*Create Insurance Final Ins Table*/
IF OBJECT_ID('SMS.dbo.Pt_Accounting_Reporting_ALT', 'U') IS NOT NULL
TRUNCATE TABLE [SMS].dbo.[Pt_Accounting_Reporting_ALT];
;

 --CREATE TABLE [SMS].dbo.[Pt_Accounting_Reporting_ALT]
--(
--[Pt_No] VARCHAR(14) NOT NULL,
--[Unit_No] VARCHAR(6) NULL,
--[PA_Ctl_PAA_Xfer_Date] DATETIME NULL,--ADD**************************
--[MRN] CHAR(12) NULL,
--[Pt_Name] CHAR(65) NULL,
--[Admit_Date] DATETIME NOT NULL,
--[Dsch_Date] DATETIME NULL,
--[Unit_Date] DATETIME NULL,
--[Acct_Type] CHAR(10) NULL,
--[Age_Bucket] VARCHAR(55) NULL,
--[First_Ins_Bl_Date] DATETIME NULL,
--[SSI_Last_Ins_Bill_Date] DATETIME NULL,
--[Days_To_First_Paid] DECIMAL (6,0) NULL,
--[Days_To_Secondary_Payment] DECIMAL (6,0) NULL,
--[Balance] MONEY NULL,
--[COB1_Balance] MONEY NULL,
--[Pt_Balance] MONEY NULL,
--[Tot_Chgs] MONEY NULL,
--[Ins_Pay_Amt] MONEY NULL,
--[Tot_Pay_Amt] MONEY NULL,
--[File] VARCHAR(30) NULL,
--[FC] VARCHAR(10) NULL,
--[FC_Description] VARCHAR(75) NULL,
--[Hosp_Svc] VARCHAR(3) NULL,
--[Hosp_Svc_Description] VARCHAR(75) NULL,
--[COB_1] CHAR(3) NULL,--ADD*******************************
--[Ins1_Cd] CHAR(4) NULL,
--[Ins1_Member_ID] CHAR(30) NULL,
--[Ins1_Pol_No] CHAR(30) NULL,
--[Ins1_Subscr_Group_ID] CHAR(30) NULL,
--[Ins1_Grp_No] CHAR(30) NULL,
--[Ins1_Balance] MONEY NULL,
--[Pyr1_Pay_Amt] MONEY NULL,
--[Ins1_First_Paid] DATETIME NULL,
--[COB_2] CHAR(2) NULL,--ADD***********************
--[Ins2_Cd] CHAR(4) NULL,
--[Ins2_Member_ID] CHAR(30) NULL,---ADD***********************
--[Ins2_Pol_No] CHAR(30) NULL,--ADD*******************
--[Ins2_Subscr_Group_ID] CHAR(30) NULL,--ADD*******************
--[Ins2_Grp_No] CHAR(30) NULL,--ADD*****************************
--[Ins2_Balance] MONEY NULL,--ADD**********************************
--[Pyr2_Pay_Amt] MONEY NULL,
--[Ins2_First_Paid] DATETIME NULL,
--[COB_3] CHAR(2) NULL,--ADD***********************************
--[Ins3_Cd] CHAR(4) NULL,
--[Ins3_Member_ID] CHAR(30) NULL,
--[Ins3_Pol_No] CHAR(30) NULL,
--[Ins3_Subscr_Group_ID] CHAR(30) NULL,
--[Ins3_Grp_No] CHAR(30) NULL,
--[Ins3_Balance] MONEY  NULL,
--[Pyr3_Pay_Amt] MONEY NULL,
--[Ins3_First_Paid] DATETIME NULL,
--[COB_4] CHAR(2) NULL,--ADD*****************************************
--[Ins4_Cd] CHAR(4) NULL,
--[Ins4_Member_ID] CHAR(30) NULL,--ADD******************************
--[Ins4_Pol_No] CHAR(30) NULL,--ADD********************************
--[Ins4_Subscr_Group_ID] CHAR(30) NULL,--ADD***************************
--[Ins4_Grp_No] CHAR(30) NULL,--ADD**************************
--[Ins4_Balance] MONEY NULL,
--[Pyr4_Pay_Amt] MONEY NULL,
--[Ins4_First_Paid] DATETIME NULL,
--[Pt_Representative] CHAR(3) NULL
--)
	;

INSERT INTO [SMS].dbo.[Pt_Accounting_Reporting_ALT] (
	[Pt_No],
	[Unit_No],
	[PA_Ctl_PAA_Xfer_Date],
	[MRN],
	[Pt_Name],
	[Admit_Date],
	[Dsch_Date],
	[Unit_Date],
	[Acct_Type],
	[Age_Bucket],
	[First_Ins_Bl_Date],
	[SSI_Last_Ins_Bill_Date],
	[Days_To_First_Paid],
	[Days_To_Secondary_Payment],
	[Balance],
	[COB1_Balance],
	[Pt_Balance],
	[Tot_Chgs],
	[Ins_Pay_Amt],
	[Tot_Pay_Amt],
	[File],
	[FC],
	[FC_Description],
	[Hosp_Svc],
	[Hosp_Svc_Description],
	[COB_1],
	[Ins1_Cd],
	[Ins1_Member_ID],
	[Ins1_Pol_No],
	[Ins1_Subscr_Group_ID],
	[Ins1_Grp_No],
	[Ins1_Balance],
	[Pyr1_Pay_Amt],
	[Ins1_First_Paid],
	[COB_2],
	[Ins2_Cd],
	[Ins2_Member_ID],
	[Ins2_Pol_No],
	[Ins2_Subscr_Group_ID],
	[Ins2_Grp_No],
	[Ins2_Balance],
	[Pyr2_Pay_Amt],
	[Ins2_First_Paid],
	[COB_3],
	[Ins3_Cd],
	[Ins3_Member_ID],
	[Ins3_Pol_No],
	[Ins3_Subscr_Group_ID],
	[Ins3_Grp_No],
	[Ins3_Balance],
	[Pyr3_Pay_Amt],
	[Ins3_First_Paid],
	[COB_4],
	[Ins4_Cd],
	[Ins4_Member_ID],
	[Ins4_Pol_No],
	[Ins4_Subscr_Group_ID],
	[Ins4_Grp_No],
	[Ins4_Balance],
	[Pyr4_Pay_Amt],
	[Ins4_First_Paid],
	[Pt_Representative]
	)
SELECT cast(a.[PA-PT-NO-WOSCD] AS VARCHAR) + cast(a.[PA-PT-NO-SCD] AS VARCHAR) AS 'Pt_No',
	a.[PA-UNIT-NO],
	a.[PA-CTL-PAA-XFER-DATE],
	a.[pa-med-rec-no] AS 'MRN',
	a.[pa-pt-name] AS 'Pt_Name',
	a.[admit_date] AS 'Admit_Date',
	a.[dsch_date] AS 'Dsch_Date',
	a.[pa-unit-date] AS 'Unit_Date',
	CASE 
		WHEN a.[pa-acct-type] IN ('0', '6', '7')
			THEN 'OP' --0=OP; 6=OP BAD DEBT; 7=OP HISTORIC
		WHEN a.[pa-acct-type] IN ('1', '2', '4', '8')
			THEN 'IP' --1=IP; 2=A/R; 4=I/P BAD DEBT; 8=I/P HISTORIC
		ELSE ''
		END AS 'Acct_Type',
	CASE 
		WHEN a.[pa-acct-type] <> 1
			AND datediff(day, COALESCE(a.[pa-unit-date], a.[dsch_date], a.[admit_date]), getdate()) BETWEEN '0'
				AND '30'
			THEN '1_0-30'
		WHEN a.[pa-acct-type] <> 1
			AND datediff(day, COALESCE(a.[pa-unit-date], a.[dsch_date], a.[admit_date]), getdate()) BETWEEN '31'
				AND '60'
			THEN '2_31-60'
		WHEN a.[pa-acct-type] <> 1
			AND datediff(day, COALESCE(a.[pa-unit-date], a.[dsch_date], a.[admit_date]), getdate()) BETWEEN '61'
				AND '90'
			THEN '3_61-90'
		WHEN a.[pa-acct-type] <> 1
			AND datediff(day, COALESCE(a.[pa-unit-date], a.[dsch_date], a.[admit_date]), getdate()) BETWEEN '91'
				AND '120'
			THEN '4_91-120'
		WHEN a.[pa-acct-type] <> 1
			AND datediff(day, COALESCE(a.[pa-unit-date], a.[dsch_date], a.[admit_date]), getdate()) BETWEEN '121'
				AND '150'
			THEN '5_121-150'
		WHEN a.[pa-acct-type] <> 1
			AND datediff(day, COALESCE(a.[pa-unit-date], a.[dsch_date], a.[admit_date]), getdate()) BETWEEN '151'
				AND '180'
			THEN '6_151-180'
		WHEN a.[pa-acct-type] <> 1
			AND datediff(day, COALESCE(a.[pa-unit-date], a.[dsch_date], a.[admit_date]), getdate()) BETWEEN '181'
				AND '210'
			THEN '7_181-210'
		WHEN a.[pa-acct-type] <> 1
			AND datediff(day, COALESCE(a.[pa-unit-date], a.[dsch_date], a.[admit_date]), getdate()) BETWEEN '211'
				AND '240'
			THEN '8_211-240'
		WHEN a.[pa-acct-type] <> 1
			AND datediff(day, COALESCE(a.[pa-unit-date], a.[dsch_date], a.[admit_date]), getdate()) BETWEEN '241'
				AND '365'
			THEN '9_241-365'
		WHEN a.[pa-acct-type] <> 1
			AND datediff(day, coalesce(a.[pa-unit-date], a.[dsch_date], a.[admit_date]), getdate()) BETWEEN '366'
				AND '525'
			THEN '90_1yr-1.5yrs'
		WHEN a.[pa-acct-type] <> 1
			AND datediff(day, coalesce(a.[pa-unit-date], a.[dsch_date], a.[admit_date]), getdate()) BETWEEN '526'
				AND '720'
			THEN '91_1.5-2yrs'
		WHEN a.[pa-acct-type] <> 1
			AND datediff(day, coalesce(a.[pa-unit-date], a.[dsch_date], a.[admit_date]), getdate()) > '720'
			THEN '91_2+yrs'
		WHEN a.[pa-acct-type] = 1
			THEN 'In House/DNFB'
		ELSE ''
		END AS 'Age_Bucket',
	a.[1st_bl_date] AS 'First_Ins_Bl_Date',
	'' AS 'SSI_Last_Ins_Bill_Date',
	CASE 
		WHEN a.[1st_bl_date] IS NOT NULL
			AND c.[ins1_first_paid] IS NOT NULL
			THEN datediff(dd, a.[1st_bl_date], c.[ins1_First_Paid])
		ELSE ''
		END AS 'Days_To_First_Paid',
	CASE 
		WHEN c.[ins1_pymts] < '0'
			AND c.[ins2_pymts] < '0'
			THEN DATEDIFF(dd, a.[1st_Bl_Date], [Ins2_First_Paid])
		ELSE ''
		END AS 'Days_To_Secondary_Pymt',
	COALESCE((b.[pa-unit-ins1-bal] + b.[pa-unit-ins2-bal] + b.[pa-unit-ins3-bal] + b.[pa-unit-ins4-bal] + b.[pa-unit-pt-bal]), a.[balance]) AS 'Balance',
	COALESCE(b.[pa-unit-ins1-bal], ISNULL(c.[Ins1_Balance], 0)) AS 'COB1_Balance',
	COALESCE(b.[pa-unit-pt-bal], a.[pt_balance]) AS 'Pt_Balance',
	COALESCE(b.[pa-unit-tot-chg-amt], a.[tot_chgs]) AS 'Tot_Chgs',
	(CAST(ISNULL(c.[ins1_pymts], 0) AS MONEY) + CAST(ISNULL(c.[ins2_pymts], 0) AS MONEY) + CAST(ISNULL(c.[ins3_pymts], 0) AS MONEY) + CAST(ISNULL(c.[ins4_pymts], 0) AS MONEY)) AS 'Ins_Pay_Amt',
	(CAST(ISNULL(c.[ins1_pymts], 0) AS MONEY) + CAST(ISNULL(c.[ins2_pymts], 0) AS MONEY) + CAST(ISNULL(c.[ins3_pymts], 0) AS MONEY) + CAST(ISNULL(c.[ins4_pymts], 0) AS MONEY)) + CAST(ISNULL(a.[pa-bal-tot-pt-pay-amt], 0) AS MONEY) AS 'Tot_Pay_Amt',
	CASE 
		WHEN a.[pa-acct-type] IN ('6', '4')
			THEN 'Bad Debt'
		WHEN a.[dsch_date] IS NOT NULL
			AND a.[pa-acct-type] = '1'
			THEN 'DNFB'
		WHEN a.[dsch_date] IS NULL
			AND a.[pa-acct-type] = '1'
			THEN 'Inhouse'
		ELSE 'A/R'
		END AS 'File',
	a.[pa-fc] AS 'FC',
	CASE 
		WHEN a.[pa-fc] = '1'
			THEN 'Bad Debt Medicaid Pending'
		WHEN a.[pa-fc] IN ('2', '6')
			THEN 'Bad Debt AG'
		WHEN a.[pa-fc] = '3'
			THEN 'MCS'
		WHEN a.[pa-fc] = '4'
			THEN 'Bad Debt AG Legal'
		WHEN a.[pa-fc] = '5'
			THEN 'Bad Debt POM'
		WHEN a.[pa-fc] = '8'
			THEN 'Bad Debt AG Exchange Plans'
		WHEN a.[pa-fc] = '9'
			THEN 'Kopp-Bad Debt'
		WHEN a.[pa-fc] = 'A'
			THEN 'Commercial'
		WHEN a.[pa-fc] = 'B'
			THEN 'Blue Cross'
		WHEN a.[pa-fc] = 'C'
			THEN 'Champus'
		WHEN a.[pa-fc] = 'D'
			THEN 'Medicaid'
		WHEN a.[pa-fc] = 'E'
			THEN 'Employee Health Svc'
		WHEN a.[pa-fc] = 'G'
			THEN 'Contract Accts'
		WHEN a.[pa-fc] = 'H'
			THEN 'Medicare HMO'
		WHEN a.[pa-fc] = 'I'
			THEN 'Balance After Ins'
		WHEN a.[pa-fc] = 'J'
			THEN 'Managed Care'
		WHEN a.[pa-fc] = 'K'
			THEN 'Pending Medicaid'
		WHEN a.[pa-fc] = 'M'
			THEN 'Medicare'
		WHEN a.[pa-fc] = 'N'
			THEN 'No-Fault'
		WHEN a.[pa-fc] = 'P'
			THEN 'Self Pay'
		WHEN a.[pa-fc] = 'R'
			THEN 'Aergo Commercial'
		WHEN a.[pa-fc] = 'T'
			THEN 'RTR WC NF'
		WHEN a.[pa-fc] = 'S'
			THEN 'Special Billing'
		WHEN a.[pa-fc] = 'U'
			THEN 'Medicaid Mgd Care'
		WHEN a.[pa-fc] = 'V'
			THEN 'First Source'
		WHEN a.[pa-fc] = 'W'
			THEN 'Workers Comp'
		WHEN a.[pa-fc] = 'X'
			THEN 'Control Accts'
		WHEN a.[pa-fc] = 'Y'
			THEN 'MCS'
		WHEN a.[pa-fc] = 'Z'
			THEN 'Unclaimed Credits'
		ELSE ''
		END AS 'FC_Description',
	a.[pa-hosp-svc] AS 'Hosp_Svc',
	d.[Hosp Svc Desc] AS 'Hosp Svc Description',
	'1' AS 'COB1',
	c.[INS1] AS 'Ins1_Cd',
	COALESCE(c.[Ins1_Pol_No], c.[Ins1_Subscr_Group_Id], [Ins1_Grp_No]) AS 'Ins1_Member_ID',
	c.[Ins1_Pol_No],
	c.[Ins1_Subscr_Group_ID],
	c.[Ins1_Grp_No],
	c.[Ins1_Balance],
	c.[ins1_pymts] AS 'Pyr1_Pay_Amt',
	c.[ins1_First_Paid],
	'2' AS 'COB2',
	c.[ins2] AS 'Ins2_Cd',
	COALESCE(c.[Ins2_Pol_No], c.[Ins2_Subscr_Group_Id], [Ins2_Grp_No]) AS 'Ins2_Member_ID',
	c.[Ins2_Pol_No],
	c.[Ins2_Subscr_Group_ID],
	c.[Ins2_Grp_No],
	ISNULL(c.[Ins2_Balance], 0) AS 'Ins2_Balance',
	c.[ins2_pymts] AS 'Pyr2_Pay_Amt',
	c.[ins2_first_Paid],
	'3' AS 'COB3',
	c.[INS3] AS 'Ins3_Cd',
	COALESCE(c.[Ins3_Pol_No], c.[Ins3_Subscr_Group_Id], c.[Ins3_Grp_No]) AS 'Ins3_Member_ID',
	c.[Ins3_Pol_No],
	c.[Ins3_Subscr_Group_ID],
	c.[Ins3_Grp_No],
	ISNULL(c.[Ins3_Balance], 0) AS 'Ins3_Balance',
	c.[ins3_pymts] AS 'Pyr3_Pay_Amt',
	c.[Ins3_First_Paid],
	'4' AS 'COB4',
	c.[INS4] AS 'Ins4_Cd',
	COALESCE(c.[Ins4_Pol_No], c.[Ins4_Subscr_Group_Id], c.[Ins4_Grp_No]) AS 'Ins4_Member_ID',
	c.[Ins4_Pol_No],
	c.[Ins4_Subscr_Group_ID],
	c.[Ins4_Grp_No],
	ISNULL(c.[Ins4_Balance], 0) AS 'Ins4_Balance',
	c.[ins4_pymts] AS 'Pyr4_Pay_Amt',
	c.[Ins4_First_Paid],
	a.[pa-pt-representative]
FROM dbo.[#Encounters_For_Reporting_Unit] a
LEFT OUTER JOIN [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Active].dbo.[UnitizedAccounts] b ON a.[pa-pt-no-woscd] = b.[pa-pt-no-woscd]
	AND a.[pa-unit-date] = b.[pa-unit-date]
	AND a.[pa-ctl-paa-xfer-date] = b.[pa-ctl-paa-xfer-date]
LEFT OUTER JOIN [SMS].dbo.[CUSTOM_INSURANCE_SM_ALT] c --_3] C
	ON A.[PA-PT-NO-WOSCD] = C.[PA-PT-NO-WOSCD]
	AND A.[PA-UNIT-DATE] = C.[PA-UNIT-DATE]
	AND a.[pa-ctl-paa-xfer-date] = c.[pa-ctl-paa-xfer-date]
LEFT OUTER JOIN [Swarm].dbo.[HospSvc] d ON a.[pa-hosp-svc] = d.[Hosp Svc]
--[ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Active].dbo.PatientDemographics a left outer join [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Active].dbo.unitizedaccounts b
--ON a.[pa-pt-no-woscd]=b.[pa-pt-no-woscd] and a.[pa-pt-no-scd]=b.[pa-pt-no-scd-1]
--left outer join SMS.dbo.[CUSTOM_INSURANCE_SM] c
--ON a.[pa-pt-no-woscd]=c.[pa-pt-no-woscd]
--left outer join [Swarm].dbo.[HospSvc] d
--ON a.[pa-hosp-svc] = d.[Hosp Svc]
----left outer join SMS.[UHMC\smathesi].[CUSTOM_INSURANCE_SM] d
----ON a.[pa-pt-no-woscd]=d.[pa-pt-no-woscd] and d.[rank]='2'
----left outer join SMS.[UHMC\smathesi].[CUSTOM_INSURANCE] e
----ON a.[pa-pt-no-woscd]=e.[pa-pt-no-woscd] and e.[rank]='3'
----left outer join SMS.[UHMC\smathesi].[CUSTOM_INSURANCE] f
----ON a.[pa-pt-no-woscd]=f.[pa-pt-no-woscd] and f.[rank]='4'
--left outer join [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Active].dbo.diagnosisinformation g
--ON a.[pa-pt-no-woscd]=g.[pa-pt-no-woscd] and g.[pa-dx2-prio-no]='1' and g.[pa-dx2-type1-type2-cd]='DF'
--left outer join [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Active].dbo.[NADInformation] k
--ON a.[pa-pt-no-woscd]=k.[pa-pt-no-woscd] and k.[pa-nad-cd]='PTGAR'
--left outer join [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Active].dbo.PatientDemographics l
--ON a.[pa-pt-no-woscd]=l.[pa-pt-no-woscd]
--left outer join [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Active].dbo.AccountComments zz
--ON a.[pa-pt-no-woscd]=zz.[pa-pt-no-woscd] and zz.[pa-smart-comment] like 'PJOC%'
--left outer join dbo.#Emblem_Claim_Nos m
--ON a.[pa-pt-no-woscd]=m.[pa-pt-no-woscd] and m.[Rank]='1'
--left outer join [Echo_Active].dbo.[UserDefined] n
--ON a.[pa-pt-no-woscd]=n.[pa-pt-no-woscd] and n.[pa-component-id] like '%5C49NAME%'
----AND [pa-user-text] LIKE '%QHP%'
WHERE a.[pa-unit-no] <> '0'
	--AND a.[pa-fc] NOT IN ('0','1','2','3','4','5','6','7','8','9')
	--AND COALESCE(ISNULL(c.[pa-bal-ins-pay-amt],0)+ ISNULL(d.[pa-bal-ins-pay-amt],0) + ISNULL(e.[pa-bal-ins-pay-amt],0) + ISNULL(f.[pa-bal-ins-pay-amt],0)+ ISNULL(a.[pa-bal-tot-pt-pay-amt],0),a.[pa-bal-acct-bal])< '0'
	AND (
		COALESCE((b.[pa-unit-ins1-bal] + b.[pa-unit-ins2-bal] + b.[pa-unit-ins3-bal] + b.[pa-unit-ins4-bal] + b.[pa-unit-pt-bal]), a.[balance]) <> '0'
		OR COALESCE(b.[pa-unit-tot-chg-amt], a.[tot_chgs]) <> '0'
		)
--AND c.[INS1] IN ('O53','O23','J23','U23','U57','G12','M23','J57','M57','P12')--emblem

UNION

SELECT cast(a.[PA-PT-NO-WOSCD] AS VARCHAR) + cast(a.[PA-PT-NO-SCD] AS VARCHAR) AS 'Pt_No',
	a.[PA-UNIT-NO],
	a.[PA-CTL-PAA-XFER-DATE],
	a.[pa-med-rec-no] AS 'MRN',
	a.[pa-pt-name] AS 'Pt_Name',
	a.[admit_date] AS 'Admit_Date',
	a.[dsch_date] AS 'Dsch_Date',
	a.[pa-unit-date] AS 'Unit_Date',
	CASE 
		WHEN a.[pa-acct-type] IN ('0', '6', '7')
			THEN 'OP' --0=OP; 6=OP BAD DEBT; 7=OP HISTORIC
		WHEN a.[pa-acct-type] IN ('1', '2', '4', '8')
			THEN 'IP' --1=IP; 2=A/R; 4=I/P BAD DEBT; 8=I/P HISTORIC
		ELSE ''
		END AS 'Acct_Type',
	CASE 
		WHEN a.[pa-acct-type] <> 1
			AND datediff(day, COALESCE(a.[pa-unit-date], a.[dsch_date], a.[admit_date]), getdate()) BETWEEN '0'
				AND '30'
			THEN '1_0-30'
		WHEN a.[pa-acct-type] <> 1
			AND datediff(day, COALESCE(a.[pa-unit-date], a.[dsch_date], a.[admit_date]), getdate()) BETWEEN '31'
				AND '60'
			THEN '2_31-60'
		WHEN a.[pa-acct-type] <> 1
			AND datediff(day, COALESCE(a.[pa-unit-date], a.[dsch_date], a.[admit_date]), getdate()) BETWEEN '61'
				AND '90'
			THEN '3_61-90'
		WHEN a.[pa-acct-type] <> 1
			AND datediff(day, COALESCE(a.[pa-unit-date], a.[dsch_date], a.[admit_date]), getdate()) BETWEEN '91'
				AND '120'
			THEN '4_91-120'
		WHEN a.[pa-acct-type] <> 1
			AND datediff(day, COALESCE(a.[pa-unit-date], a.[dsch_date], a.[admit_date]), getdate()) BETWEEN '121'
				AND '150'
			THEN '5_121-150'
		WHEN a.[pa-acct-type] <> 1
			AND datediff(day, COALESCE(a.[pa-unit-date], a.[dsch_date], a.[admit_date]), getdate()) BETWEEN '151'
				AND '180'
			THEN '6_151-180'
		WHEN a.[pa-acct-type] <> 1
			AND datediff(day, COALESCE(a.[pa-unit-date], a.[dsch_date], a.[admit_date]), getdate()) BETWEEN '181'
				AND '210'
			THEN '7_181-210'
		WHEN a.[pa-acct-type] <> 1
			AND datediff(day, COALESCE(a.[pa-unit-date], a.[dsch_date], a.[admit_date]), getdate()) BETWEEN '211'
				AND '240'
			THEN '8_211-240'
		WHEN a.[pa-acct-type] <> 1
			AND datediff(day, COALESCE(a.[pa-unit-date], a.[dsch_date], a.[admit_date]), getdate()) > '240'
			THEN '9_240+'
		WHEN a.[pa-acct-type] = 1
			THEN 'In House/DNFB'
		ELSE ''
		END AS 'Age_Bucket',
	a.[1st_bl_date] AS 'First_Ins_Bl_Date',
	e.[SSI_Last_Ins_Bill_Date],
	CASE 
		WHEN e.[SSI_Last_Ins_Bill_Date] > a.[1st_Bl_Date]
			THEN datediff(dd, e.[SSI_Last_Ins_Bill_Date], c.[ins1_First_Paid])
		WHEN e.[SSI_Last_Ins_Bill_Date] IS NULL
			AND a.[1st_bl_date] IS NOT NULL
			AND c.[ins1_first_paid] IS NOT NULL
			THEN datediff(dd, a.[1st_bl_date], c.[ins1_First_Paid])
		ELSE ''
		END AS 'Days_To_First_Paid',
	CASE 
		WHEN c.[ins1_pymts] < '0'
			AND c.[ins2_pymts] < '0'
			THEN DATEDIFF(dd, a.[1st_Bl_Date], [Ins2_First_Paid])
		ELSE ''
		END AS 'Days_To_Secondary_Pymt',
	COALESCE((b.[pa-unit-ins1-bal] + b.[pa-unit-ins2-bal] + b.[pa-unit-ins3-bal] + b.[pa-unit-ins4-bal] + b.[pa-unit-pt-bal]), a.[balance]) AS 'Balance',
	COALESCE(b.[pa-unit-ins1-bal], ISNULL(c.[Ins1_Balance], 0)) AS 'COB1_Balance',
	COALESCE(b.[pa-unit-pt-bal], a.[pt_balance]) AS 'Pt_Balance',
	COALESCE(b.[pa-unit-tot-chg-amt], a.[tot_chgs]) AS 'Tot_Chgs',
	(CAST(ISNULL(c.[ins1_pymts], 0) AS MONEY) + CAST(ISNULL(c.[ins2_pymts], 0) AS MONEY) + CAST(ISNULL(c.[ins3_pymts], 0) AS MONEY) + CAST(ISNULL(c.[ins4_pymts], 0) AS MONEY)) AS 'Ins_Pay_Amt',
	(CAST(ISNULL(c.[ins1_pymts], 0) AS MONEY) + CAST(ISNULL(c.[ins2_pymts], 0) AS MONEY) + CAST(ISNULL(c.[ins3_pymts], 0) AS MONEY) + CAST(ISNULL(c.[ins4_pymts], 0) AS MONEY)) + CAST(ISNULL(a.[pa-bal-tot-pt-pay-amt], 0) AS MONEY) AS 'Tot_Pay_Amt',
	CASE 
		WHEN a.[pa-acct-type] IN ('6', '4')
			THEN 'Bad Debt'
		WHEN a.[dsch_date] IS NOT NULL
			AND a.[pa-acct-type] = '1'
			THEN 'DNFB'
		WHEN a.[dsch_date] IS NULL
			AND a.[pa-acct-type] = '1'
			THEN 'Inhouse'
		ELSE 'A/R'
		END AS 'File',
	a.[pa-fc] AS 'FC',
	CASE 
		WHEN a.[pa-fc] = '1'
			THEN 'Bad Debt Medicaid Pending'
		WHEN a.[pa-fc] IN ('2', '6')
			THEN 'Bad Debt AG'
		WHEN a.[pa-fc] = '3'
			THEN 'MCS'
		WHEN a.[pa-fc] = '4'
			THEN 'Bad Debt AG Legal'
		WHEN a.[pa-fc] = '5'
			THEN 'Bad Debt POM'
		WHEN a.[pa-fc] = '8'
			THEN 'Bad Debt AG Exchange Plans'
		WHEN a.[pa-fc] = '9'
			THEN 'Kopp-Bad Debt'
		WHEN a.[pa-fc] = 'A'
			THEN 'Commercial'
		WHEN a.[pa-fc] = 'B'
			THEN 'Blue Cross'
		WHEN a.[pa-fc] = 'C'
			THEN 'Champus'
		WHEN a.[pa-fc] = 'D'
			THEN 'Medicaid'
		WHEN a.[pa-fc] = 'E'
			THEN 'Employee Health Svc'
		WHEN a.[pa-fc] = 'G'
			THEN 'Contract Accts'
		WHEN a.[pa-fc] = 'H'
			THEN 'Medicare HMO'
		WHEN a.[pa-fc] = 'I'
			THEN 'Balance After Ins'
		WHEN a.[pa-fc] = 'J'
			THEN 'Managed Care'
		WHEN a.[pa-fc] = 'K'
			THEN 'Pending Medicaid'
		WHEN a.[pa-fc] = 'M'
			THEN 'Medicare'
		WHEN a.[pa-fc] = 'N'
			THEN 'No-Fault'
		WHEN a.[pa-fc] = 'P'
			THEN 'Self Pay'
		WHEN a.[pa-fc] = 'R'
			THEN 'Aergo Commercial'
		WHEN a.[pa-fc] = 'T'
			THEN 'RTR WC NF'
		WHEN a.[pa-fc] = 'S'
			THEN 'Special Billing'
		WHEN a.[pa-fc] = 'U'
			THEN 'Medicaid Mgd Care'
		WHEN a.[pa-fc] = 'V'
			THEN 'First Source'
		WHEN a.[pa-fc] = 'W'
			THEN 'Workers Comp'
		WHEN a.[pa-fc] = 'X'
			THEN 'Control Accts'
		WHEN a.[pa-fc] = 'Y'
			THEN 'MCS'
		WHEN a.[pa-fc] = 'Z'
			THEN 'Unclaimed Credits'
		ELSE ''
		END AS 'FC_Description',
	a.[pa-hosp-svc] AS 'Hosp_Svc',
	d.[Hosp Svc Desc] AS 'Hosp Svc Description',
	'1' AS 'COB1',
	c.[INS1] AS 'Ins1_Cd',
	COALESCE(c.[Ins1_Pol_No], c.[Ins1_Subscr_Group_Id], [Ins1_Grp_No]) AS 'Ins1_Member_ID',
	c.[Ins1_Pol_No],
	c.[Ins1_Subscr_Group_ID],
	c.[Ins1_Grp_No],
	c.[Ins1_Balance],
	c.[ins1_pymts] AS 'Pyr1_Pay_Amt',
	c.[ins1_First_Paid],
	'2' AS 'COB2',
	c.[ins2] AS 'Ins2_Cd',
	COALESCE(c.[Ins2_Pol_No], c.[Ins2_Subscr_Group_Id], [Ins2_Grp_No]) AS 'Ins2_Member_ID',
	c.[Ins2_Pol_No],
	c.[Ins2_Subscr_Group_ID],
	c.[Ins2_Grp_No],
	ISNULL(c.[Ins2_Balance], 0) AS 'Ins2_Balance',
	c.[ins2_pymts] AS 'Pyr2_Pay_Amt',
	c.[ins2_First_Paid],
	'3' AS 'COB3',
	c.[INS3] AS 'Ins3_Cd',
	COALESCE(c.[Ins3_Pol_No], c.[Ins3_Subscr_Group_Id], c.[Ins3_Grp_No]) AS 'Ins3_Member_ID',
	c.[Ins3_Pol_No],
	c.[Ins3_Subscr_Group_ID],
	c.[Ins3_Grp_No],
	ISNULL(c.[Ins3_Balance], 0) AS 'Ins3_Balance',
	c.[ins3_pymts] AS 'Pyr3_Pay_Amt',
	c.[ins3_First_Paid],
	'4' AS 'COB4',
	c.[INS4] AS 'Ins4_Cd',
	COALESCE(c.[Ins4_Pol_No], c.[Ins4_Subscr_Group_Id], c.[Ins4_Grp_No]) AS 'Ins4_Member_ID',
	c.[Ins4_Pol_No],
	c.[Ins4_Subscr_Group_ID],
	c.[Ins4_Grp_No],
	ISNULL(c.[Ins4_Balance], 0) AS 'Ins4_Balance',
	c.[ins4_pymts] AS 'Pyr4_Pay_Amt',
	c.[ins4_First_Paid],
	a.[pa-pt-representative]
FROM dbo.[#Encounters_For_Reporting_NonUnit] a
LEFT OUTER JOIN [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Active].dbo.[UnitizedAccounts] b ON a.[pa-pt-no-woscd] = b.[pa-pt-no-woscd]
	AND a.[pa-ctl-paa-xfer-date] = b.[pa-ctl-paa-xfer-date] --and a.[pa-unit-date]=b.[pa-unit-date]
LEFT OUTER JOIN dbo.[#CUSTOM_INSURANCE_SM_3_NonUnit] C ON A.[PA-PT-NO-WOSCD] = C.[PA-PT-NO-WOSCD]
	AND A.[PA-UNIT-DATE] IS NULL
	AND a.[pa-ctl-paa-xfer-date] = c.[pa-ctl-paa-xfer-date]
LEFT OUTER JOIN [Swarm].dbo.[HospSvc] d ON a.[pa-hosp-svc] = d.[Hosp Svc]
LEFT OUTER JOIN [#SSI_Primary_Claim_Release_Date] e ON CAST(a.[pa-pt-no-woscd] AS VARCHAR) + CAST(a.[pa-pt-no-scd] AS VARCHAR) = e.[pt_no]
	AND e.[rank] = '1'
WHERE --a.[pa-fc] NOT IN ('0','1','2','3','4','5','6','7','8','9')
	--AND COALESCE(ISNULL(c.[pa-bal-ins-pay-amt],0)+ ISNULL(d.[pa-bal-ins-pay-amt],0) + ISNULL(e.[pa-bal-ins-pay-amt],0) + ISNULL(f.[pa-bal-ins-pay-amt],0)+ ISNULL(a.[pa-bal-tot-pt-pay-amt],0),a.[pa-bal-acct-bal])< '0'
	(
		COALESCE((b.[pa-unit-ins1-bal] + b.[pa-unit-ins2-bal] + b.[pa-unit-ins3-bal] + b.[pa-unit-ins4-bal] + b.[pa-unit-pt-bal]), a.[balance]) <> '0'
		OR COALESCE(b.[pa-unit-tot-chg-amt], a.[tot_chgs]) <> '0'
		)
	--AND COALESCE((b.[pa-unit-ins1-bal] + b.[pa-unit-ins2-bal] + b.[pa-unit-ins3-bal]+b.[pa-unit-ins4-bal]+b.[pa-unit-pt-bal]),a.[balance])<>'0'
	--AND c.[INS1] IN ('O53','O23','J23','U23','U57','G12','M23','J57','M57','P12')--emblem
	AND a.[pa-unit-date] IS NULL

UNION

/*Add Open Units-------------------------------------------------------------------*/
SELECT cast(a.[PA-PT-NO-WOSCD] AS VARCHAR) + cast(a.[PA-PT-NO-SCD] AS VARCHAR) AS 'Pt_No',
	a.[PA-UNIT-NO],
	a.[PA-CTL-PAA-XFER-DATE],
	a.[pa-med-rec-no] AS 'MRN',
	a.[pa-pt-name] AS 'Pt_Name',
	a.[admit_date] AS 'Admit_Date',
	a.[dsch_date] AS 'Dsch_Date',
	a.[pa-unit-date] AS 'Unit_Date',
	CASE 
		WHEN a.[pa-acct-type] IN ('0', '6', '7')
			THEN 'OP' --0=OP; 6=OP BAD DEBT; 7=OP HISTORIC
		WHEN a.[pa-acct-type] IN ('1', '2', '4', '8')
			THEN 'IP' --1=IP; 2=A/R; 4=I/P BAD DEBT; 8=I/P HISTORIC
		ELSE ''
		END AS 'Acct_Type',
	CASE 
		WHEN a.[pa-acct-type] <> 1
			AND datediff(day, COALESCE(a.[pa-unit-date], a.[dsch_date], a.[admit_date]), getdate()) BETWEEN '0'
				AND '30'
			THEN '1_0-30'
		WHEN a.[pa-acct-type] <> 1
			AND datediff(day, COALESCE(a.[pa-unit-date], a.[dsch_date], a.[admit_date]), getdate()) BETWEEN '31'
				AND '60'
			THEN '2_31-60'
		WHEN a.[pa-acct-type] <> 1
			AND datediff(day, COALESCE(a.[pa-unit-date], a.[dsch_date], a.[admit_date]), getdate()) BETWEEN '61'
				AND '90'
			THEN '3_61-90'
		WHEN a.[pa-acct-type] <> 1
			AND datediff(day, COALESCE(a.[pa-unit-date], a.[dsch_date], a.[admit_date]), getdate()) BETWEEN '91'
				AND '120'
			THEN '4_91-120'
		WHEN a.[pa-acct-type] <> 1
			AND datediff(day, COALESCE(a.[pa-unit-date], a.[dsch_date], a.[admit_date]), getdate()) BETWEEN '121'
				AND '150'
			THEN '5_121-150'
		WHEN a.[pa-acct-type] <> 1
			AND datediff(day, COALESCE(a.[pa-unit-date], a.[dsch_date], a.[admit_date]), getdate()) BETWEEN '151'
				AND '180'
			THEN '6_151-180'
		WHEN a.[pa-acct-type] <> 1
			AND datediff(day, COALESCE(a.[pa-unit-date], a.[dsch_date], a.[admit_date]), getdate()) BETWEEN '181'
				AND '210'
			THEN '7_181-210'
		WHEN a.[pa-acct-type] <> 1
			AND datediff(day, COALESCE(a.[pa-unit-date], a.[dsch_date], a.[admit_date]), getdate()) BETWEEN '211'
				AND '240'
			THEN '8_211-240'
		WHEN a.[pa-acct-type] <> 1
			AND datediff(day, COALESCE(a.[pa-unit-date], a.[dsch_date], a.[admit_date]), getdate()) > '240'
			THEN '9_240+'
		WHEN a.[pa-acct-type] = 1
			THEN 'In House/DNFB'
		ELSE ''
		END AS 'Age_Bucket',
	a.[1st_bl_date] AS 'First_Ins_Bl_Date',
	'' AS 'SSI_Last_Ins_Bill_Date',
	CASE 
		WHEN a.[1st_bl_date] IS NOT NULL
			AND c.[ins1_first_paid] IS NOT NULL
			THEN datediff(dd, a.[1st_bl_date], c.[ins1_First_Paid])
		WHEN a.[1st_bl_Date] IS NOT NULL
			AND c.[ins1_First_Paid] IS NULL
			AND c.[ins2_first_paid] IS NOT NULL
			THEN datediff(dd, a.[1st_Bl_Date], c.[ins2_first_paid])
		WHEN a.[1st_bl_Date] IS NOT NULL
			AND c.[ins1_First_Paid] IS NULL
			AND c.[ins2_first_paid] IS NULL
			AND c.[ins3_first_paid] IS NOT NULL
			THEN datediff(dd, a.[1st_Bl_Date], c.[ins3_first_paid])
		WHEN a.[1st_bl_Date] IS NOT NULL
			AND c.[ins1_First_Paid] IS NULL
			AND c.[ins2_first_paid] IS NULL
			AND c.[ins3_first_paid] IS NULL
			AND c.[ins4_first_paid] IS NOT NULL
			THEN datediff(dd, a.[1st_Bl_Date], c.[ins4_first_paid])
		ELSE ''
		END AS 'Days_To_First_Paid',
	CASE 
		WHEN c.[ins1_pymts] < '0'
			AND c.[ins2_pymts] < '0'
			THEN DATEDIFF(dd, a.[1st_Bl_Date], [Ins2_First_Paid])
		ELSE ''
		END AS 'Days_To_Secondary_Pymt',
	COALESCE((b.[pa-unit-ins1-bal] + b.[pa-unit-ins2-bal] + b.[pa-unit-ins3-bal] + b.[pa-unit-ins4-bal] + b.[pa-unit-pt-bal]), a.[balance]) AS 'Balance',
	COALESCE(b.[pa-unit-ins1-bal], ISNULL(c.[Ins1_Balance], 0)) AS 'COB1_Balance',
	COALESCE(b.[pa-unit-pt-bal], a.[pt_balance]) AS 'Pt_Balance',
	COALESCE(b.[pa-unit-tot-chg-amt], a.[tot_chgs]) AS 'Tot_Chgs',
	(CAST(ISNULL(c.[ins1_pymts], 0) AS MONEY) + CAST(ISNULL(c.[ins2_pymts], 0) AS MONEY) + CAST(ISNULL(c.[ins3_pymts], 0) AS MONEY) + CAST(ISNULL(c.[ins4_pymts], 0) AS MONEY)) AS 'Ins_Pay_Amt',
	(CAST(ISNULL(c.[ins1_pymts], 0) AS MONEY) + CAST(ISNULL(c.[ins2_pymts], 0) AS MONEY) + CAST(ISNULL(c.[ins3_pymts], 0) AS MONEY) + CAST(ISNULL(c.[ins4_pymts], 0) AS MONEY)) + CAST(ISNULL(a.[pa-bal-tot-pt-pay-amt], 0) AS MONEY) AS 'Tot_Pay_Amt',
	CASE 
		WHEN a.[pa-acct-type] IN ('6', '4')
			THEN 'Bad Debt'
		WHEN a.[dsch_date] IS NOT NULL
			AND a.[pa-acct-type] = '1'
			THEN 'DNFB'
		WHEN a.[dsch_date] IS NULL
			AND a.[pa-acct-type] = '1'
			THEN 'Inhouse'
		ELSE 'A/R'
		END AS 'File',
	a.[pa-fc] AS 'FC',
	CASE 
		WHEN a.[pa-fc] = '1'
			THEN 'Bad Debt Medicaid Pending'
		WHEN a.[pa-fc] IN ('2', '6')
			THEN 'Bad Debt AG'
		WHEN a.[pa-fc] = '3'
			THEN 'MCS'
		WHEN a.[pa-fc] = '4'
			THEN 'Bad Debt AG Legal'
		WHEN a.[pa-fc] = '5'
			THEN 'Bad Debt POM'
		WHEN a.[pa-fc] = '8'
			THEN 'Bad Debt AG Exchange Plans'
		WHEN a.[pa-fc] = '9'
			THEN 'Kopp-Bad Debt'
		WHEN a.[pa-fc] = 'A'
			THEN 'Commercial'
		WHEN a.[pa-fc] = 'B'
			THEN 'Blue Cross'
		WHEN a.[pa-fc] = 'C'
			THEN 'Champus'
		WHEN a.[pa-fc] = 'D'
			THEN 'Medicaid'
		WHEN a.[pa-fc] = 'E'
			THEN 'Employee Health Svc'
		WHEN a.[pa-fc] = 'G'
			THEN 'Contract Accts'
		WHEN a.[pa-fc] = 'H'
			THEN 'Medicare HMO'
		WHEN a.[pa-fc] = 'I'
			THEN 'Balance After Ins'
		WHEN a.[pa-fc] = 'J'
			THEN 'Managed Care'
		WHEN a.[pa-fc] = 'K'
			THEN 'Pending Medicaid'
		WHEN a.[pa-fc] = 'M'
			THEN 'Medicare'
		WHEN a.[pa-fc] = 'N'
			THEN 'No-Fault'
		WHEN a.[pa-fc] = 'P'
			THEN 'Self Pay'
		WHEN a.[pa-fc] = 'R'
			THEN 'Aergo Commercial'
		WHEN a.[pa-fc] = 'T'
			THEN 'RTR WC NF'
		WHEN a.[pa-fc] = 'S'
			THEN 'Special Billing'
		WHEN a.[pa-fc] = 'U'
			THEN 'Medicaid Mgd Care'
		WHEN a.[pa-fc] = 'V'
			THEN 'First Source'
		WHEN a.[pa-fc] = 'W'
			THEN 'Workers Comp'
		WHEN a.[pa-fc] = 'X'
			THEN 'Control Accts'
		WHEN a.[pa-fc] = 'Y'
			THEN 'MCS'
		WHEN a.[pa-fc] = 'Z'
			THEN 'Unclaimed Credits'
		ELSE ''
		END AS 'FC_Description',
	a.[pa-hosp-svc] AS 'Hosp_Svc',
	d.[Hosp Svc Desc] AS 'Hosp Svc Description',
	'1' AS 'COB1',
	c.[INS1] AS 'Ins1_Cd',
	COALESCE(c.[Ins1_Pol_No], c.[Ins1_Subscr_Group_Id], [Ins1_Grp_No]) AS 'Ins1_Member_ID',
	c.[Ins1_Pol_No],
	c.[Ins1_Subscr_Group_ID],
	c.[Ins1_Grp_No],
	c.[Ins1_Balance],
	c.[ins1_pymts] AS 'Pyr1_Pay_Amt',
	c.[Ins1_FIRST_PAID],
	'2' AS 'COB2',
	c.[ins2] AS 'Ins2_Cd',
	COALESCE(c.[Ins2_Pol_No], c.[Ins2_Subscr_Group_Id], [Ins2_Grp_No]) AS 'Ins2_Member_ID',
	c.[Ins2_Pol_No],
	c.[Ins2_Subscr_Group_ID],
	c.[Ins2_Grp_No],
	ISNULL(c.[Ins2_Balance], 0) AS 'Ins2_Balance',
	c.[ins2_pymts] AS 'Pyr2_Pay_Amt',
	c.[ins2_first_paid],
	'3' AS 'COB3',
	c.[INS3] AS 'Ins3_Cd',
	COALESCE(c.[Ins3_Pol_No], c.[Ins3_Subscr_Group_Id], c.[Ins3_Grp_No]) AS 'Ins3_Member_ID',
	c.[Ins3_Pol_No],
	c.[Ins3_Subscr_Group_ID],
	c.[Ins3_Grp_No],
	ISNULL(c.[Ins3_Balance], 0) AS 'Ins3_Balance',
	c.[ins3_pymts] AS 'Pyr3_Pay_Amt',
	c.[ins3_first_paid],
	'4' AS 'COB4',
	c.[INS4] AS 'Ins4_Cd',
	COALESCE(c.[Ins4_Pol_No], c.[Ins4_Subscr_Group_Id], c.[Ins4_Grp_No]) AS 'Ins4_Member_ID',
	c.[Ins4_Pol_No],
	c.[Ins4_Subscr_Group_ID],
	c.[Ins4_Grp_No],
	ISNULL(c.[Ins4_Balance], 0) AS 'Ins4_Balance',
	c.[ins4_pymts] AS 'Pyr4_Pay_Amt',
	c.[ins4_first_paid],
	a.[pa-pt-representative]
FROM dbo.[#Encounters_For_Reporting_Open_Unit] a
LEFT OUTER JOIN [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Active].dbo.[UnitizedAccounts] b ON a.[pa-pt-no-woscd] = b.[pa-pt-no-woscd]
	AND a.[pa-unit-no] = b.[pa-unit-no]
	AND a.[pa-ctl-paa-xfer-date] = b.[pa-ctl-paa-xfer-date]
LEFT OUTER JOIN [SMS].dbo.[CUSTOM_INSURANCE_SM_ALT] C --_3] C
	ON A.[PA-PT-NO-WOSCD] = C.[PA-PT-NO-WOSCD]
	AND A.[PA-UNIT-NO] = C.[PA-UNIT-NO]
	AND a.[pa-ctl-paa-xfer-date] = c.[pa-ctl-paa-xfer-date]
LEFT OUTER JOIN [Swarm].dbo.[HospSvc] d ON a.[pa-hosp-svc] = d.[Hosp Svc]
WHERE (
		COALESCE((b.[pa-unit-ins1-bal] + b.[pa-unit-ins2-bal] + b.[pa-unit-ins3-bal] + b.[pa-unit-ins4-bal] + b.[pa-unit-pt-bal]), a.[balance]) <> '0'
		OR COALESCE(b.[pa-unit-tot-chg-amt], a.[tot_chgs]) <> '0'
		)
	--AND a.[pa-fc] NOT IN ('0','1','2','3','4','5','6','7','8','9')
    
	--SELECT *
	--FROM [#SSI_Primary_Claim_Release_Date]
