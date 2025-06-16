# Load the tidyverse, rvest and rlang packages
library(tidyverse)
library(rlang)
library(httr2)
library(fs)

# Define the URL of the webpage to scrape
base_url = "https://www.cigna.com/"
json_url <- "https://p-gsg.digitaledge.cigna.com/digital/cigna/search?index=index-public-cigna-prod&query=.pdf&from=0&type=application/pdf&size=20"

# Make a request
response <- request(json_url) %>%
  req_perform() |>
  resp_body_json()

# Get the total paged records
total_records <- response$total

# Now we need to loop through the json results pages from 0 to (total_records - 1)
# We need to do this from 0 to (total_records - 1) in increments of 100
# Create an empty list to store the data
# First lets create the url parts
front_url <- "https://p-gsg.digitaledge.cigna.com/digital/cigna/search?index=index-public-cigna-prod&query=.pdf&from="
back_url <- "&type=application/pdf&size=100"
data_list <- list()

# Loop through the pages
for (i in seq(0, total_records, by = 100)) {
  # Create the url
  fetch_url <- paste0(front_url, i, back_url)
  # Make a request
  cat("Fetching page ", i, " of ", total_records, "\n")
  response <- request(fetch_url) %>%
    req_perform() |>
    resp_body_json()
  
  response_tbl <- response[["results"]] |>
    map(as_tibble) |>
    list_rbind() |>
    mutate(
      base_url = base_url
    ) |>
    select(
      base_url, everything()
    ) |>
    # Filter out the contentType, we only want the pdfs
    filter(
      contentType == "application/pdf"
    )
  
  # Append the data to the list
  data_list[[length(data_list) + 1]] <- response_tbl
  cat(paste0("Appending page ", i, " of ", total_records, "\n"))
}

# Combine all the data into a single data frame
link_tbl <- data_list |>
  list_rbind() |>
  distinct(ID, .keep_all = TRUE) |>
  mutate(
    file_link = paste0(base_url, link)
  ) |>
  # If description does not end in file extension .pdf then add .pdf
  mutate(
    description = if_else(
      str_detect(description, "\\.pdf$"),
      description,
      paste0(description, ".pdf")
    )
  )

# Now we need to download the files
# Create a directory to store the files
f_path <- "W:/PATACCT/BusinessOfc/Revenue Cycle Analyst/Payer_Policies/Cigna_PDFs/"
if (!dir_exists(f_path)) {
  dir_create(f_path)
}

# Loop through the data frame and download the files
for (i in seq_len(nrow(link_tbl))) {
  # Get the file name
  file_name <- link_tbl[i, "description"][[1]]
  # Get the file link
  file_link <- link_tbl[i, "file_link"][[1]]
  # Create the file path
  file_path <- paste0(f_path, file_name)
  
  # Check if the file already exists
  if (!file_exists(file_path)) {
    # Download the file
    cat("Downloading ", file_name, "\n")
    # Use try in case the link throws an error
    tryCatch({
      download.file(file_link, destfile = file_path, mode = "wb")
    }, error = function(e) {
      cat("Error downloading file: ", file_name, "\n",
          "Error message: ", e$message, "\n")
    })
  } else {
    cat("File already exists: ", file_name, "\n")
  }
}

# How many files were successfully downloaded
all_files <- dir_ls(f_path, recurse = TRUE, type = "file")

inform(
  message = paste0(
    "Files downloaded successfully to: \n", f_path, "\n\n",
    
    "Total files downloaded: ", length(all_files)
  ))
