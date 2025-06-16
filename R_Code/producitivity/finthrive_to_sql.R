# This R script will import a FinThrive_fromdate_todate.xlsx file
# The data needs to stored in an MS-SQL table called: SMS.dbo.c_finthrive_productivity_tbl
# The script will need to read in the Excel file and insert the data into the SQL table
# the excel file has a trailer at the end, we only want the records. We also need
# to create a new column called 'Source' and set it to 'FinThrive' and an 
# additional column called 'SourceFile' and set it to the name of the file
# with a third and final custom column for the date of the import.


# Import Libraries --------------------------------------------------------

library(readxl)
library(dplyr)
library(DBI)
library(odbc)
library(janitor)
library(purrr)


# Source SQL Connection File ----------------------------------------------

source("W:/PATACCT/BusinessOfc/Revenue Cycle Analyst/R_Code/DSS_Connection_Functions.r")

# Read in the Excel File --------------------------------------------------

base_path <- "W:/PATACCT/BusinessOfc/Revenue Cycle Analyst/Joe Mendola/Global AR Metrics/Weekly_AR_Metrics/FinThrive_Accounts_Worked/"
input_path <- paste0(base_path, "Input_Files")
input_file <- list.files(input_path, pattern = "*.xlsx$", full.names = TRUE)

# Employee Listing File
emp_path <- paste0(base_path, "Employee_Crosswalk.xlsx")

# Make sure a file exists
if (length(input_file) == 0) {
  stop("No Excel files found in the input directory.")
}

# Read the Excel file
df_tbl <- read_excel(input_file[1])
df_tbl <- clean_names(df_tbl)

# Drop lines that are not records. Bad lines start with 'Total' in the first
# column
df_tbl <- df_tbl |>
  (\(x) filter(x, !grepl("^Total", x[[1]]))) () |>
  (\(x) filter(x, !is.na(x[[1]]))) () |>
  (\(x) filter(x, !grepl("Applied", x[[1]]))) () |>
  mutate(Source = "FinThrive",
         SourceFile = basename(input_file[1]),
         ImportDate = Sys.Date())


# Correct the datatypes
df_tbl <- df_tbl |>
  mutate(
    claim_id = as.numeric(claim_id),
    export_outgoing_claim_charges = as.numeric(export_outgoing_claim_charges),
    event_date = as.Date(event_date),
    # pt_no is going to be the first 12 charactesrs of the patient_account_number
    pt_no = substr(patient_account_number, 1, 12),
    # get unit_seq_no which is characters 13 and 14 of patient_account_number
    unit_seq_no = substr(patient_account_number, 13, 14)
  ) |>
  relocate(pt_no, .after = patient_account_number) |>
  relocate(unit_seq_no, .after = pt_no)

# Strip leading zeros from pt_no
df_tbl <- df_tbl |>
  mutate(pt_no = sub("^0+", "", pt_no)) |>
  # create unit_no_int which is the unit_seq_no as an integer if it is numeric
  mutate(unit_no_int = ifelse(grepl("^[0-9]+$", unit_seq_no), as.integer(unit_seq_no), NA))  |>
  relocate(unit_no_int, .after = unit_seq_no) |>
  # If the unit_no_int is 0 then set it to NA
  mutate(unit_no_int = ifelse(unit_no_int == 0, NA, unit_no_int)) |>
  # drop unit_seq_no then rename unit_in_no to unit_seq_no
  select(-unit_seq_no) |>
  rename(unit_seq_no = unit_no_int)

# Read in the emp_tbl file
emp_tbl <- read_excel(emp_path) |>
  set_names(c("finthrive_alias", "department")) |>
  mutate(emp_id = as.character(finthrive_alias)) |>
  select(finthrive_alias, emp_id, department)

# Connect to the SQL Server and insert the data -------------------------
# Insert the data into the SQL table if it does not exist, else append
con_obj <- db_connect()

if (dbExistsTable(con_obj, "c_finthrive_productivity_tbl")) {
  dbWriteTable(
    conn = con_obj, 
    Id(
        schema = "dbo",
        table = "c_finthrive_productivity_tbl"
    ),
    df_tbl,
    append = TRUE,
    overwrite = FALSE,
    row.names = FALSE
    )
} else {
  dbWriteTable(
    conn = con_obj,    
    Id(
      schema = "dbo",
      table = "c_finthrive_productivity_tbl"
    ),
    df_tbl,
    row.names = FALSE)
}

# Insert the employee crosswalk data into the SQL table
if (dbExistsTable(con_obj, "c_finthrive_emp_crosswalk_tbl")) {
  dbWriteTable(
    conn = con_obj, 
    Id(
      schema = "dbo",
      table = "c_finthrive_emp_crosswalk_tbl"
    ),
    emp_tbl,
    overwrite = TRUE,
    row.names = FALSE
  )
} else {
  dbWriteTable(
    conn = con_obj,    
    Id(
      schema = "dbo",
      table = "c_finthrive_emp_crosswalk_tbl"
    ),
    emp_tbl,
    row.names = FALSE)
}

# Close the connection
db_disconnect(con_obj)

# Move file from Input_Files to Processed_Files
processed_path <- paste0(base_path, "Processed_Files")

if (!dir.exists(processed_path)) {
  dir.create(processed_path)
}

# Use file.copy() copy files to processed_path
if (!file.copy(input_file[1], processed_path, overwrite = TRUE)) {
  stop("Failed to copy the file to the processed directory.")
}

# Use file.remove() to remove the original file from input_path
file.remove(input_file[1])

# Print a message indicating the process is complete
cat("Data import and processing complete. File moved to Processed_Files.\n")
# End of script -----------------------------------------------------------

