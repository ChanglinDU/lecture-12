# ------------------------------------------------------------------------------
# Fit Lasso, intercept-only, and full OLS to train data.
# Lasso: 5-fold CV for penalty tuning. Saves workflows to output/fits/.
# Run from project root: Rscript scripts/model-fit.R
# ------------------------------------------------------------------------------

source(file.path("src", "setup.R"))

SEED <- 42L
set.seed(SEED)

# Paths
path_train <- file.path("data", "processed", "train.csv")
dir_fits   <- file.path("output", "fits")
dir.create(dir_fits, showWarnings = FALSE, recursive = TRUE)

# Load data and drop non-predictors
train_data <- read_csv(path_train, show_col_types = FALSE) %>%
  select(-url)

# Recipes
rec            <- recipe(shares ~ ., data = train_data)
rec_intercept  <- recipe(shares ~ 1, data = train_data)

# ------------------------------------------------------------------------------
# Lasso: 5-fold CV for hyperparameter tuning
# ------------------------------------------------------------------------------
lasso_spec <- linear_reg(penalty = tune(), mixture = 1) %>%
  set_engine("glmnet")
penalty_grid <- grid_regular(penalty(range = c(-5, 0)), levels = 25)
train_cv <- vfold_cv(train_data, v = 5)

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
        " (sd = ", round(metrics_lasso$std_err * sqrt(5), 4), ")")

saveRDS(final_lasso, file.path(dir_fits, "fit_lasso.rds"))
saveRDS(final_intercept, file.path(dir_fits, "fit_intercept.rds"))
saveRDS(final_full, file.path(dir_fits, "fit_full.rds"))
message("\nFitted workflows saved to output/fits/")
message("Done.")
