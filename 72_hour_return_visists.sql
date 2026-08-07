WITH cte
AS (
	SELECT mrn,
		cast(Admit_Date AS DATE) AS [adm_date],
		cast(Dsch_Date AS DATE) AS [dsch_date],
		pt_no,
		Acct_Type,
		hosp_svc,
		hosp_svc_description,
		[hours_until_next_visit] = datediff(hour, Dsch_Date, lead(admit_date) OVER (
				PARTITION BY mrn ORDER BY admit_date
				)),
		[next_admit_date] = cast(lead(admit_date) OVER (
				PARTITION BY mrn ORDER BY admit_date
				) AS DATE),
		[next_dsch_date] = cast(lead(dsch_date) OVER (
				PARTITION BY mrn ORDER BY admit_date
				) AS DATE),
		[next_visit_no] = lead(pt_no) OVER (
			PARTITION BY mrn ORDER BY admit_date
			),
		[next_acct_type] = lead(acct_type) OVER (
			PARTITION BY mrn ORDER BY admit_date
			),
		[next_hosp_svc] = lead(hosp_svc) OVER (
			PARTITION BY mrn ORDER BY admit_date
			),
		[next_hosp_svc_description] = lead(hosp_svc_description) OVER (
			PARTITION BY mrn ORDER BY admit_date
			)
	FROM sms.dbo.Pt_Accounting_Reporting_ALT
	WHERE mrn != ''
		AND mrn IS NOT NULL
		AND UNIT_NO IS NULL
		AND Active_Archive = 'active'
		AND Tot_Chgs > 0
		AND FC != 'x'
	)
SELECT *
FROM cte
WHERE hours_until_next_visit <= 72
	AND hours_until_next_visit >= 0
	AND adm_date >= '2024-01-01'

