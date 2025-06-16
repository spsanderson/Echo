model_evaluation <- function(.model){
  ggplot2::theme_set(ggplot2::theme_test())
  
  m <- .model
  
  cm <- try(performance::check_model(m), silent = TRUE)
  
  ge <- try(ggeffects::ggeffect(m) |> plot() |> sjPlot::plot_grid(), silent = TRUE)
  
  gts <- try(gtsummary::tbl_regression(m, add_pairwise_contrasts = TRUE), silent = TRUE)
  
  eta <- try(effectsize::eta_squared(m), silent = TRUE)
  
  vimp <- try(vip::vip(m) + ggplot2::theme_minimal(), silent = TRUE)
  
  perf <- try(performance::performance(m), silent = TRUE)
  
  eq <- try(equatiomatic::extract_eq(m), silent = TRUE)
  
  output <- list(
    check_model = cm,
    ggeffects = ge,
    gtsummary = gts,
    eta_squared = eta,
    vip = vimp,
    performance = perf,
    equation = eq
    )
  
  return(output)
  
}