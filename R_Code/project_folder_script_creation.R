if(!require(fs)) {
  install.packages("fs")
}
suppressPackageStartupMessages(library(fs))

folders <- c(
  "00_Scripts"
  , "00_Data"
  , "01_Queries"
  , "02_Data_Manipulation"
  , "03_Viz"
  , "04_TS_Modeling"
  , "05_Classification_Modeling"
  , "99_Automations"
)

fs::dir_create(
  path = folders
)


file_create("01_Queries/query_functions.R")
file_create("02_Data_Manipulation/data_functions.R")
file_create("03_Viz/viz_functions.R")
file_create("04_TS_Modeling/ts_functions.R")

# DSS Connection 
db_connect <- function(.server_name = "financedbp.uhmc.sbuh.stonybrook.edu",
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

# Disconnect from Database
db_disconnect <- function(.connection) {
  
  DBI::dbDisconnect(
    conn = db_connect()
  )
  
}

# Library Load

library_load <- function(){
  
  if(!require(pacman)){install.packages("pacman")}
  pacman::p_load(
    # Database 
    "DBI"
    , "odbc"

    # Clean column names
    , "janitor"

    # Data manipulation
    , "tidyverse"

    # TidyDensity to check distribution data
    , "healthyverse"

    # Time series
    , "modeltime"
    , "timetk"

    # Machine Learning/AI AUTO ML
    , "h2o"
    , "tidymodels"
  )
  
}

db_funs <- c("db_connect","db_disconnect")
dump(
  list = db_funs,
  file = "00_Scripts/db_con_obj.R"
)

lib_funs <- "library_load"
dump(
  list = lib_funs,
  file = "00_Scripts/library_load.R"
)
