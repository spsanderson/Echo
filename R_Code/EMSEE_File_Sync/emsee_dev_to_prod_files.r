# The point of this script is to find any `file_name` that is in DEV that is NOT in PROD.

# Library Load ----
library(dplyr)
library(odbc)
library(DBI)

# Source DSS Connection Function ----
source(
  "W:/PATACCT/BusinessOfc/Revenue Cycle Analyst/R_Code/DSS_Connection_Functions.r"
)

# Make DSS Connection to DEV ----
cat("Connecting to Development Environment", "\n")
DEV_CONNECTION <- db_connect(
  .server_name = "financeDBDev.uhmc.sbuh.stonybrook.edu",
  .database = "EMSEE"
)
cat("Connected to:", DEV_CONNECTION@info$dbname, "\n")

# Query each file type in DEV and store in a tibble ----
## Professional Claims ----
dev_prof_claims_query <- paste0(
  "
  SELECT [FILE_NAME],
	[ENVIRONMENT_NAME] = 'DEVELOPMENT'
  FROM EMSEE.dbo.PROF
  GROUP BY [FILE_NAME];
  "
)
dev_prof_claims_tbl <- dbGetQuery(DEV_CONNECTION, dev_prof_claims_query) |>
  as_tibble()

## Professional Remits ----
dev_prof_remits_query <- paste0(
  "
  SELECT [FILE_NAME],
	[ENVIRONMENT_NAME] = 'DEVELOPMENT'
  FROM EMSEE.dbo.PROF_REMIT
  GROUP BY [FILE_NAME];
  "
)
dev_prof_remits_tbl <- dbGetQuery(DEV_CONNECTION, dev_prof_remits_query) |>
  as_tibble()

## Institutional Claims ----
dev_inst_claims_query <- paste0(
  "
  SELECT [FILE_NAME],
	[ENVIRONMENT_NAME] = 'DEVELOPMENT'
  FROM EMSEE.dbo.INST
  GROUP BY [FILE_NAME];
  "
)
dev_inst_claims_tbl <- dbGetQuery(DEV_CONNECTION, dev_inst_claims_query) |>
  as_tibble()

## Institutional Remits ----
dev_inst_remits_query <- paste0(
  "
  SELECT [FILE_NAME],
  [ENVIRONMENT_NAME] = 'DEVELOPMENT'
  FROM EMSEE.dbo.REMIT
  GROUP BY [FILE_NAME];
  "
)
dev_inst_remits_tbl <- dbGetQuery(DEV_CONNECTION, dev_inst_remits_query) |>
  as_tibble()

# Dev File Message ----
cat(
  "Distinct Professional Claims Files in DEV:",
  nrow(dev_prof_claims_tbl),
  "\n",
  "Distinct Professional Remits Files in DEV:",
  nrow(dev_prof_remits_tbl),
  "\n",
  "Distinct Institutional Claims Files in DEV:",
  nrow(dev_inst_claims_tbl),
  "\n",
  "Distinct Institutional Remits Files in DEV:",
  nrow(dev_inst_remits_tbl),
  "\n"
)

# Disconnect from DEV ----
cat("Disconnecting from:", DEV_CONNECTION@info$dbname, "\n")
db_disconnect(DEV_CONNECTION)
cat("Disconnected", "\n")

# Make DSS Connection to PROD ----
cat("Connecting to Production Environment", "\n")
PROD_CONNECTION <- db_connect(.database = "EMSEE")
cat("Connected to:", PROD_CONNECTION@info$dbname, "\n")

# Query each file type in PROD and store in a tibble ----
## Professional Claims ----
prod_prof_claims_query <- paste0(
  "
  SELECT [FILE_NAME],
	[ENVIRONMENT_NAME] = 'PRODUCTION'
  FROM EMSEE.dbo.PROF
  GROUP BY [FILE_NAME];
  "
)
prod_prof_claims_tbl <- dbGetQuery(PROD_CONNECTION, prod_prof_claims_query) |>
  as_tibble()

## Professional Remits ----
prod_prof_remits_query <- paste0(
  "
  SELECT [FILE_NAME],
	[ENVIRONMENT_NAME] = 'PRODUCTION'
  FROM EMSEE.dbo.PROF_REMIT
  GROUP BY [FILE_NAME];
  "
)
prod_prof_remits_tbl <- dbGetQuery(PROD_CONNECTION, prod_prof_remits_query) |>
  as_tibble()

## Institutional Claims ----
prod_inst_claims_query <- paste0(
  "
  SELECT [FILE_NAME],
	[ENVIRONMENT_NAME] = 'PRODUCTION'
  FROM EMSEE.dbo.INST
  GROUP BY [FILE_NAME];
  "
)
prod_inst_claims_tbl <- dbGetQuery(PROD_CONNECTION, prod_inst_claims_query) |>
  as_tibble()

## Institutional Remits ----
prod_inst_remits_query <- paste0(
  "
  SELECT [FILE_NAME],
	[ENVIRONMENT_NAME] = 'PRODUCTION'
  FROM EMSEE.dbo.REMIT
  GROUP BY [FILE_NAME];
  "
)
prod_inst_remits_tbl <- dbGetQuery(PROD_CONNECTION, prod_inst_remits_query) |>
  as_tibble()

# Prod File Message ----
cat(
  "Distinct Professional Claims Files in PROD:",
  nrow(prod_prof_claims_tbl),
  "\n",
  "Distinct Professional Remits Files in PROD:",
  nrow(prod_prof_remits_tbl),
  "\n",
  "Distinct Institutional Claims Files in PROD:",
  nrow(prod_inst_claims_tbl),
  "\n",
  "Distinct Institutional Remits Files in PROD:",
  nrow(prod_inst_remits_tbl),
  "\n"
)

# Disconnect from PROD ----
cat("Disconnecting from:", PROD_CONNECTION@info$dbname, "\n")
db_disconnect(PROD_CONNECTION)
cat("Disconnected", "\n")

# Get setdiff from DEV to PROD ----
## Professional Claims ----
missing_prof_claims_tbl <-
  setdiff(
    unique(dev_prof_claims_tbl$FILE_NAME),
    unique(prod_prof_claims_tbl$FILE_NAME)
  ) |>
  as_tibble() |>
  setNames("PROFESSIONAL_CLAIMS") |>
  mutate(FILE_NAME = basename(PROFESSIONAL_CLAIMS))

## Professional Remits ----
missing_prof_remits_tbl <-
  setdiff(
    unique(dev_prof_remits_tbl$FILE_NAME),
    unique(prod_prof_remits_tbl$FILE_NAME)
  ) |>
  as_tibble() |>
  setNames("PROFESSIONAL_REMITS") |>
  mutate(FILE_NAME = basename(PROFESSIONAL_REMITS))

## Institutional Claims ----
missing_inst_claims_tbl <-
  setdiff(
    unique(dev_inst_claims_tbl$FILE_NAME),
    unique(prod_inst_claims_tbl$FILE_NAME)
  ) |>
  as_tibble() |>
  setNames("INSTITUTIONAL_CLAIMS") |>
  mutate(FILE_NAME = basename(INSTITUTIONAL_CLAIMS))

## Institutional Remits ----
missing_inst_remits_tbl <-
  setdiff(
    unique(dev_inst_remits_tbl$FILE_NAME),
    unique(prod_inst_remits_tbl$FILE_NAME)
  ) |>
  as_tibble() |>
  setNames("INSTITUTIONAL_REMITS") |>
  mutate(FILE_NAME = basename(INSTITUTIONAL_REMITS))

# Missing File Message ----
cat(
  "Missing Professional Claims Files in PROD:",
  nrow(missing_prof_claims_tbl),
  "\n",
  "Missing Professional Remits Files in PROD:",
  nrow(missing_prof_remits_tbl),
  "\n",
  "Missing Instutional Claims Files in PROD:",
  nrow(missing_inst_claims_tbl),
  "\n",
  "Missing Institutional Remits Files in PROD:",
  nrow(missing_inst_remits_tbl),
  "\n"
)

# Now write each `missing_` tibble to a csv file ----
## Change this for production automation
base_write_path <- "W:/PATACCT/BusinessOfc/Revenue Cycle Analyst/R_Code/EMSEE_File_Sync/"

## Get todays date to append to file name ----
file_date <- Sys.Date()

## Write Files if nrows() != 0 ----
file_tbl <- tibble(
  file_to_write = list(
    missing_prof_claims_tbl,
    missing_prof_remits_tbl,
    missing_inst_claims_tbl,
    missing_inst_remits_tbl
  ),
  file_name = c(
    "missing_prof_claims",
    "missing_prof_remits",
    "missing_inst_claims",
    "missing_inst_remits"
  )
) |>
  mutate(
    file_path = paste0(base_write_path, file_name, "_", file_date, ".csv")
  )

if (file_tbl[sapply(file_tbl$file_to_write, nrow) > 0, ] |> nrow() > 0) {
  file_tbl[sapply(file_tbl$file_to_write, nrow) > 0, ] |>
    pull(file_path) |>
    lapply(write.csv, row.names = FALSE)
} else {
  cat("No files to write", "\n")
}

# End of Script ----
cat("Script Complete")

# # Professional Claims
# write.csv(
#   missing_prof_claims_tbl,
#   paste0(base_write_path, "missing_prof_claims.csv"),
#   row.names = FALSE
# )

# # Professional Remits
# write.csv(
#   missing_prof_remits_tbl,
#   paste0(base_write_path, "missing_prof_remits.csv"),
#   row.names = FALSE
# )

# # Institutional Claims
# write.csv(
#   missing_inst_claims_tbl,
#   paste0(base_write_path, "missing_inst_claims.csv"),
#   row.names = FALSE
# )

# # Institutional Remits
# write.csv(
#   missing_inst_remits_tbl,
#   paste0(base_write_path, "missing_inst_remits.csv"),
#   row.names = FALSE
# )
