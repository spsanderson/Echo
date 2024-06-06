/*
***********************************************************************
File: c_tableau_revenue_integrity_pmts_outcome_v.sql

Input Parameters:
	None

Tables/Views:
	c_tableau_revenue_integrity_dashboard_tbl
	c_tableau_revenue_integrity_dashboard_payments_tbl

Creates Table/View:
	c_tableau_revenue_integrity_pmts_outcome_v

Functions:
	None

Author: Steven P. Sanderson II, MPH

Department: Patient Financial Services

Purpose/Description
	To create a view that will be used to create a Tableau dashboard for the
    Outcomes team.

Revision History:
Date		Version		Description
----		----		----
2024-04-18	1.0			Initial Creation
***********************************************************************
*/

IF EXISTS (
		SELECT *
		FROM sys.VIEWS
		JOIN sys.schemas ON sys.VIEWS.schema_id = sys.schemas.schema_id
		WHERE sys.schemas.name = N'dbo'
			AND sys.VIEWS.name = N'c_tableau_revenue_integrity_pmts_outcome_v'
		)
	DROP VIEW dbo.c_tableau_revenue_integrity_pmts_outcome_v
GO

-- Create the view in the specified schema
CREATE VIEW dbo.c_tableau_revenue_integrity_pmts_outcome_v
AS

WITH CTE
AS (
	SELECT t1.pt_no,
		t1.pa_smart_comment,
		t1.letter_type,
		t1.[user_id_dirty],
		t1.pa_smart_date,
		t2.pa_ins_plan,
		t2.pa_dtl_cdm_description,
		t2.pa_dtl_chg_amt AS [pmt_after_letter],
		t2.pa_dtl_post_date,
		t2.pa_ctl_paa_xfer_date,
		t2.pa_unit_date,
		[rec_no] = ROW_NUMBER() OVER (
			PARTITION BY T1.PT_NO,
			t2.PA_DTL_POST_DATE ORDER BY DATEDIFF(DAY, T1.PA_SMART_DATE, T2.PA_DTL_POST_DATE)        
			),
		t1.report_run_datetime,
		t3.pa_dtl_chg_amt AS [tot_pmt_adj_after_activity]
	FROM dbo.c_tableau_revenue_integrity_dashboard_tbl t1    
	CROSS APPLY (
		SELECT TOP 1 pa_ins_plan,
			pa_dtl_cdm_description,
			pa_dtl_post_date,
			pa_ctl_paa_xfer_date,
			pa_unit_date,
			SUM(pa_dtl_chg_amt) AS pa_dtl_chg_amt
		FROM dbo.c_tableau_revenue_integrity_dashboard_payments_tbl        
		WHERE pa_dtl_post_date > t1.pa_smart_date            
			AND pt_no = t1.pt_no
			AND pa_ctl_paa_xfer_date = t1.pa_ctl_paa_xfer_date
		GROUP BY pa_ins_plan,
			pa_dtl_cdm_description,
			pa_dtl_post_date,
			pa_ctl_paa_xfer_date,
			pa_unit_date 
		ORDER BY pa_dtl_post_date     
		) t2
	CROSS APPLY (
		SELECT SUM(pa_dtl_chg_amt) AS pa_dtl_chg_amt
		FROM dbo.c_tableau_revenue_integrity_dashboard_payments_tbl        
		WHERE pa_dtl_post_date > t1.pa_smart_date            
			AND pt_no = t1.pt_no
			AND pa_ctl_paa_xfer_date = t1.pa_ctl_paa_xfer_date
		GROUP BY pa_ins_plan,
			pa_dtl_cdm_description,
			pa_dtl_post_date,
			pa_ctl_paa_xfer_date,
			pa_unit_date 
		) t3
	)

SELECT CTE.pt_no,
	CTE.pa_smart_comment,
	CTE.letter_type,
	[user_id] = CASE 
		WHEN B.[USER_ID] IS NULL
			THEN 'UNKNOWN'
		ELSE B.[USER_ID]
		END,
	CTE.[user_id_dirty],
	CTE.pa_smart_date,
	CTE.pa_ins_plan,
	[ins_desc] = CASE 
		WHEN CTE.pa_ins_plan = '00'
			THEN 'SELF PAY'
		ELSE UPPER(INS.[payer_name])
		END,
	[payer_type] = CASE 
		WHEN CTE.pa_ins_plan = '00'
			THEN 'SELF PAY'
		ELSE UPPER(INS.[product_class])
		END,
	[payer_carrier] = CASE 
		WHEN CTE.pa_ins_plan = '00'
			THEN 'SELF PAY'
		ELSE UPPER(INS.payer_organization)
		END,
	CTE.pa_dtl_cdm_description,
	CTE.pmt_after_letter,
	CTE.tot_pmt_adj_after_activity,
	CTE.pa_dtl_post_date,
	CTE.pa_ctl_paa_xfer_date,
	CTE.pa_unit_date,
	[days_to_payment] = datediff(day, cte.pa_smart_date, cte.pa_dtl_post_date),
	[report_rundate] = CAST(CTE.report_run_datetime AS DATE),
	[activity_type_group] = CASE 
		WHEN CTE.letter_type IN ('RIRI')
			THEN 'RESOLVED'
		WHEN CTE.letter_type IN ('RIUI')
			THEN 'RESOLVED - SENT IN ERROR'
		WHEN CTE.letter_type IN ('RIRV')
			THEN 'REFERRED'
		END
FROM CTE
LEFT JOIN dbo.revenue_cycle_employee_listing AS B ON CTE.[USER_ID_DIRTY] = B.[USER_ID]
LEFT JOIN dbo.c_tableau_insurance_tbl AS INS ON CTE.pa_ins_plan = INS.[Code]
WHERE CTE.REC_NO = 1;