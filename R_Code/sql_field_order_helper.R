sql_field_order_helper <- function(
    .table_name = "Pt_Accounting_Reporting_ALT",
    .connection = db_con_obj
){
  
  # Tidyeval 
  # server_name <- as.character(.server_name)
  # db_name <- as.character(.database_name)
  table_name <- as.character(.table_name)
  
  column_types <- DBI::dbGetQuery(
    conn = db_con_obj,
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
  
  ct <- column_types %>%
    dplyr::mutate(
      cml = dplyr::case_when(
        is.na(CHARACTER_MAXIMUM_LENGTH) ~ 10,
        CHARACTER_MAXIMUM_LENGTH == -1 ~ 100000,
        TRUE ~ as.double(CHARACTER_MAXIMUM_LENGTH)
      )
    ) %>%
    dplyr::arrange(cml) %>%
    dplyr::pull(COLUMN_NAME)
  
  fields <- paste(ct, collapse=", ")
  
  return(fields)
  
}