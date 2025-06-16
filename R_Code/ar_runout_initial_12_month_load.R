# Lib Load ----------------------------------------------------------------
library(DBI)
library(odbc)
library(tidyverse)
library(janitor)

# Source Functions --------------------------------------------------------

base_path <- "W:/PATACCT/BusinessOfc/Revenue Cycle Analyst/R_Code"
source(paste0(base_path, "/DSS_Connection_Functions.r"))

# Dates to use for run outs ----

## Get dates to use
date_query <- "
-- Create a CTE to get the last 13 end-of-month timestamps
WITH CTE AS (
    SELECT TOP 13
        CAST(EOMonth_Timestamp AS DATE) AS start_eomonth_timestamp
    FROM para.dbo.Pt_Accounting_Reporting_ALT_Backup
    GROUP BY EOMonth_Timestamp
    ORDER BY EOMonth_Timestamp DESC
),
Numbers AS (
    SELECT TOP 12 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS Number
    FROM master.dbo.spt_values
),
RunoutDates AS (
    SELECT 
        start_eomonth_timestamp,
        DATEADD(MONTH, Number, start_eomonth_timestamp) AS end_eomonth_timestamp
    FROM CTE
    CROSS JOIN Numbers
),
FilteredRunoutDates AS (
    SELECT * 
    FROM RunoutDates
    WHERE start_eomonth_timestamp <> (
        SELECT MAX(start_eomonth_timestamp) 
        FROM RunoutDates
    )
)
-- Select the remaining dates
SELECT * 
FROM FilteredRunoutDates
ORDER BY start_eomonth_timestamp, end_eomonth_timestamp;
"

db_con_obj <- db_connect(.database = "PARA")

dates <- dbGetQuery(
  conn = db_con_obj,
  statement = date_query
)

db_disconnect(db_con_obj)

dates_list <- as_tibble(dates) |>
  filter(
    start_eomonth_timestamp <= max_timstamp,
    end_eomonth_timestamp <= max_timstamp
  ) |>
  mutate(across(everything(), as_date)) |>
  mutate(id = row_number()) |>
  relocate(id, .before = start_eomonth_timestamp) |>
  group_split(id)

# Generate Run outs for all dates ----

runout_query <- function(start_date, end_date) {
  
  db_con_obj <- db_connect()
  
  query <- paste0("
    execute sms.dbo.c_ar_runout_sp 
    @start_date = '", start_date, "', 
    @end_date = '", end_date, "';
  ")
  
  result <- dbGetQuery(
    conn = db_con_obj,
    statement = query
  )
  
  result <- as_tibble(result) |>
    mutate(across(where(is.character), str_squish))
  
  db_disconnect(db_con_obj)
 
  return(result)
}

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
  overwrite = TRUE
)

db_disconnect(db_con_obj)