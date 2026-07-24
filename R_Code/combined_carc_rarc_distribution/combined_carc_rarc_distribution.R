# Lib Load ----
library(forcats)
library(dplyr)
library(readxl)
library(stringr)
library(writexl)
library(lubridate)

# Read in Excel file ----
df_tbl <- read_excel(
  "combined_carc_rarc_data_sps_rundate_2026-07-24_1037.xlsx"
) |>
  mutate(
    CHECK_EFT_DATE = ymd(CHECK_EFT_DATE)
  )
head(df_tbl)
names(df_tbl)

## Select out the needed columns ----
df_modified_tbl <- df_tbl |>
  # Drop records where the PCN == 0
  filter(PATIENT_CONTROL_NUMBER != 0)

## Factor the LINE_ADJUSTMENT_GROUP column ----
df_modified_tbl <- df_modified_tbl |>
  mutate(
    LINE_ADJUSTMENT_GROUP_CODE = fct_relevel(LINE_ADJUSTMENT_GROUP_CODE, "PR")
  )

df_combined_tbl <- df_modified_tbl |>
  filter(!is.na(INS_CD)) |>
  arrange(LINE_ADJUSTMENT_GROUP_CODE, LINE_ADJUSTMENT_REASON_CODE) |>
  group_by(INS_CD, CLAIM_STATUS, BILL_TYPE) |>
  mutate(
    COMBINED_CODES = str_flatten(unique(CARC_RARC_CODE), collapse = " -> ")
  ) |>
  ungroup() |>
  # Get a row_number by pcn to show the order of claims
  group_by(PATIENT_CONTROL_NUMBER) |>
  mutate(
    ascending_claim_number = dense_rank(CHECK_EFT_DATE),
    descending_claim_number = dense_rank(desc(CHECK_EFT_DATE))
  ) |>
  ungroup()

# Write out to excel file ----
write_xlsx(
  list(
    initial_data = df_tbl,
    modified_data = df_modified_tbl,
    combined_data = df_combined_tbl
  ),
  path = "linked_carc_rarc_data.xlsx"
)
