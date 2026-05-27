SELECT 	active_archive_ind,
	acct_type,
	file_type,
	[visit_count] = FORMAT(visit_count, 'N0'),
	[balance] = FORMAT(balance, 'N0'),
	update_date,
	update_time
FROM sms.dbo.c_alt_tbl_summary_v
ORDER BY active_archive_ind,
	acct_type,
	file_type;
