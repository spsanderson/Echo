# Load the rvest package (install if needed using install.packages("rvest"))
library(rvest)
library(tidyverse)
library(rlang)

# Define the target URL
base_url <- "https://www.uhcprovider.com"
# The url that has the links to the pdfs
url <- "https://www.uhcprovider.com/en/policies-protocols/protocols.html"

# Read the HTML content from the page
page <- read_html(url)

# Use html_node() to select the first matching element with the provided XPath
node <- html_node(page, xpath = "/html/body/div/div/div/div[6]/div/div[2]/div/div/ul")
link_tbl <- node |> 
  html_elements("li") |>
  html_elements("a") |>
  html_attr("href") |>
  as_tibble() |>
  rename(link = value) |>
  mutate(
    base_url = base_url,
    link_url = url,
    full_url = paste0(base_url, link),
    file_name = gsub("[- ]", "_", toupper(basename(link)))
  ) |>
  select(base_url, link, full_url, file_name)

# Download each file into a specified directory
f_path <- "W:/PATACCT/BusinessOfc/Revenue Cycle Analyst/Payer_Policies/UHCPDFs/Medicare_Advantage/Protocols/"

# Create the directory if it doesn't exist
if (!dir.exists(f_path)) {
  dir.create(f_path, recursive = TRUE)
}

# Download the files
walk2(
  .x = link_tbl$full_url, 
  .y = basename(link_tbl$link), 
  .f = ~ {
    download.file(.x, destfile = file.path(f_path, .y), mode = "wb")
    Sys.sleep(3) # Pause for 3 seconds between downloads
  }
)

# Print the file names of the downloaded files
inform(
  message = paste0(
    "Files downloaded successfully to: ", f_path, "\n\n",
  
    "Total files downloaded: ", length(list.files(f_path)), "\n\n",
  
    "File names:\n", paste0(
    1:length(list.files(f_path)),
    ": ",
    list.files(f_path),
    collapse = "\n")
    )
)
