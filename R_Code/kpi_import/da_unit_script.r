# =========================================================
# D&A KPI Report Formatter
# =========================================================
# This script transforms Finalized_DA_KPI_Report_v1.xlsx
# (wide, multi-sheet format) into a single tidy sheet.
# =========================================================

# ---- 1. Package Setup ----
required_pkgs <- c(
  "readxl",
  "openxlsx",
  "dplyr",
  "tidyr",
  "stringr",
  "lubridate",
  "DBI",
  "odbc",
  "purrr",
  "tibble"
)
for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg)
  }
  library(pkg, character.only = TRUE)
}

## --------------------------
## 2 Paths (edit as needed)
## --------------------------
input_file <- "W:/PATACCT/Billing KPI’s/Katie - KPIs/D and A KPI Reports/Finalized_DA_KPI_Report_v1.xlsx"
output_file <- "W:/PATACCT/Billing KPI’s/Katie - KPIs/D and A KPI Reports/da_kpi_report.xlsx"


# ---- 3) Output Options ----
## User requested ALL metrics:
only_sample_metrics <- FALSE

## ---- 4) Metric Mapping (explicit known names -> standardized codes) ----
## Everything not listed here will be standardized by fallback logic.
metric_map <- c(
  "# of Accounts Worked on Worklists - Weekly" = "NUMBER_OF_ACCOUNTS_WORKED_ON_WORKLISTS_WEEKLY",
  "# of Accounts on Worklist - Start of Week" = "NUMBER_OF_ACCOUNTS_ON_WORKLIST_START_OF_WEEK",
  "# of Accounts on Worklist - End of Week" = "NUMBER_OF_ACCOUNTS_ON_WORKLIST_END_OF_WEEK",
  "# of New Accounts on Worklist" = "NUMBER_OF_NEW_ACCOUNTS_ON_WORKLIST",
  "# of Old Accounts on Worklist" = "NUMBER_OF_OLD_ACCOUNTS_ON_WORKLIST",
  "# of Days Worked" = "NUMBER_OF_DAYS_WORKED",
  "Weekly Productivity Target" = "WEEKLY_PRODUCTIVITY_TARGET",
  "Daily Productivity" = "DAILY_PRODUCTIVITY"
)

full_metric_set <- metric_map |> unname()

sample_metric_set <- c(
  "NUMBER_OF_CLAIMS_WORKED_IN_SCRUBBER_TOUCHED",
  "NUMBER_OF_CLAIMS_WORKED_IN_SCRUBBER_RELEASED",
  "UNBILLED_ASSIGNED_CLAIMS"
)

## ---- 5) Helpers ----

# Robust date parsing: handles Excel serials, Date, and text like "01/04/2026"
parse_excel_date <- function(x) {
  # Try ISO string first
  d <- suppressWarnings(as.Date(as.numeric(x), origin = "1899-12-30"))
  if (is.na(d)) {
    # Try Excel serial (origin 1899-12-30)
    d <- suppressWarnings(as.Date(as.numeric(x), origin = "1899-12-30"))
  }
  return(d)
}

# Normalize billing unit/title: "Gov't - Supervisor" -> "GOVT_SUPERVISOR"
clean_unit <- function(x) {
  x <- toupper(trimws(as.character(x)))
  x <- str_replace_all(x, "GOV'T", "GOVT")
  x <- str_replace_all(x, "NON-GOV'T", "NON_GOVT")
  x <- str_replace_all(x, "[^A-Z0-9]+", "_")
  x <- str_replace_all(x, "_+", "_")
  x <- str_replace_all(x, "^_|_$", "")
  x
}

# Normalize employee: "Taylor Kravitz" -> "TAYLOR_KRAVITZ"
clean_employee <- function(x) {
  x <- toupper(trimws(as.character(x)))
  x <- str_replace_all(x, "[^A-Z0-9]+", "_")
  x <- str_replace_all(x, "_+", "_")
  x <- str_replace_all(x, "^_|_$", "")
  x
}

# Standardize metric name (explicit mapping first, then fallback normalization)
standardize_metric <- function(x) {
  x0 <- trimws(as.character(x))
  if (is.na(x0) || x0 == "") {
    return(NA_character_)
  }

  if (x0 %in% names(metric_map)) {
    return(unname(metric_map[x0]))
  }

  y <- toupper(x0)
  y <- str_replace_all(y, "GOV'T", "GOVT")
  y <- str_replace_all(y, "NON-GOV'T", "NON_GOVT")
  y <- str_replace_all(y, "#", "NUMBER")
  y <- str_replace_all(y, "%", "PERCENT")
  y <- str_replace_all(y, "&", "AND")
  y <- str_replace_all(y, "[^A-Z0-9]+", "_")
  y <- str_replace_all(y, "_+", "_")
  y <- str_replace_all(y, "^_|_$", "")
  y
}

# Convert values to numeric when possible; handle patterns like "10/2/2024 - 1"
to_numeric_safely <- function(v) {
  v0 <- trimws(as.character(v))
  if (is.na(v0) || v0 == "") {
    return(NA_real_)
  }

  v0 <- str_replace_all(v0, ",", "")

  if (str_detect(v0, " - ")) {
    last_num <- suppressWarnings(as.numeric(str_extract(
      v0,
      "(-?\\d+\\.?\\d*)\\s*$"
    )))
    if (!is.na(last_num)) return(last_num)
  }

  suppressWarnings(as.numeric(v0))
}

# Locate a row that contains a label in ANY column
find_row_anycol <- function(df, pattern) {
  idx <- which(apply(df, 1, function(r) {
    any(str_detect(as.character(r), pattern))
  }))
  if (length(idx) == 0) {
    return(NA_integer_)
  }
  idx[1]
}

# Identify week columns based on SOW/EOW rows
get_week_cols <- function(df, sow_row, eow_row) {
  sow_cells <- as.character(unlist(df[sow_row, ], use.names = FALSE))
  eow_cells <- as.character(unlist(df[eow_row, ], use.names = FALSE))

  cand <- which(
    !is.na(sow_cells) &
      trimws(sow_cells) != "" &
      !str_detect(
        sow_cells,
        regex("^\\s*Start of Week", ignore_case = TRUE)
      )
  )
  if (length(cand) == 0) {
    stop("Could not detect week columns from 'Start of Week' row.")
  }

  valid <- cand[!is.na(eow_cells[cand]) & trimws(eow_cells[cand]) != ""]
  if (length(valid) == 0) {
    valid <- cand
  }

  list(
    week_cols = valid,
    sow = sow_cells[valid],
    eow = eow_cells[valid]
  )
}

# Detect employee blocks: rows where col1 & col2 have values and it isn't the header row
find_employee_blocks <- function(df, start_row) {
  c1 <- as.character(df[[1]])
  c2 <- as.character(df[[2]])
  c3 <- as.character(df[[3]])

  rows <- seq.int(start_row, nrow(df))

  is_block <- function(i) {
    a <- trimws(c1[i])
    b <- trimws(c2[i])
    m <- trimws(c3[i])
    if (is.na(a) || a == "" || is.na(b) || b == "") {
      return(FALSE)
    }

    # exclude header rows
    if (str_detect(a, regex("^Billing Unit/Title$", ignore_case = TRUE))) {
      return(FALSE)
    }
    if (str_detect(b, regex("^Employee$", ignore_case = TRUE))) {
      return(FALSE)
    }

    # typical block header has metric column empty or "Metrics"/"Weekly Target"
    if (is.na(m) || m == "") {
      return(TRUE)
    }
    if (
      str_detect(
        m,
        regex("^Metrics$|^Weekly Target$", ignore_case = TRUE)
      )
    ) {
      return(TRUE)
    }

    # fallback: unit rows usually contain a hyphen (e.g., "Gov't - Biller")
    if (str_detect(a, "-")) {
      return(TRUE)
    }

    # typical block: col3 empty
    if (is.na(m) || m == "") {
      return(TRUE)
    }

    # if col3 is a metric name (including # of Days Worked), still a block header
    if (m %in% names(metric_map)) {
      return(TRUE)
    }

    # heuristic: metric-like strings
    if (
      str_detect(
        m,
        regex("^(#|%|Unbilled|Accounts|Combined|Total)\\b", ignore_case = TRUE)
      )
    ) {
      return(TRUE)
    }

    # fallback: unit rows often contain a hyphen
    if (str_detect(a, "-")) {
      return(TRUE)
    }

    FALSE
  }

  blocks <- rows[vapply(rows, is_block, logical(1))]
  blocks <- blocks[c(TRUE, diff(blocks) > 1)]
  blocks
}

## ---- 6) Main Sheet Extraction ----
extract_sheet <- function(sheet_name) {
  df <- read_xlsx(
    input_file,
    sheet = sheet_name,
    col_names = FALSE,
    col_types = "text",
    .name_repair = "minimal"
  ) %>%
    as.data.frame(stringsAsFactors = FALSE)

  sow_row <- find_row_anycol(df, regex("Start of Week:", ignore_case = TRUE))
  eow_row <- find_row_anycol(df, regex("End of Week:", ignore_case = TRUE))
  hdr_row <- find_row_anycol(
    df,
    regex("Billing Unit/Title", ignore_case = TRUE)
  )

  if (is.na(sow_row) || is.na(eow_row) || is.na(hdr_row)) {
    stop(paste(
      "Sheet",
      sheet_name,
      ": missing Start/End of Week or header row."
    ))
  }

  wk <- get_week_cols(df, sow_row, eow_row)
  week_cols <- wk$week_cols

  sow_dates <- map(wk$sow, parse_excel_date) %>% list_c()
  eow_dates <- map(wk$eow, parse_excel_date) %>% list_c()

  ok <- which(!is.na(sow_dates) & !is.na(eow_dates))
  week_cols <- week_cols[ok]
  sow_dates <- sow_dates[ok]
  eow_dates <- eow_dates[ok]
  if (length(week_cols) == 0) {
    stop(paste("Sheet", sheet_name, ": no valid week date columns found."))
  }

  blocks <- find_employee_blocks(df, start_row = hdr_row + 1)
  if (length(blocks) == 0) {
    return(NULL)
  }

  block_ends <- c(blocks[-1] - 1, nrow(df))

  out_list <- vector("list", length(blocks))
  non_numeric_log <- character(0)

  for (i in seq_along(blocks)) {
    bstart <- blocks[i]
    bend <- block_ends[i]

    billing_unit <- clean_unit(df[bstart, 1])
    employee <- clean_employee(df[bstart, 2])

    if (bstart + 1 > bend) {
      next
    }

    metric_rows <- bstart:bend #EDITED
    metric_names <- trimws(as.character(df[metric_rows, 3]))

    is_metric <- !is.na(metric_names) &
      metric_names != "" &
      !str_detect(
        metric_names,
        regex("^Metrics$|^Weekly Target$", ignore_case = TRUE)
      )

    metric_rows <- metric_rows[is_metric]
    if (length(metric_rows) == 0) {
      next
    }

    metric_raw <- as.character(df[metric_rows, 3])
    metric_std <- vapply(metric_raw, standardize_metric, character(1))

    values_mat <- df[metric_rows, week_cols, drop = FALSE]

    tmp <- tibble(
      BILLING_UNIT_TITLE = billing_unit,
      EMPLOYEE = employee,
      METRIC_RAW = metric_raw,
      METRIC = metric_std
    ) %>%
      bind_cols(as.data.frame(values_mat, stringsAsFactors = FALSE))

    wk_names <- paste0("W", seq_along(week_cols))
    names(tmp)[(ncol(tmp) - length(week_cols) + 1):ncol(tmp)] <- wk_names

    long <- tmp %>%
      pivot_longer(
        cols = all_of(wk_names),
        names_to = "WEEK_INDEX",
        values_to = "VALUE_RAW"
      ) %>%
      mutate(
        WEEK_NUM = as.integer(str_remove(WEEK_INDEX, "^W")),
        START_OF_WEEK = sow_dates[WEEK_NUM],
        END_OF_WEEK = eow_dates[WEEK_NUM],
        METRIC_VALUE = vapply(VALUE_RAW, to_numeric_safely, numeric(1))
      ) %>%
      select(
        BILLING_UNIT_TITLE,
        EMPLOYEE,
        START_OF_WEEK,
        END_OF_WEEK,
        METRIC,
        METRIC_VALUE,
        VALUE_RAW
      )

    bad <- long %>%
      filter(
        is.na(METRIC_VALUE),
        !is.na(VALUE_RAW),
        trimws(as.character(VALUE_RAW)) != ""
      ) %>%
      mutate(
        MSG = paste(
          sheet_name,
          BILLING_UNIT_TITLE,
          EMPLOYEE,
          METRIC,
          VALUE_RAW,
          sep = " | "
        )
      ) %>%
      pull(MSG)

    non_numeric_log <- c(non_numeric_log, bad)

    out_list[[i]] <- long %>%
      select(
        BILLING_UNIT_TITLE,
        EMPLOYEE,
        START_OF_WEEK,
        END_OF_WEEK,
        METRIC,
        METRIC_VALUE
      ) %>%
      filter(
        !METRIC %in%
          c(
            "TOTAL_CLAIMS_RELEASED_INCLUDING_SUPERVISORS",
            "TOTAL_CLAIMS_EXCLUDING_SUPERVISORS",
            "TOTAL_UNBILLED_CLAIMS_EXCLUDING_NON_GOVT_FOLLOW_UP",
            "TOTAL_EMPLOYEES_WORKED_EXCLUDING_SUPERVISORS_AND_NON_GOVT_FOLLOW_UP",
            "NUMBER_OF_CLAIMS_PER_PERSON_PER_WEEK",
            "NUMBER_OF_CLAIMS_PER_PERSON_PER_DAY",
            "GOVT_BILLING_TOTAL_PROD",
            "NON_GOVT_BILLING_TOTAL_PROD"
          )
      )
  }

  out <- bind_rows(out_list)
  attr(out, "non_numeric_log") <- unique(non_numeric_log)
  out
}

## ---- 7) Process All Sheets ----
sheets <- excel_sheets(input_file)

all_data <- map(sheets, extract_sheet)
final_df <- bind_rows(all_data)
final_df <- final_df |>
  filter(END_OF_WEEK < Sys.Date())

## If you ever need sample-only output, flip only_sample_metrics to TRUE
if (only_sample_metrics) {
  final_df <- final_df |> filter(METRIC %in% sample_metric_set)
} else {
  final_df <- final_df %>%
    filter(
      !is.na(METRIC),
      METRIC != "",
      !is.na(METRIC_VALUE),
      METRIC %in% full_metric_set
    )
}

## ---- 8) Validations ----
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

expected_cols <- c(
  "BILLING_UNIT_TITLE",
  "EMPLOYEE",
  "START_OF_WEEK",
  "END_OF_WEEK",
  "METRIC",
  "METRIC_VALUE"
)
missing <- setdiff(expected_cols, names(final_df))
extra <- setdiff(names(final_df), expected_cols)

if (length(missing) > 0) {
  stop(paste("Missing required columns:", paste(missing, collapse = ", ")))
}
if (length(extra) > 0) {
  cat("Note: Extra cols will be removed:", paste(extra, collapse = ", "), "\n")
  final_df <- final_df[, expected_cols]
}

na_rate <- mean(is.na(final_df$METRIC_VALUE))
cat("METRIC_VALUE NA rate:", round(na_rate * 100, 2), "%\n")

## ---- 9) Write Output (single tab) ----
wb <- createWorkbook()
sn <- "da_kpi_report"
addWorksheet(wb, sn)

writeData(wb, sn, final_df)
freezePane(wb, sn, firstRow = TRUE)
addFilter(wb, sn, row = 1, cols = 1:ncol(final_df))
setColWidths(wb, sn, cols = 1:ncol(final_df), widths = "auto")

date_style <- createStyle(numFmt = "mm/dd/yyyy")
if (nrow(final_df) > 0) {
  addStyle(
    wb,
    sn,
    style = date_style,
    cols = 3:4,
    rows = 2:(nrow(final_df) + 1),
    gridExpand = TRUE
  )
}

saveWorkbook(wb, output_file, overwrite = TRUE)
cat("\nOutput written to:", output_file, "\n")

## ---- 10) Non-numeric log (optional print) ----
logs <- map(all_data, ~ attr(.x, "non_numeric_log")) %>%
  unlist() %>%
  unique()

if (length(logs) > 0) {
  cat("\n==== NON-NUMERIC VALUES THAT BECAME NA (showing up to 50) ====\n")
  print(head(logs, 50))
  cat("Count:", length(logs), "\n")
}
