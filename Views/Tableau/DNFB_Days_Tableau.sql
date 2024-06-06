USE [PARA]
GO

/****** Object:  View [dbo].[DNFB_Days_Tableau]    Script Date: 6/6/2024 8:53:52 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



ALTER VIEW [dbo].[DNFB_Days_Tableau] AS


-- Define a CTE to find the maximum timestamp for each pt_no where file = 'DNFB'
WITH MaxDNFB AS (
    SELECT 
        A.Pt_No, 
        A.Dsch_Date,
		[File] = CASE 
	    WHEN bh.[PA-COMPONENT-ID] = '2RFLGIND'
			THEN 'Red Flag'
		WHEN A.Ins1_Cd = 'L40' or A.Ins2_Cd = 'L40' or A.Ins3_Cd = 'L40' or A.Ins4_Cd = 'L40'
			THEN 'Never Event'
		WHEN A.[Balance] < 0
			AND A.[File] = 'Bad Debt'
			THEN 'Bad Debt Credit'
		WHEN A.Balance < 0
			AND A.[File] != 'Bad Debt'
			THEN 'Credit'
		ELSE A.[File]
		END,
        -- Calculate the maximum timestamp
        MAX(a.[Timestamp]) AS MaxTimestamp
    FROM para.dbo.Pt_Accounting_Reporting_ALT_Backup AS A
	LEFT JOIN SMS.DBO.bill_hold_red_flag AS BH ON A.PT_NO = BH.Pt_No
		AND A.PA_Ctl_PAA_Xfer_Date = BH.[PA-CTL-PAA-XFER-DATE]
    WHERE [file] = 'DNFB'
    GROUP BY A.Pt_No, 
		A.Dsch_Date,
		CASE 
	    WHEN bh.[PA-COMPONENT-ID] = '2RFLGIND'
			THEN 'Red Flag'
		WHEN A.Ins1_Cd = 'L40' or A.Ins2_Cd = 'L40' or A.Ins3_Cd = 'L40' or A.Ins4_Cd = 'L40'
			THEN 'Never Event'
		WHEN A.[Balance] < 0
			AND A.[File] = 'Bad Debt'
			THEN 'Bad Debt Credit'
		WHEN A.Balance < 0
			AND A.[File] != 'Bad Debt'
			THEN 'Credit'
		ELSE A.[File]
		END
		 -- Group results by pt_no and Dsch_Date
),

-- Define a CTE to find the minimum timestamp after the maximum timestamp identified for DNFB for each pt_no
MinAfterDNFB AS (
    SELECT 
        t.pt_no,
        -- Handle NULL First_Ins_Bl_Date by replacing it with the current date
        [First_Ins_Bl_Date] = ISNULL(First_Ins_Bl_Date, GETDATE()), 
        -- Calculate the minimum timestamp that is greater than the MaxTimestamp from MaxDNFB
        MIN(t.[Timestamp]) AS MinTimestamp
    FROM para.dbo.Pt_Accounting_Reporting_ALT_Backup t
    INNER JOIN MaxDNFB m ON t.pt_no = m.pt_no AND t.Timestamp > m.MaxTimestamp
    WHERE t.[file] != 'DNFB'
    GROUP BY t.pt_no, ISNULL(First_Ins_Bl_Date, GETDATE())
)

-- Final SELECT to output the results combining data from both CTEs
SELECT 
    m.pt_no, -- Patient number
    -- Display the dsch_date, ensuring it's cast as DATE type for consistency
    [dsch_date] = CAST(m.Dsch_Date AS DATE),
    -- Display the first insurance bill date, ensuring it's cast as DATE type for consistency
    [first_ins_bl_date] = CAST(n.First_Ins_Bl_Date AS DATE),
    m.MaxTimestamp AS MaxTimestampDNFB, -- Max timestamp where file = 'DNFB'
    n.MinTimestamp AS MinTimestampAfterDNFB, -- Min timestamp where file != 'DNFB' and after MaxTimestampDNFB
    -- Calculate the number of days between discharge date and the first insurance bill date (or current date if null)
    [days_in_dnfb] = DATEDIFF(DAY, m.Dsch_Date, ISNULL(n.First_Ins_Bl_Date, GETDATE()))
FROM MaxDNFB m
LEFT JOIN MinAfterDNFB n ON m.pt_no = n.pt_no -- Ensure all pt_no from MaxDNFB are included
WHERE M.[File] = 'DNFB'




GO


