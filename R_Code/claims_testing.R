# Library Load ----

library(readxl)
library(dplyr)
library(writexl)

# Set seed ----
set.seed(20260715)

# Parameters ----
target_sample_size <- 3000L

# Allocation Function ----
allocate_weighted_sample <- function(
  group_tbl,
  target_n = 3000L
) {
  group_tbl <- group_tbl |>
    mutate(
      weight = discharge_percent
    )

  number_of_groups <- nrow(group_tbl)
  available_records <- sum(group_tbl$available_n)

  # Feasibility checks
  if (target_n < number_of_groups) {
    stop(
      paste0(
        "The target sample size is ",
        target_n,
        ", but there are ",
        number_of_groups,
        " groups. At least ",
        number_of_groups,
        " records are needed to sample every group."
      )
    )
  }

  if (target_n > available_records) {
    stop(
      paste0(
        "The target sample size exceeds the ",
        available_records,
        " available records."
      )
    )
  }

  if (any(is.na(group_tbl$weight))) {
    stop("At least one group does not have a discharge weight.")
  }

  if (any(group_tbl$weight < 0)) {
    stop("Discharge weights cannot be negative.")
  }

  if (all(group_tbl$weight == 0)) {
    stop("At least one group must have a positive discharge weight.")
  }

  # If there is exactly one slot per group, the answer is simple
  if (target_n == number_of_groups) {
    return(
      group_tbl |>
        mutate(
          ideal_sample_n = 1,
          sample_n = 1L
        )
    )
  }

  # Constrained allocation:
  # minimum = 1
  # maximum = number of available records
  allocation_total <- function(multiplier) {
    sum(
      pmin(
        group_tbl$available_n,
        pmax(1, multiplier * group_tbl$weight)
      )
    )
  }

  # Find an upper bound for the allocation multiplier
  lower_multiplier <- 0
  upper_multiplier <- 1

  while (allocation_total(upper_multiplier) < target_n) {
    upper_multiplier <- upper_multiplier * 2
  }

  # Binary search for the multiplier producing the target total
  for (iteration in seq_len(200)) {
    middle_multiplier <-
      (lower_multiplier + upper_multiplier) / 2

    if (allocation_total(middle_multiplier) < target_n) {
      lower_multiplier <- middle_multiplier
    } else {
      upper_multiplier <- middle_multiplier
    }
  }

  final_multiplier <-
    (lower_multiplier + upper_multiplier) / 2

  allocation_tbl <- group_tbl |>
    mutate(
      ideal_sample_n = pmin(
        available_n,
        pmax(1, final_multiplier * weight)
      ),
      sample_n = floor(ideal_sample_n),
      decimal_remainder = ideal_sample_n - sample_n
    )

  # Flooring may leave some unassigned slots
  slots_remaining <-
    target_n - sum(allocation_tbl$sample_n)

  if (slots_remaining > 0) {
    rows_to_increment <- allocation_tbl |>
      filter(sample_n < available_n) |>
      arrange(
        desc(decimal_remainder),
        desc(weight),
        group_key
      ) |>
      slice_head(n = slots_remaining) |>
      pull(group_key)

    allocation_tbl <- allocation_tbl |>
      mutate(
        sample_n = sample_n +
          as.integer(group_key %in% rows_to_increment)
      )
  }

  allocation_tbl |>
    select(
      group_key,
      available_n,
      discharge_percent,
      ideal_sample_n,
      sample_n
    )
}

# Data Load ----
# Claim Level data: one row per claim/encounter
claims_tbl <- read_excel(
  path = "case_mix_selection_data_06262026.xlsx",
  sheet = "Case_Mix_Selection_Data_6262026"
) |>
  rename("group_key" = "UNIQUE_CLAIM_TYPE_IND")

# Group-level weights from the weights workbook
sample_weights_tbl <- read_excel(
  path = "claims_testing_sample_weights.xlsx"
) |>
  transmute(
    group_key,
    discharge_percent
  )

# Before sampling, confirm that each group appears only once in the weights
duplicate_weights <- sample_weights_tbl |>
  count(group_key) |>
  filter(n > 1)

if (nrow(duplicate_weights) > 0) {
  stop("One or more group keys appear more than once int he weights table.")
} else {
  print("No duplicate group keys found. Good to go.")
}

group_counts_tbl <- claims_tbl |>
  count(
    group_key,
    name = "available_n"
  ) |>
  left_join(
    sample_weights_tbl,
    by = "group_key"
  ) |>
  # If sample weights are NA then defaul to 0
  mutate(
    discharge_percent = if_else(
      is.na(discharge_percent),
      0,
      discharge_percent
    )
  )

allocation_tbl <- allocate_weighted_sample(
  group_tbl = group_counts_tbl,
  target_n = target_sample_size
)

# Let's do some samplin
claims_sampled_tbl <- claims_tbl |>
  mutate(
    original_row_number = row_number(),
    random_value = runif(n())
  ) |>
  left_join(
    allocation_tbl,
    by = "group_key"
  ) |>
  group_by(group_key) |>
  arrange(
    random_value,
    .by_group = TRUE
  ) |>
  mutate(
    sample_status = if_else(
      row_number() <= first(sample_n),
      "sampled",
      "not_sampled"
    )
  ) |>
  ungroup() |>
  arrange(original_row_number) |>
  select(
    -original_row_number,
    -random_value
  )

# Get only the sample accounts
sample_only_tbl <- claims_sampled_tbl |>
  filter(sample_status == "sampled")

# Quality control...just kidding I don't do that
sampling_validation_tbl <- claims_sampled_tbl |>
  group_by(
    group_key,
    available_n,
    discharge_percent,
    ideal_sample_n,
    sample_n
  ) |>
  summarise(
    actual_sampled_n = sum(sample_status == "sampled"),
    .groups = "drop"
  ) |>
  mutate(
    allocation_matches = sample_n == actual_sampled_n,
    group_has_sample = actual_sampled_n >= 1
  )

sampling_validation_tbl |>
  summarise(
    groups_present = n(),
    total_allocated = sum(sample_n),
    total_sampled = sum(actual_sampled_n),
    groups_without_sample = sum(!group_has_sample),
    allocation_errors = sum(!allocation_matches)
  )

# Export it all
write_xlsx(
  list(
    all_reords_with_indicator = claims_sampled_tbl,
    sample_records = sample_only_tbl,
    sampling_validation = sampling_validation_tbl
  ),
  path = "claims_testing_sample.xlsx"
)
