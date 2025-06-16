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

base_path <- "W:/PATACCT/BusinessOfc/Revenue Cycle Analyst/R_Code/SQL_DB_Imports/Fee_Schedule/Medicare/"
medicare_lab_file <- "medicare_lab_fee_schedul_2024-07-01.xlsx"
medicare_phys_file <- "medicare_physician_fee_schedule_2024-03-09.xlsx"

medicare_lab_path <- paste0(base_path, medicare_lab_file)
medicare_phys_path <- paste0(base_path, medicare_phys_file)

lab_tbl <- read_excel(
  path = medicare_lab_path,
  skip = 4
) |>
  clean_names() |>
  mutate(across(where(is.character), str_squish))

phys_tbl <- read_excel(path = medicare_phys_path) |>
  clean_names() |>
  mutate(across(where(is.character), str_squish))


# Insert Into SQL Server --------------------------------------------------

db_con <- db_connect()

dbWriteTable(
  conn = db_con,
  Id(
    schemea = "dbo",
    table = "c_medicare_lab_fee_schedule_tbl"
  ),
  lab_tbl,
  overwrite = TRUE
)

dbWriteTable(
  conn = db_con,
  Id(
    schemea = "dbo",
    table = "c_medicare_phys_fee_schedule_tbl"
  ),
  phys_tbl,
  overwrite = TRUE
)

dbDisconnect(db_con)
