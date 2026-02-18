# ------------------------------------------------------------------------------
# Compute test rMSE for Lasso, intercept-only, and full OLS.
# Writes output/test/test_rmse.csv.
# Run from project root: Rscript scripts/model-test.R
# (Run model-fit.R first to create output/fits/*.rds)
# ------------------------------------------------------------------------------

source(file.path("src", "setup.R"))

# Paths
path_test   <- file.path("data", "processed", "test.csv")
dir_fits    <- file.path("output", "fits")
dir_test    <- file.path("output", "test")
dir.create(dir_test, showWarnings = FALSE, recursive = TRUE)

# Load fitted workflows (produced by model-fit.R)
final_lasso     <- readRDS(file.path(dir_fits, "fit_lasso.rds"))
final_intercept <- readRDS(file.path(dir_fits, "fit_intercept.rds"))
final_full      <- readRDS(file.path(dir_fits, "fit_full.rds"))

# Load test data and drop non-predictors
test_data <- read_csv(path_test, show_col_types = FALSE) %>%
  select(-url)

# Predict and compute test rMSE
pred_lasso     <- predict(final_lasso, new_data = test_data)
pred_intercept <- predict(final_intercept, new_data = test_data)
pred_full      <- predict(final_full, new_data = test_data)

test_rmse_lasso     <- sqrt(mean((test_data$shares - pred_lasso$.pred)^2))
test_rmse_intercept <- sqrt(mean((test_data$shares - pred_intercept$.pred)^2))
test_rmse_full      <- sqrt(mean((test_data$shares - pred_full$.pred)^2))

message("========== Test rMSE ==========")
message("Lasso: ", round(test_rmse_lasso, 4))
message("Intercept-only: ", round(test_rmse_intercept, 4))
message("Full OLS: ", round(test_rmse_full, 4))

# Write to output/test/
out_test <- tibble(
  model     = c("lasso", "intercept", "full"),
  test_rmse = c(test_rmse_lasso, test_rmse_intercept, test_rmse_full)
)
write_csv(out_test, file.path(dir_test, "test_rmse.csv"))
message("\nOutput written to ", file.path(dir_test, "test_rmse.csv"))
message("Done.")
