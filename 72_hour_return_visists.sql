with cte as (
	select mrn,
		cast(Admit_Date as date) as [adm_date],
		cast(Dsch_Date as date) as [dsch_date],
		pt_no,
		Acct_Type,
		hosp_svc,
		hosp_svc_description,
		[hours_until_next_visit] = datediff(hour, Dsch_Date, lead(admit_date) over(partition by mrn order by admit_date)),
		[next_admit_date] = cast(lead(admit_date) over(partition by mrn order by admit_date) as date),
		[next_dsch_date] = cast(lead(dsch_date) over(partition by mrn order by admit_date) as date),
		[next_visit_no] = lead(pt_no) over(partition by mrn order by admit_date),
		[next_acct_type] = lead(acct_type) over(partition by mrn order by admit_date),
		[next_hosp_svc] = lead(hosp_svc) over(partition by mrn order by admit_date),
		[next_hosp_svc_description] = lead(hosp_svc_description) over(partition by mrn order by admit_date)
	from sms.dbo.Pt_Accounting_Reporting_ALT
	where mrn != ''
	and mrn is not null
	and Unit_No is null
	and Active_Archive = 'active'
	and Tot_Chgs > 0
	and FC != 'x'
) 

select *
from cte
where hours_until_next_visit <= 72
and adm_date >= '2024-01-01'