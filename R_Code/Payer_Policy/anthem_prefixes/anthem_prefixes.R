
# Library Load ------------------------------------------------------------


library(dplyr)
library(rvest)
library(purrr)
library(tidyr)
library(writexl)
library(DBI)
library(odbc)

# Source SQL Connection Fns -----------------------------------------------

source("W:/PATACCT/BusinessOfc/Revenue Cycle Analyst/R_Code/DSS_Connection_Functions.r")

# Base URL for Prefixes ---------------------------------------------------

# base_url
base_url <- "https://mypayerdirectory.com/bcbs-prefix-list/"

# xpath_location
xpath_location <- '//*[@id="article"]'

# read in the page
page <- read_html(base_url)

# generate a tibble of prefix urls to read
prefix_urls_tbl <- html_node(page, xpath = xpath_location) |>
  html_elements("a") |>
  html_attr("href") |>
  as_tibble() |>
  set_names("link")

# read in the page of each prefix url link
page_tbl <- prefix_urls_tbl |>
  mutate(
    page_data = map(link, read_html)
  )

# Get a table of the prefixes from their links into a tibble column
page_tbl <- page_tbl |>
  mutate(
    table_data = map(page_data, ~ html_table(.x))
  )

page_tbl <- page_tbl |>
  mutate(
    table_data = map(table_data, ~ .x[[1]] |> 
                       select(1, 2) |>
                       set_names(c("plan_identifier_prefix", "plan_name"))
    )
  ) |>
  unnest(cols = c(table_data))

# Get a distinct list of links where the plan_identifier_prefix == ''
missing_prefixes_link_tbl <- page_tbl |>
  filter(plan_identifier_prefix == "") |>
  distinct(link, page_data)

missing_prefixes_link_tbl <- missing_prefixes_link_tbl |>
  mutate(
    page_data = map(link, read_html)
  )

missing_prefixes_link_tbl <- missing_prefixes_link_tbl |>
  mutate(
    table_data = map(page_data, ~ html_table(.x))
  )

missing_prefixes_link_tbl <- missing_prefixes_link_tbl |>
  mutate(
    table_data = map(table_data, ~ .x[[1]] |>
                       select(1, 2) |>
                       set_names(c("plan_identifier_prefix", "plan_name"))
    )
  ) |>
  unnest(cols = c(table_data))

# Combine the two tables into one
page_tbl <- page_tbl |>
  select(link, plan_identifier_prefix, plan_name) |>
  bind_rows(missing_prefixes_link_tbl |>
              select(link, plan_identifier_prefix, plan_name)) |>
  distinct()

# Write to Share Drive ----------------------------------------------------


base_path <- "W:/PATACCT/BusinessOfc/Revenue Cycle Analyst/Payer_Policies/"
prefix_folder <- "anthem_prefixes"

# Create the folder if it doesn't exist
if (!dir.exists(file.path(base_path, prefix_folder))) {
  dir.create(file.path(base_path, prefix_folder))
}

# Write the prefix table to an excel file. Only use the columns: 
# - link
# - plan_identifier_prefix
# - plan_name
# Then write the file to the share drive
write_xlsx(
  page_tbl |>
    select(link, plan_identifier_prefix, plan_name),
  file.path(base_path, prefix_folder, "anthem_prefixes.xlsx")
)

# Write data to SQL -------------------------------------------------------


# Create a table if not exists called: c_anthem_prefixes_tbl
con_obj <- db_connect()

if (dbExistsTable(con_obj, "c_anthem_prefixes_tbl")){
  dbWriteTable(
    conn = con_obj,
    Id(
      schema = "dbo",
      table = "c_anthem_prefixes_tbl"
    ),
    page_tbl |>
      select(plan_identifier_prefix, plan_name) |>
      mutate(insert_date = as.Date(Sys.Date())),
    append = TRUE,
    overwrite = FALSE,
    row.names = FALSE
  )
} else {
  dbWriteTable(
    conn = con_obj,
    Id(
      schema = "dbo",
      table = "c_anthem_prefixes_tbl"
    ),
    page_tbl |>
      select(plan_identifier_prefix, plan_name) |>
      mutate(insert_date = as.Date(Sys.Date())),
    row.names = FALSE
  )
}

# Query table and count the rows just inserted into c_anthme_prefixes_tbl
rows_inserted <- dbGetQuery(con_obj, "
                            SELECT COUNT(*) AS row_count 
                            FROM dbo.c_anthem_prefixes_tbl
                            WHERE insert_date = (
                              SELECT MAX(insert_date) 
                              FROM dbo.c_anthem_prefixes_tbl
                            )
                            ")[[1]]

db_disconnect(con_obj)

# Message how many rows were just pushed to the table
cat("Rows inserted into c_anthem_prefixes_tbl:", rows_inserted, "\n")

# End of Script -----------------------------------------------------------