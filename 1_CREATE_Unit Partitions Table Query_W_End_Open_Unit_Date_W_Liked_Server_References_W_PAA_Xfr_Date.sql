USE [SMS]

DROP TABLE IF EXISTS dbo.[#Units]

GO

CREATE TABLE [#Units]

 
 
(
[PA-PT-NO-WOSCD] DECIMAL(11,0) NOT NULL,
[PA-PT-NO-SCD] CHAR(1) NOT NULL,
[PA-CTL-PAA-XFER-DATE] DATETIME NULL,
[PA-PT-NAME] CHAR(25) NULL,
[PA-MED-REC-NO] CHAR(12) NULL,
[UNIT-DATE] DATETIME NULL,
[pa-unit-no] char(4) null,
[pa-hosp-svc] char(3) null

);




INSERT INTO [#Units] ([PA-PT-NO-WOSCD],[PA-PT-NO-SCD],[PA-CTL-PAA-XFER-DATE],[PA-PT-NAME],[PA-MED-REC-NO],[UNIT-DATE],[pa-unit-no],[pa-hosp-svc])
  
  





SELECT A.[PA-PT-NO-woscd]
      ,A.[pa-pt-no-scd-1]
	  ,A.[PA-CTL-PAA-XFER-DATE]
	  ,A.[PA-PT-NAME]
	  ,A.[PA-MED-REC-NO]
	  ,ISNULL(b.[PA-UNIT-DATE],DATEADD(s,-1,DATEADD(mm, DATEDIFF(m,0,GETDATE())+1,0)) ) as 'UNIT-DATE'
	  ,b.[PA-UNIT-NO]
	  ,a.[pa-hosp-svc]
     
  
   
FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_ACTIVE].dbo.PatientDemographics a left outer join [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_ACTIVE].dbo.unitizedaccounts b
ON a.[pa-pt-no-woscd]=b.[pa-pt-no-woscd] and a.[pa-pt-no-scd]=b.[pa-pt-no-scd-1] and a.[pa-ctl-paa-xfer-date]=b.[pa-ctl-paa-xfer-date]

WHERE  ( a.[pa-acct-type] in ('0','6','7') AND a.[pa-unit-sts] = 'U' )   -- is not null and b.[pa-unit-date] BETWEEN '2015-11-01 00:00:00.000' AND GETDATE())
 
 
 UNION

  SELECT A.[PA-PT-NO-woscd]
      ,A.[pa-pt-no-scd-1]
	  ,A.[pa-ctl-paa-xfer-date]
	  ,A.[PA-PT-NAME]
	  ,A.[PA-MED-REC-NO]
	  ,ISNULL(b.[PA-UNIT-DATE],DATEADD(s,-1,DATEADD(mm, DATEDIFF(m,0,GETDATE())+1,0)) ) as 'UNIT-DATE'
	  ,b.[PA-UNIT-NO]
	  ,a.[pa-hosp-svc]
  
   
FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_ARCHIVE].dbo.PatientDemographics a left outer join [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_ARCHIVE].dbo.unitizedaccounts b
ON a.[pa-pt-no-woscd]=b.[pa-pt-no-woscd] and a.[pa-pt-no-scd]=b.[pa-pt-no-scd-1] and a.[pa-ctl-paa-xfer-date]=b.[pa-ctl-paa-xfer-date]

WHERE  ( a.[pa-acct-type] in ('0','6','7') AND a.[pa-unit-sts] = 'U')-- is not null and b.[pa-unit-date] BETWEEN '2015-11-01 00:00:00.000' AND GETDATE())
 
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


DROP TABLE IF EXISTS dbo.[#Units_W_Rank]

GO

CREATE TABLE [#Units_W_Rank]

 
 
(
[PA-PT-NO-WOSCD] DECIMAL(11,0) NOT NULL,
[PA-PT-NO-SCD] CHAR(1) NOT NULL,
[pa-ctl-paa-xfer-date] datetime null,
[PA-PT-NAME] CHAR(25) NULL,
[PA-MED-REC-NO] CHAR(12) NULL,
[UNIT-DATE] DATETIME NULL,
[pa-unit-no] char(4) null,
[alt-pa-unit-no] char(5) null,
[pa-hosp-svc] char(3) null

);




INSERT INTO [#Units_W_Rank] ([PA-PT-NO-WOSCD],[PA-PT-NO-SCD],[pa-ctl-paa-xfer-date],[PA-PT-NAME],[PA-MED-REC-NO],[UNIT-DATE],[pa-unit-no],[alt-pa-unit-no],[pa-hosp-svc])
  
  





SELECT [PA-PT-NO-woscd]
      ,[pa-pt-no-scd]
	  ,[pa-ctl-paa-xfer-date]
	  ,[PA-PT-NAME]
	  ,[PA-MED-REC-NO]
      ,[UNIT-DATE]
	  ,[PA-UNIT-NO]
      ,RANK() OVER (PARTITION BY [pa-pt-no-woscd] ORDER BY [unit-date] asc) as 'alt-pa-unit-no'
	  ,[pa-hosp-svc]
  
   
FROM dbo.[#Units]

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

SELECT *

FROM dbo.[#Units_W_Rank]

  ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
USE [SMS]


DROP TABLE IF EXISTS [Unit_Partitions]

GO

  
  SELECT a.[pa-pt-no-woscd],
  a.[pa-pt-no-scd],
  a.[pa-ctl-paa-xfer-date],
  A.[PA-PT-NAME],
  A.[PA-MED-REC-NO],
  isnull(DATEADD(DAY,1,b.[unit-date]),DATEADD(DAY,1,EOMONTH(a.[unit-date],-1))) as 'Start_Unit_Date',
  DATEADD(DAY,0,a.[unit-date]) as 'End_Unit_Date',
   a.[pa-unit-no],
   a.[pa-hosp-svc]

INTO [Unit_Partitions]


  FROM [dbo].[#Units_W_Rank] a left outer join [dbo].[#Units_W_Rank] b
  ON a.[pa-pt-no-woscd]=b.[pa-pt-no-woscd] and b.[alt-pa-unit-no]=a.[alt-pa-unit-no]-1


  ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

  SELECT *  FROM [Unit_Partitions]

  -- where [pa-pt-no-woscd] = '1014891738'
  WHERE  [pa-pt-no-woscd] = '1000214949'

  ORDER BY [pa-pt-no-woscd], [pa-unit-no]

 