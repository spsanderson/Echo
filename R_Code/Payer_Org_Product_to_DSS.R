# Library Load ------------------------------------------------------------


library(DBI)
library(odbc)
library(tidyverse)
library(readxl)
library(dbplyr)
library(janitor)


# Get SQL Connection File -------------------------------------------------


source("W:/PATACCT/BusinessOfc/Revenue Cycle Analyst/R_Code/DSS_Connection_Functions.r")

# Get File ----------------------------------------------------------------


f_path <- "W:/PATACCT/BusinessOfc/Revenue Cycle Analyst/Cerner Manuals/Payer_Org_Mapping/Payer Org Mapping_PIC_updated_2025-06-05.xlsx"
f_tbl <- read_excel(
  path = f_path,
  sheet = "FastLoad (46)"
) |>
  clean_names() |>
  mutate(across(where(is.character), str_squish))


# Insert Into SQL Server --------------------------------------------------

db_con <- db_connect()

dbWriteTable(
  conn = db_con,
  Id(
    schemea = "dbo",
    table = "c_tableau_insurance_tbl"
  ),
  f_tbl,
  overwrite = TRUE
)

# Now we need to update the table to create an indicator column called active_ind
update_query <- "
  ALTER TABLE sms.dbo.c_tableau_insurance_tbl
  ADD active_ind VARCHAR(10); -- Adjust the data type and size as needed
  
  WITH RankedRows AS (
      SELECT 
          *,
          ROW_NUMBER() OVER (
              PARTITION BY code
              ORDER BY revised_date DESC
          ) AS row_num
      FROM sms.dbo.c_tableau_insurance_tbl
  )
  
  UPDATE sms.dbo.c_tableau_insurance_tbl
  SET active_ind = CASE
      WHEN RankedRows.row_num = 1 THEN 'ACTIVE'
      ELSE 'INACTIVE'
  END
  FROM sms.dbo.c_tableau_insurance_tbl
  JOIN RankedRows
  ON sms.dbo.c_tableau_insurance_tbl.[code] = RankedRows.[code]
  	and sms.dbo.c_tableau_insurance_tbl.[payer_name] = RankedRows.payer_name

"

dbExecute(db_con, update_query)

dbDisconnect(db_con)
