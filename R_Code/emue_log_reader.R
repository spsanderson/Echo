library(tidyverse)

f_path <- ""
f <- read.table(f_path, header = FALSE, sep = "\n")
f <- as_tibble(f, .name_repair = "unique") |>
  setNames("text")

glimpse(f)

f <- f |>
  mutate(linenumber = row_number()) |>
  mutate(dnm = cumsum(str_detect(text, "does not match")))

max(f$dnm)
