sql_field_order_helper <- function(
    .server_name = "financedbp.uhmc.sbuh.stonybrook.edu",
    .database_name ="SMS",
    .table_name = "Pt_Accounting_Reporting_ALT"
){
  
  # Tidyeval 
  server_name <- as.character(.server_name)
  db_name <- as.character(.database_name)
  table_name <- as.character(.table_name)
  
  #  DB connect
  db_con <- db_connect(
    .server_name = server_name,
    .database = db_name
  )
  
  column_types <- DBI::dbGetQuery(
    conn = db_con,
    statement = paste0(
      "
      SELECT COLUMN_NAME,
      DATA_TYPE, 
      CHARACTER_MAXIMUM_LENGTH 
      FROM INFORMATION_SCHEMA.COLUMNS 
      WHERE TABLE_NAME = '",
      table_name,
      "'"
    )
  )
  
  ct <- column_types |>
    dplyr::mutate(
      cml = dplyr::case_when(
        is.na(CHARACTER_MAXIMUM_LENGTH) ~ 10,
        CHARACTER_MAXIMUM_LENGTH == -1 ~ 100000,
        TRUE ~ as.double(CHARACTER_MAXIMUM_LENGTH)
      )
    ) %>%
    dplyr::arrange(cml) |>
    dplyr::pull(COLUMN_NAME)
  
  fields <- paste(ct, collapse=", ")
  
  return(fields)
  
}