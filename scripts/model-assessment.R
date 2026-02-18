# ------------------------------------------------------------------------------
# Model assessment: Lasso (nested 5x5 CV), intercept-only and full OLS (5-fold CV).
# Outputs assessment rMSE and SD to output/assessment/.
# Run from project root: Rscript scripts/model-assessment.R
# ------------------------------------------------------------------------------

source(file.path("src", "setup.R"))
source(file.path("src", "nested_cv.R"))

SEED <- 42L
set.seed(SEED)

# Paths
path_train     <- file.path("data", "processed", "train.csv")
dir_assessment <- file.path("output", "assessment")
dir.create(dir_assessment, showWarnings = FALSE, recursive = TRUE)

# Load data and drop non-predictors
train_data <- read_csv(path_train, show_col_types = FALSE) %>%
  select(-url)

# Recipes: full predictors vs intercept-only
rec       <- recipe(shares ~ ., data = train_data)
rec_intercept <- recipe(shares ~ 1, data = train_data)

# ------------------------------------------------------------------------------
# Same 5 folds for all models; aggregate as mean(fold rMSE) for all
# ------------------------------------------------------------------------------
outer_folds <- vfold_cv(train_data, v = 5)
nested_splits <- nested_cv(
  train_data,
  outside = outer_folds,
  inside  = vfold_cv(v = 5)
)

# ------------------------------------------------------------------------------
# Lasso: nested CV (inner for tuning), outer evaluation on outer_folds
# ------------------------------------------------------------------------------
lasso_spec <- linear_reg(penalty = tune(), mixture = 1) %>%
  set_engine("glmnet")
penalty_grid <- grid_regular(penalty(range = c(-5, 0)), levels = 25)

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
outer_rmse_lasso <- map2_dbl(
  nested_splits_lasso$splits,
  nested_splits_lasso$best_penalty,
  ~ eval_outer(.x, .y, lasso_spec, rec)
)

# Aggregation: mean of fold rMSE (consistent with intercept and full)
assessment_rmse_lasso    <- mean(outer_rmse_lasso)
assessment_rmse_sd_lasso <- sd(outer_rmse_lasso)

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
  metrics   = metric_set(rmse)
)
fold_rmse_intercept <- collect_metrics(cv_intercept, summarize = FALSE)$.estimate
assessment_rmse_intercept    <- mean(fold_rmse_intercept)
assessment_rmse_sd_intercept <- sd(fold_rmse_intercept)

# Full OLS (all regressors)
message("Running 5-fold CV for full OLS model (same folds)...")
wf_full <- workflow() %>%
  add_recipe(rec) %>%
  add_model(linear_reg() %>% set_engine("lm"))
cv_full <- fit_resamples(
  wf_full,
  resamples = outer_folds,
  metrics   = metric_set(rmse)
)
fold_rmse_full <- collect_metrics(cv_full, summarize = FALSE)$.estimate
assessment_rmse_full    <- mean(fold_rmse_full)
assessment_rmse_sd_full <- sd(fold_rmse_full)

# ------------------------------------------------------------------------------
# Report and write to output/assessment/
# ------------------------------------------------------------------------------
message("\n========== Assessment rMSE (5-fold or nested CV) ==========")
message("Lasso (nested 5x5): ", round(assessment_rmse_lasso, 4), " (SD = ", round(assessment_rmse_sd_lasso, 4), ")")
message("Intercept-only (5-fold): ", round(assessment_rmse_intercept, 4), " (SD = ", round(assessment_rmse_sd_intercept, 4), ")")
message("Full OLS (5-fold): ", round(assessment_rmse_full, 4), " (SD = ", round(assessment_rmse_sd_full, 4), ")")

out_assessment <- tibble(
  model             = c("lasso", "intercept", "full"),
  assessment_rmse   = c(assessment_rmse_lasso, assessment_rmse_intercept, assessment_rmse_full),
  assessment_rmse_sd = c(assessment_rmse_sd_lasso, assessment_rmse_sd_intercept, assessment_rmse_sd_full)
)
write_csv(out_assessment, file.path(dir_assessment, "assessment_rmse.csv"))
message("\nOutput written to ", file.path(dir_assessment, "assessment_rmse.csv"))
message("Done.")
