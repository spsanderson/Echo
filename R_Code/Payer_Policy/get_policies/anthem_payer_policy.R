library(httr2)
library(tidyverse)

jsonurl <- "https://providers.anthem.com/sites/Satellite?d=Universal&pagename=getdocuments&brand=BCCNYE&state=&formslibrary=gpp_formslib"
#f_path <- "W:/PATACCT/BusinessOfc/Revenue Cycle Analyst/Payer_Policies/Anthem_PDFs/"
f_path <- paste0(getwd(), "/Anthem_PDFs/")
# Make directory if not exists
if (!dir.exists(f_path)) {
  dir.create(f_path)
}

# Step 1: Perform the GET request and parse the JSON response
response <- request(jsonurl) |> 
  req_perform() |> 
  resp_body_json()

# Step 2: Extract the relevant data and process it into a tibble
alldocs_tbl <- tibble(URI = map_chr(response[[1]], "URI")) |> 
  mutate(
    filename = str_extract(URI, "(?<=/)[^/]+(?=\\?)"),
    is_pdf = str_detect(filename, "\\.pdf$")
  ) 
  #filter(is_pdf)

# Step 3: Download the first PDF file
walk2(
  paste0("https://providers.anthem.com", alldocs_tbl$URI[1:nrow(alldocs_tbl)]), 
  alldocs_tbl$filename[1:nrow(alldocs_tbl)], 
  ~ { request(.x) |> req_perform(path = paste0(f_path, .y)); Sys.sleep(3) }
)

# Step 4: Print the file names of the downloaded files
print(list.files(f_path))
