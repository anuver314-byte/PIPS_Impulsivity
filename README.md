# PiPS Group Project: Emotion, Trait Anxiety, and Impulsivity

## Project overview

This project investigates how emotional stimulus valence and individual differences in trait anxiety may relate to impulsive responses during a Go/No-Go inhibition task.

The project combines a Python-based experiment developed using PsychoPy with R scripts for data preparation, statistical analysis, and Monte Carlo power analysis. Data-validation scripts are included to check the structure and consistency of experimental and statistical datasets.

The research question guiding the current analysis is:

**Does trait anxiety moderate the relationship between emotional stimulus valence and commission errors during a Go/No-Go task?**

The analysis is exploratory and uses an existing dataset to investigate this question. The experiment scripts also provide a basis for running a configurable Go/No-Go task.

## Repository contents

The repository contains the following components:

- **Experiment:** Python/PsychoPy scripts for presenting instructions, practice trials, and Go/No-Go trials, with trial-level output saved to CSV.
- **Data preparation:** R code for preparing the questionnaire and experimental data for analysis.
- **Statistical analysis:** R code for fitting a generalized linear mixed-effects model (GLMM).
- **Power analysis:** R code using Monte Carlo simulation to investigate statistical power based on the fitted model.
- **Data validation:** R scripts that check experimental CSV files and statistical-analysis data for common data-quality problems.
- **Project documentation:** This README and the project status documentation.

## Data

The statistical analysis uses the dataset hosted on Zenodo:

[Zenodo dataset, DOI: 10.5281/zenodo.12599247](https://doi.org/10.5281/zenodo.12599247)

The data-preparation workflow combines the relevant experimental and questionnaire data. The analysis scripts create processed data and model objects for subsequent analysis.

The experiment also produces trial-level CSV files containing information such as trial number, trial type, error code, and response time.

**Data note:** Do not commit identifiable participant information or other sensitive data to the public repository.

## Analysis workflow

The intended workflow is:

1. **Run the experiment** using the Python/PsychoPy task script, where applicable.
2. **Prepare the data** using `data_preparation.R`.
3. **Fit the statistical model** using `Analysis.R`.
4. **Estimate statistical power** using `Simulation_power_analysis.R`.
5. **Run the validation scripts** to check the relevant data files.

The statistical scripts depend on the prepared data and model objects produced earlier in the workflow. Run them in the required order and ensure that input files and output directories are available.

## Data validation

The repository includes two R validation scripts:

- `tests/check_go_nogo_data.R` checks the format and consistency of the Go/No-Go task output, including trial numbering, trial types, error codes, and reaction times.
- `tests/check_statistics_data.R` checks data used in the statistical workflow.

The Go/No-Go checker accepts a CSV path as a command-line argument or allows a file to be selected interactively in RStudio.

To run the Go/No-Go data checker from R, use:

```r
source("tests/check_go_nogo_data.R")
```

When running non-interactively, provide the path to the CSV as a command-line argument:

```bash
Rscript tests/check_go_nogo_data.R path/to/task_data.csv
```

Replace `path/to/task_data.csv` with the actual path to the CSV file.

## Requirements

The project uses:

- **R** and the packages required by the analysis scripts, including `dplyr`, `tidyr`, `lme4`, `readxl`, and `here`, where applicable.
- **Python** and **PsychoPy** to run the experiment.
- The emotional face-image stimuli required by the experiment script.

Install the required packages before running the relevant scripts. The exact package requirements should be checked against the library calls in each script.

## Statistical considerations

The GLMM examines the relationship between emotional stimulus valence, trait anxiety, and commission errors. The Monte Carlo power analysis uses parameters estimated from the preliminary model to explore the sample size needed to detect the effect of interest.

Power estimates depend on the fitted model, the assumptions used in the simulation, and successful model convergence. Results should therefore be interpreted in light of the exploratory nature of the preliminary analysis and any model diagnostics, including potential overdispersion.

## References

- Zenodo dataset. (2024). *Dataset associated with the Go/No-Go task project*. https://doi.org/10.5281/zenodo.12599247

- **Original study:** Add the full APA reference for the original study associated with the dataset, using the publication details in the project's research literature or the Zenodo record.

## Contributors

A. Verma, K. Huang, and S. Radeva.
