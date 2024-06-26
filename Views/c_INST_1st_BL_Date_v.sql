USE [SMS]
GO

/****** Object:  View [dbo].[c_INST_1st_BL_Date_v]    Script Date: 11/20/2023 3:31:36 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


create VIEW [dbo].[c_INST_1st_BL_Date_v] AS

  select 
   [Pt_No]
  ,[Ins_CD]
  ,[Unit_No]
  ,min([file_creation_Date]) as '1st_BL_Date'
  FROM [SMS].[dbo].[c_INST_v] 
  group by [Pt_No],[Ins_CD],[Unit_No]

GO
