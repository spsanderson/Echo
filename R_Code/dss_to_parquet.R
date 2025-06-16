library(DBI)
library(odbc)
library(dplyr)
library(parquetize)
library(arrow)
library(stringr)

source("W:/PATACCT/BusinessOfc/Revenue Cycle Analyst/R_Code/DSS_Connection_Functions.r")
source("W:/PATACCT/BusinessOfc/Revenue Cycle Analyst/R_Code/DBI_SQL_Field_Return_Order.R")

field_order <- sql_field_order_helper()
fields <- field_order |>
  strsplit(",") |>
  as.data.frame() |>
  as_tibble() |>
  setNames("field") |>
  mutate(field = str_squish(field)) |>
  mutate(field = paste0("[", field, "],")) |>
  pull() |>
  as.character()

first_fields <- head(fields, -1)
last_field <- tail(fields, 1) |>
  str_remove(pattern = ",")
all_fields <- c(first_fields, last_field)

db_con_obj <- db_connect()

dbi_to_parquet(
  conn = db_con_obj,
  sql = paste(
    "select",
    paste(all_fields, collapse = " "),
    "from dbo.Pt_Accounting_Reporting_ALT"
  ),
  path_to_parquet = tempfile(fileext = ".parquet"),
  max_rows = 100000L
)

db_disconnect(db_con_obj)

temp_dir_path <- normalizePath(tempdir())
subfolder_in_dir <- list.files(temp_dir_path, patter = "*.parquet$")
full_file_path <- paste0(temp_dir_path, "\\", subfolder_in_dir)
all_files <- list.files(full_file_path, pattern = "*.parquet$")

df_parquet <- open_dataset(paste0(full_file_path,"/",all_files))

collect(df_parquet) |>
  write_parquet(sink = "C://Users/ssanders/Desktop/test_alt.parquet")

collect(df_parquet) |>
  write_fst(path = "C:/Users/ssanders/Desktop/test_alt.fst")

f <- fst("C:/Users/ssanders/Desktop/test_alt.fst")

f |>
  select_fst(Admit_Date, Dsch_Date) |>
  mutate_vars("days_stay", diff.Date(Admit_Date - Dsch_Date))
