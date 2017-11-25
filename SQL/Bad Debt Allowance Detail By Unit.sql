(
	SELECT CAST(a.[pa-pt-no-woscd] as varchar) + 
	CAST(a.[pa-pt-no-scd-1] as varchar) AS 'pa-pt-no'
	, b.[pa-unit-no]
	, CAST(a.[pa-pt-no-woscd] as varchar) + 
	  CAST(a.[pa-pt-no-scd-1] as varchar) + 
	  CAST(b.[pa-unit-no] as varchar) AS 'pa-pt-no-wunit'
	, b.[pa-unit-no]
	, b.[pa-unit-date]
	, CASE
		WHEN b.[pa-unit-no] IS NULL 
			THEN a.[pa-acct-bd-xfr-date]
			ELSE b.[pa-unit-xfr-bd-date]
	  END as 'Bad_Debt_Xfr_Date'
	, c.[pa-dtl-type-ind]
	, c.[pa-dtl-svc-cd-woscd]
	, c.[pa-dtl-svc-cd-scd]
	, c.[pa-dtl-cdm-description]
	, c.[pa-dtl-technical-desc]
	--, SUM(c.[pa-dtl-chg-qty])
	, SUM(c.[pa-dtl-chg-amt]) as 'Total'

	FROM [Echo_Archive].dbo.PatientDemographics AS a 
	left outer join [Echo_Archive].dbo.unitizedaccounts AS b
	ON a.[pa-pt-no-woscd] = b.[pa-pt-no-woscd] 
		and a.[pa-pt-no-scd-1] = b.[pa-pt-no-scd-1] 
	left outer join [Echo_Archive].dbo.detailinformation AS c
	ON b.[pa-pt-no-woscd] = c.[pa-pt-no-woscd] 
		and b.[pa-unit-date] = c.[pa-dtl-unit-date]


	WHERE 
	--(a.[pa-pt-representative] is not null AND not(a.[pa-pt-representative] IN ('','000'))
	--a.[pa-acct-type] NOT IN ('4','6')
	--AND a.[pa-op-first-ins-bl-date] > '5/26/2017'
	(
		(
			b.[pa-unit-no] is null 
			and a.[pa-acct-bd-xfr-date] BETWEEN '2015-01-01 00:00:00.000' AND '2017-05-31 23:59:59.000'
		)
		OR 
		(
			b.[pa-unit-no] is not null 
			and b.[pa-unit-xfr-bd-date] BETWEEN '2015-01-01 00:00:00.000' AND '2017-05-31 23:59:59.000'
		)
	)
	and c.[pa-dtl-type-ind] <> '1'
	and c.[pa-dtl-fc] IN (
		'0','1','2','3','4','5','6','7','8','9'
	)

	GROUP BY CAST(a.[pa-pt-no-woscd] as varchar) + CAST(a.[pa-pt-no-scd-1] as varchar)
	, b.[pa-unit-no]
	, CAST(a.[pa-pt-no-woscd] as varchar) + CAST(a.[pa-pt-no-scd-1] as varchar) + CAST(b.[pa-unit-no] as varchar)
	, b.[pa-unit-no]
	, b.[pa-unit-date]
	, a.[pa-acct-bd-xfr-date]
	, b.[pa-unit-xfr-bd-date]
	, c.[pa-dtl-type-ind]
	, c.[pa-dtl-svc-cd-woscd]
	, c.[pa-dtl-svc-cd-scd]
	, c.[pa-dtl-cdm-description]
	, c.[pa-dtl-technical-desc]

	HAVING SUM(c.[pa-dtl-chg-amt]) <> '0'

	UNION

	SELECT CAST(a.[pa-pt-no-woscd] as varchar) + 
	  CAST(a.[pa-pt-no-scd-1] as varchar) as 'pa-pt-no'
	, b.[pa-unit-no]
	, CAST(a.[pa-pt-no-woscd] as varchar) + 
	  CAST(a.[pa-pt-no-scd-1] as varchar) + 
	  CAST(b.[pa-unit-no] as varchar) as 'pa-pt-no-wunit'
	, b.[pa-unit-no]
	, b.[pa-unit-date]
	, CASE
		WHEN b.[pa-unit-no] IS NULL 
			THEN a.[pa-acct-bd-xfr-date]
			ELSE b.[pa-unit-xfr-bd-date]
	  END as 'Bad_Debt_Xfr_Date'
	, c.[pa-dtl-type-ind]
	, c.[pa-dtl-svc-cd-woscd]
	, c.[pa-dtl-svc-cd-scd]
	, c.[pa-dtl-cdm-description]
	, c.[pa-dtl-technical-desc]
	--, c.[pa-dtl-chg-qty]
	, SUM(c.[pa-dtl-chg-amt]) as 'Total'

	FROM [Echo_Active].dbo.PatientDemographics AS a 
	left outer join [Echo_Active].dbo.unitizedaccounts AS b
	ON a.[pa-pt-no-woscd] = b.[pa-pt-no-woscd] 
		and a.[pa-pt-no-scd-1] = b.[pa-pt-no-scd-1] 
	left outer join [Echo_Active].dbo.detailinformation AS c
	ON b.[pa-pt-no-woscd] = c.[pa-pt-no-woscd] 
		and b.[pa-unit-date] = c.[pa-dtl-unit-date]

	WHERE 
	--(a.[pa-pt-representative] is not null AND not(a.[pa-pt-representative] IN ('','000'))
	--a.[pa-acct-type] NOT IN ('4','6')
	--AND a.[pa-op-first-ins-bl-date] > '5/26/2017'
	(
		(
			b.[pa-unit-no] is null 
			and a.[pa-acct-bd-xfr-date] BETWEEN '2015-01-01 00:00:00.000' AND '2017-05-31 23:59:59.000'
		)
		OR 
		(
			b.[pa-unit-no] is not null 
			and b.[pa-unit-xfr-bd-date] BETWEEN '2015-01-01 00:00:00.000' AND '2017-05-31 23:59:59.000'
		)
	)
	and c.[pa-dtl-type-ind] <> '1'
	and c.[pa-dtl-fc] IN (
		'0','1','2','3','4','5','6','7','8','9'
	)

	GROUP BY CAST(a.[pa-pt-no-woscd] as varchar) + CAST(a.[pa-pt-no-scd-1] as varchar)
	, b.[pa-unit-no]
	, CAST(a.[pa-pt-no-woscd] as varchar) + CAST(a.[pa-pt-no-scd-1] as varchar) + CAST(b.[pa-unit-no] as varchar)
	, b.[pa-unit-no]
	, b.[pa-unit-date]
	, a.[pa-acct-bd-xfr-date]
	, b.[pa-unit-xfr-bd-date]
	, c.[pa-dtl-type-ind]
	, c.[pa-dtl-svc-cd-woscd]
	, c.[pa-dtl-svc-cd-scd]
	, c.[pa-dtl-cdm-description]
	, c.[pa-dtl-technical-desc]

	HAVING SUM(c.[pa-dtl-chg-amt]) <> '0'
)

UNION

(
	SELECT CAST(a.[pa-pt-no-woscd] as varchar) + 
	CAST(a.[pa-pt-no-scd-1] as varchar) as 'pa-pt-no'
	, b.[pa-unit-no]
	, CAST(a.[pa-pt-no-woscd] as varchar) + 
	  CAST(a.[pa-pt-no-scd-1] as varchar) + 
	  CAST(b.[pa-unit-no] as varchar) as 'pa-pt-no-wunit'
	, b.[pa-unit-no]
	, b.[pa-unit-date]
	, CASE
		WHEN b.[pa-unit-no] IS NULL 
			THEN a.[pa-acct-bd-xfr-date]
			ELSE b.[pa-unit-xfr-bd-date]
	  END as 'Bad_Debt_Xfr_Date'
	, c.[pa-dtl-type-ind]
	, c.[pa-dtl-svc-cd-woscd]
	, c.[pa-dtl-svc-cd-scd]
	, c.[pa-dtl-cdm-description]
	, c.[pa-dtl-technical-desc]
	--, SUM(c.[pa-dtl-chg-qty])
	, SUM(c.[pa-dtl-chg-amt]) as 'Total'

	FROM [Echo_Archive].dbo.PatientDemographics AS a
	left outer join [Echo_Archive].dbo.unitizedaccounts AS b
	ON a.[pa-pt-no-woscd] = b.[pa-pt-no-woscd] 
		and a.[pa-pt-no-scd-1] = b.[pa-pt-no-scd-1] 
	left outer join [Echo_Archive].dbo.detailinformation AS c
	ON a.[pa-pt-no-woscd] = c.[pa-pt-no-woscd] 

	WHERE 
	--(a.[pa-pt-representative] is not null AND not(a.[pa-pt-representative] IN ('','000'))
	--a.[pa-acct-type] NOT IN ('4','6')
	--AND a.[pa-op-first-ins-bl-date] > '5/26/2017'
	(
		(
			b.[pa-unit-no] is null 
			and a.[pa-acct-bd-xfr-date] BETWEEN '2015-01-01 00:00:00.000' AND '2017-05-31 23:59:59.000'
		)
		OR 
		(
			b.[pa-unit-no] is not null 
			and b.[pa-unit-xfr-bd-date] BETWEEN '2015-01-01 00:00:00.000' AND '2017-05-31 23:59:59.000'
		)
	)
	and c.[pa-dtl-type-ind] <> '1'
	and c.[pa-dtl-fc] IN (
		'0','1','2','3','4','5','6','7','8','9'
	)
	and b.[pa-unit-no] is null

	GROUP BY CAST(a.[pa-pt-no-woscd] as varchar) + CAST(a.[pa-pt-no-scd-1] as varchar)
	, b.[pa-unit-no]
	, CAST(a.[pa-pt-no-woscd] as varchar) + CAST(a.[pa-pt-no-scd-1] as varchar) + CAST(b.[pa-unit-no] as varchar)
	, b.[pa-unit-no]
	, b.[pa-unit-date]
	, a.[pa-acct-bd-xfr-date]
	, b.[pa-unit-xfr-bd-date]
	, c.[pa-dtl-type-ind]
	, c.[pa-dtl-svc-cd-woscd]
	, c.[pa-dtl-svc-cd-scd]
	, c.[pa-dtl-cdm-description]
	, c.[pa-dtl-technical-desc]

	HAVING SUM(c.[pa-dtl-chg-amt]) <> '0'

	UNION

	SELECT CAST(a.[pa-pt-no-woscd] as varchar) + 
	CAST(a.[pa-pt-no-scd-1] as varchar) as 'pa-pt-no'
	, b.[pa-unit-no]
	, CAST(a.[pa-pt-no-woscd] as varchar) + 
	  CAST(a.[pa-pt-no-scd-1] as varchar) + 
	  CAST(b.[pa-unit-no] as varchar) as 'pa-pt-no-wunit'
	, b.[pa-unit-no]
	, b.[pa-unit-date]
	, CASE
		WHEN b.[pa-unit-no] IS NULL 
			THEN a.[pa-acct-bd-xfr-date]
			ELSE b.[pa-unit-xfr-bd-date]
	  END as 'Bad_Debt_Xfr_Date'
	, c.[pa-dtl-type-ind]
	, c.[pa-dtl-svc-cd-woscd]
	, c.[pa-dtl-svc-cd-scd]
	, c.[pa-dtl-cdm-description]
	, c.[pa-dtl-technical-desc]
	--, c.[pa-dtl-chg-qty]
	, SUM(c.[pa-dtl-chg-amt]) as 'Total'

	FROM [Echo_Active].dbo.PatientDemographics AS a 
	left outer join [Echo_Active].dbo.unitizedaccounts AS b
	ON a.[pa-pt-no-woscd] = b.[pa-pt-no-woscd] 
		and a.[pa-pt-no-scd-1] = b.[pa-pt-no-scd-1] 
	left outer join [Echo_Active].dbo.detailinformation AS c
	ON a.[pa-pt-no-woscd] = c.[pa-pt-no-woscd] 

	WHERE 
	--(a.[pa-pt-representative] is not null AND not(a.[pa-pt-representative] IN ('','000'))
	--a.[pa-acct-type] NOT IN ('4','6')
	--AND a.[pa-op-first-ins-bl-date] > '5/26/2017'
	(
		(
			b.[pa-unit-no] is null 
			and a.[pa-acct-bd-xfr-date] BETWEEN '2015-01-01 00:00:00.000' AND '2017-05-31 23:59:59.000'
		)
		OR
		(
			b.[pa-unit-no] is not null 
			and b.[pa-unit-xfr-bd-date] BETWEEN '2015-01-01 00:00:00.000' AND '2017-05-31 23:59:59.000'
		)
	)
	and c.[pa-dtl-type-ind] <> '1'
	and c.[pa-dtl-fc] IN (
		'0','1','2','3','4','5','6','7','8','9'
	)
	and b.[pa-unit-no] is null

	GROUP BY CAST(a.[pa-pt-no-woscd] as varchar) + CAST(a.[pa-pt-no-scd-1] as varchar)
	, b.[pa-unit-no]
	, CAST(a.[pa-pt-no-woscd] as varchar) + CAST(a.[pa-pt-no-scd-1] as varchar) + CAST(b.[pa-unit-no] as varchar)
	, b.[pa-unit-no]
	, b.[pa-unit-date]
	, a.[pa-acct-bd-xfr-date]
	, b.[pa-unit-xfr-bd-date]
	, c.[pa-dtl-type-ind]
	, c.[pa-dtl-svc-cd-woscd]
	, c.[pa-dtl-svc-cd-scd]
	, c.[pa-dtl-cdm-description]
	, c.[pa-dtl-technical-desc]
	
	HAVING SUM(c.[pa-dtl-chg-amt]) <> '0'
)