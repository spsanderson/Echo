# Payer Policy Helper Functions

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

row_to_md <- function(row) {
  # Convert fs::bytes to character
  file_size_str <- as.character(row$file_size)
  # Convert dttm to date string
  file_date_str <- as.character(row$file_date)
  # Convert other columns to character
  llm_resp_str <- as.character(row$llm_resp)
  email_body_str <- as.character(row$email_body)

  md <- paste0(
    '**File Path:** "',
    row$file_path,
    '"\n\n',
    '**File Name:** "',
    row$file_name,
    '"\n\n',
    '**File Extension:** "',
    row$file_extension,
    '\n\n',
    '**File Size:** ',
    file_size_str,
    '\n\n',
    '**File Date:** ',
    file_date_str,
    '\n\n',
    '**LLM Response:** "',
    llm_resp_str,
    '"\n\n'
    #'**Email Body:** "', email_body_str, '"\n\n'
  )
  return(md)
}
