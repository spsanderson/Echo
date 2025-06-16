library(DBI)
library(odbc)
library(tidyverse)
library(readxl)
library(dbplyr)
library(janitor)

source("W:\\PATACCT\\BusinessOfc\\Revenue Cycle Analyst\\R_Code\\DSS_Connection_Functions.r")

f_path <- "W:\\PATACCT\\BusinessOfc\\Revenue Cycle Analyst\\NPI_EIN_Numbers_For_SQL.xlsx"
f <- read_excel(f_path, sheet = "Sheet1") |>
  clean_names()

f_tbl <- f |>
  mutate(across(everything(), str_squish)) |>
  rowid_to_column()

db_con <- db_connect()

dbWriteTable(
  conn = db_con,
  Id(
    schemea = "dbo",
    table = "c_npi_ein_facility_dim_tbl"
  ),
  f_tbl,
  overwrite = TRUE
)

dbDisconnect(db_con)
