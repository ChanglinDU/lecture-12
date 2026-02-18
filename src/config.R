# ------------------------------------------------------------------------------
# Pipeline configuration: paths, seeds, and tuning parameters
# Sourced by setup.R so all scripts get these when they source setup.
# ------------------------------------------------------------------------------

# Reproducibility
SEED <- 42L

# Data paths (relative to project root)
PATH_RAW   <- file.path("data", "raw", "data.csv")
PATH_TRAIN <- file.path("data", "processed", "train.csv")
PATH_TEST  <- file.path("data", "processed", "test.csv")
DIR_PROCESSED <- file.path("data", "processed")

# Output paths
DIR_ASSESSMENT <- file.path("output", "assessment")
DIR_FITS       <- file.path("output", "fits")
DIR_TEST       <- file.path("output", "test")
DIR_FIGURES       <- file.path("output", "figures")
DIR_FIGURES_DATA  <- file.path("output", "figures", "data")

# Train/test split
TEST_FRAC <- 0.20

# Cross-validation
N_FOLDS_OUTER <- 5L
N_FOLDS_INNER <- 5L

# Lasso tuning grid
PENALTY_RANGE  <- c(-5, 2)
PENALTY_LEVELS <- 25L

# Figure dimensions (inches)
FIG_WIDTH  <- 6
FIG_HEIGHT <- 4
