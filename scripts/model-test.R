# ------------------------------------------------------------------------------
# Compute test rMSE for Lasso, intercept-only, and full OLS. Target: log(shares).
# Writes output/test/test_rmse.csv (rMSE in log space).
# Run from project root: Rscript scripts/model-test.R
# (Run model-fit.R first to create output/fits/*.rds)
# ------------------------------------------------------------------------------

source(file.path("src", "setup.R"))
source(file.path("src", "data.R"))

dir.create(DIR_TEST, showWarnings = FALSE, recursive = TRUE)

final_lasso     <- readRDS(file.path(DIR_FITS, "fit_lasso.rds"))
final_intercept <- readRDS(file.path(DIR_FITS, "fit_intercept.rds"))
final_full      <- readRDS(file.path(DIR_FITS, "fit_full.rds"))

test_data <- load_test_data()

# Predict (in log space) and compute test rMSE and MAE
pred_lasso     <- predict(final_lasso, new_data = test_data)
pred_intercept <- predict(final_intercept, new_data = test_data)
pred_full      <- predict(final_full, new_data = test_data)

test_rmse_lasso     <- sqrt(mean((test_data$log_shares - pred_lasso$.pred)^2))
test_rmse_intercept <- sqrt(mean((test_data$log_shares - pred_intercept$.pred)^2))
test_rmse_full      <- sqrt(mean((test_data$log_shares - pred_full$.pred)^2))

test_mae_lasso     <- mean(abs(test_data$log_shares - pred_lasso$.pred))
test_mae_intercept <- mean(abs(test_data$log_shares - pred_intercept$.pred))
test_mae_full      <- mean(abs(test_data$log_shares - pred_full$.pred))

message("========== Test rMSE ==========")
message("Lasso: ", round(test_rmse_lasso, 4), "  Intercept-only: ", round(test_rmse_intercept, 4), "  Full OLS: ", round(test_rmse_full, 4))
message("========== Test MAE ==========")
message("Lasso: ", round(test_mae_lasso, 4), "  Intercept-only: ", round(test_mae_intercept, 4), "  Full OLS: ", round(test_mae_full, 4))

# Write to output/test/
out_test <- tibble(
  model     = c("lasso", "intercept", "full"),
  test_rmse = c(test_rmse_lasso, test_rmse_intercept, test_rmse_full),
  test_mae  = c(test_mae_lasso, test_mae_intercept, test_mae_full)
)
write_csv(out_test, file.path(DIR_TEST, "test_rmse.csv"))
message("\nOutput written to ", file.path(DIR_TEST, "test_rmse.csv"))
message("Done.")
