# ------------------------------------------------------------------------------
# Nested cross-validation helpers for tidymodels workflows.
# Source after setup.R: source(file.path("src", "nested_cv.R"))
# ------------------------------------------------------------------------------

#' Run inner tuning on one outer split and return best penalty.
#'
#' @param outer_split An rsplit (one fold from the outer resample).
#' @param inner_resamples An rset of inner resamples (e.g. from nested_cv()).
#' @param model_spec A parsnip model spec with penalty = tune().
#' @param rec A recipe.
#' @param grid A tuning grid (e.g. from grid_regular(penalty(...))).
#' @param metric Metric name for select_best (default "rmse").
#' @return The best penalty value (scalar).
tune_inner <- function(outer_split, inner_resamples, model_spec, rec, grid, metric = "rmse") {
  wf <- workflow() %>%
    add_recipe(rec) %>%
    add_model(model_spec)
  tune_res <- tune_grid(
    wf,
    resamples = inner_resamples,
    grid = grid,
    control = control_grid(save_workflow = TRUE),
    metrics = metric_set(rmse)
  )
  best <- select_best(tune_res, metric = metric)
  best$penalty
}

#' Fit workflow with given penalty on outer analysis set and return rMSE on assessment set.
#'
#' @param outer_split An rsplit (one fold from the outer resample).
#' @param penalty_val The penalty value to use (e.g. from tune_inner).
#' @param model_spec A parsnip model spec with penalty = tune().
#' @param rec A recipe.
#' @return rMSE on the outer assessment set (scalar).
eval_outer <- function(outer_split, penalty_val, model_spec, rec) {
  wf <- workflow() %>%
    add_recipe(rec) %>%
    add_model(model_spec) %>%
    finalize_workflow(tibble(penalty = penalty_val))
  fit <- fit(wf, data = analysis(outer_split))
  pred <- predict(fit, new_data = assessment(outer_split))
  rmse_vec(truth = assessment(outer_split)$shares, estimate = pred$.pred)
}
