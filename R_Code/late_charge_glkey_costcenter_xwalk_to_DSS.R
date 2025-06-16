library(DBI)
library(odbc)
library(tidyverse)
library(readxl)
library(dbplyr)

f_path <- "W:\\PATACCT\\BusinessOfc\\Revenue Cycle Analyst\\Tableau\\Late_Charge_DB\\gl_cost_center_xwalk.xlsx"
f <- read_excel(f_path, sheet = "Apr2023") |>
  janitor::clean_names()

# col_nms <- colnames(f)
# col_nms <- gsub(x = col_nms, pattern = "[ /]", replacement = "_")
# names(f) <- col_nms

f_tbl <- f |>
  mutate(across(everything(), str_squish)) |>
  rowid_to_column()

db_connect <- function(.server_name = "dev16db1.uhmc.sbuh.stonybrook.edu",
                       .database = "SMS") {
  
  server_name <- as.character(.server_name)
  data_base_name <- as.character(.database)
  
  db_con <- DBI::dbConnect(
    odbc::odbc(),
    Driver = "SQL Server",
    Server = server_name,
    Database = data_base_name,
    Trusted_Connection = T
  )
  
  return(db_con)
  
}

db_con <- db_connect()

dbWriteTable(
  conn = db_con,
  Id(
    schemea = "dbo",
    table = "c_tableau_gl_cost_center_xwalk_tbl"
  ),
  f_tbl,
  overwrite = TRUE
)

dbDisconnect(db_con)
