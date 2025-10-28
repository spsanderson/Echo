# Load Libraries
library(fs)
library(tidyverse)
library(glue)
library(blastula)
library(RDCOMClient)

# Get all files from all subdirectories from the parent directory
parent_directory <- "W:/PATACCT/BusinessOfc/Revenue Cycle Analyst/Payer_Policies"
all_files <- dir_ls(parent_directory, recurse = TRUE, type = "file")
folders <- dir_ls(parent_directory, type = "directory")

# Email to send to
anthem_address <- "6b63fc6c-91e8-4412-88ce-2a928c1b2fdb@email.dotadda.io"
uhc_address <- "4cd241c7-5619-4b4f-a2fe-971cfd00f586@email.dotadda.io"
emblem_address <- "66d8d49f-d5d3-435e-9de0-e97d3b38193e@email.dotadda.io"
cigna_address <- "04194f37-df4e-4450-9bc1-7519aa64d53d@email.dotadda.io"

# Make a tibble of all_files
all_files_tbl <- as_tibble(all_files)
all_files_tbl <- all_files_tbl |>
  mutate(
    file_name = path_file(all_files),
    ins_name = map(all_files_tbl$value, \(x) {
      x |>
        strsplit(split = "/") |>
        pluck(1) |>
        pluck(6)
    }) |>
      unlist(),
    file_extension = path_ext(all_files),
    file_size = file_size(all_files),
    file_date = file_info(all_files)$modification_time,
    email_body = md(glue(
      "
        ## Payer Policy Files
        
        Please see attached file {file_name}, from {ins_name} with the file extension {file_extension} and size {file_size} bytes.
        
        The file attached is a payer policy.
        
        Thank you,
        
        The Patient Financial Services Team
        "
    ))
  )
all_files_tbl <- all_files_tbl |>
  group_by(file_name) |>
  mutate(rn = row_number()) |>
  ungroup() |>
  filter(rn == 1)

# Compose Email ----
# Open Outlook
# purr the emails out to DoTadda Dots
walk(
  .x = all_files_tbl$email_body,
  ~ {
    Outlook <- COMCreate("Outlook.Application")
    Email <- Outlook$CreateItem(0)
    Email[["subject"]] <- "Payer Policy Files"
    Email[["body"]] <- .x
    attachment <- str_replace_all(
      all_files_tbl$value[all_files_tbl$email_body == .x],
      "/",
      "\\\\"
    )
    Email[["body"]] <- .x
    Email[["to"]] <- # make a switch statement to send to either address
      if (str_detect(attachment, "Anthem")) {
        anthem_address
      } else if (str_detect(attachment, "UHC")) {
        uhc_address
      } else if (str_detect(attachment, "Emblem")) {
        emblem_address
      } else {
        stop("No email address found")
      }
    Email[["attachments"]]$Add(attachment)
    Email$Send()
    rm(Outlook)
    rm(Email)
    Sys.sleep(5)
  }
)
