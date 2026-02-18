# Full pipeline (split + assess + fit + test): make
# Modeling only (no split): make model

.PHONY: all model data 

all:
	Rscript scripts/split_data.R
	Rscript scripts/plot_data_frequencies.R
	Rscript scripts/model-assessment.R
	Rscript scripts/model-fit.R
	Rscript scripts/model-test.R
	Rscript scripts/plot_mse_comparison.R

model:
	Rscript scripts/plot_data_frequencies.R
	Rscript scripts/model-assessment.R
	Rscript scripts/model-fit.R
	Rscript scripts/model-test.R
	Rscript scripts/plot_mse_comparison.R

data: 
	Rscript scripts/split_data.R
	Rscript scripts/plot_data_frequencies.R
