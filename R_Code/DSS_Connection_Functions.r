db_connect <-
function(.server_name = "financedbp.uhmc.sbuh.stonybrook.edu",
                       .database = "SMS") {
  
  server_name <- as.character(.server_name)
  data_base_name <- as.character(.database)

  db_con <- DBI::dbConnect(
    odbc::odbc(), 
    Driver = "SQL Server", 
    Server = server_name,
    Database = data_base_name,
    Trusted_Connection = T
  )
  
  return(db_con)
  
}
db_disconnect <-
function(.connection) {
  
  DBI::dbDisconnect(
    conn = .connection
  )
  
}