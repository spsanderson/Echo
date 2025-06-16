source("W://PATACCT//BusinessOfc//Revenue Cycle Analyst//R_Code//DSS_Connection_Functions.r")

db_con_obj_active <- db_connect(
  .server_name = "ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU",
  .database = "Echo_Active"
)

library(DBI)
library(odbc)
library(tidyverse)

echo_active_cmts <- DBI::dbGetQuery(
  conn = db_con_obj_active,
  statement = paste0(
    "
    SELECT [PA-REGION-CD],
    	[PA-HOSP-CD],
    	[PA-PT-NO-WOSCD],
    	[PA-PT-NO-SCD-1],
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
toc()

db_disconnect(db_con_obj_active)

db_con_obj_archive <- db_connect(
  .server_name = "ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU",
  .database = "Echo_Archive"
)

tic()
echo_archive_cmts <- DBI::dbGetQuery(
  conn = db_con_obj_archive,
  statement = paste0(
    "
    SELECT [PA-REGION-CD],
    	[PA-HOSP-CD],
    	[PA-PT-NO-WOSCD],
    	[PA-PT-NO-SCD-1],
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
toc()

db_disconnect(db_con_obj_archive)

tasks <- taskscheduler_ls()

taskscheduler_create(
  taskname = "test_run",
  rscript = "C://Users//ssanders//Desktop//test_script.R",
  schedule = "ONCE",
  starttime = "12:07"
)

tasks |>
  as_tibble() |>
  filter(str_detect(Author, pattern = "ssanders")) |>
  filter(str_detect(TaskName, pattern = ".R$")) |>
  mutate(RunDTime = `Next Run Time`) |>
  mutate(RunDTime = RunDTime |> mdy_hms()) |>
  select(TaskName, RunDTime) |>
  arrange(RunDTime)
