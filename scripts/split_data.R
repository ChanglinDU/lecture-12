# ------------------------------------------------------------------------------
# Split data.csv into training (80%) and test (20%) samples
# Run from project root: Rscript scripts/split_data.R
# ------------------------------------------------------------------------------

source(file.path("src", "setup.R"))

# Replicable split
SEED <- 42L
set.seed(SEED)

# Paths (relative to project root)
dir_processed <- file.path("data", "processed")
path_raw      <- file.path("data", "raw", "data.csv")
path_train    <- file.path(dir_processed, "train.csv")
path_test     <- file.path(dir_processed, "test.csv")

dir.create(dir_processed, showWarnings = FALSE, recursive = TRUE)

# Read full data
dat <- read.csv(path_raw, stringsAsFactors = FALSE)
n   <- nrow(dat)

# 20% test, 80% train
n_test  <- floor(0.20 * n)
i_test  <- sample.int(n, size = n_test)
i_train <- setdiff(seq_len(n), i_test)

train <- dat[i_train, ]
test  <- dat[i_test, ]

# Write out
write.csv(train, path_train, row.names = FALSE)
write.csv(test,  path_test,  row.names = FALSE)

message(
  "Split complete. Train: ", nrow(train), " rows -> ", path_train, "\n",
  "                Test:  ", nrow(test),  " rows -> ", path_test
)
