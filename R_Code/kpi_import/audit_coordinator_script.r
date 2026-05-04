# =========================
# Audit Coordinator KPI Report Formatter
# =========================
# This script transforms Finalized_AuditCoordinator_KPI_Report_v1.xlsx
# (wide, multi-sheet) into a single tidy sheet.
# =========================

# ---- 1. Package Setup ----
required_pkgs <- c(
  "readxl",
  "openxlsx",
  "dplyr",
  "tidyr",
  "stringr",
  "lubridate",
  "DBI",
  "odbc"
)
for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg)
  }
  library(pkg, character.only = TRUE)
}

# ---- 2. File Paths ----
input_file <- "W:/PATACCT/Billing KPI’s/Katie - KPIs/Audit Coordinator KPI reports/Finalized_AuditCoordinator_KPI_Report_v1.xlsx"
output_file <- "W:/PATACCT/Billing KPI’s/Katie - KPIs/Audit Coordinator KPI reports/audit_coordinator_kpi_report.xlsx"

# ---- 3. Metric Name Mapping ----
metric_map <- c(
  "# of days worked" = "NUMBER_OF_DAYS_WORKED",
  "# of Accounts Worked on Worklists - Weekly" = "NUMBER_OF_ACCOUNTS_WORKED_ON_WORLISTS_WEEKLY",
  "# of Accounts on Worklist - Start of Week" = "NUMBER_OF_ACCOUNTS_ON_WORKLIST_START_OF_WEEK",
  "# of Accounts on Worklist - End of Week" = "NUMBER_OF_ACCOUNTS_ON_WORKLIST_END_OF_WEEK",
  "# of New Accounts on Worklist" = "NUMBER_OF_NEW_ACCOUNTS_ON_WORKLIST",
  "# of Old Accounts on Worklist" = "NUMBER_OF_OLD_ACCOUNTS_ON_WORKLIST"
)

# ---- 4. Helper: Robust Date Parsing ----
parse_excel_date <- function(x) {
  # Try ISO string first
  d <- suppressWarnings(as.Date(as.numeric(x), origin = "1899-12-30"))
  if (is.na(d)) {
    # Try Excel serial (origin 1899-12-30)
    d <- suppressWarnings(as.Date(as.numeric(x), origin = "1899-12-30"))
  }
  return(d)
}

# ---- 5. Main Extraction Function ----
extract_sheet <- function(sheetname) {
  # Read as text to avoid type issues
  df <- read_xlsx(
    input_file,
    sheet = sheetname,
    col_types = "text",
    .name_repair = "minimal",
    col_names = FALSE
  )
  df <- as.data.frame(df, stringsAsFactors = FALSE)

  # Find where the "Start of Week:" and "End of Week:" rows are
  sow_row <- which(apply(df, 1, function(r) {
    any(grepl("Start of Week:", r, ignore.case = TRUE))
  }))[1]
  eow_row <- which(apply(df, 1, function(r) {
    any(grepl("End of Week:", r, ignore.case = TRUE))
  }))[1]
  header_row <- which(apply(df, 1, function(r) {
    any(grepl("Billing Unit/Title", r, ignore.case = TRUE))
  }))[1]
  emp_row <- header_row + 1
  metric_start <- emp_row + 1
  metric_end <- metric_start + 5

  # Extract week columns (start at col 5)
  week_cols <- 5:ncol(df)
  sow <- as.character(df[sow_row, week_cols])
  eow <- as.character(df[eow_row, week_cols])
  # Remove empty trailing columns
  valid_weeks <- which(!is.na(sow) & sow != "")
  sow <- sow[valid_weeks]
  eow <- eow[valid_weeks]
  week_cols <- week_cols[valid_weeks]

  # Extract employee/unit info
  billing_unit <- as.character(df[emp_row, 1])
  employee <- as.character(df[emp_row, 2])
  # Normalize
  billing_unit <- toupper(gsub(" ", "_", trimws(billing_unit)))
  employee <- toupper(trimws(employee))

  # Extract metric names and values
  metrics <- as.character(df[metric_start:metric_end, 3])

  # Map to output codes
  metrics_check <- names(metric_map)
  if (any(is.na(metrics_check))) {
    stop(
      "Unmapped metric names found: ",
      paste(metrics[is.na(metrics_check)], collapse = ", ")
    )
  }

  # Build long data frame
  records <- list()
  for (w in seq_along(week_cols)) {
    sow_val <- parse_excel_date(sow[w])
    eow_val <- parse_excel_date(eow[w])
    if (is.na(sow_val) | is.na(eow_val)) {
      next
    } # skip invalid weeks
    for (m in seq_along(metrics)) {
      val <- as.character(df[metric_start + m - 1, week_cols[w]])
      if (is.na(val) || val == "") {
        next
      } # skip empty
      records[[length(records) + 1]] <- data.frame(
        BILLING_UNIT_TITLE = billing_unit,
        EMPLOYEE = employee,
        START_OF_WEEK = sow_val, #format(sow_val, "%Y-%m-%d"),
        END_OF_WEEK = eow_val, #format(eow_val, "%Y-%m-%d"),
        METRIC = metric_map[m],
        METRIC_VALUE = val |> as.numeric(),
        stringsAsFactors = FALSE
      )
    }
  }
  if (length(records) == 0) {
    return(NULL)
  }
  do.call(rbind, records)
}

# ---- 6. Process All Sheets ----
sheets <- excel_sheets(input_file)
all_data <- lapply(sheets, extract_sheet)
final_df <- bind_rows(all_data) |>
  as_tibble() |>
  group_by(BILLING_UNIT_TITLE, EMPLOYEE, START_OF_WEEK, END_OF_WEEK) |>
  mutate(GROUP_ID = cur_group_id()) |>
  mutate(RECORD_COUNT = row_number()) |>
  ungroup() |>
  # filter out max GROUP_ID if RECORD_COUNT != 6
  group_by(GROUP_ID) |>
  filter(!(GROUP_ID == max(GROUP_ID) & max(RECORD_COUNT) != 6)) |>
  ungroup() |>
  select(-GROUP_ID, -RECORD_COUNT) |>
  as.data.frame()


# ---- 7. Validation Output ----
cat(
  "\n==== VALIDATION SUMMARY ====\n",
  "Sheets processed:",
  paste(sheets, collapse = ", "),
  "\n",
  "Total rows:",
  nrow(final_df),
  "\n",
  "Unique BILLING_UNIT_TITLE:",
  paste(unique(final_df$BILLING_UNIT_TITLE), collapse = ", "),
  "\n",
  "Unique EMPLOYEE:",
  paste(unique(final_df$EMPLOYEE), collapse = ", "),
  "\n",
  "Date range:",
  format(min(final_df$START_OF_WEEK), "%Y-%m-%d"),
  "to",
  format(max(final_df$END_OF_WEEK), "%Y-%m-%d"),
  "\n",
  "Unique METRICS: \n -",
  paste(unique(final_df$METRIC), collapse = "\n - "),
  "\n",
  "First 12 rows:\n"
)
print(utils::head(final_df, 12))
str(final_df)

# ---- 8. Write Output ----
sn <- "audit_coordinator_kpi_report"
wb <- createWorkbook()
addWorksheet(wb, sn)
writeData(wb, sn, final_df)
saveWorkbook(wb, output_file, overwrite = TRUE)
cat("\nOutput written to", output_file, "\n")
