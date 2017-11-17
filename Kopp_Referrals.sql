/*Create Temp Table W RTR Patients*/
 
IF OBJECT_ID('tempdb.dbo.#Kopp_Referals','U') IS NOT NULL
DROP TABLE #Kopp_Referals;
GO
 
CREATE TABLE #Kopp_Referals
 
(
[PA-PT-NO] CHAR(12) NOT NULL,
[PA-ACCT-TYPE] CHAR(1) NULL,
[PA-ADM-DATE] DATETIME NULL,
[PA-ADM-TIME] DECIMAL(4,0) NULL,
[PA-DSCH-DATE] DATETIME NULL,
[PA-DSCH-TIME] DECIMAL(4,0) NULL,
[PA-LAST-FC-CNG-DATE] DATETIME NULL,
[PA-FIRST-BL-DATE] DATETIME NULL,
[PA-ACCT-BD-XFR-DATE] DATETIME NULL,
[PA-PT-NAME] CHAR(25) NULL,
[PA-MED-REC-NO] CHAR(12) NULL,
[PA-PT-REPRESENTATIVE] CHAR(3) NULL,
[PA-LAST-FC] CHAR(1) NULL,
[PA-ORIGINAL-FC] CHAR(1) NULL,
[PA-CR-RATING] CHAR(1) NULL,
[PA-PAY-SCALE] CHAR(1) NULL,
[PA-RESP-CD] CHAR(1) NULL,
[PA-BAL-TOT-CHG-AMT] MONEY NULL,
[PA-FC] CHAR(1) NULL,
[PA-PT-TYPE] CHAR(1) NULL,
[PA-HOSP-SVC] CHAR(3) NULL,
[PA-UNIT-STS] CHAR(1) NULL,
[PA-BAL-ACCT-BAL] MONEY NULL,
[PA-BAL-PT-BAL] MONEY NULL,
[PA-BAL-TOT-INS-BAL] MONEY NULL,
[PA-BAL-TOT-PT-PAY-AMT] MONEY NULL,
[PA-STMT-CD] CHAR(1) NULL
);
 
INSERT INTO #Kopp_Referals([PA-PT-NO],[PA-ACCT-TYPE],[PA-ADM-DATE],[PA-ADM-TIME],[PA-DSCH-DATE],[PA-DSCH-TIME],[PA-LAST-FC-CNG-DATE],[PA-FIRST-BL-DATE],[PA-ACCT-BD-XFR-DATE],[PA-PT-NAME],[PA-MED-REC-NO],[PA-PT-REPRESENTATIVE],[PA-LAST-FC],[PA-ORIGINAL-FC],[PA-CR-RATING],[PA-PAY-SCALE],[PA-RESP-CD],[PA-BAL-TOT-CHG-AMT],[PA-FC],[PA-PT-TYPE],[PA-HOSP-SVC],[PA-UNIT-STS],[PA-BAL-ACCT-BAL],[PA-BAL-PT-BAL],[PA-BAL-TOT-INS-BAL],[PA-BAL-TOT-PT-PAY-AMT],[PA-STMT-CD]
)
 
         SELECT (CAST(a.[PA-PT-NO-WOSCD] as varchar) + CAST(a.[pa-pt-no-scd-1] as varchar)) as 'PA-PT-NO'
         ,a.[PA-ACCT-TYPE]
      ,[PA-ADM-DATE]
      ,[PA-ADM-TIME]
      ,[PA-DSCH-DATE]
      ,[PA-DSCH-TIME]
      ,[PA-LAST-FC-CNG-DATE]
      ,coalesce([PA-FINAL-BILL-DATE],[pa-op-first-ins-bl-date]) as 'PA-FIRST-BL-DATE'
      ,[PA-ACCT-BD-XFR-DATE]
      ,[PA-PT-NAME]
      ,[PA-MED-REC-NO]
      ,[PA-PT-REPRESENTATIVE]
      ,[PA-LAST-FC]
      ,[PA-ORIGINAL-FC]
      ,[PA-CR-RATING]
      ,[PA-PAY-SCALE]
      ,[PA-RESP-CD]
      ,[PA-BAL-TOT-CHG-AMT]
      ,[PA-FC]
      ,[PA-PT-TYPE]
      ,[PA-HOSP-SVC]
      ,[PA-UNIT-STS]
      ,[PA-BAL-ACCT-BAL]
      ,[PA-BAL-PT-BAL]
      ,[PA-BAL-TOT-INS-BAL]
      ,[PA-BAL-TOT-PT-PAY-AMT]
         ,[PA-STMT-CD]
      
  FROM [Echo_Active].[dbo].[PatientDemographics] a inner join [Echo_Active].dbo.[AccountComments] b
  ON a.[pa-pt-no-woscd]=b.[pa-pt-no-woscd]
 
  where [pa-smart-svc-cd-woscd] IN ('216','219')
  --[pa-pt-representative] IN ('780','781','782','783')
 
  UNION
         SELECT (CAST(a.[PA-PT-NO-WOSCD] as varchar) + CAST(a.[pa-pt-no-scd-1] as varchar)) as 'PA-PT-NO'
         ,a.[PA-ACCT-TYPE]
      ,[PA-ADM-DATE]
      ,[PA-ADM-TIME]
      ,[PA-DSCH-DATE]
      ,[PA-DSCH-TIME]
      ,[PA-LAST-FC-CNG-DATE]
      ,coalesce([PA-FINAL-BILL-DATE],[pa-op-first-ins-bl-date]) as 'PA-FIRST-BL-DATE'
      ,[PA-ACCT-BD-XFR-DATE]
      ,[PA-PT-NAME]
      ,[PA-MED-REC-NO]
      ,[PA-PT-REPRESENTATIVE]
      ,[PA-LAST-FC]
      ,[PA-ORIGINAL-FC]
      ,[PA-CR-RATING]
      ,[PA-PAY-SCALE]
      ,[PA-RESP-CD]
      ,[PA-BAL-TOT-CHG-AMT]
      ,[PA-FC]
      ,[PA-PT-TYPE]
      ,[PA-HOSP-SVC]
      ,[PA-UNIT-STS]
      ,[PA-BAL-ACCT-BAL]
      ,[PA-BAL-PT-BAL]
      ,[PA-BAL-TOT-INS-BAL]
      ,[PA-BAL-TOT-PT-PAY-AMT]
         ,[PA-STMT-CD]
      
  FROM [Echo_Archive].[dbo].[PatientDemographics]a inner join [Echo_Archive].[dbo].[AccountComments] b
  On a.[pa-pt-no-woscd]=b.[pa-pt-no-woscd]
 
  where [pa-smart-svc-cd-woscd] IN ('216','219')
  --[pa-pt-representative] IN ('780','781','782','783')
 
 
 
  /*Create Temp Table Kopp Referred Date*/
 
IF OBJECT_ID('tempdb.dbo.#Kopp_Referred_Dates','U') IS NOT NULL
DROP TABLE #Kopp_Referred_Dates;
GO
 
CREATE TABLE #Kopp_Referred_Dates
 
(
[PA-PT-NO] CHAR(12) NOT NULL,
[PA-REFERRED-DATE] DATETIME NULL,
[PA-REFERRED-COMMENT] VARCHAR(45) NULL,
[RANK] VARCHAR(3) NULL,
);
 
INSERT INTO #Kopp_Referred_Dates([PA-PT-NO],[PA-REFERRED-DATE],[PA-REFERRED-COMMENT],[RANK])
 
         SELECT (CAST([PA-PT-NO-WOSCD] as varchar) + CAST([pa-pt-no-scd-1] as varchar)) as 'PA-PT-NO',
         [PA-SMART-DATE] AS 'PA-REFERRED-DATE',
         [PA-SMART-COMMENT] AS 'PA-REFERRED-COMMENT',
         RANK() OVER (PARTITION BY [pa-pt-no-woscd] ORDER BY [pa-smart-date] asc)
 
         FROM [Echo_Active].[dbo].[AccountComments]
 
         WHERE [pa-smart-svc-cd-woscd] IN ('216','219')
 
 
         UNION
 
         SELECT (CAST([PA-PT-NO-WOSCD] as varchar) + CAST
