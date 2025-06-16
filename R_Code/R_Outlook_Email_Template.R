library(RDCOMClient)
library(readxl)

# Compose Email ----
# Open Outlook
Outlook <- COMCreate("Outlook.Application")

# File
email_file_path <- "The//path//to//your//file.xlsx"

# Create Email
Email = Outlook$CreateItem(0)

# Set the recipeitn, subject, and body
Email[["to"]] = ""
Email[["cc"]] = ""
Email[["bcc"]] = ""
Email[["subject"]] = ""
Email[["body"]] = "
Place the body of your text and signature here
"
Email[["attachments"]]$Add(email_file_path)

# Send the email
Email$Send()

# Clost Outlook, clear the message
rm(list = ls())
