# ------------------------------------------------------------------------------
# Plot Test vs Assessment rMSE and MAE by model (Lasso, Intercept, Full OLS).
# Target is log(shares). Writes output/figures/rmse_comparison.pdf and mae_comparison.pdf.
# Run from project root: Rscript scripts/plot_mse_comparison.R
# ------------------------------------------------------------------------------

source(file.path("src", "setup.R"))

dir.create(DIR_FIGURES, showWarnings = FALSE, recursive = TRUE)
path_fig    <- file.path(DIR_FIGURES, "rmse_comparison.pdf")

test_rmse   <- read_csv(file.path(DIR_TEST, "test_rmse.csv"), show_col_types = FALSE) %>%
  mutate(model = case_when(
    model == "lasso"     ~ "Lasso",
    model == "intercept" ~ "Intercept",
    model == "full"      ~ "Full OLS",
    TRUE ~ model
  ))
assessment  <- read_csv(file.path(DIR_ASSESSMENT, "assessment_rmse.csv"), show_col_types = FALSE) %>%
  mutate(model = case_when(
    model == "lasso"     ~ "Lasso",
    model == "intercept" ~ "Intercept",
    model == "full"      ~ "Full OLS",
    TRUE ~ model
  ))

# Combine and reshape for plotting; add SD for error bars (Assessment rMSE only)
plot_dat <- test_rmse %>%
  left_join(assessment, by = "model") %>%
  pivot_longer(
    cols = c(test_rmse, assessment_rmse),
    names_to = "metric",
    values_to = "rmse"
  ) %>%
  mutate(
    metric  = if_else(metric == "test_rmse", "Test rMSE", "Assessment rMSE"),
    rmse_sd = if_else(metric == "Assessment rMSE", assessment_rmse_sd, 0)
  )

# Order models for plot
plot_dat <- plot_dat %>%
  mutate(model = factor(model, levels = c("Intercept", "Full OLS", "Lasso")))

# Grouped barplot with error bars for assessment rMSE
# Zoom y-axis so small differences between models are visible (bars look identical from 0)
rmse_range <- range(plot_dat$rmse)
delta <- max(diff(rmse_range), 1)  # avoid 0 for identical values
y_min <- rmse_range[1] - 0.02 * delta
y_max <- rmse_range[2] + 0.22 * delta  # headroom for error bars and value labels

p <- ggplot(plot_dat, aes(x = model, y = rmse, fill = metric)) +
  geom_col(position = position_dodge(width = 0.7), width = 0.7) +
  geom_errorbar(
    aes(ymin = rmse - rmse_sd, ymax = rmse + rmse_sd),
    position = position_dodge(width = 0.7),
    width = 0.2,
    linewidth = 0.5
  ) +
  geom_text(
    aes(label = sprintf("%.2f", rmse)),
    position = position_dodge(width = 0.7),
    vjust = -0.4,
    size = 2.9
  ) +
  coord_cartesian(ylim = c(y_min, y_max)) +
  labs(
    x = "Model",
    y = "rMSE (log shares)",
    fill = ""
  ) +
  scale_fill_manual(values = c("Test rMSE" = "steelblue", "Assessment rMSE" = "darkorange")) +
  theme_minimal() +
  theme(legend.position = "top")

ggsave(path_fig, plot = p, width = FIG_WIDTH, height = FIG_HEIGHT, device = "pdf")
message("Figure saved to ", path_fig)

# ------------------------------------------------------------------------------
# MAE comparison plot (same structure as rMSE)
# ------------------------------------------------------------------------------
plot_dat_mae <- test_rmse %>%
  left_join(assessment, by = "model") %>%
  pivot_longer(
    cols = c(test_mae, assessment_mae),
    names_to = "metric",
    values_to = "mae"
  ) %>%
  mutate(
    metric  = if_else(metric == "test_mae", "Test MAE", "Assessment MAE"),
    mae_sd  = if_else(metric == "Assessment MAE", assessment_mae_sd, 0)
  ) %>%
  mutate(model = factor(model, levels = c("Intercept", "Full OLS", "Lasso")))

mae_range <- range(plot_dat_mae$mae)
delta_mae <- max(diff(mae_range), 1)
y_min_mae <- mae_range[1] - 0.02 * delta_mae
y_max_mae <- mae_range[2] + 0.22 * delta_mae

p_mae <- ggplot(plot_dat_mae, aes(x = model, y = mae, fill = metric)) +
  geom_col(position = position_dodge(width = 0.7), width = 0.7) +
  geom_errorbar(
    aes(ymin = mae - mae_sd, ymax = mae + mae_sd),
    position = position_dodge(width = 0.7),
    width = 0.2,
    linewidth = 0.5
  ) +
  geom_text(
    aes(label = sprintf("%.2f", mae)),
    position = position_dodge(width = 0.7),
    vjust = -0.4,
    size = 2.9
  ) +
  coord_cartesian(ylim = c(y_min_mae, y_max_mae)) +
  labs(
    x = "Model",
    y = "MAE (log shares)",
    fill = ""
  ) +
  scale_fill_manual(values = c("Test MAE" = "steelblue", "Assessment MAE" = "darkorange")) +
  theme_minimal() +
  theme(legend.position = "top")

path_fig_mae <- file.path(DIR_FIGURES, "mae_comparison.pdf")
ggsave(path_fig_mae, plot = p_mae, width = FIG_WIDTH, height = FIG_HEIGHT, device = "pdf")
message("Figure saved to ", path_fig_mae)
