
# Source Files ------------------------------------------------------------


source("W:\\PATACCT\\BusinessOfc\\Revenue Cycle Analyst\\R_Code\\DSS_Connection_Functions.r")
source("W:\\PATACCT\\BusinessOfc\\Revenue Cycle Analyst\\R_Code\\simple_model_eval_script.R")

# Library Load ------------------------------------------------------------


library(tidyverse)
library(DBI)
library(odbc)
library(forecast)
library(modeltime)
library(tidymodels)
library(timetk)

# SMS Connection ----------------------------------------------------------

## DB Connect ----

db_con_obj <- db_connect()

## Query -------------------------------------------------------------------


query <- dbGetQuery(db_con_obj, "
                    with ts as (
                    	select *
                    	from sms.dbo.C_TIME_SERIES_TRAIN_DATA_TBL
                    	union all
                    	select *
                    	from sms.dbo.C_TIME_SERIES_TEST_DATA_TBL
                    )
                    
                    select [dsch_yr_mo] = cast(a.[ADMIT DATE] as date),
                    	[pmt] = a.[PAYMENT 30-60 DAYS]
                    from ts as a
                    where a.[PAYMENT 30-60 DAYS] is not null
                    and a.[TOTAL CHARGES] > 100
                    and a.Expected_Payment > 0
                    and a.[ADMIT DATE] is not null
                    --group by eomonth(cast(a.[DISCHARGE DATE] as date))
                    order by cast(a.[ADMIT DATE] as date)
                    ")

## Disconnect ----

db_disconnect(db_con_obj)

# Make sure no time gaps ------------------------------------------

agg_date_type <- "week"

query_tbl <- as_tibble(query) |>
  set_names(c("date_col", "value")) |>
  mutate(date_col = as.Date(date_col)) |>
  # Data is really only useful from here on.
  filter_by_time(.date_var = date_col, .start_date = "2014-01-01") |>
  # Lowest aggregate we will use is week
  summarize_by_time(.date_var = date_col, .by = agg_date_type, 
                    value = sum(value)/7) |>
  pad_by_time(.date_var = date_col, .by = agg_date_type, .pad_value = 0) |>
  # impute 0 values for smoothness
  mutate(value = ifelse(value == 0, NA_real_, value)) |>
  mutate(value = ts_impute_vec(value, period = 4, lambda = "auto"))

query_tbl <- query_tbl |>
  filter(date_col <= Sys.Date() - 60)

# Intial Viz of data ------------------------------------------------------

## Time Series Plot ----

query_tbl |>
  plot_time_series(
    .date_var = date_col,
    .value = value
  )

query_tbl |>
  plot_time_series(
    date_col, log1p(value)
  )

## ACF Plots ----

query_tbl |> 
  plot_acf_diagnostics(date_col, log1p(value), .lags = 26)

## Seasonality Plots ----

query_tbl |> 
  plot_seasonal_diagnostics(date_col, log1p(value),
                            .feature = c("year","month.lbl","week"))

## Anomalies ----

query_tbl |>
  plot_anomaly_diagnostics(
    date_col, log1p(value)
  )

## STL Diagnostics ----

query_tbl |>
  plot_stl_diagnostics(
    date_col, log1p(value)
  )

## Time Series Regression Plot ----

query_tbl |>
  plot_time_series_regression(
    .date_var = date_col,
    .formula = (value) ~ as.numeric(date_col) 
    + month(date_col, label = TRUE)
    + week(date_col) |> as.factor()
    + fourier_vec(date_col, period = 52, K = 2) 
    , .show_summary = TRUE
  )

query_tbl |>
  plot_time_series_regression(
    .date_var = date_col,
    .formula = log1p(value) ~ as.numeric(date_col) 
    + month(date_col, label = TRUE)
    + fourier_vec(date_col, period = 52, K = 2)
    , .show_summary = TRUE
  )

# Transformations ---------------------------------------------------------

## Variance Reduction -----

query_tbl |>
  plot_time_series(
    date_col,
    box_cox_vec(value + 1, lambda = "auto")
  )

query_tbl |>
  plot_time_series_regression(
    date_col,
    .formula = box_cox_vec(value + 1, lambda = "auto") ~ as.numeric(date_col)
    + month(date_col, label = TRUE)
    + fourier_vec(date_col, period = 52, K = 2),
    .show_summary = TRUE
  )

## Rolling and Smoothing ----

query_tbl |>
  mutate(value_roll = slidify_vec(
    .x = value,
    .f = mean,
    .period = 4,
    .align = "center",
    .partial = TRUE
  )) |>
  pivot_longer(cols = -date_col) |>
  group_by(name) |>
  plot_time_series(
    date_col,
    value,
    .color_var = name,
    .smooth = FALSE
  )

rolling_cor_12 <- slidify(
  .f = ~ cor(.x, .y, use = "pairwise.complete.obs"),
  .period = 4,
  .align = "center",
  .partial = TRUE
)

query_tbl |>
  mutate(value_roll = slidify_vec(
    .x = value,
    .f = mean,
    .period = 12,
    .align = "center",
    .partial = TRUE
  )) |>
  mutate(rolling_cor = rolling_cor_12(value, value_roll)) |>
  pivot_longer(cols = -date_col) |>
  group_by(name) |>
  plot_time_series(
    date_col,
    value,
    .color_var = name,
    .smooth = FALSE
  )

### Problem with MA Forecasting ----

query_tbl |>
  mutate(
    ma_12 = slidify_vec(
      .x = value,
      .f = mean,
      .period = 3,
      .align = "center",
      .partial = TRUE
    )
  ) %>%
  bind_rows(
    future_frame(., .length_out = 12)
  ) |>
  fill(ma_12, .direction = "down") |>
  pivot_longer(cols = -date_col) |>
  plot_time_series(
    .date_var = date_col,
    .value = value,
    .color_var = name,
    .smooth = FALSE
  )

## Outlier Cleaning ----

query_tbl |> 
  mutate(val_clean = ts_clean_vec(value, period = 3, lambda = "auto")) |> 
  pivot_longer(-date_col) |> 
  plot_time_series(date_col, value, .color_var = name, .smooth = FALSE)

query_tbl |>
  mutate(value = ts_clean_vec(value, period = 3, lambda = "auto")) |>
  plot_time_series_regression(
    date_col,
    .formula = value ~ as.numeric(date_col) 
    + month(date_col, label = TRUE)
    + fourier_vec(date_col, period = 52, K = 2),
    .show_summary = TRUE
  )

## Lags and Differencing ----

query_tbl |>
  tk_augment_lags(
    .value = value,
    .lags = c(1, 2, 17)
  ) |>
  #drop_na() |>
  plot_time_series_regression(
    date_col,
    .formula = value ~ as.numeric(date_col) 
    + month(date_col, label = TRUE)
    + fourier_vec(date_col, period = 52, K = 2)
    + value_lag1
    + value_lag2
    + value_lag17
    ,.show_summary = TRUE
  )

## Cumulative Sum and Differencing ----

query_tbl |>
  mutate(value= cumsum(value)) |>
  mutate(value_diff_1 = diff_vec(value, lag = 1)) |>
  mutate(value_diff_2 = diff_vec(value, lag = 2)) |>
  pivot_longer(cols = -date_col) |>
  group_by(name) |>
  plot_time_series(
    date_col,
    .value = value, 
    .color_var = name,
    .smooth = FALSE
  )

# Model of Data ----

## Forecast Horizon ----

h <- 12
lag_vec <- tail(query_tbl[["value"]], h + 4)

## Base Linear Model ----
base_lag4_lm <- lm(value ~ lag(value, 1) + lag(value, 2) + lag(value, 4), 
                   data = query_tbl)
base_lag1_lm <- lm(value ~ lag(value, 1), data = query_tbl)

## Predictions ----
lag1_preds <- predict(
  base_lag1_lm,
  newdata = data.frame(value = lag_vec),
  interval = "prediction"
) |>
  as_tibble() |>
  slice(1:h)
#lag1_preds <- lag1_preds[!is.na(lag1_preds)][1:h]

lag4_preds <- predict(
  base_lag4_lm,
  newdata = data.frame(value = lag_vec),
  interval = "prediction"
) |>
  as_tibble() |>
  slice(1:h)
#lag4_preds <- lag4_preds[!is.na(lag4_preds)][1:h]

## Bind Data Together ----
future_tbl <- query_tbl |>
  future_frame(
    .date_var = date_col,
    .length_out = h,
    .bind_data = FALSE
  )
lag1_fcst <- bind_cols(future_tbl, lag1_preds) |>
  mutate(type = "Lag 1 Forecast") |>
  rename(value = fit) |>
  drop_na()

lag4_fcst <- bind_cols(future_tbl, lag4_preds) |>
  mutate(type = "Lag 4 Forecast") |>
  rename(value = fit) |>
  drop_na()

## Recursive Forecasting ----
query_tbl_extended <- query_tbl |>
  future_frame(
    .date_var = date_col,
    .length_out = h,
    .bind_data = TRUE
  )

# Lag transformer
lag_transformer <- function(.data) {
  .data |>
    tk_augment_lags(value, .lags = 1:h)
}

# Data Prep
query_lagged <- query_tbl_extended |>
  lag_transformer()

train_data <- drop_na(query_lagged)
future_data <- query_lagged |>
  filter(is.na(value))

# Model
model_fit_recursive_lag_lm <- linear_reg() |>
  set_engine("lm") |>
  fit(value ~ ., data = train_data, interval = "prediction") |>
  recursive(
    transform = lag_transformer,
    train_tail = tail(train_data, h)
  )

## Model Inspection ----

me_recursive <- model_evaluation(model_fit_recursive_lag_lm)
me_lag1 <- model_evaluation(base_lag1_lm)
me_lag4 <- model_evaluation(base_lag4_lm)

bind_rows(
  me_recursive$performance,
  me_lag1$performance,
  me_lag4$performance
) |>
  mutate(
    model = c("Recursive Lag Model", "Lag 1 Model", "Lag 4 Model")
  ) |>
  select(model, everything()) |>
  arrange(desc(R2))

me_recursive$check_model
me_lag1$check_model
me_lag4$check_model

output_tbl <- query_tbl |>
  mutate(type = "Actual") |>
  bind_rows(lag1_fcst, lag4_fcst)

output_tbl |>
  # Return to original scale
  mutate(value = value * 7) |>
  mutate(lwr = lwr * 7, upr = upr * 7) |> 
  plot_time_series(
    .date_var = date_col,
    .value = value,
    .title = "BCBS Outpatient Non-Unitized 30-60 Day Cash Forecast Post Discharge",
    .smooth = FALSE,
    .color_var = type
  )

# Predictions Outputs ----

## Get Modeltime Forecast ----
recursive_fcst <- modeltime_table(model_fit_recursive_lag_lm) |>
  modeltime_forecast(
    new_data = future_data,
    actual_data = query_tbl,
    conf_interval = 0.95
  ) |>
  select(.index, .value, .model_desc) |>
  set_names(c("date_col", "value", "type")) |>
  mutate(type = "Recursive LM Forecast") |>
  filter(date_col %in% future_data[["date_col"]])

output_tbl <- query_tbl |>
  mutate(type = "ACTUAL") |>
  bind_rows(lag1_fcst, lag4_fcst, recursive_fcst)

output_tbl |>
  # Return to original scale
  mutate(value = value * 7) |>
  plot_time_series(
    .date_var = date_col,
    .value = value,
    .title = "BCBS Outpatient Non-Unitized 30-60 Day Cash Forecast Post Discharge",
    .smooth = FALSE,
    .color_var = type
  )

output_tbl |>
  # Return to original scale
  mutate(
    value = value * 7,
    lwr = lwr * 7,
    upr = upr * 7
  ) |>
  # Last 52 weeks actual and forecast data
  filter(date_col > subtract_time(output_tbl[["date_col"]], "64 weeks") |> tail(1)) |>
  # Plot
  plot_time_series(
    date_col,
    value,
    .color_var = type,
    .smooth = FALSE,
    .interactive = FALSE
  ) +
  geom_line(aes(y = lwr, group = type, color = type), linetype = "dashed") +
  geom_line(aes(y = upr, group = type, color = type), linetype = "dashed") +
  scale_y_continuous(
    labels = scales::dollar_format(scale = 1e-3)
  ) +
  labs(
    title = "BCBS Outpatient Non-Unitized 30-60 Day Cash Forecast Post Discharge",
    caption = "Forecasted values are based on a linear model with lags of 1 and 4",
    subtitle = paste0(
      "Forecast Horizon ", h, " weeks - with prediction intervals.\n",
      paste(c("Lag 1 Predictions", scales::dollar(round(lag1_preds$fit), scale = 1e-3)), collapse = " | "), "\n",
      paste(c("Lag 4 Predictions", scales::dollar(round(lag4_preds$fit), sacle = 1e-3)), collapse = " | "), "\n",
      paste(c("Recursive Predictions", scales::dollar(round(recursive_fcst$value), scale = 1e-3)), collapse = " | ")
    ),
    y = "Dollars in Thousands",
    x = "Date"
  )

# Stop ----