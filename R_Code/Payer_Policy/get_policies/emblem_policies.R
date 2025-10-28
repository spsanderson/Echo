# Load the tidyverse, rvest and rlang packages
library(rvest)
library(tidyverse)
library(rlang)
library(fs)

# Define the target URL
base_url <- "https://www.emblemhealth.com"

# PDF file base url
pdf_base_url <- "https://www.emblemhealth.com/providers/search?page=1&query=.pdf&contenttype=file&audience=provider&sort=relevance"

# Read initial page
page <- read_html(pdf_base_url)

# Get the total number of pages
page_numbers_xpath <- "/html/body/div[1]/div/div[2]/div/div/div/div[1]/div[2]/div"
page_number_node <- html_node(page, xpath = page_numbers_xpath)
page_numbers <- page_number_node |>
  html_elements("a") |>
  html_attr("data-destination") |>
  as.vector() |>
  as.integer() |>
  unique()

# Break pdf page url into front url and then back url
# this will allow us to construct the search results page
# where we can downlod the pdf files.
pdf_front_url <- "https://www.emblemhealth.com/providers/search?page="
pdf_end_url <- "&query=.pdf&contenttype=file&audience=provider&sort=relevance"

# PDF xpath for each page
pdf_xpath <- "/html/body/div[1]/div/div[2]/div/div/div/div[1]/div[1]"

# Create a function to generate the full URL for each page
generate_page_url <- function(page_number) {
  paste0(pdf_front_url, page_number, pdf_end_url)
}

# Create function to get folder name
# Get directory name from the url
extract_directory <- function(url) {
  # Handle empty or NULL input
  if (is.null(url) || nchar(url) == 0) {
    return("PROVIDER")
  }
  
  # Convert URL-encoded spaces
  url <- gsub("%20", " ", url)
  
  # Extract path after provider/
  pattern <- "/provider/([^?#]*)"
  path_match <- regexpr(pattern, url, perl = TRUE)
  
  if (path_match == -1) {
    return("PROVIDER")
  }
  
  # Get the path after provider/
  path_after_provider <- substr(url, 
                                path_match + 9,  # length of "/provider/"
                                path_match + attr(path_match, "match.length") - 1)
  
  # Split path into directories
  directories <- strsplit(path_after_provider, "/")[[1]]
  directories <- directories[directories != ""]
  
  if (length(directories) == 0) {
    return("PROVIDER")
  }
  
  # Get the last directory before filename
  last_dir <- directories[length(directories)]
  
  # Check if last directory is meaningful (not a single letter or contains file extension)
  if (nchar(last_dir) <= 1 || grepl("\\.", last_dir)) {
    # If not meaningful, take first directory after provider
    directory <- directories[1]
  } else {
    directory <- last_dir
  }
  
  # Format the directory name
  directory <- toupper(directory)
  # Replace special characters with underscore
  directory <- gsub("[-,\\s]", "_", directory)
  
  return(directory)
}

# Get a list of links in tibble format
pdf_link_list <- lapply(page_numbers, function(x) {
  page_url <- generate_page_url(x)
  
  # Print the page URL for debugging
  cat("Page Number: ", x, "\n",
      "Page URL: ", page_url, "\n", sep = "")
  
  # Get the HTML content of the page
  page <- read_html(page_url)
  
  # Use html_node() to select the matching XPath element
  page_node <- html_node(page, xpath = pdf_xpath)
  
  # Extract the links from the page node
  links <- page_node |>
    html_elements("a") |>
    html_attr("href") |>
    unique() |>
    as.list()
  
  # Drop any NA values in the links list
  # use purrr to map over the list of links
  # and extract the directory name
  links <- map(links, \(x) x |> 
        as_tibble()) |> 
    list_rbind() |> 
    filter(!is.na(value)) |>
    mutate(folder = map(value, extract_directory) |> 
             unlist()
    )
  
  # Print the links for debugging
  print(paste0("Links Extracted: ", nrow(links)))
  
  # Return the links
  return(links)
})

pdf_link_tbl <- pdf_link_list |>
  list_rbind() |>
  rename(link = value) |>
  # drop duplicates if they exist
  distinct(link, .keep_all = TRUE) |>
  # Get the file name
  mutate(
    file_name = sub(".*\\/([^\\/]+)$", "\\1", link) |>
      str_replace_all("%20","_") |>
      str_replace_all(",","") |>
      str_replace_all("[-]","_") |>
      toupper()
  )

# Update the folder names
pdf_link_tbl <- pdf_link_tbl |>
  mutate(folder = ifelse(grepl("\\.PDF$", folder, ignore.case = TRUE), 
                         "PROVIDER", folder)) |>
  mutate(folder_path = paste0(base_folder, folder))

# Download all pdfs from the links to the appropriate folder inside of the 
# base download folder
base_folder <- "W:/PATACCT/BusinessOfc/Revenue Cycle Analyst/Payer_Policies/Emblem_PDFs/"

# Create the base download folder if it doesn't exist
if (!dir.exists(base_folder)) {
  dir.create(base_folder, recursive = TRUE)
}

# Create the download folder if it does not exist from the pdf_link_tbl
# The folder should be paste0(base_folder, folder) use the fs library to create
# the folders. If the folder name contains .PDF then rename the folder to PROVIDER
# and create the folder inside the base_folder
# Create the folders

# Get list of folders paths to create
folder_paths <- pdf_link_tbl |>
  select(folder_path) |>
  distinct() |>
  pull(folder_path)
# Create the folders
for (folder_path in folder_paths) {
  # Create the folder if it doesn't exist
  if (!dir.exists(folder_path)) {
    dir.create(folder_path, recursive = TRUE)
  }
}

# Download the pdfs to the appropriate folder, use a for loop
for (i in 1:nrow(pdf_link_tbl)) {
  # Get the link and file name
  link <- pdf_link_tbl$link[i]
  file_name <- pdf_link_tbl$file_name[i]
  folder_path <- pdf_link_tbl$folder_path[i]
  
  # Create the full file path
  file_path <- paste0(folder_path, "/", file_name)
  
  # Download the PDF if it doesn't already exist
  # use try catch to handle errors if a file is not found
  # Check if the file already exists
  if (!file.exists(file_path)) {
    # Print the file path for debugging
    cat("Downloading: ", file_path, "\n", sep = "")
    
    # Try to download the file
    tryCatch({
      download.file(link, file_path, mode = "wb")
    }, error = function(e) {
      # Print an error message if the download fails
      cat("Error downloading: ", file_path, "\n", e$message, "\n", sep = "")
    })
  } else {
    # Print a message if the file already exists
    cat("File already exists: ", file_path, "\n", sep = "")
  }
}

# Get the list of all files in the base folder
# and its subfolders
# Use fs::dir_ls to get the list of files
all_files <- dir_ls(base_folder, recurse = TRUE, type = "file")
folders <- dir_ls(base_folder, type = "directory")

file_count_by_folder_tbl <- all_files |>
  as_tibble() |>
  mutate(
    file_name = basename(value),
    folder = dirname(value) |>
      str_replace_all(base_folder, "") |>
      str_replace_all("/", "") |>
      str_replace_all("\\\\", "")
  ) |>
  select(folder, file_name) |>
  group_by(folder) |>
  summarize(file_count = n()) |>
  ungroup() |>
  arrange(desc(file_count))

# How many files were downloaded
inform(
  message = paste0(
    "Files downloaded successfully to: ", base_folder, "\n\n",
    
    "Total files downloaded: ", nrow(file_name_tbl), "\n\n",
    
    "Files by folder:\n",
    paste0(
      file_count_by_folder_tbl$folder, ": ", file_count_by_folder_tbl$file_count,
      collapse = "\n"
  )
))
