# ------------------------------------------------------------------------------
# Split data.csv into training (80%) and test (20%) samples
# Run from project root: Rscript scripts/split_data.R
# ------------------------------------------------------------------------------

source(file.path("src", "setup.R"))

set.seed(SEED)
dir.create(DIR_PROCESSED, showWarnings = FALSE, recursive = TRUE)

# Read full data
dat <- read.csv(PATH_RAW, stringsAsFactors = FALSE)
n   <- nrow(dat)

n_test  <- floor(TEST_FRAC * n)
i_test  <- sample.int(n, size = n_test)
i_train <- setdiff(seq_len(n), i_test)

train <- dat[i_train, ]
test  <- dat[i_test, ]

write.csv(train, PATH_TRAIN, row.names = FALSE)
write.csv(test,  PATH_TEST,  row.names = FALSE)

message(
  "Split complete. Train: ", nrow(train), " rows -> ", PATH_TRAIN, "\n",
  "                Test:  ", nrow(test),  " rows -> ", PATH_TEST
)
