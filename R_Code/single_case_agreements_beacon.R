
# Load Libraries ----------------------------------------------------------

library(tidyverse)
library(readxl)
library(writexl)
library(xlsx)
library(DBI)
library(odbc)
library(lubridate)
library(janitor)


# Read in the excel file --------------------------------------------------

f_path <- "W://PATACCT//BusinessOfc//Revenue Cycle Analyst//Single_Case_Agreements_Analysis//Beacon Open AR 04-03-23.xlsx"

beacon_open_ar_tbl <- read_xlsx(path = f_path)

beacon_open_ar_tbl <- beacon_open_ar_tbl |>
  clean_names() |> 
  mutate(across(c(where(is.POSIXct), -sp_run_date_time), ymd)) |>
  mutate(sp_run_date_time = as.Date(sp_run_date_time, format = "%Y%M%D")) |>
  mutate(across(!where(is.Date), str_squish))

# SCA Excel file
sca_f_path <- "W://PATACCT//BusinessOfc//Revenue Cycle Analyst//Single_Case_Agreements_Analysis/sca_letters_of_agreement_email_2023_03_31.xlsx"

sca_sheets <- excel_sheets(sca_f_path)

read_all_sheets <- function(filename) {
  sheets <- excel_sheets(filename)
  x <- lapply(sheets, function(X) read_excel(filename, sheet = X))
  names(x) <- sheets
  x
}

sca_sheet_list <- read_all_sheets(sca_f_path) |>
  clean_names() |>
  map(clean_names)

# Sheets to keep
keep_sheets <- paste0("x", 2007:2023)

sca_sheet_keep_list <- sca_sheet_list[names(sca_sheet_list) %in% keep_sheets]

sca_rbind_tbl <- map(sca_sheet_keep_list, \(x) x |>
      select(patient_name, mr_no_patient_encounter, payor, authorization) |>
      mutate(across(everything(), str_squish))) |>
  list_rbind(names_to = "sheet_id")


# Get Auth Info from DSS --------------------------------------------------

source("W://PATACCT//BusinessOfc//Revenue Cycle Analyst//R_Code/DSS_Connection_Functions.r")

db_con_obj <- db_connect(.database = "PARA")

dss_auths_tbl <- dbGetQuery(
  conn = db_con_obj,
  statement = paste0(
    "
    SELECT pt_no,
      post_date,
      authorization_code
    FROM [dbo].[c_treatment_auth_v]
    "
  )
) |> 
  as_tibble() |>
  clean_names() |>
  mutate(across(everything(), str_squish)) |>
  mutate(post_date = ymd(post_date))

db_disconnect(.connection = db_con_obj)


# SCA Search --------------------------------------------------------------

beacon_tbl_a <- beacon_open_ar_tbl |>
  filter(mrn %in% sca_rbind_tbl$mr_no_patient_encounter)

beacon_tbl_b <- beacon_open_ar_tbl |>
  filter(pt_no %in% sca_rbind_tbl$mr_no_patient_encounter)

beacon_tbl_c <- beacon_open_ar_tbl |>
  filter(pt_no %in% dss_auths_tbl$pt_no)

beacon_unioned_tbl <- union(beacon_tbl_a, beacon_tbl_b) |>
  union(beacon_tbl_c)

beacon_unioned_tbl

save_path <- "W://PATACCT//BusinessOfc//Revenue Cycle Analyst//Single_Case_Agreements_Analysis//"
# write_xlsx(
#   x = beacon_unioned_tbl,
#   path = paste0(save_path, "beacon_sca_volume.xlsx")
# )

beacon_sca_tbl <- sca_rbind_tbl |>
  filter(str_detect(str_to_lower(payor), "beacon"))

# write_xlsx(
#   x = beacon_sca_tbl,
#   path = paste0(save_path, "sca_beacon_log.xlsx")
# )

wb <- createWorkbook()
beacon_found_sheet <- createSheet(wb, sheetName = "beacon_open_ar_found_in_sca")
beacon_sca_sheet <- createSheet(wb, sheetName = "beacon_sca")
addDataFrame(x = beacon_unioned_tbl, sheet = beacon_found_sheet)
addDataFrame(x = beacon_sca_tbl, sheet = beacon_sca_sheet)
saveWorkbook(
  wb,
  file = paste0(save_path, "beacon_open_ar_in_sca.xlsx")
)
