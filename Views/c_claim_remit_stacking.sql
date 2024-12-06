USE [SMS]
GO

/*
***********************************************************************
File: c_claim_remit_stacking_v.sql

Input Parameters:
	None

Tables/Views:
	sms.dbo.c_remit_tbl
	sms.dbo.c_INST_tbl


Creates Table/View:
	c_claim_remit_stacking_v

Functions:
	None

Author: Steven P. Sanderson II, MPH

Department: Patient Financial Services

Purpose/Description
This SQL script performs the following operations:

1. Common Table Expressions (CTEs):
	- `cte`: Combines data from `sms.dbo.c_INST_tbl` and `sms.dbo.c_remit_tbl` into a unified format.
	- `EventsWithNum`: Adds a row number (`event_num`) to each event, partitioned by patient number, 
		unit number, sequence number, and insurance code.
	- `ChainNumber`: Assigns a chain number to the first event for each patient.
	- `Chains`: Calculates the total number of chains for each patient and unit.

2. Final SELECT Statement:
	- Joins the `EventsWithNum`, `Chains`, and `ChainNumber` CTEs.
	- Adds `chain_number` and `total_chain_count` columns to the result set.
	- Filters the results to include only specific patient numbers.
	- Orders the results by patient number, sequence number, and file creation date.

The script is designed to analyze and stack claim and remit data for specific patient accounts.

Revision History:
Date		Version		Description
----		----		----
2024-12-06	v1			Initial Creation
***********************************************************************
*/

CREATE VIEW dbo.c_claim_remit_stacking_v
AS
WITH cte AS (
	SELECT Patient_Account_Number,
		pt_no,
		Ins_CD,
		Unit_NO,
		Seq_No,
		record_type = 'INST',
		index_key = inst,
		Export_Date_Time,
		[File_Name],
		File_Creation_Date,
		EDI_Version,
		EDI_Format,
		Charge_Amount,
		Statement_From_Date,
		Statement_Through_Date,
		[bill_type] = CONCAT (
			facility_type_code,
			Frequency_Code
			),
		tot_pay_adj_amount = NULL,
		coinsured_copay = NULL,
		claim_status = NULL
	FROM sms.dbo.c_INST_tbl
	
	UNION ALL
	
	SELECT Patient_Control_Number,
		pt_no,
		Ins_CD,
		Unit_NO,
		Seq_No,
		record_type = 'REMIT',
		index_key = remit,
		Export_Date_Time,
		[File_Name],
		File_Creation_Date,
		EDI_Version,
		EDI_Format,
		Charge_Amount,
		Date_of_Service,
		Service_Date_Through,
		Bill_Type,
		tot_pay_adj_amt = Paid_Amount,
		CoInsured_CoPay,
		claim_status
	FROM sms.dbo.c_remit_tbl
	),

EventsWithNum AS (
	SELECT *,
		[event_num] = ROW_NUMBER() OVER (
			PARTITION BY A.pt_no,
			A.unit_no,
			seq_no,
			ins_cd ORDER BY A.pt_no,
				A.unit_no,
				A.seq_no,
				A.file_creation_date
			)
	FROM CTE AS A
	WHERE A.PT_NO IS NOT NULL
		AND A.PT_NO != '0'
		AND LEFT(A.PT_NO, 1) != '-'
		AND A.Ins_CD IS NOT NULL
	),

ChainNumber AS (
	SELECT Pt_NO,
		Unit_NO,
		seq_no,
		File_Creation_Date,
		chain_number = ROW_NUMBER() OVER (
			PARTITION BY pt_no ORDER BY pt_no
			)
	FROM EventsWithNum
	WHERE event_num = 1
	),

Chains AS (
	SELECT PT_NO,
		unit_no,
		total_chain_count = SUM(CASE 
				WHEN event_num = 1
					THEN 1
				ELSE 0
				END)
	FROM EventsWithNum
	GROUP BY Pt_NO,
		unit_no
	)

SELECT A.*,
	[chain_number] = COUNT(C.chain_number) OVER (
		PARTITION BY A.pt_no,
		ISNULL(A.unit_no, '0') ORDER BY A.pt_no,
			A.seq_no,
			A.file_creation_date
		),
	[total_chain_count] = B.total_chain_count
FROM EventsWithNum AS A
INNER JOIN Chains AS B ON A.Pt_NO = B.Pt_NO
LEFT JOIN ChainNumber AS C ON A.Pt_NO = c.Pt_NO
	AND A.File_Creation_Date = c.File_Creation_Date
	AND A.Seq_No = C.Seq_No
WHERE A.Pt_NO IN ('10213503617', '10224846559', '10208688654', '10229456560')
ORDER BY A.Pt_NO,
	A.Seq_No,
	A.File_Creation_Date;
GO


