# Library Load ----

library(fs)
library(tidyverse)
library(ragnar)
library(ellmer)
library(glue)
library(blastula)
library(RDCOMClient)
library(rlang)
library(tictoc)
library(reticulate)

# Source Files ----

## Helper Functions
source(file = "helper_functions/payer_policy_helpers.r")

# Path of Policies ----

#base_path <- "W:/PATACCT/BusinessOfc/Revenue Cycle Analyst/Payer_Policies/"
base_path <- paste0(getwd())
pdf_base_paths <- dir_ls(base_path, regexp = "\\PDFs$")
pdf_base_paths

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

## Get payer name ----
all_files_tbl <- all_files_tbl |>
  distinct() |>
  rowwise() |>
  mutate(
    payer_name = extract_payer_name(full_file_path)
  ) |>
  ungroup()

## Add Other Payer Information column ----
all_files_tbl <- all_files_tbl |>
  rowwise() |>
  mutate(
    other_payer_information = extract_dirs_between_pdfs_and_file(full_file_path)
  ) |>
  ungroup()

## Separate other_payer_information column ----
all_files_tbl <- all_files_tbl |>
  separate_wider_delim(
    other_payer_information,
    delim = ",",
    names = c("payer_product", "payer_policy_group"),
    too_many = "merge",
    too_few = "align_start"
  )

# Get smaller files
all_files_tbl <- all_files_tbl |>
  filter(file_size < 1055440)

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

# LLM Response ----
## First Split tbl ----
file_split_tbl <- group_split(all_files_tbl, full_file_path)

# RAG Storeage Name
store_location <- "pdf_ragnar_duckdb"

## Map over the files and insert into storage ----
## We have already summarized and pushed Anthem
## So filter them out
output_list <- vector("list", length = length(file_split_tbl))
names(output_list) <- all_files_tbl$file_name

for (i in seq_along(file_split_tbl)) {
  if (i < 26) {
    next
  }
  # Progress
  message(
    "Working on file number: ",
    i,
    " of ",
    length(file_split_tbl),
    " file(s). \n"
  )
  obj <- file_split_tbl[[i]]
  file_path <- obj |> pull(2) |> pluck(1)
  message("Working on file: ", file_path, "\n")

  # Storage ----
  embedding_model <- "nomic-embed-text:latest" #"qllama/bge-large-en-v1.5:q4_k_m"
  message("Using embedding model: ", embedding_model)
  tic()
  store <- ragnar_store_create(
    store_location,
    embed = \(x) embed_ollama(x, model = embedding_model),
    overwrite = TRUE
  )
  toc()
  message("Created store \n")

  # Chunking
  message("Chunking file")
  tic()
  chunks <- file_path |>
    read_as_markdown() |>
    markdown_chunk()
  toc()
  message(
    "Chunked file. Start: ",
    min(chunks$start),
    " End: ",
    max(chunks$end),
    " Rows: ",
    nrow(chunks),
    "\n"
  )

  # Insert into storage
  message("Inserting into storage")
  tic()
  ragnar_store_insert(store, chunks)
  toc()
  message("Inserted into storage \n")

  # Build index
  message("Building index")
  tic()
  ragnar_store_build_index(store)
  toc()
  message("Built index \n")

  # Chat Client
  #"qwen3-vl:235b-cloud"
  chat_model = "llama3.2" #"qwen3:0.6b" #"qwen3-vl:235b-cloud"
  message("Creating chat client with model: ", chat_model)
  tic()
  client <- chat_ollama(
    model = chat_model,
    system_prompt = system_prompt,
    params = list(temperature = 0.1)
  )
  toc()
  message("Created chat client \n")

  # Set Tool
  message("Setting tool")
  tic()
  ragnar_register_tool_retrieve(
    chat = client,
    store = store
  )
  toc()
  message("Set tool \n")

  # Get response
  user_prompt <- glue("Please summarize this policy: {file_path}.")
  message("Getting response")
  tic()
  res <- client$chat(user_prompt, echo = "all")
  cat("\n")
  toc()
  message("Got response \n")

  # Add response to obj tibble
  message("Adding response to obj")
  rec <- obj |> mutate(llm_resp = res)
  message("Added response to obj \n")

  # Delete RAG Store
  message("Deleting RAG store via unlink().")
  unlink(paste0(getwd(), "/pdf_ragnar_duckdb"))
  unlink(paste0(getwd(), "/pdf_ragnar_duckdb.wal"))
  message("Files unlinked. \n")
  message("----\n")

  # Return tibble
  output_list[[i]] <- rec
}

# Email files to DoTadda Dots ----
## Emails ----
email_address_anthem <- "6b63fc6c-91e8-4412-88ce-2a928c1b2fdb@email.dotadda.io"
email_address_uhc <- "4cd241c7-5619-4b4f-a2fe-971cfd00f586@email.dotadda.io"
email_address_emblem <- "66d8d49f-d5d3-435e-9de0-e97d3b38193e@email.dotadda.io"
email_address_cigna <- "04194f37-df4e-4450-9bc1-7519aa64d53d@email.dotadda.io"

## Create Email Body ----
output_tbl <- list_rbind(llm_resp_list) |>
  mutate(
    email_body = md(glue(
      "
      Please see summary for below:

      Name: {file_name}

      Extension: {file_extension}
      
      Size: {file_size} bytes
      
      Date: {file_date}

      Payer Name: {payer_name}

      Payer Product: {payer_product}

      Payer Policy Group: {payer_policy_group}

      Summary Response: 

      {llm_resp}
      "
    ))
  )

# purr the emails out to whomever
walk(
  .x = output_tbl$email_body,
  ~ {
    payer_name = output_tbl$payer_name[output_tbl$email_body == .x]

    Outlook <- COMCreate("Outlook.Application")
    Email <- Outlook$CreateItem(0)
    Email[["subject"]] <- "Payer Policy Summary"
    Email[["htmlbody"]] <- markdown::markdownToHTML(.x)
    attachment <- str_replace_all(
      output_tbl$full_file_path[output_tbl$email_body == .x],
      "/",
      "\\\\"
    )
    Email[["to"]] <- if (payer_name == "Anthem") {
      email_address_anthem
    } else if (payer_name == "UHC") {
      email_address_uhc
    } else if (payer_name == "Emblem") {
      email_address_emblem
    } else if (payer_name == "Cigna") {
      email_address_cigna
    } else {
      stop("No email address found")
    }
    Email[["attachments"]]$Add(attachment)
    Email$Send()
    rm(Outlook)
    rm(Email)
    Sys.sleep(trunc(runif(1, 1, 3)))
  }
)
