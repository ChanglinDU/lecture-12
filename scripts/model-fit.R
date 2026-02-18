# ------------------------------------------------------------------------------
# Fit Lasso, intercept-only, and full OLS to train data.
# Saves workflows and coefficient estimates (output/fits/coefficients.csv) to output/fits/.
# Run from project root: Rscript scripts/model-fit.R
# ------------------------------------------------------------------------------

source(file.path("src", "setup.R"))
source(file.path("src", "data.R"))

set.seed(SEED)
dir.create(DIR_FITS, showWarnings = FALSE, recursive = TRUE)

train_data <- load_train_data()

# Recipes: outcome = log_shares; standardize predictors for lasso/full
rec            <- recipe(log_shares ~ ., data = train_data) %>%
  step_normalize(all_numeric_predictors())
rec_intercept  <- recipe(log_shares ~ 1, data = train_data)

# ------------------------------------------------------------------------------
# Lasso: 5-fold CV for hyperparameter tuning
# ------------------------------------------------------------------------------
lasso_spec <- linear_reg(penalty = tune(), mixture = 1) %>%
  set_engine("glmnet")
penalty_grid <- grid_regular(penalty(range = PENALTY_RANGE), levels = PENALTY_LEVELS)
train_cv <- vfold_cv(train_data, v = N_FOLDS_OUTER)

message("Tuning and fitting Lasso (5-fold CV)...")
wf_lasso <- workflow() %>%
  add_recipe(rec) %>%
  add_model(lasso_spec)
tune_lasso <- tune_grid(
  wf_lasso,
  resamples = train_cv,
  grid = penalty_grid,
  metrics = metric_set(rmse)
)
best_lasso <- select_best(tune_lasso, metric = "rmse")
final_lasso <- finalize_workflow(wf_lasso, best_lasso) %>%
  fit(train_data)

# ------------------------------------------------------------------------------
# Intercept-only and full OLS: fit on full train (no tuning)
# ------------------------------------------------------------------------------
message("Fitting intercept-only model...")
wf_intercept <- workflow() %>%
  add_recipe(rec_intercept) %>%
  add_model(linear_reg() %>% set_engine("lm"))
final_intercept <- fit(wf_intercept, train_data)

message("Fitting full OLS model...")
wf_full <- workflow() %>%
  add_recipe(rec) %>%
  add_model(linear_reg() %>% set_engine("lm"))
final_full <- fit(wf_full, train_data)

# ------------------------------------------------------------------------------
# Report and save
# ------------------------------------------------------------------------------
metrics_lasso <- collect_metrics(tune_lasso) %>%
  filter(.config == best_lasso$.config)
message("\n========== Lasso (5-fold CV on train) ==========")
message("Best penalty = ", format(best_lasso$penalty, digits = 4),
        ", mean rMSE = ", round(metrics_lasso$mean, 4),
        " (sd = ", round(metrics_lasso$std_err * sqrt(N_FOLDS_OUTER), 4), ")")

saveRDS(final_lasso, file.path(DIR_FITS, "fit_lasso.rds"))
saveRDS(final_intercept, file.path(DIR_FITS, "fit_intercept.rds"))
saveRDS(final_full, file.path(DIR_FITS, "fit_full.rds"))
message("\nFitted workflows saved to output/fits/")

# ------------------------------------------------------------------------------
# Write coefficient estimates: one row per term, columns lasso_est and full_est
# Top row: tuned lambda for lasso (full_est = NA)
# ------------------------------------------------------------------------------
lambda_row <- tibble(term = "lambda", lasso_est = best_lasso$penalty, full_est = NA_real_)
coef_lasso <- tidy(extract_fit_parsnip(final_lasso)) %>% select(term, estimate) %>% rename(lasso_est = estimate)
coef_full  <- tidy(extract_fit_parsnip(final_full)) %>% select(term, estimate) %>% rename(full_est = estimate)
out_coef   <- bind_rows(lambda_row, full_join(coef_lasso, coef_full, by = "term"))
write_csv(out_coef, file.path(DIR_FITS, "coefficients.csv"))
message("Coefficients written to ", file.path(DIR_FITS, "coefficients.csv"))
message("Done.")
