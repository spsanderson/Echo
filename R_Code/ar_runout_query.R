runout_query <- function(start_date, end_date) {
  
  db_con_obj <- db_connect()
  
  query <- paste0("
    execute sms.dbo.c_ar_runout_sp 
    @start_date = '", start_date, "', 
    @end_date = '", end_date, "';
  ")
  
  result <- dbGetQuery(
    conn = db_con_obj,
    statement = query
  )
  
  result <- as_tibble(result) |>
    mutate(across(where(is.character), str_squish))
  
  db_disconnect(db_con_obj)
 
  return(result)
}