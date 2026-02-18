# Lecture 10: Linear Models with CV and Regularization

This repo trains and compares three linear models for predicting **log(shares)** (number of social shares of online news articles) from the [Online News Popularity](https://archive.ics.uci.edu/dataset/332/online+news+popularity) dataset. Performance is measured with **rMSE** (root mean squared error) and **MAE** (mean absolute error) in log space.

**Tested with R 4.4.x** (and current tidyverse/tidymodels). Run `R --version` to check.

---

## What the analysis does (step by step)

1. **Split the data**  
   `data/raw/data.csv` is split into 80% train and 20% test. Outputs: `data/processed/train.csv`, `data/processed/test.csv`.

2. **Data frequency plots**  
   One frequency plot (histogram or bar chart) per variable in the training data, plus the **raw target** (`shares`).  
   Outputs: `output/figures/data/<variable>.pdf` for each variable (including `log_shares` and `shares.pdf`).

3. **Assess models (cross-validation)**  
   On the training set only:
   - **Lasso:** Nested 5×5 CV (inner folds tune the penalty; outer folds give the performance estimate).
   - **Intercept-only:** 5-fold CV (predicts the mean of log(shares)).
   - **Full OLS:** 5-fold CV (linear model with all predictors).  
   All three use the **same 5 folds** and the **same summary** (mean of fold rMSE and MAE).  
   Outputs: `output/assessment/assessment_rmse.csv` (rMSE, rMSE SD, MAE, MAE SD per model).

4. **Fit final models**  
   On the full training set:
   - Lasso: penalty chosen by 5-fold CV, then refit on all train data.
   - Intercept-only and full OLS: fit on all train data (no tuning).  
   Outputs: `output/fits/fit_lasso.rds`, `fit_intercept.rds`, `fit_full.rds`, and `output/fits/coefficients.csv` (one row per coefficient: top row is tuned `lambda` for Lasso with `full_est` = NA; then columns `term`, `lasso_est`, `full_est`).

5. **Evaluate on the test set**  
   Each fitted model predicts on the held-out test set. Test rMSE and MAE are computed in log space.  
   Outputs: `output/test/test_rmse.csv` (columns: `model`, `test_rmse`, `test_mae`).

6. **Plot comparison**  
   Bar charts compare **Assessment** vs **Test** rMSE and MAE for the three models, with error bars for assessment SD.  
   Outputs: `output/figures/rmse_comparison.pdf`, `output/figures/mae_comparison.pdf`.

---

## How to run it

From the project root:

- **Full pipeline** (split data, data frequency plots, assess, fit, test, and comparison plots):  
  `make all`

- **Modeling only** (assume train/test exist; run frequency plots, assess, fit, test, comparison plots):  
  `make model`

- **Data only** (split and frequency plots):  
  `make data`

R packages are installed automatically when needed (see `src/setup.R`). Pipeline parameters (seed, paths, CV folds, lasso grid, figure size) live in **`src/config.R`**; data prep (load train/test with `url` dropped and `log_shares` created) is centralized in **`src/data.R`** (`load_train_data()`, `load_test_data()`).

The `output/` directory is gitignored and is recreated when you run the pipeline; if you clone the repo, run `make` (or `make model`) to generate the results and figures.

---

## Project layout

| Path | Purpose |
|------|--------|
| `data/raw/` | Raw data and dataset description (`.names` file). |
| `data/processed/` | Train and test splits. |
| `scripts/` | R scripts for split, data frequency plots, assessment, fit, test, and comparison plots. |
| `src/` | Setup (`setup.R`), config (`config.R`), data helpers (`data.R`), and shared code (e.g. `nested_cv.R`). |
| `output/assessment/` | Cross-validation rMSE and MAE (and SD) per model. |
| `output/fits/` | Saved fitted workflows (`.rds`) and `coefficients.csv`. |
| `output/test/` | Test-set rMSE and MAE per model (`test_rmse.csv`). |
| `output/figures/` | rMSE and MAE comparison plots (PDF). |
| `output/figures/data/` | One frequency plot per variable (PDF). |
