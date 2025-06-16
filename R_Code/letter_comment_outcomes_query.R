# Load libraries ----
library(DBI)
library(odbc)
library(tidyverse)
library(writexl)
library(readxl)
library(janitor)
library(lubridate)

# Get db connection file function ----
source("W://PATACCT//BusinessOfc//Revenue Cycle Analyst//R_Code//DSS_Connection_Functions.r")

# Make db connection object ----
db_con_obj_active <- db_connect(
  .server_name = "ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU",
  .database = "Echo_Active"
)

# Queries ----
echo_active_cmts <- DBI::dbGetQuery(
  conn = db_con_obj_active,
  statement = paste0(
    "
    SELECT [PA-REGION-CD],
    	[PA-HOSP-CD],
    	[PA-PT-NO-WOSCD],
    	[PA-PT-NO-SCD-1],
      [PT-NO] = CAST([PA-PT-NO-WOSCD] AS VARCHAR) + CAST([PA-PT-NO-SCD-1] AS VARCHAR),
    	[PA-SMART-COMMENT],
    	[PA-SMART-DATE],
    	[LETTER-TYPE] = SUBSTRING([PA-SMART-COMMENT], 1, 4),
    	[USER-ID] = SUBSTRING([PA-SMART-COMMENT], 6, 6),
    	[PA-SMART-SVC-CD-WOSCD],
    	[PA-SMART-SVC-CD-SCD]
    FROM [dbo].[AccountComments]
    WHERE substring([pa-smart-comment], 1, 4) IN ('APPC', 'CIFB', 'CILM', 'CINS', 'CMSA', 'IBSI', 'ICPP', 'ICPR', 'L130', 'L131', 'L132', 'L133', 'L135', 'L136', 'L137', 'L138', 'L139', 'L140', 'L142', 'L143', 'L144', 'L145', 'L146', 'L147', 'L148', 'L149', 'LSTI', 'MRRH', 'MRUR', 'PCUR', 'PJOC', 'RJOC', 'RPPA', 'RTPA', 'SLTP', 'UMVA', 'WCCT')
    "
  )
) |>
  as_tibble() |>
  mutate(across(everything(), str_squish))

db_disconnect(db_con_obj_active)

db_con_obj_archive <- db_connect(
  .server_name = "ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU",
  .database = "Echo_Archive"
)

echo_archive_cmts <- DBI::dbGetQuery(
  conn = db_con_obj_archive,
  statement = paste0(
    "
    SELECT [PA-REGION-CD],
    	[PA-HOSP-CD],
    	[PA-PT-NO-WOSCD],
    	[PA-PT-NO-SCD-1],
      [PT-NO] = CAST([PA-PT-NO-WOSCD] AS VARCHAR) + CAST([PA-PT-NO-SCD-1] AS VARCHAR),
    	[PA-SMART-COMMENT],
    	[PA-SMART-DATE],
    	[LETTER-TYPE] = SUBSTRING([PA-SMART-COMMENT], 1, 4),
    	[USER-ID] = SUBSTRING([PA-SMART-COMMENT], 6, 6),
    	[PA-SMART-SVC-CD-WOSCD],
    	[PA-SMART-SVC-CD-SCD]
    FROM [dbo].[AccountComments]
    WHERE substring([pa-smart-comment], 1, 4) IN ('APPC', 'CIFB', 'CILM', 'CINS', 'CMSA', 'IBSI', 'ICPP', 'ICPR', 'L130', 'L131', 'L132', 'L133', 'L135', 'L136', 'L137', 'L138', 'L139', 'L140', 'L142', 'L143', 'L144', 'L145', 'L146', 'L147', 'L148', 'L149', 'LSTI', 'MRRH', 'MRUR', 'PCUR', 'PJOC', 'RJOC', 'RPPA', 'RTPA', 'SLTP', 'UMVA', 'WCCT')
    "
  )
) |>
  as_tibble() |>
  mutate(across(everything(), str_squish))

db_disconnect(db_con_obj_archive)

# Union Comments Results ----
unioned_cmts_tbl <- union_all(echo_active_cmts, echo_archive_cmts) |>
  clean_names() |>
  mutate(pa_smart_date = ymd(pa_smart_date)) |>
  distinct()

# Payments ----
echo_active_pmts <- dbGetQuery(
  conn = db_con_obj_active,
  statement = paste0(
    "
    SELECT [PA-REGION-CD],
    	[PA-HOSP-CD],
    	[PA-PT-NO-WOSCD],
    	[PA-PT-NO-SCD-1],
      [PT-NO] = CAST([PA-PT-NO-WOSCD] AS VARCHAR) + CAST([PA-PT-NO-SCD-1] AS VARCHAR),
    	[PA-DTL-TYPE-IND],
    	[PA-DTL-SVC-CD-WOSCD],
    	[PA-DTL-SVC-CD-SCD],
    	[PA-DTL-TECHNICAL-DESC],
    	[PA-DTL-CDM-DESCRIPTION],
    	CAST([PA-DTL-POST-DATE] AS DATE) AS [PA-DTL-POST-DATE],
    	[PA-DTL-CHG-AMT],
    	[PA-INS-PLAN] = CASE
    		WHEN LEN(ltrim(rtrim([pa-dtl-ins-plan-no]))) = '1'
    			THEN CAST(CAST(LTRIM(RTRIM([pa-dtl-ins-co-cd])) AS VARCHAR) + CONVERT(VARCHAR(1), 0) + CAST(LTRIM(RTRIM([pa-dtl-ins-plan-no])) AS VARCHAR) AS VARCHAR)
    		WHEN LEN(LTRIM(RTRIM([pa-dtl-ins-plan-no]))) = '2'
    			THEN CAST(CAST(LTRIM(RTRIM([pa-dtl-ins-co-cd])) AS VARCHAR) + CAST(LTRIM(RTRIM([pa-dtl-ins-plan-no])) AS VARCHAR) AS VARCHAR)
    		END
    FROM [dbo].[DetailInformation]
    WHERE (
    	[PA-DTL-TYPE-IND] = '1'
    	OR [PA-DTL-SVC-CD-WOSCD] IN ('60320','60215')
    )
    "
  )
) |>
  as_tibble() |>
  mutate(across(everything(), str_squish)) |>
  clean_names() |>
  filter(pt_no %in% unique(unioned_cmts_tbl$pt_no))

db_disconnect(db_con_obj_active)

echo_archive_pmts <- dbGetQuery(
  conn = db_con_obj_archive,
  statement = paste0(
    "
    SELECT [PA-REGION-CD],
    	[PA-HOSP-CD],
    	[PA-PT-NO-WOSCD],
    	[PA-PT-NO-SCD-1],
      [PT-NO] = CAST([PA-PT-NO-WOSCD] AS VARCHAR) + CAST([PA-PT-NO-SCD-1] AS VARCHAR),
    	[PA-DTL-TYPE-IND],
    	[PA-DTL-SVC-CD-WOSCD],
    	[PA-DTL-SVC-CD-SCD],
    	[PA-DTL-TECHNICAL-DESC],
    	[PA-DTL-CDM-DESCRIPTION],
    	CAST([PA-DTL-POST-DATE] AS DATE) AS [PA-DTL-POST-DATE],
    	[PA-DTL-CHG-AMT],
    	[PA-INS-PLAN] = CASE
    		WHEN LEN(ltrim(rtrim([pa-dtl-ins-plan-no]))) = '1'
    			THEN CAST(CAST(LTRIM(RTRIM([pa-dtl-ins-co-cd])) AS VARCHAR) + CONVERT(VARCHAR(1), 0) + CAST(LTRIM(RTRIM([pa-dtl-ins-plan-no])) AS VARCHAR) AS VARCHAR)
    		WHEN LEN(LTRIM(RTRIM([pa-dtl-ins-plan-no]))) = '2'
    			THEN CAST(CAST(LTRIM(RTRIM([pa-dtl-ins-co-cd])) AS VARCHAR) + CAST(LTRIM(RTRIM([pa-dtl-ins-plan-no])) AS VARCHAR) AS VARCHAR)
    		END
    FROM [dbo].[DetailInformation]
    WHERE (
    	[PA-DTL-TYPE-IND] = '1'
    	OR [PA-DTL-SVC-CD-WOSCD] IN ('60320','60215')
    )
    "
  )
) |>
  as_tibble() |>
  mutate(across(everything(), str_squish)) |>
  clean_names() |>
  filter(pt_no %in% unique(unioned_cmts_tbl$pt_no))

db_disconnect(db_con_obj_archive)

# Union Payments Results ----

unioned_pmts_tbl <- union_all(echo_active_pmts, echo_archive_pmts) |>
  mutate(pa_dtl_post_date = ymd(pa_dtl_post_date))

# Place results in DSS
db_con_fin_obj <- db_connect(
  .database = "PARA"
)

library(dbplyr)

dbWriteTable(
  overwrite = TRUE,
  conn = db_con_fin_obj,
  Id(
    schema = "dbo",
    table = "c_letters_comments_tbl"
  ),
  unioned_cmts_tbl
)

dbWriteTable(
  overwrite = TRUE,
  conn = db_con_fin_obj,
  Id(
    schema = "dbo",
    table = "c_letters_payments_tbl"
  ),
  unioned_pmts_tbl
)

db_disconnect(.connection = db_con_fin_obj)