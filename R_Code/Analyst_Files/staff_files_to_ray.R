# Libraries ----
library(tidyverse)
library(RDCOMClient)
library(rmarkdown)
library(tinytex)

# Directory ----
base_path <- "C:/Users/ssanders/Documents/GitHub/my_obsidian_vault/Work/Analyst_Team/"
input_dirs <- list.dirs(base_path)[-1L]
output_dir <- "C:/Users/ssanders/Documents/GitHub/my_obsidian_vault/Work/pdfs_for_ray/"
input_dir_tbl <- tibble(
  input_dir = input_dirs,
  output_dir = output_dir
)

# Delete files in output directory ----
files_to_delete <- list.files(
  path = output_dir,
  #pattern = "\\.docx$",
  pattern = "\\.pdf$"
  full.names = TRUE
)

if (length(files_to_delete) > 0) {
  cat("Deleting old .docx files...\n")
  file.remove(files_to_delete)
}

# Process the files
input_dir_tbl |>
  group_split(input_dir) |>
  # get the newest file for each input directory ----
  imap(
    .f = function(obj, .id) {
      input_dir = obj$input_dir

      # Check if the directory exists
      if (!dir.exists(input_dir)) {
        stop(paste0("Error: Directory", input_dir, "does not exist."))
      }

      # List all .md files in the directory ----
      cat("\n")
      cat("Searching for .md files in:", input_dir, "\n")
      md_files <- list.files(
        path = input_dir,
        pattern = "\\.md$",
        full.names = TRUE
      )

      # Check if any .md files were found
      if (length(md_files) == 0) {
        stop("No .md files found in the specified directory.")
      }

      cat("Found", length(md_files), ".md files:\n")
      for (file in md_files) {
        cat("-", basename(file), "\n")
      }

      # Read in the newest .md file
      cat("\n")
      newest_md <- md_files[which.max(file.info(md_files)$mtime)]
      cat("The newest file is:", newest_md, "\n")
      cat("With basename of:", basename(newest_md), "\n\n")

      # Render file to .pdf
      cat("Converting file to Word File.\n\n")

      docx_file <- sub("\\.md$", ".pdf", basename(newest_md))
      cat("New File: ", docx_file, "\n")
      pdf_output <- render(
        input = newest_md,
        output_format = "pdf_document",#"word_document",
        output_file = paste0(obj$output_dir, docx_file)
      )

      cat("Successfully converted to Word Document.")
      cat("\n")
    }
  )

# Email out files using RDCOMClient ----
output_files <- list.files(
  path = output_dir,
  pattern = "\\.docx$",
  full.names = TRUE
)

# The most Recent Monday from today
today <- Sys.Date()
last_monday <- today - wday(today, week_start = 1) + 1

# Filter out the output_files if the date is less thatn last_monday
date_pattern <- "\\d{4}-\\d{2}-\\d{2}"
extracted_dates <- as.Date(
  regmatches(output_files, regexpr(date_pattern, output_files)),
)

# Build logical index
keep_idx <- extracted_dates >= last_monday

# Apply the filter
filtered_paths <- output_files[keep_idx]

# Print results
cat("Extracted dates:\n")
print(data.frame(
  date = extracted_dates,
  kept = keep_idx,
  file = basename(output_files)
))

cat("\nFiltered file paths (date > last_monday):\n")
print(filtered_paths)

# Create email
Outlook <- COMCreate("Outlook.Application")
Email <- Outlook$CreateItem(0)

# Set the recipient, subject, and body
Email[["to"]] = "Raymond.Gross2@stonybrookmedicine.edu"
Email[["cc"]] = ""
Email[["bcc"]] = ""
Email[["subject"]] = "Weekly Staff Updates"
Email[["body"]] = "
Hi Ray,

Please see attached files which are the latest files I have from my 1:1 with staff.
"
for (file in filtered_paths) {
  Email[["attachments"]]$Add(normalizePath(file))
}

# Send email
Email$Send()
