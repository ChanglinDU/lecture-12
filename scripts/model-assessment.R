# ------------------------------------------------------------------------------
# Model assessment: Lasso (nested 5x5 CV), intercept-only and full OLS (5-fold CV).
# Target: log(shares). Outputs assessment rMSE (in log space) and SD to output/assessment/.
# Run from project root: Rscript scripts/model-assessment.R
# ------------------------------------------------------------------------------

source(file.path("src", "setup.R"))
source(file.path("src", "nested_cv.R"))
source(file.path("src", "data.R"))

set.seed(SEED)
dir.create(DIR_ASSESSMENT, showWarnings = FALSE, recursive = TRUE)

train_data <- load_train_data()

# Recipes: outcome = log_shares; standardize predictors for lasso/full
rec            <- recipe(log_shares ~ ., data = train_data) %>%
  step_normalize(all_numeric_predictors())
rec_intercept  <- recipe(log_shares ~ 1, data = train_data)

# ------------------------------------------------------------------------------
# Same 5 folds for all models; aggregate as mean(fold rMSE) for all
# ------------------------------------------------------------------------------
outer_folds <- vfold_cv(train_data, v = N_FOLDS_OUTER)
nested_splits <- nested_cv(
  train_data,
  outside = outer_folds,
  inside  = vfold_cv(v = N_FOLDS_INNER)
)

# ------------------------------------------------------------------------------
# Lasso: nested CV (inner for tuning), outer evaluation on outer_folds
# ------------------------------------------------------------------------------
lasso_spec <- linear_reg(penalty = tune(), mixture = 1) %>%
  set_engine("glmnet")
penalty_grid <- grid_regular(penalty(range = PENALTY_RANGE), levels = PENALTY_LEVELS)

message("Running nested CV for Lasso (5 outer x 5 inner)...")
best_penalty_lasso <- map_dbl(
  seq_len(nrow(nested_splits)),
  function(i) {
    tune_inner(
      nested_splits$splits[[i]],
      nested_splits$inner_resamples[[i]],
      lasso_spec, rec, penalty_grid
    )
  }
)
nested_splits_lasso <- nested_splits %>%
  mutate(best_penalty = best_penalty_lasso)
outer_metrics_lasso <- map2_dfr(
  nested_splits_lasso$splits,
  nested_splits_lasso$best_penalty,
  ~ eval_outer(.x, .y, lasso_spec, rec, outcome = "log_shares")
)

# Aggregation: mean of fold rMSE and MAE (consistent with intercept and full)
assessment_rmse_lasso    <- mean(outer_metrics_lasso$rmse)
assessment_rmse_sd_lasso <- sd(outer_metrics_lasso$rmse)
assessment_mae_lasso     <- mean(outer_metrics_lasso$mae)
assessment_mae_sd_lasso  <- sd(outer_metrics_lasso$mae)

# ------------------------------------------------------------------------------
# Intercept-only and full OLS: same 5 folds (outer_folds), no tuning
# ------------------------------------------------------------------------------
# Intercept-only
message("Running 5-fold CV for intercept-only model (same folds)...")
wf_intercept <- workflow() %>%
  add_recipe(rec_intercept) %>%
  add_model(linear_reg() %>% set_engine("lm"))
cv_intercept <- fit_resamples(
  wf_intercept,
  resamples = outer_folds,
  metrics   = metric_set(rmse, mae)
)
metrics_intercept <- collect_metrics(cv_intercept, summarize = FALSE)
assessment_rmse_intercept    <- mean(metrics_intercept %>% filter(.metric == "rmse") %>% pull(.estimate))
assessment_rmse_sd_intercept <- sd(metrics_intercept %>% filter(.metric == "rmse") %>% pull(.estimate))
assessment_mae_intercept    <- mean(metrics_intercept %>% filter(.metric == "mae") %>% pull(.estimate))
assessment_mae_sd_intercept <- sd(metrics_intercept %>% filter(.metric == "mae") %>% pull(.estimate))

# Full OLS (all regressors)
message("Running 5-fold CV for full OLS model (same folds)...")
wf_full <- workflow() %>%
  add_recipe(rec) %>%
  add_model(linear_reg() %>% set_engine("lm"))
cv_full <- fit_resamples(
  wf_full,
  resamples = outer_folds,
  metrics   = metric_set(rmse, mae)
)
metrics_full <- collect_metrics(cv_full, summarize = FALSE)
assessment_rmse_full    <- mean(metrics_full %>% filter(.metric == "rmse") %>% pull(.estimate))
assessment_rmse_sd_full <- sd(metrics_full %>% filter(.metric == "rmse") %>% pull(.estimate))
assessment_mae_full    <- mean(metrics_full %>% filter(.metric == "mae") %>% pull(.estimate))
assessment_mae_sd_full <- sd(metrics_full %>% filter(.metric == "mae") %>% pull(.estimate))

# ------------------------------------------------------------------------------
# Report and write to output/assessment/
# ------------------------------------------------------------------------------
message("\n========== Assessment rMSE (5-fold or nested CV) ==========")
message("Lasso (nested 5x5): ", round(assessment_rmse_lasso, 4), " (SD = ", round(assessment_rmse_sd_lasso, 4), ")")
message("Intercept-only (5-fold): ", round(assessment_rmse_intercept, 4), " (SD = ", round(assessment_rmse_sd_intercept, 4), ")")
message("Full OLS (5-fold): ", round(assessment_rmse_full, 4), " (SD = ", round(assessment_rmse_sd_full, 4), ")")
message("\n========== Assessment MAE (5-fold or nested CV) ==========")
message("Lasso (nested 5x5): ", round(assessment_mae_lasso, 4), " (SD = ", round(assessment_mae_sd_lasso, 4), ")")
message("Intercept-only (5-fold): ", round(assessment_mae_intercept, 4), " (SD = ", round(assessment_mae_sd_intercept, 4), ")")
message("Full OLS (5-fold): ", round(assessment_mae_full, 4), " (SD = ", round(assessment_mae_sd_full, 4), ")")

out_assessment <- tibble(
  model              = c("lasso", "intercept", "full"),
  assessment_rmse    = c(assessment_rmse_lasso, assessment_rmse_intercept, assessment_rmse_full),
  assessment_rmse_sd = c(assessment_rmse_sd_lasso, assessment_rmse_sd_intercept, assessment_rmse_sd_full),
  assessment_mae    = c(assessment_mae_lasso, assessment_mae_intercept, assessment_mae_full),
  assessment_mae_sd  = c(assessment_mae_sd_lasso, assessment_mae_sd_intercept, assessment_mae_sd_full)
)
write_csv(out_assessment, file.path(DIR_ASSESSMENT, "assessment_rmse.csv"))
message("\nOutput written to ", file.path(DIR_ASSESSMENT, "assessment_rmse.csv"))
message("Done.")
