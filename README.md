# Final_models.ipynb — Overview

This repository contains a single Jupyter notebook, `Final_models.ipynb`, which performs exploratory plots and fits two count-data models (Poisson GLM and Poisson GAM) to smoking-related survey data from the Philippines.

## What the notebook does

- Loads and cleans `dataset/PHILIPPINES_DATA_19.csv` (replaces common missing markers and drops rows with missing values).
- Converts `CR7` (number of days smoked in the past 30 days) to numeric and derives a binary `smoker_status` indicator (1 = smoked >1 day, 0 otherwise).
- Produces exploratory visualizations:
  - Distribution of smoking days (`CR7`).
  - Age histogram (`CR1`).
  - Sex count (`CR2`).
  - Mean smoking days by peer offer (`CR39`).
- Fits a Poisson GLM with formula:
  - `CR7 ~ CR1 + CR2 + PHR3 + PHR4 + CR5 + CR9 + PHR20 + CR39 + PHR31 + PHR44`
  - Prints a summary and a coefficient bar chart.
- Fits a Poisson GAM on selected predictors `CR1`, `CR39`, `CR5` and plots partial dependence with 95% confidence intervals.
- Shows model diagnostic plots: coefficient significance, predicted vs actual, and residuals distribution.

## Data columns referenced (short)
- `CR7`: Number of days smoked in the past 30 days (response).
- `CR1`: Age.
- `CR2`: Sex (coded numerically in the dataset).
- `CR5`: Tried smoking indicator.
- `CR39`: Peer offer (best friends offered tobacco scale).
- `PHR3, PHR4, CR9, PHR20, PHR31, PHR44`: Covariates used in GLM.

## Requirements
Install the Python packages used by the notebook (example via pip):

```powershell
pip install pandas numpy matplotlib seaborn statsmodels pygam
```

Note: use the environment you prefer (conda, venv). `pygam` may require a C compiler on some platforms.

## How to run
1. Open `Final_models.ipynb` in Jupyter or VS Code.
2. Make sure `dataset/PHILIPPINES_DATA_19.csv` exists at the shown relative path.
3. Run cells top-to-bottom. The notebook is organized so that execution in order reproduces the plots and models.

## Expected outputs
- A printed GLM summary (coefficients, p-values).
- Plots: distributions, mean-by-group bar, GLM coefficients, GAM partial-dependence plots with CI, predicted vs actual scatter, and residual histogram.
