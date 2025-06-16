
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
library(markovchain)
library(earth)
library(nnet)
library(parsnip)
library(modeltime.ensemble)
library(TidyDensity)
library(healthyR.ts)
library(plotly)
library(smooth)
library(healthyR)
library(NNS)

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
                    
                    select [date_col] = cast(a.[ADMIT DATE] as date),
                    	[value] = a.[PAYMENT 30 DAYS OR LESS]
                    from ts as a
                    where a.[PAYMENT 30 DAYS OR LESS] is not null
                    and a.[TOTAL CHARGES] > 100
                    and a.Expected_Payment > 0
                    and a.[ADMIT DATE] is not null
                    order by cast(a.[ADMIT DATE] as date)
                    ")

## Disconnect ----

db_disconnect(db_con_obj)

# Make sure no time gaps ------------------------------------------

# Keep only last 365*2 days of data
last_date <- max(ymd(query[["date_col"]]))
last_two_years <- last_date - years(5)

query <- query |>
  mutate(date_col = ymd(date_col)) |>
  # Data is really only useful from here on.
  filter_by_time(.date_var = date_col, .start_date = last_two_years) |>
  # Daily Sum
  summarize_by_time(
    .date_var = date_col, 
    .by = "day", 
    value = sum(value)
  ) |>
  # Pad time for missing days
  pad_by_time(
    .date_var = date_col, 
    .by = "day", 
    .pad_value = 0
  )

agg_date_type <- "day"

query_tbl <- query |>
  # Lowest aggregate we will use is week
  summarize_by_time(.date_var = date_col, .by = agg_date_type, 
                    value = sum(value)) |>
  pad_by_time(.date_var = date_col, .by = agg_date_type, .pad_value = 0) |>
  # impute 0 values for smoothness
  mutate(value = ifelse(value == 0, NA_real_, value)) |>
  mutate(value = ts_impute_vec(value, period = 4, lambda = "auto")) |>
  # Make sure we are at least 30 days back from today
  filter(date_col <= Sys.Date() - 30)

# Intial Viz of data ------------------------------------------------------

## Stat Plots ----

tidy_empirical(query_tbl[["value"]]) |> 
  tidy_autoplot() + 
  scale_y_continuous(labels = scales::number_format(scale = 1e3)) + 
  scale_x_continuous(labels = scales::dollar) +
  labs(title = "Empirical Distribution of Cash Flow",
       subtitle = "BCBS OP Non Unitized Accounts within 30 Days of Service",
       x = "Cash Flow",
       y = "Density Scaled 1e-3"
  )

tidy_bootstrap(query_tbl[["value"]]) |> 
  bootstrap_stat_plot(y, "cmean") + 
  scale_y_continuous(labels = scales::dollar)

tidy_bootstrap(query_tbl[["value"]]) |> 
  bootstrap_stat_plot(y, "csd") + 
  scale_y_continuous(labels = scales::dollar)

hist_bin_vec <- opt_bin(query_tbl, value, 100) |>
  pull()

query_tbl |>
  ggplot(aes(x = value)) +
  geom_histogram(
    breaks = hist_bin_vec, 
    fill = "skyblue", 
    color = "black",
    aes(y = after_stat(density))
  ) +
  geom_density(aes(x = value, y = after_stat(density))) +
  theme_minimal() +
  scale_x_continuous(labels = scales::dollar) +
  scale_y_continuous(labels = scales::number_format(scale = 1e3)) +
  labs(
    title = "Histogram of Cash Flow",
    subtitle = "BCBS OP Non Unitized Accounts within 30 Days of Service",
    x = "Cash Flow",
    y = "Frequency Scaled 1e-3",
    caption = paste0("Source: SMS Data as of: ", max(query_tbl$date_col))
  )

# Summarize the data

query_tbl |>
  summarize(
    obs = nrow(query_tbl),
    mean_val = NNS::NNS.moments(value)[["mean"]],
    median = median(value),
    range = max(value) - min(value),
    quantile_lo = quantile(value, 0.025),
    quantile_hi = quantile(value, 0.975),
    variance = NNS::NNS.moments(value)[["variance"]],
    sd = sd(value),
    min_val = min(value),
    max_val = max(value),
    harmonic_mean = length(value) / sum(1 / value),
    geometric_mean = exp(mean(log(value))),
    skewness = NNS::NNS.moments(value)[["skewness"]],
    kurtosis = NNS::NNS.moments(value)[["kurtosis"]]
  ) |>
  glimpse()

## Time Series Plot ----

query_tbl |>
  plot_time_series(
    .date_var = date_col,
    .value = value,
    .title = "Daily Cash Flow of BCBS OP Non Unitized Accounts within 30 Days of Service"
  )

query_tbl |>
  ts_time_event_analysis_tbl(
    .horizon = 4, 
    .date_col = date_col, 
    .value_col = value, 
    .direction = "forward", 
    .percent_change = -0.05
  ) |> 
  ts_event_analysis_plot(.plot_type = "individual")  +
  theme(legend.position = "none")

query_tbl |>
  ts_time_event_analysis_tbl(
    .horizon = 4, 
    .date_col = date_col, 
    .value_col = value, 
    .direction = "forward", 
    .percent_change = -0.05
  ) |> 
  ts_event_analysis_plot(.plot_type = "mean")

query_tbl |>
  ts_time_event_analysis_tbl(
    .horizon = 4, 
    .date_col = date_col, 
    .value_col = value, 
    .direction = "forward", 
    .percent_change = -0.05
  ) |> 
  ts_event_analysis_plot(.plot_type = "median")


## ACF Plots ----

query_tbl |> 
  plot_acf_diagnostics(date_col, value, .lags = 30)

## Lag Correlations ----

lag_output <- ts_lag_correlation(
  .data = query_tbl,
  .date_col = date_col,
  .value_col = value,
  .lags = c(7,14,21,28)
)

lp <- lag_output[["plots"]][["lag_plot"]] +
  scale_y_continuous(labels = scales::dollar) +
  scale_x_continuous(labels = scales::dollar) +
  geom_smooth(se = FALSE, method = "lm", color = "black",
              linetype = "dashed", formula = y ~ x) +
  labs(
    title = "Lag Correlation of Cash Flow by Day: BCBS OP Non Unitized Accounts",
    x = "Original Value",
    y = "Lagged Value"
  )
ggplotly(lp)

lag_output[["data"]][["correlation_lag_matrix"]] |>
  round(2)

hm <- lag_output[["plots"]][["correlation_heatmap"]] +
  labs(
    title = "Lag Correlation Heatmap of Cash Flow by Day: BCBS OP Non Unitized Accounts",
    x = "Lag",
    y = "Lag"
  )
ggplotly(hm)

## Seasonality Plots ----

query_tbl |> 
  plot_seasonal_diagnostics(date_col, value,
                            .feature = c("year","month.lbl","wday.lbl"))

chp <- query |>
  filter_by_time(
    .date_var = date_col
  ) |>
  ts_calendar_heatmap_plot(date_col, value, .interactive = FALSE) +
  labs(
    title = "Calendar Heatmap of Cash Flow by Week: BCBS OP Non Unitized Accounts",
    x = "Week",
    y = "Year",
    fill = "Cash Flow"
  )
ggplotly(chp)

query_tbl |>
  mutate(dow = wday(date_col, label = TRUE)) |>
  ggplot(aes(x = value)) +
  scale_x_continuous(labels = scales::dollar) +
  geom_histogram(breaks = opt_bin(query_tbl, value, 100) |> pull(),
                 aes(fill = factor(dow)), color = "black") +
  geom_vline(aes(xintercept = mean(value), group = dow), 
             color = "red", linetype = "dashed") +
  facet_wrap(~ dow, scales = "free") +
  theme_minimal() +
  labs(
    title = "Histogram of Cash Flow by Day of Week",,
    subtitle = "BCBS OP Non Unitized Accounts. Redline is the mean of all payments.",
    x = "Cash Flow",
    y = "Frequency",
    fill = "Day of Week"
  ) +
  theme(legend.position = "bottom")

## Anomalies ----

query_tbl |>
  plot_anomaly_diagnostics(
    date_col, value
  )

## STL Diagnostics ----

query_tbl |>
  plot_stl_diagnostics(
    date_col, value
  )

# Transformations ---------------------------------------------------------

## Lags and Differencing ----

query_tbl |>
  tk_augment_lags(
    .value = value,
    .lags = c(7,14,21,28)
  ) |>
  #drop_na() |>
  plot_time_series_regression(
    date_col,
    .formula = value ~ as.numeric(date_col) 
    + month(date_col, label = TRUE)
    #+ fourier_vec(date_col, period = 52, K = 2)
    + value_lag7
    + value_lag14
    + value_lag21
    + value_lag28
    ,.show_summary = TRUE
  )

## Cumulative Sum and Differencing ----

query_tbl |>
  mutate(value = cumsum(value)) |>
  tk_augment_differences(
    .value = value,
    .lags = c(1, 2)
  ) |>
  rename(velocity = contains("_lag1")) |>
  rename(acceleration = contains("_lag2")) |>
  pivot_longer(cols = -date_col) |>
  mutate(name = stringr::str_to_title(name)) |>
  mutate(name = forcats::as_factor(name)) |>
  group_by(name) |>
  plot_time_series(
    date_col,
    .value = value, 
    .color_var = name,
    .smooth = FALSE
  )
  
# Model of Data ----

## Forecast Horizon ----

h <- 30 * 2 # 2 months to also get the forecast of accounts not yet out of the 30 day window

## NNS Predictions ----
nns_predict <- NNS.ARMA.optim(
  query_tbl[["value"]], 
  h = h, 
  seasonal.factor = NNS.seas(query_tbl[["value"]])$periods, 
  obj.fn = expression(Metrics::rmse(actual, predicted)), 
  objective = "min", 
  print.trace = TRUE
)

future_nns_data <- future_frame(query_tbl, date_col, length(nns_predict$results)) |>
  bind_cols(
    value = nns_predict$results,
    type = "predicted",
    .ll_pred = nns_predict$lower.pred.int, 
    .up_pred = nns_predict$upper.pred.int
  )
head(future_nns_data)

full_nns_tbl <- query_tbl |> 
  mutate(type = ifelse(!is.na(value), "actual", "future"),
         .ll_pred = NA_real_,
         .up_pred = NA_real_) |>
  bind_rows(future_data)
head(full_nns_tbl)

full_nns_tbl |>
  ggplot(aes(x = date_col, y = value, color = type)) +
  geom_line() +
  theme_minimal()

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
    mutate(
      up = ifelse(value > lag(value), 1, 0)
    ) |>
    mutate(
      up_pct = cummean(ifelse(is.na(up), 0, up))
    ) |>
    tk_augment_lags(value, .lags = c(7,14,21,28,30)) |>
    tk_augment_lags(up_pct, .lags = 7) |>
    select(-c(up, up_pct))
}

# Data Prep
query_lagged <- query_tbl_extended |>
  lag_transformer()

train_data <- drop_na(query_lagged)
future_data <- query_lagged |>
  filter(is.na(value))

future_data

### Recursive Models ----


model_fit_recursive_lag_lm <- linear_reg() |>
  set_engine("lm") |>
  fit(value ~ ., data = train_data) |>
  recursive(
    transform = lag_transformer,
    train_tail = tail(train_data, h)
  )

model_fit_recursive_lag_earth <- mars(mode = "regression") |>
  set_engine("earth") |>
  fit(value ~ ., data = train_data) |>
  recursive(
    transform = lag_transformer,
    train_tail = tail(train_data, h)
  )

model_fit_recursive_lag_nnet <- nnetar_reg(
  mode = "regression",
  penalty = 0.5
) |>
  set_engine("nnetar") |>
  fit(value ~ ., data = train_data) |>
  recursive(
    transform = lag_transformer,
    train_tail = tail(train_data, h)
  )

model_fit_recursive_prophet_boost <- prophet_boost(
  mode = "regression",
  changepoint_num = round(nrow(train_data) / 52, 0),
  seasonality_yearly = "auto",
  seasonality_weekly = "auto",
  growth = "logistic",
  logistic_floor = 0,
  logistic_cap = 1e6
) |>
  set_engine("prophet_xgboost") |>
  fit(value ~ ., data = train_data) |>
  recursive(
    transform = lag_transformer,
    train_tail = tail(train_data, h)
  )

model_fit_recursive_arima_boost <- arima_boost(mode = "regression") |>
  set_engine("auto_arima_xgboost") |>
  fit(value ~ ., data = train_data) |>
  recursive(
    transform = lag_transformer,
    train_tail = tail(train_data, h)
  )

### Univariate Models ----

model_fit_exp_smooth_ets <- exp_smoothing() |>
  set_engine("ets") |>
  fit(value ~ ., data = train_data |>
        select(date_col, value))

model_fit_exp_smooth_croston <- exp_smoothing() |>
  set_engine("croston") |>
  fit(value ~ ., data = train_data |>
        select(date_col, value))

model_fit_exp_smooth_theta <- exp_smoothing() |>
  set_engine("theta") |>
  fit(value ~ ., data = train_data |>
        select(date_col, value))

model_fit_exp_smooth <- exp_smoothing() |>
  set_engine("smooth_es") |>
  fit(value ~ ., data = train_data |>
        select(date_col, value))

model_fit_sr_tbats <- seasonal_reg() |>
  set_engine("tbats") |>
  fit(value ~ ., data = train_data |>
        select(date_col, value))

model_fit_sr_stlm_ets <- seasonal_reg() |>
  set_engine("stlm_ets") |>
  fit(value ~ ., data = train_data |>
        select(date_col, value))

model_fit_sr_stlm_arima <- seasonal_reg() |>
  set_engine("stlm_arima") |>
  fit(value ~ ., data = train_data |>
        select(date_col, value))

## Model Inspection ----

models_tbl <- modeltime_table(
  model_fit_recursive_lag_lm,
  model_fit_recursive_lag_earth,
  model_fit_recursive_lag_nnet,
  model_fit_recursive_prophet_boost,
  model_fit_recursive_arima_boost,
  model_fit_sr_tbats,
  model_fit_sr_stlm_ets,
  model_fit_sr_stlm_arima,
  model_fit_exp_smooth_ets, # ETS(A,N,A)
  model_fit_exp_smooth_croston,
  model_fit_exp_smooth_theta,
  model_fit_exp_smooth # ETS(ANA)
)

calibration_tbl <- modeltime_calibrate(
  models_tbl,
  new_data = train_data
)

calibration_tbl |>
  mutate(
    group = case_when(
      str_detect(.model_desc, "RECURSIVE") ~ "Recursive",
      str_detect(.model_desc, "TBATS") ~ "Seasonal Reg",
      str_detect(.model_desc, "SEASONAL DECOMP:") ~ "Seasonal Reg",
      str_detect(.model_desc, "ETS") ~ "Exp Smoothing",
      str_detect(.model_desc, "CROSTON") ~ "Exp Smoothing",
      str_detect(.model_desc, "THETA") ~ "Exp Smoothing"
    )
  ) |>
  modeltime_residuals() |> 
  ggplot(aes(x = .residuals, fill = factor(.model_desc))) + 
  facet_wrap(group ~ .model_desc, scales = "free") + 
  scale_x_continuous(labels = scales::dollar) + 
  scale_y_continuous(labels = scales::number) + 
  geom_density(alpha = 0.2) + 
  theme_minimal() + 
  theme(legend.position = "bottom") + 
  labs(fill = "Model")

calibration_tbl |>
  mutate(
    group = case_when(
      str_detect(.model_desc, "RECURSIVE") ~ "Recursive",
      str_detect(.model_desc, "TBATS") ~ "Seasonal Reg",
      str_detect(.model_desc, "SEASONAL DECOMP:") ~ "Seasonal Reg",
      str_detect(.model_desc, "ETS") ~ "Exp Smoothing",
      str_detect(.model_desc, "CROSTON") ~ "Exp Smoothing",
      str_detect(.model_desc, "THETA") ~ "Exp Smoothing"
    )
  ) |>
  modeltime_residuals() |> 
  ggplot(aes(x = .residuals, fill = factor(.model_desc))) + 
  facet_wrap(~ group, scales = "free") + 
  scale_x_continuous(labels = scales::dollar) + 
  scale_y_continuous(labels = scales::number) + 
  geom_density(alpha = 0.2) + 
  theme_minimal() + 
  theme(legend.position = "bottom") + 
  labs(fill = "Model")

calibration_tbl |>
  ts_model_rank_tbl() |>
  select(-.type)

calibration_tbl |>
  modeltime_residuals() |>
  plot_modeltime_residuals()

ts_scedacity_scatter_plot(
  calibration_tbl |> filter(.type == "Fitted")
) +
  scale_y_continuous(labels = scales::dollar) +
  scale_x_continuous(labels = scales::dollar)

calibration_tbl |>
  filter(.type == "Fitted") |>
  modeltime_residuals()  |>
  mutate(
    group = case_when(
      str_detect(.model_desc, "RECURSIVE") ~ "Recursive",
      str_detect(.model_desc, "TBATS") ~ "Seasonal Reg",
      str_detect(.model_desc, "SEASONAL DECOMP:") ~ "Seasonal Reg",
      str_detect(.model_desc, "ETS") ~ "Exp Smoothing",
      str_detect(.model_desc, "CROSTON") ~ "Exp Smoothing",
      str_detect(.model_desc, "THETA") ~ "Exp Smoothing"
    )
  ) |>
  ggplot(aes(x = .prediction, y = .actual, color = .model_desc)) +
  facet_wrap(group ~ .model_desc, scale = "free") +
  geom_point(alpha = 0.312) +
  geom_smooth(method = "lm", formula = y ~ x) +
  scale_y_continuous(labels = scales::dollar) +
  scale_x_continuous(labels = scales::dollar) +
  theme_minimal() +
  theme(legend.position = "none") +
  labs(
    title = "Actual vs. Predicted",
    x = "Predicted",
    y = "Actual"
  )

ts_qq_plot(calibration_tbl |> filter(.type == "Fitted")) +
  scale_y_continuous(labels = scales::dollar)

calibration_tbl |>
  filter(.type == "Fitted") |>
  modeltime_residuals() |>
  mutate(
    group = case_when(
      str_detect(.model_desc, "RECURSIVE") ~ .model_desc,
      str_detect(.model_desc, "TBATS") ~ paste("Seasonal Reg", .model_desc),
      str_detect(.model_desc, "SEASONAL DECOMP:") ~ paste("Seasonal Reg", .model_desc),
      str_detect(.model_desc, "ETS") ~ paste("Exp Smoothing", .model_desc),
      str_detect(.model_desc, "CROSTON") ~ paste("Exp Smoothing", .model_desc),
      str_detect(.model_desc, "THETA") ~ paste("Exp Smoothing", .model_desc)
    )
  ) |>
  ggplot(aes(x = factor(group), y = .residuals, 
             fill = factor(group))) +
  geom_boxplot() +
  #facet_wrap(~ group, scales = "free") +
  theme_minimal() +
  labs(title = "Residuals by Model",
       x = "Model",
       y = "Residuals",
       fill = "Model") +
  scale_y_continuous(labels = scales::dollar) +
  theme(axis.text.x = element_blank(),
        legend.position = "bottom"
  )

# Predictions Outputs ----

## Get Modeltime Forecast ----

### Refit Models ----

refit_tbl <- calibration_tbl |>
  modeltime_refit(
    data = query_lagged
  )
refit_tbl <- refit_tbl[!sapply(refit_tbl[[".model"]], is.null),]

refit_tbl |>
  mutate(
    group = case_when(
      str_detect(.model_desc, "RECURSIVE") ~ "Recursive",
      str_detect(.model_desc, "TBATS") ~ "Seasonal Reg",
      str_detect(.model_desc, "SEASONAL DECOMP:") ~ "Seasonal Reg",
      str_detect(.model_desc, "ETS") ~ "Exp Smoothing",
      str_detect(.model_desc, "CROSTON") ~ "Exp Smoothing",
      str_detect(.model_desc, "THETA") ~ "Exp Smoothing"
    )
  ) |>
  modeltime_residuals() |> 
  ggplot(aes(x = .residuals, fill = factor(.model_desc))) + 
  facet_wrap(group ~ .model_desc, scales = "free") + 
  scale_x_continuous(labels = scales::dollar) + 
  scale_y_continuous(labels = scales::number) + 
  geom_density(alpha = 0.2) + 
  theme_minimal() + 
  theme(legend.position = "bottom") + 
  labs(fill = "Model")

refit_tbl |>
  mutate(
    group = case_when(
      str_detect(.model_desc, "RECURSIVE") ~ "Recursive",
      str_detect(.model_desc, "TBATS") ~ "Seasonal Reg",
      str_detect(.model_desc, "SEASONAL DECOMP:") ~ "Seasonal Reg",
      str_detect(.model_desc, "ETS") ~ "Exp Smoothing",
      str_detect(.model_desc, "CROSTON") ~ "Exp Smoothing",
      str_detect(.model_desc, "THETA") ~ "Exp Smoothing"
    )
  ) |>
  modeltime_residuals() |> 
  ggplot(aes(x = .residuals, fill = factor(.model_desc))) + 
  facet_wrap(~ group, scales = "free") + 
  scale_x_continuous(labels = scales::dollar) + 
  scale_y_continuous(labels = scales::number) + 
  geom_density(alpha = 0.2) + 
  theme_minimal() + 
  theme(legend.position = "bottom") + 
  labs(fill = "Model")

refit_tbl |>
  ts_model_rank_tbl() |>
  select(-.type)

refit_tbl |>
  modeltime_residuals() |>
  plot_modeltime_residuals()

ts_scedacity_scatter_plot(
  refit_tbl
) +
  scale_y_continuous(labels = scales::dollar) +
  scale_x_continuous(labels = scales::dollar)

refit_tbl |>
  modeltime_residuals()  |>
  mutate(
    group = case_when(
      str_detect(.model_desc, "RECURSIVE") ~ "Recursive",
      str_detect(.model_desc, "TBATS") ~ "Seasonal Reg",
      str_detect(.model_desc, "SEASONAL DECOMP:") ~ "Seasonal Reg",
      str_detect(.model_desc, "ETS") ~ "Exp Smoothing",
      str_detect(.model_desc, "CROSTON") ~ "Exp Smoothing",
      str_detect(.model_desc, "THETA") ~ "Exp Smoothing"
    )
  ) |>
  ggplot(aes(x = .prediction, y = .actual, color = .model_desc)) +
  facet_wrap(group ~ .model_desc, scale = "free") +
  geom_point(alpha = 0.312) +
  geom_smooth(method = "lm", formula = y ~ x) +
  scale_y_continuous(labels = scales::dollar) +
  scale_x_continuous(labels = scales::dollar) +
  theme_minimal() +
  theme(legend.position = "none") +
  labs(
    title = "Actual vs. Predicted",
    x = "Predicted",
    y = "Actual"
  )

ts_qq_plot(refit_tbl) +
  scale_y_continuous(labels = scales::dollar)

refit_tbl |>
  modeltime_residuals() |>
  mutate(
    group = case_when(
      str_detect(.model_desc, "RECURSIVE") ~ .model_desc,
      str_detect(.model_desc, "TBATS") ~ paste("Seasonal Reg", .model_desc),
      str_detect(.model_desc, "SEASONAL DECOMP:") ~ paste("Seasonal Reg", .model_desc),
      str_detect(.model_desc, "ETS") ~ paste("Exp Smoothing", .model_desc),
      str_detect(.model_desc, "CROSTON") ~ paste("Exp Smoothing", .model_desc),
      str_detect(.model_desc, "THETA") ~ paste("Exp Smoothing", .model_desc)
    )
  ) |>
  ggplot(aes(x = factor(group), y = .residuals, 
             fill = factor(group))) +
  geom_boxplot() +
  #facet_wrap(~ group, scales = "free") +
  theme_minimal() +
  labs(title = "Residuals by Model",
       x = "Model",
       y = "Residuals",
       fill = "Model") +
  scale_y_continuous(labels = scales::dollar) +
  theme(axis.text.x = element_blank(),
        legend.position = "bottom"
  )

## Ensemble models ----


ensemble_model_tbl <- calibration_tbl |>
  filter(!.model_desc %in% c("RECURSIVE LM", "RECURSIVE EARTH",
                             "THETA METHOD", "CROSTON METHOD"))

### Viz Ensemble Models Only ----

ensemble_model_tbl |>
  mutate(
    group = case_when(
      str_detect(.model_desc, "RECURSIVE") ~ "Recursive",
      str_detect(.model_desc, "TBATS") ~ "Seasonal Reg",
      str_detect(.model_desc, "SEASONAL DECOMP:") ~ "Seasonal Reg",
      str_detect(.model_desc, "ETS") ~ "Exp Smoothing",
      str_detect(.model_desc, "CROSTON") ~ "Exp Smoothing",
      str_detect(.model_desc, "THETA") ~ "Exp Smoothing"
    )
  ) |>
  modeltime_residuals() |> 
  ggplot(aes(x = .residuals, fill = factor(.model_desc))) + 
  facet_wrap(group ~ .model_desc, scales = "free") + 
  scale_x_continuous(labels = scales::dollar) + 
  scale_y_continuous(labels = scales::number) + 
  geom_density(alpha = 0.2) + 
  theme_minimal() + 
  theme(legend.position = "bottom") + 
  labs(fill = "Model",
       title = "Ensemble Models Only")

ensemble_model_tbl |>
  mutate(
    group = case_when(
      str_detect(.model_desc, "RECURSIVE") ~ "Recursive",
      str_detect(.model_desc, "TBATS") ~ "Seasonal Reg",
      str_detect(.model_desc, "SEASONAL DECOMP:") ~ "Seasonal Reg",
      str_detect(.model_desc, "ETS") ~ "Exp Smoothing",
      str_detect(.model_desc, "CROSTON") ~ "Exp Smoothing",
      str_detect(.model_desc, "THETA") ~ "Exp Smoothing"
    )
  ) |>
  modeltime_residuals() |> 
  ggplot(aes(x = .residuals, fill = factor(.model_desc))) + 
  facet_wrap(~ group, scales = "free") + 
  scale_x_continuous(labels = scales::dollar) + 
  scale_y_continuous(labels = scales::number) + 
  geom_density(alpha = 0.2) + 
  theme_minimal() + 
  theme(legend.position = "bottom") + 
  labs(fill = "Model",
       title = "Ensemble Models Only")

ensemble_model_tbl |>
  ts_model_rank_tbl() |>
  select(-.type)

ensemble_model_tbl |>
  modeltime_residuals() |>
  plot_modeltime_residuals()

ts_scedacity_scatter_plot(
  ensemble_model_tbl
) +
  scale_y_continuous(labels = scales::dollar) +
  scale_x_continuous(labels = scales::dollar)

ensemble_model_tbl |>
  modeltime_residuals()  |>
  mutate(
    group = case_when(
      str_detect(.model_desc, "RECURSIVE") ~ "Recursive",
      str_detect(.model_desc, "TBATS") ~ "Seasonal Reg",
      str_detect(.model_desc, "SEASONAL DECOMP:") ~ "Seasonal Reg",
      str_detect(.model_desc, "ETS") ~ "Exp Smoothing",
      str_detect(.model_desc, "CROSTON") ~ "Exp Smoothing",
      str_detect(.model_desc, "THETA") ~ "Exp Smoothing"
    )
  ) |>
  ggplot(aes(x = .prediction, y = .actual, color = .model_desc)) +
  facet_wrap(group ~ .model_desc, scale = "free") +
  geom_point(alpha = 0.312) +
  geom_smooth(method = "lm", formula = y ~ x) +
  scale_y_continuous(labels = scales::dollar) +
  scale_x_continuous(labels = scales::dollar) +
  theme_minimal() +
  theme(legend.position = "none") +
  labs(
    title = "Actual vs. Predicted",
    x = "Predicted",
    y = "Actual"
  )

ts_qq_plot(ensemble_model_tbl) +
  scale_y_continuous(labels = scales::dollar)

ensemble_model_tbl |>
  modeltime_residuals() |>
  mutate(
    group = case_when(
      str_detect(.model_desc, "RECURSIVE") ~ .model_desc,
      str_detect(.model_desc, "TBATS") ~ paste("Seasonal Reg", .model_desc),
      str_detect(.model_desc, "SEASONAL DECOMP:") ~ paste("Seasonal Reg", .model_desc),
      str_detect(.model_desc, "ETS") ~ paste("Exp Smoothing", .model_desc),
      str_detect(.model_desc, "CROSTON") ~ paste("Exp Smoothing", .model_desc),
      str_detect(.model_desc, "THETA") ~ paste("Exp Smoothing", .model_desc)
    )
  ) |>
  ggplot(aes(x = factor(group), y = .residuals, 
             fill = factor(group))) +
  geom_boxplot() +
  #facet_wrap(~ group, scales = "free") +
  theme_minimal() +
  labs(title = "Ensemble Models Only: Residuals by Model",
       x = "Model",
       y = "Residuals",
       fill = "Model") +
  scale_y_continuous(labels = scales::dollar) +
  theme(axis.text.x = element_blank(),
        legend.position = "bottom"
  )

model_loadings_vec <- ts_model_rank_tbl(ensemble_model_tbl) |>
  select(.model_id, .model_desc, model_score) |>
  mutate(rank = rank(-model_score)) |>
  arrange(.model_id) |>
  pull(rank) |>
  as.integer()

ensemble_fit_mean <- ensemble_model_tbl |>
  ensemble_average(
    type = "mean"
  )

ensemble_fit_median <- ensemble_model_tbl |>
  ensemble_average(
    type = "median"
  )

ensemble_fit_weighted <- ensemble_model_tbl |>
  ensemble_weighted(
    loadings = model_loadings_vec,
    #loadings = c(1,3,3,0,0,0,0,0),
    scale_loadings = TRUE
  )

ensemble_calibration_tbl <- modeltime_table(
  ensemble_fit_mean,
  ensemble_fit_median,
  ensemble_fit_weighted
) |>
  modeltime_calibrate(
    new_data = train_data
  )

ensemble_calibration_combined_tbl <- bind_rows(
  ensemble_model_tbl,
  ensemble_calibration_tbl
)

ensemble_calibration_combined_tbl |>
  mutate(
    group = case_when(
      str_detect(.model_desc, "RECURSIVE") ~ "Recursive",
      str_detect(.model_desc, "TBATS") ~ "Seasonal Reg",
      str_detect(.model_desc, "SEASONAL DECOMP:") ~ "Seasonal Reg",
      str_detect(.model_desc, "ETS") ~ "Exp Smoothing",
      str_detect(.model_desc, "CROSTON") ~ "Exp Smoothing",
      str_detect(.model_desc, "THETA") ~ "Exp Smoothing",
      str_detect(.model_desc, "ENSEMBLE") ~ "Recursive Ensemble"
    )
  ) |>
  modeltime_residuals() |> 
  ggplot(aes(x = .residuals, fill = factor(.model_desc))) + 
  facet_wrap(~ group, scales = "free") + 
  scale_x_continuous(labels = scales::dollar) + 
  scale_y_continuous(labels = scales::number) + 
  geom_density(alpha = 0.312) + 
  theme_minimal() + 
  theme(legend.position = "bottom") + 
  labs(fill = "Model")

ensemble_calibration_combined_tbl |>
  mutate(
    group = case_when(
      str_detect(.model_desc, "RECURSIVE") ~ "Recursive",
      str_detect(.model_desc, "TBATS") ~ "Seasonal Reg",
      str_detect(.model_desc, "SEASONAL DECOMP:") ~ "Seasonal Reg",
      str_detect(.model_desc, "ETS") ~ "Exp Smoothing",
      str_detect(.model_desc, "CROSTON") ~ "Exp Smoothing",
      str_detect(.model_desc, "THETA") ~ "Exp Smoothing",
      str_detect(.model_desc, "ENSEMBLE") ~ "Recursive Ensemble"
    )
  ) |>
  modeltime_residuals() |> 
  ggplot(aes(x = .residuals, fill = factor(.model_desc))) + 
  facet_wrap(group ~ .model_desc, scales = "free") + 
  scale_x_continuous(labels = scales::dollar) + 
  scale_y_continuous(labels = scales::number) + 
  geom_density(alpha = 0.312) + 
  theme_minimal() + 
  theme(legend.position = "bottom") + 
  labs(fill = "Model")

ensemble_calibration_combined_tbl |>
  modeltime_accuracy() |>
  arrange(.model_id)

ensemble_calibration_combined_tbl |>
  modeltime_residuals() |>
  plot_modeltime_residuals()

ts_scedacity_scatter_plot(
  ensemble_calibration_combined_tbl
) +
  scale_y_continuous(labels = scales::dollar) +
  scale_x_continuous(labels = scales::dollar)

ensemble_calibration_combined_tbl |>
  modeltime_residuals() |>
  ggplot(aes(x = .prediction, y = .actual, color = .model_desc)) +
  facet_wrap(~ .model_desc, scale = "free") +
  geom_point(alpha = 0.312) +
  geom_smooth(method = "lm") +
  scale_y_continuous(labels = scales::dollar) +
  scale_x_continuous(labels = scales::dollar) +
  theme_minimal() +
  theme(legend.position = "none") +
  labs(
    title = "Actual vs. Predicted",
    x = "Predicted",
    y = "Actual"
  )

ts_qq_plot(ensemble_calibration_combined_tbl) +
  scale_y_continuous(labels = scales::dollar)
  
ensemble_calibration_combined_tbl |>
  modeltime_residuals() |>
  ggplot(aes(x = factor(.model_desc), y = .residuals, 
             fill = factor(.model_desc))) +
  geom_boxplot() +
  theme_minimal() +
  labs(title = "Residuals by Model",
       x = "Model",
       y = "Residuals",
       fill = "Model") +
  scale_y_continuous(labels = scales::dollar) +
  theme(axis.text.x = element_blank(),
        legend.position = "bottom")

### Refit ----

ensemble_refit_tbl <- ensemble_calibration_combined_tbl |>
  modeltime_refit(
    data = query_lagged
  )

fcst_tbl <- ensemble_refit_tbl |>
  modeltime_forecast(
    new_data = future_data,
    actual_data = query_lagged
  )  |>
  select(.index, .value, .model_desc) |>
  set_names(c("date_col", "value", "type"))


# Visualize Forecast ----

full_fcst_tbl <- bind_rows(
  query_tbl |> mutate(type = "Actual"),
  fcst_tbl
) |> 
  bind_rows(
    future_nns_data |> 
      select(date_col, value) |>
      mutate(type = "NNS Forecast")
  ) |>
  # force negative values to zero as negative makes no sense
  mutate(value = ifelse(value < 0, 0, value))

full_fcst_tbl |>
  # Last 52 weeks actual and forecast data
  filter(date_col > subtract_time(full_fcst_tbl[["date_col"]], "180 days") |> 
           tail(1)
  ) |>
  plot_time_series(
    .date_var = date_col,
    .value = value,
    .title = "BCBS Outpatient Non-Unitized 30 Day Cash Forecast Post Discharge",
    .smooth = FALSE,
    .color_var = type
  )
  
full_fcst_tbl |>
  # Last 52 weeks actual and forecast data
  filter(date_col > subtract_time(full_fcst_tbl[["date_col"]], "180 days") |> 
           tail(1)
  ) |>
  # Plot
  plot_time_series(
    date_col,
    value,
    .color_var = type,
    .smooth = FALSE,
    .interactive = FALSE
  ) +
  scale_y_continuous(
    labels = scales::dollar_format(scale = 1e-3)
  ) +
  labs(
    title = "BCBS Outpatient Non-Unitized 30 Day Cash Forecast Post Discharge",
    caption = "Forecasted values are based on an ensemble of models.",
    subtitle = paste0("Forecast Horizon ", h, " days."),
    y = "Dollars in Thousands",
    x = "Date"
  )

# Model with MCMC and lags ----
## Get Markov Chains ----
mcmc_tbl <- query_tbl |>
  mutate(
    direction = ifelse(value > lag(value), "up", "down")
  ) |>
  drop_na()

mcmc_tbl$mc_chains <- sapply(
  1:nrow(mcmc_tbl), 
  FUN = function(i) markovchainFit(mcmc_tbl[["direction"]][1:i])$estimate@transitionMatrix, 
  simplify = FALSE
)

mcmc_final_tbl <- mcmc_tbl |>
  mutate(
    chains = map(mcmc_tbl$mc_chains, \(x) {
      if (length(x) < 4) {
        tibble(
          up_to_up = 0,
          up_to_down = 0,
          down_to_up = 0,
          down_to_down = 0
        )
      } else {
        tibble(
          up_to_up = x[2, 2],
          up_to_down = x[2, 1],
          down_to_up = x[1, 2],
          down_to_down = x[1, 1]
        )
      }
    })
  ) |>
  unnest(cols = chains) |>
  select(-mc_chains, -direction)

# Visualize Markov Chains
transitionMatrix <- markovchainFit(mcmc_tbl[["direction"]])$estimate@transitionMatrix
mcmat <- new("markovchain", transitionMatrix = transitionMatrix)

my_title = paste0("MCMC Transition Matrix | Up to Down: ", 
                  round(transitionMatrix[1, 2],2)," ",
                  "Down to Up: ", round(transitionMatrix[2,1],2)
                  )
plot(mcmat, main = my_title)

transition_tbl <- as.data.frame(transitionMatrix) |>
  as_tibble(rownames = "Direction")

mcmc_final_tbl |>
  select(-value) |>
  pivot_longer(cols = -date_col, names_to = "direction", 
               values_to = "probability") |>
  mutate(direction = case_when(
    direction == "up_to_up" ~ "Up to Up",
    direction == "up_to_down" ~ "Up to Down",
    direction == "down_to_up" ~ "Down to Up",
    direction == "down_to_down" ~ "Down to Down"
  )) |>
  ggplot(aes(x = date_col, y = probability, color = direction)) +
  facet_wrap(~ direction, scales = "free") +
  geom_line() +
  geom_label(
    # Only the last value
    data = . %>% group_by(direction) %>% slice_tail(n = 1),
    aes(label = scales::percent(probability)),
    nudge_y = 0.05,
    nudge_x = 0.15
  ) +
  theme_minimal() +
  theme(legend.position = "none") +
  labs(
    title = "Markov Chains",
    x = "Date",
    y = "Probability",
    color = "Direction"
  )

