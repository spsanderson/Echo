# Thse are just for Katie D
# "W:/PATACCT/Billing KPI’s/Katie - KPIs/Audit Coordinator KPI reports/Finalized_AuditCoordinator_KPI_Report_v1.xlsx"
# "W:/PATACCT/Billing KPI’s/Katie - KPIs/Billing units - KPI reports/Finalized_Billing_KPI_Report_v1.xlsx"
# "W:/PATACCT/Billing KPI’s/Katie - KPIs/D and A KPI Reports/Finalized_DA_KPI_Report_v1.xlsx"
# "W:/PATACCT/Billing KPI’s/Katie - KPIs/RI-RCM KPI reports/Finalized_RI_RCM_KPI_Report_v1.xlsx"
# These are for Ray
# "W:/PATACCT/BusinessOfc/Revenue Cycle Analyst/Ray G/Variance KPI/Finalized_Variance_KPI_Report_v1.xlsx"
# These are for Liz
# "W:/PATACCT/BusinessOfc/FOLLOW UP UNITS/KPI/Master KPI/Non_Govt_Follow_Up_KPI_Report.xlsx"
# "W:/PATACCT/BusinessOfc/FOLLOW UP UNITS/KPI/Master KPI/Unitized_Follow_Up_KPI_Report.xlsx"
# Velkeys
# "W:/PATACCT/BusinessOfc/Insurance_Verification/KPI/Insurance_Verification_KPI_Report.xlsx"

# ---- 0. Libary Load ----
required_pkgs <- c(
  "tidyverse",
  "DBI",
  "odbc"
)
for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg)
  }
  library(pkg, character.only = TRUE)
}

# ---- 1. Source Scripts ----
source("audit_coordinator_script.r")
rm(list = ls())

source("billing_units_script.r")
rm(list = ls())

source("da_unit_script.r")
rm(list = ls())

source("ri_rcm_script.r")
rm(list = ls())

source("variance_script.r")
rm(list = ls())

source("non_govt_follow_up_script.r")
rm(list = ls())

source("unitized_follow_up_script.r")
rm(list = ls())

source("insurance_verification_script.r")
rm(list = ls())


# ---- 2. Read in output files ----
file_paths <- list(
  audit_coordinator = "W:/PATACCT/Billing KPI’s/Katie - KPIs/Audit Coordinator KPI reports/audit_coordinator_kpi_report.xlsx",
  billing_units = "W:/PATACCT/Billing KPI’s/Katie - KPIs/Billing units - KPI reports/billing_units_kpi_report.xlsx",
  da_unit = "W:/PATACCT/Billing KPI’s/Katie - KPIs/D and A KPI Reports/da_kpi_report.xlsx",
  ri_rcm = "W:/PATACCT/Billing KPI’s/Katie - KPIs/RI-RCM KPI reports/ri_rcm_kpi_report.xlsx",
  variance = "W:/PATACCT/Billing KPI’s/Katie - KPIs/RI-RCM KPI reports/ri_rcm_kpi_report.xlsx",
  non_govt_follow_up = "W:/PATACCT/BusinessOfc/FOLLOW UP UNITS/KPI/Master KPI/non_gov_fol_up_kpi_report.xlsx",
  unitized_follow_up = "W:/PATACCT/BusinessOfc/FOLLOW UP UNITS/KPI/Master KPI/unit_accts_fol_up_kpi_report_.xlsx",
  insurance_verification = "W:/PATACCT/BusinessOfc/Insurance_Verification/KPI/ins_ver_kpi_report.xlsx"
)

combined_tbl <- map(file_paths, read_xlsx) |>
  list_rbind()
combined_tbl <- combined_tbl |>
  filter(END_OF_WEEK < Sys.Date())

# ---- 3. Write to SQL ----

## ---- Source connection file ----
source(
  "W:/PATACCT/BusinessOfc/Revenue Cycle Analyst/R_Code/DSS_Connection_Functions.r"
)

## ---- Create Connection Object ----
db_con_obj <- db_connect()

## ---- Create Table ----
dbWriteTable(
  conn = db_con_obj,
  Id(
    schema = "dbo",
    table = "c_business_ofc_kpi_report_tbl"
  ),
  combined_tbl,
  overwrite = TRUE
)

db_disconnect(db_con_obj)
