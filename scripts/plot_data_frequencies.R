# ------------------------------------------------------------------------------
# Frequency plot for each variable in the training data.
# Runs after split; outputs one PDF per variable to output/figures/data/.
# Run from project root: Rscript scripts/plot_data_frequencies.R
# ------------------------------------------------------------------------------

source(file.path("src", "setup.R"))
source(file.path("src", "data.R"))

dir.create(DIR_FIGURES_DATA, showWarnings = FALSE, recursive = TRUE)

train_data <- load_train_data()

# Sanitize variable name for use as filename (no spaces or path chars)
safe_name <- function(x) {
  gsub("[^A-Za-z0-9_.-]", "_", x)
}

for (v in names(train_data)) {
  x <- train_data[[v]]
  if (is.numeric(x)) {
    p <- ggplot(tibble(x = x), aes(x = x)) +
      geom_histogram(bins = min(50L, max(10L, length(unique(x)))), fill = "steelblue", colour = "white", linewidth = 0.2) +
      labs(title = v, x = NULL, y = "Count") +
      theme_minimal()
  } else {
    p <- ggplot(tibble(x = factor(x)), aes(x = x)) +
      geom_bar(fill = "steelblue") +
      labs(title = v, x = NULL, y = "Count") +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 45, hjust = 1))
  }
  path_out <- file.path(DIR_FIGURES_DATA, paste0(safe_name(v), ".pdf"))
  ggsave(path_out, plot = p, width = FIG_WIDTH, height = FIG_HEIGHT, device = "pdf")
}

# Raw target (shares) — not in train_data because load_train_data() uses log(shares) only
train_raw <- read_csv(PATH_TRAIN, show_col_types = FALSE)
p_shares <- ggplot(train_raw, aes(x = shares)) +
  geom_histogram(bins = min(50L, max(10L, length(unique(train_raw$shares)))), fill = "steelblue", colour = "white", linewidth = 0.2) +
  labs(title = "shares (raw target)", x = NULL, y = "Count") +
  theme_minimal()
ggsave(file.path(DIR_FIGURES_DATA, "shares.pdf"), plot = p_shares, width = FIG_WIDTH, height = FIG_HEIGHT, device = "pdf")

message("Frequency plots written to ", DIR_FIGURES_DATA, " (", ncol(train_data), " variables + raw target shares).")
