# Lib Load ----
library(forcats)
library(dplyr)
library(readxl)
library(stringr)
library(writexl)

# Read in Excel file ----
df_tbl <- read_excel("combined_carc_rarc_data.xlsx")
head(df)

## Select out the needed columns ----
df_modified_tbl <- df_tbl |>
  rename(INS_CD = Ins_CD)

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
    COMBINED_CODES = str_flatten(CARC_RARC_CODE, collapse = " -> ")
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
