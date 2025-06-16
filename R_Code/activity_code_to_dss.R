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


f_path <- "W:/PATACCT/BusinessOfc/Revenue Cycle Analyst/Cerner Manuals/Activity Code Descriptions.xlsx"

f_tbl <- read_excel(
  path = f_path
) |>
  clean_names() |>
  mutate(across(where(is.character), str_squish))


# Insert Into SQL Server --------------------------------------------------

db_con <- db_connect()

dbWriteTable(
  conn = db_con,
  Id(
    schemea = "dbo",
    table = "c_activity_code_tbl"
  ),
  f_tbl,
  overwrite = TRUE
)

dbDisconnect(db_con)
