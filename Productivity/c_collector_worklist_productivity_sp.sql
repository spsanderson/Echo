USE [PARA]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[c_collector_worklist_productivity_sp]
AS

SET NOCOUNT ON;
SET ANSI_WARNINGS OFF;

/*
***********************************************************************
File: c_collector_worklist_productivity_sp.sql

Input Parameters:
	None

Tables/Views:
	swarm.dbo.CW_DTL_productivity c
    dbo.c_productivity_users_tbl

Creates Table/View:
	dbo.c_collector_worklist_productivity_tbl

Functions:
	None

Author: Steven P. Sanderson II, MPH

Department: Patient Financial Services

Purpose/Description
	This is part of the productivity report.  It creates a table that
    contains the collector worklist data needed for the productivity
    report.

Revision History:
Date		Version		Description
----		----		----
2023-03-31	v1			Initial Creation
***********************************************************************
*/

IF NOT EXISTS (
    SELECT TOP 1 * FROM SYSOBJECTS WHERE NAME = 'c_collector_worklist_productivity_tbl' AND TYPE = 'U'
)

BEGIN
    -- Create the table in the specified schema
    CREATE TABLE dbo.c_collector_worklist_productivity_tbl
    (
        [report_date] VARCHAR(255),
        [ifacctnewoldoff] VARCHAR(255),
        [supervisor_id] VARCHAR(255),
        [supervisor_name] VARCHAR(255),
        [responsible_collector] VARCHAR(255),
        [rc_name] VARCHAR(255),
        [worklist] VARCHAR(255),
        [worklist_name] VARCHAR(255),
        [seq_no] VARCHAR(255),
        [patient_no] VARCHAR(255),
        [patient_name] VARCHAR(255),
        [pyr_id] VARCHAR(255),
        [guar_no] VARCHAR(255),
        [med_rec_no] VARCHAR(255),
        [fol_amt] VARCHAR(255),
        [last_bill_date] VARCHAR(255),
        [last_pay_date] VARCHAR(255),
        [rpm_vof_line] VARCHAR(255),
        [fol_lvl] VARCHAR(255),
        [fol_typ] VARCHAR(255),
        [file_type] VARCHAR(255),
        [svc_fac_id] VARCHAR(255),
        [user_id] VARCHAR(255),
        [unit] VARCHAR(255),
        [sp_rundate_time] SMALLDATETIME
    )

    DECLARE @BEGINDATE DATETIME
    DECLARE @PRODREPORTDATE DATETIME
    DECLARE @ThisDate DATETIME
      
    SET @ThisDate = getdate()
    SET @BEGINDATE = dateadd(wk, datediff(wk, 0, @ThisDate) - 1, - 1)
    SET @PRODREPORTDATE = @BEGINDATE - 1

    -- Insert data into the table
    INSERT INTO dbo.c_collector_worklist_productivity_tbl (
        [report_date],
        [ifacctnewoldoff],
        [supervisor_id],
        [supervisor_name],
        [responsible_collector],
        [rc_name],
        [worklist],
        [worklist_name],
        [seq_no],
        [patient_no],
        [patient_name],
        [pyr_id],
        [guar_no],
        [med_rec_no],
        [fol_amt],
        [last_bill_date],
        [last_pay_date],
        [rpm_vof_line],
        [fol_lvl],
        [fol_typ],
        [file_type],
        [svc_fac_id],
        [user_id],
        [unit],
        [sp_rundate_time]
    )

    SELECT [Report Date],
        [IfAcctNewOldOff],
        [Supervisor ID],
        [Supervisor Name],
        [RESPONSIBLE COLLECTOR],
        [RC Name],
        [WORKLIST],
        [WORKLIST NAME],
        [Seq No],
        [PATIENT NO],
        [PATIENT NAME],
        [Pyr ID],
        [GUAR NO],
        [MED REC NO],
        [Fol AMT],
        [LAST BILL DATE],
        [LAST PAY DATE],
        [RPM/VOF Line],
        [FOL LVL],
        [FOL TYP],
        [FILE],
        [SVC FAC ID],
        [User_ID],
        [UNIT],
        GETDATE()
    FROM swarm.dbo.CW_DTL_productivity c
    RIGHT JOIN dbo.c_productivity_users_tbl z ON c.[RESPONSIBLE COLLECTOR] = z.[User_ID]
    WHERE c.[Report Date] = @PRODREPORTDATE
END
    
ELSE BEGIN

    DECLARE @BEGINDATEA DATETIME
    DECLARE @PRODREPORTDATEA DATETIME
    DECLARE @ThisDateA DATETIME
      
    SET @ThisDateA = getdate()
    SET @BEGINDATEA = dateadd(wk, datediff(wk, 0, @ThisDateA) - 1, - 1)
    SET @PRODREPORTDATEA = @BEGINDATEA - 1

    -- Insert data into the table
    INSERT INTO dbo.c_collector_worklist_productivity_tbl (
        [report_date],
        [ifacctnewoldoff],
        [supervisor_id],
        [supervisor_name],
        [responsible_collector],
        [rc_name],
        [worklist],
        [worklist_name],
        [seq_no],
        [patient_no],
        [patient_name],
        [pyr_id],
        [guar_no],
        [med_rec_no],
        [fol_amt],
        [last_bill_date],
        [last_pay_date],
        [rpm_vof_line],
        [fol_lvl],
        [fol_typ],
        [file_type],
        [svc_fac_id],
        [user_id],
        [unit],
        [sp_rundate_time]
    )

    SELECT [Report Date],
        [IfAcctNewOldOff],
        [Supervisor ID],
        [Supervisor Name],
        [RESPONSIBLE COLLECTOR],
        [RC Name],
        [WORKLIST],
        [WORKLIST NAME],
        [Seq No],
        [PATIENT NO],
        [PATIENT NAME],
        [Pyr ID],
        [GUAR NO],
        [MED REC NO],
        [Fol AMT],
        [LAST BILL DATE],
        [LAST PAY DATE],
        [RPM/VOF Line],
        [FOL LVL],
        [FOL TYP],
        [FILE],
        [SVC FAC ID],
        [User_ID],
        [UNIT],
        GETDATE()
    FROM swarm.dbo.CW_DTL_productivity c
    RIGHT JOIN dbo.c_productivity_users_tbl z ON c.[RESPONSIBLE COLLECTOR] = z.[User_ID]
    WHERE c.[Report Date] = @PRODREPORTDATEA
END

-- example to execute the stored procedure we just created
--EXECUTE dbo.c_collector_worklist_productivity_sp
