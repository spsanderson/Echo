USE [SMS]
GO
/****** Object:  StoredProcedure [dbo].[c_transfer_patient_sp]    Script Date: 1/18/2024 11:46:54 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
***********************************************************************
File: c_transfer_patient_sp.sql

Input Parameters:
	Enter Here

Tables/Views:
	[echo_active].[dbo].[userdefined]
	[echo_archive].[dbo].[userdefined]

Creates Table:
    dbo.c_transfer_patient_tbl

Functions:
	None

Author: Fang Wu

Department: Finance, Revenue Cycle

Purpose/Description
	Transfer Patient List for Late Charge Dashboard

Revision History:
Date		Version		Description
----		----		----
2024-01-18	v1			Initial Creation

***********************************************************************
*/

-- Create the stored procedure in the specified schema
ALTER PROCEDURE [dbo].[c_transfer_patient_sp]
AS

drop table if exists [sms].[dbo].[c_transfer_patient_tbl]
select cast([pa-pt-no-woscd] as varchar) + cast([pa-pt-no-scd-1] as varchar) as 'Pt_No'
      ,[pa-user-create-date]
	  ,[pa-user-text]
	  ,[pa-ctl-paa-xfer-date]

	  into [sms].[dbo].[c_transfer_patient_tbl]
from [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[echo_active].[dbo].[userdefined]
where [pa-component-id]='TRANSFAC' and [pa-user-text] in ('ELI','SHH')

union

select cast([pa-pt-no-woscd] as varchar) + cast([pa-pt-no-scd-1] as varchar) as 'Pt_No'
      ,[pa-user-create-date]
	  ,[pa-user-text]
	  ,[pa-ctl-paa-xfer-date]
from [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[echo_archive].[dbo].[userdefined]
where [pa-component-id]='TRANSFAC' and [pa-user-text] in ('ELI','SHH')




