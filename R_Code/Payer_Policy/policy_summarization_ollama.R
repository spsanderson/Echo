library(fs)
library(tidyverse)
library(ragnar)
library(ellmer)
library(glue)
library(blastula)
library(RDCOMClient)

base_path <- "W:/PATACCT/BusinessOfc/Revenue Cycle Analyst/Payer_Policies/"
pdf_base_paths <- dir_ls(base_path, regexp = "\\PDFs$")
pdf_base_paths

# Function to get payer name
extract_payer_name <- function(file_path) {
  # Split the path into directory parts (handles both / and \)
  path_parts <- unlist(strsplit(file_path, "[/\\\\]"))
  # Find the first directory that contains '_PDFs'
  payer_dir <- path_parts[grep("_PDFs$", path_parts)][1]
  # Remove '_PDFs' from the directory name
  payer_name <- sub("_PDFs$", "", payer_dir)
  return(payer_name)
}

# For each base path, list all files recursively and collect metadata
all_files_tbl <- map_dfr(pdf_base_paths, function(pdf_base_paths) {
  files <- dir_ls(pdf_base_paths, recurse = TRUE, type = "file")
  if (length(files) == 0) {
    return(NULL)
  } # skip if no files

  file_info <- file_info(files)
  tibble(
    file_base_path = base_path,
    full_file_path = file_info$path,
    file_name = path_file(file_info$path),
    file_base_name = path_ext_remove(fs::path_file(file_info$path)),
    file_extension = path_ext(file_info$path),
    file_size = file_info$size,
    file_date = file_info$modification_time
  )
})

all_files_tbl <- all_files_tbl |>
  distinct() |>
  rowwise() |>
  mutate(
    payer_name = extract_payer_name(full_file_path)
  )

# R function to extract directory names between *_PDFs directory and filename
extract_dirs_between_pdfs_and_file <- function(file_paths) {
  # Function to process a single path
  process_single_path <- function(path) {
    # Split the path into components using forward slash or backslash
    parts <- strsplit(path, "[/\\\\]")[[1]]

    # Find the index of directory ending with "_PDFs"
    pdfs_indices <- grep("_PDFs$", parts)

    # If no _PDFs directory found, return NA
    if (length(pdfs_indices) == 0) {
      return(NA)
    }

    # Use the last occurrence of _PDFs directory (in case there are multiple)
    pdfs_idx <- max(pdfs_indices)

    # Extract directories between _PDFs directory and filename
    # Exclude the _PDFs directory itself and the filename (last element)
    start_idx <- pdfs_idx + 1
    end_idx <- length(parts) - 1

    # If there are no directories between _PDFs and filename, return empty string
    if (start_idx > end_idx) {
      return(NA)
    }

    # Extract the relevant directories
    dirs_between <- parts[start_idx:end_idx]

    # Join with " | " separator
    return(paste(dirs_between, collapse = ","))
  }

  # Apply to all paths
  if (length(file_paths) == 1) {
    return(process_single_path(file_paths))
  } else {
    return(sapply(file_paths, process_single_path, USE.NAMES = FALSE))
  }
}

# Add Other Payer Information column
all_files_tbl <- all_files_tbl |>
  rowwise() |>
  mutate(
    other_payer_information = extract_dirs_between_pdfs_and_file(full_file_path)
  )

all_files_tbl <- all_files_tbl |>
  separate_wider_delim(
    other_payer_information,
    delim = ",",
    names = c("payer_product", "payer_policy_group"),
    too_many = "merge",
    too_few = "align_start"
  )

# LLM Summarization ----

## System Prompt
system_prompt <- str_squish(
  "
  You are an expert assistant that summarizes **Health Insurance Payer Policies** clearly and accurately for healthcare, billing, and administrative users.

  When responding, you should first quote relevant material from the documents in the store,
  provide links to the sources, and then add your own context and interpretation. Try to be as concise
  as you are thorough.

  For every document passed to you the output should if applicable include:

  1. Policy Summary: 1–2 paragraphs describing purpose, scope, and coverage intent.
  2. Key Points: At least 3 concise bullet points summarizing coverage criteria, limitations, exclusions, or authorization requirements.
  3. Policy Information Table

  **Model Behavior Rules:**

  * If information is missing, state “Not specified in document.”
  * Do not infer or assume; summarize only verifiable content.
  * Maintain neutral, factual tone using payer-standard language (e.g., “medically necessary,” “experimental/investigational”).
  * Simplify complex clinical text while preserving accuracy.
  * Always follow the structure: **Policy Summary → Key Points → Policy Information Table.**
  * Avoid opinion, speculation, or advice; ensure compliance-focused clarity.
  "
)

file_split_tbl <- group_split(all_files_tbl, full_file_path)
