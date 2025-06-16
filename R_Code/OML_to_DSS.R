library(DBI)
library(odbc)
library(tidyverse)
library(readxl)
library(dbplyr)

f_path <- "W:\\PATACCT\\BusinessOfc\\Revenue Cycle Analyst\\Cerner Manuals\\FULL OML 5I 03-22-23.xlsx"
f <- read_excel(f_path, sheet = "OML")

col_nms <- colnames(f)
col_nms <- gsub(x = col_nms, pattern = "[ /]", replacement = "_")
names(f) <- col_nms

f_tbl <- f |>
  mutate(across(everything(), str_squish)) |>
  rowid_to_column()

db_connect <- function(.server_name = "financedbp.uhmc.sbuh.stonybrook.edu",
           .database = "PARA") {
    
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
    table = "c_OML_20230322_tbl"
  ),
  f_tbl,
  overwrite = TRUE
)

dbDisconnect(db_con)
