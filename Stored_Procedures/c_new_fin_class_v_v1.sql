USE [SMS]
GO

/****** Object:  View [dbo].[c_new_fin_class_v]    Script Date: 6/11/2024 2:35:05 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



-- Create the view in the specified schema
ALTER VIEW [dbo].[c_new_fin_class_v]
AS

WITH cte AS (
    SELECT 
        pt_no,
        svc_date,
        post_date,
        pa_smart_comment,
        fc,
        fc_class,
        fc_group,
        comment_yr,
        comment_month,
        comment_wk,
        ROW_NUMBER() OVER (PARTITION BY pt_no ORDER BY svc_date) AS rec_no
    FROM 
        sms.dbo.c_fc_comments_tbl
    --WHERE 
        --pt_no IN ('10214070020')
)
SELECT 
    c1.pt_no,
    c1.svc_date,
    c1.post_date,
    c1.pa_smart_comment,
    c1.fc,
    c1.fc_class,
    c1.fc_group,
    c1.comment_yr,
    c1.comment_month,
    c1.comment_wk,
    c2.svc_date AS next_svc_date,
    DATEDIFF(DAY, c1.svc_date,c2.svc_date) AS days_to_next_svc,
    c2.post_date AS next_post_date,
    c2.pa_smart_comment AS next_pa_smart_comment,
    c2.fc AS next_fc,
    c2.fc_class AS next_fc_class,
    c2.fc_group AS next_fc_group,
    c2.comment_yr AS next_comment_yr,
    c2.comment_month AS next_comment_month,
    c2.comment_wk AS next_comment_wk,
     CASE 
        -- PLACEMENT INTO BAD DEBT
        WHEN c1.fc NOT LIKE '%[0-9]%' AND c2.fc LIKE '%[0-9]%'
            THEN 'BAD DEBT PLACEMENT'
        -- STILL IN BAD DEBT
        WHEN c1.fc LIKE '%[0-9]%' AND c2.fc LIKE '%[0-9]%'
            THEN 'STILL BAD DEBT'
        -- BAD DEBT REACTIVATION
        WHEN c1.fc LIKE '%[0-9]%' AND c2.fc NOT LIKE '%[0-9]%' 
            THEN 'REACTIVATION'
        -- NOT BAD DEBT
        WHEN c1.fc NOT LIKE '%[0-9]%' AND c2.fc NOT LIKE '%[0-9]%'
            THEN 'NOT BAD DEBT'
        WHEN c2.fc IS NULL
            AND c1.fc LIKE '%[0-9]%'
            THEN 'STILL BAD DEBT'
        ELSE 'NOT BAD DEBT'
    END AS current_fc_stats
FROM 
    cte c1
LEFT JOIN 
    cte c2 ON c1.pt_no = c2.pt_no AND c1.rec_no + 1 = c2.rec_no



GO


