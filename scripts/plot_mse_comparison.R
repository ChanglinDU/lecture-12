# ------------------------------------------------------------------------------
# Plot Test rMSE and Assessment rMSE by model (Lasso, Intercept, Full OLS).
# Writes output/figures/rmse_comparison.pdf.
# Run from project root: Rscript scripts/plot_mse_comparison.R
# ------------------------------------------------------------------------------

source(file.path("src", "setup.R"))

dir_figures <- file.path("output", "figures")
dir.create(dir_figures, showWarnings = FALSE, recursive = TRUE)
path_fig    <- file.path(dir_figures, "rmse_comparison.pdf")

# Load rMSE outputs
test_rmse   <- read_csv(file.path("output", "test", "test_rmse.csv"), show_col_types = FALSE) %>%
  mutate(model = case_when(
    model == "lasso"     ~ "Lasso",
    model == "intercept" ~ "Intercept",
    model == "full"      ~ "Full OLS",
    TRUE ~ model
  ))
assessment  <- read_csv(file.path("output", "assessment", "assessment_rmse.csv"), show_col_types = FALSE) %>%
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
y_max <- rmse_range[2] + 0.15 * delta  # headroom for error bars and labels

p <- ggplot(plot_dat, aes(x = model, y = rmse, fill = metric)) +
  geom_col(position = position_dodge(width = 0.7), width = 0.7) +
  geom_errorbar(
    aes(ymin = rmse - rmse_sd, ymax = rmse + rmse_sd),
    position = position_dodge(width = 0.7),
    width = 0.2,
    linewidth = 0.5
  ) +
  geom_text(
    aes(label = round(rmse, 0)),
    position = position_dodge(width = 0.7),
    vjust = -0.5,
    size = 2.8
  ) +
  coord_cartesian(ylim = c(y_min, y_max)) +
  labs(
    x = "Model",
    y = "rMSE",
    fill = ""
  ) +
  scale_fill_manual(values = c("Test rMSE" = "steelblue", "Assessment rMSE" = "darkorange")) +
  theme_minimal() +
  theme(legend.position = "top")

ggsave(path_fig, plot = p, width = 6, height = 4, device = "pdf")
message("Figure saved to ", path_fig)
