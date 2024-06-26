/*
***********************************************************************
File: c_Insurance_Updated_By_EMUE_v.sql

Input Parameters:
	None

Tables/Views:
    [Echo_Active].[dbo].[AccountComments]

Creates Table/View:
	dbo.c_Insurance_Updated_By_EMUE_v
	

Functions:
	None

Author: Fang Wu

Department: Patient Financial Services

Purpose/Description
	Create a View for the accounts of which the insurance plans were updated by EMUE in SMS database 

Revision History:
Date		Version		Description
----		----		----
2023-11-06	v1			Initial Creation		
2023-11-08  v2	        Add archive data
***********************************************************************
*/

IF EXISTS (
    SELECT
        *
    FROM
        sys.views
        JOIN sys.schemas ON sys.views.schema_id = sys.schemas.schema_id
    WHERE
        sys.schemas.name = N'dbo'
        AND sys.views.name = N'c_Insurance_Updated_By_EMUE_v'
) DROP VIEW dbo.c_Insurance_Updated_By_EMUE_v
GO

Create View  dbo.c_Insurance_Updated_By_EMUE_v as
SELECT
      cast(a.[PA-PT-NO-WOSCD] as varchar) + Cast(a.[PA-PT-NO-SCD-1] as varchar) as 'pt_no'
	  ,cast(a.[PA-SMART-SVC-CD-WOSCD] as varchar) + cast(a.[PA-SMART-SVC-CD-SCD] as varchar) as 'Svc_Cd'
      --,a.[PA-SMART-COUNTER]
      ,a.[PA-SMART-DATE]
      ,a.[PA-SMART-COMMENT]
      --,a.[PA-SMART-IND]
	  ,b.[PA-SMART-COMMENT] as 'Project'
    
  FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Active].[dbo].[AccountComments] a 
  left join  [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Active].[dbo].[AccountComments] b
  on a.[PA-PT-NO-WOSCD]=b.[PA-PT-NO-WOSCD] and a.[PA-SMART-DATE]=b.[PA-SMART-DATE]
      and 
		(b.[PA-SMART-SVC-CD-WOSCD]='3800867' and b.[PA-SMART-COMMENT] not like 'Insurance%')
 
  where (a.[PA-SMART-SVC-CD-WOSCD]='3800867' and a.[PA-SMART-COMMENT] like 'Insurance%')

  union

  SELECT
      cast(a.[PA-PT-NO-WOSCD] as varchar) + Cast(a.[PA-PT-NO-SCD-1] as varchar) as 'pt_no'
	  ,cast(a.[PA-SMART-SVC-CD-WOSCD] as varchar) + cast(a.[PA-SMART-SVC-CD-SCD] as varchar) as 'Svc_Cd'
      --,a.[PA-SMART-COUNTER]
      ,a.[PA-SMART-DATE]
      ,a.[PA-SMART-COMMENT]
      --,a.[PA-SMART-IND]
	  ,b.[PA-SMART-COMMENT] as 'Project'
    
  FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Archive].[dbo].[AccountComments] a 
  left join  [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Archive].[dbo].[AccountComments] b
  on a.[PA-PT-NO-WOSCD]=b.[PA-PT-NO-WOSCD] and a.[PA-SMART-DATE]=b.[PA-SMART-DATE]
      and 
		(b.[PA-SMART-SVC-CD-WOSCD]='3800867' and b.[PA-SMART-COMMENT] not like 'Insurance%')
 
  where (a.[PA-SMART-SVC-CD-WOSCD]='3800867' and a.[PA-SMART-COMMENT] like 'Insurance%')

  GO
         
		