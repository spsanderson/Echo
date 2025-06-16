# Lib Load ----------------------------------------------------------------
library(DBI)
library(odbc)
library(tidyverse)
library(janitor)

# Source Functions --------------------------------------------------------

base_path <- "W:/PATACCT/BusinessOfc/Revenue Cycle Analyst/R_Code"
source(paste0(base_path, "/DSS_Connection_Functions.r"))
source(paste0(base_path, "/ar_runout_query.R"))

# Connect to DSS ----------------------------------------------------------

db_con_obj <- db_connect(.database = "PARA")

# Query -------------------------------------------------------------------

date_query <- "
WITH cte AS (
	SELECT TOP 12 EOMonth_Timestamp
	FROM para.dbo.Pt_Accounting_Reporting_ALT_Backup
	GROUP BY EOMonth_Timestamp
	ORDER BY EOMonth_Timestamp DESC
	)
	
SELECT CAST(EOMonth_Timestamp AS DATE) AS eomonth_timestamp
FROM cte
ORDER BY EOMonth_Timestamp;
"

date_df <- dbGetQuery(db_con_obj, date_query) |>
  as_tibble() |>
  mutate(eomonth_timestamp = as_date(eomonth_timestamp))

db_disconnect(db_con_obj)

# Get Latest Date ---------------------------------------------------------

latest_date <- tail(date_df$eomonth_timestamp, 1)

dates_list <- date_df |>
  mutate(end_date = latest_date) |>
  set_names(c("start_date", "end_date")) |>
  mutate(id = row_number()) |>
  relocate(id, .before = start_date) |>
  slice(1:11) |>
  group_split(id)

result_tbl <- dates_list |>
  imap(
    .f = function(obj, id) {
      start_date <- obj |> pull(2) |> pluck(1)
      end_date <- obj |> pull(3) |> pluck(1)
      
      ret <- runout_query(start_date, end_date)
      
      return(ret)
    }
  ) |>
  list_rbind() |>
  mutate(sp_run_datetime = ymd_hms(Sys.time()))

# Write data to database ----

db_con_obj <- db_connect()

dbWriteTable(
  conn = db_con_obj,
  name = "c_ar_runout_tbl",
  value = result_tbl,
  append = TRUE
)

db_disconnect(db_con_obj)
