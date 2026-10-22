# PIPS Impulsivity Project

## Overview

This repository contains the code and supporting materials for our group project in Programming in Psychological Science (PiPS) at the University of Amsterdam (UvA).

The project investigates whether trait anxiety moderates the relationship between emotional stimulus valence and impulsivity, measured using commission errors in a Go/No-Go task.

**Research question:** Does trait anxiety moderate the effect of emotional stimulus valence on impulsivity, as measured by commission errors in a Go/No-Go task?

The project combines data validation, statistical analysis, and Monte Carlo simulation-based power analysis. R is used for the statistical workflow. The complete integration of the project's components is still in progress.

## Data Source

The project uses the publicly available SSRA and Human Behaviour dataset hosted on Zenodo:

https://doi.org/10.5281/zenodo.12599247

The statistical workflow uses Go/No-Go task data and questionnaire data. The current analysis plan focuses on the placebo group and post-intervention measurements.

The original source files used by the statistical workflow are:

- `study_data.csv`
- `PREPOST_questionnaires_combined.xlsx`

The statistical scripts expect these files to be located in `data and statistics/previous_data/`. Their availability and location must be confirmed when the statistical branch is integrated.

Original data should only be committed to the repository after the group has confirmed that redistribution is permitted and consistent with the project's data-management requirements.

## Project Components

### 1. Data validation

The `tests/` directory contains two validation scripts:

- **`tests/check_go_nogo_data.R`** checks the structure and response coding of Go/No-Go task-output CSV files. It validates required columns, trial numbering, trial types, error codes, and reaction times. The script accepts a file path from the command line or allows interactive file selection in RStudio.
- **`tests/check_statistics_data.R`** checks the statistical input files for expected columns, usable participant identifiers, recognised measurement occasions, overlapping participant/time-point records, and selected data properties.

The test files `tests/bad_data_test.csv` and `tests/test_bad_trial_type.csv` contain deliberately corrupted data for testing the Go/No-Go validation checks.

`tests/tests_log.md` records validation and testing results.

These scripts check selected data properties; they do not independently establish the scientific validity of the analysis or statistical model.

### 2. Data preparation

The statistical workflow includes `data and statistics/data_preparation.R`. It prepares the analysis dataset from the Go/No-Go task data and questionnaire data, including participant matching, measurement occasions, and variables needed for the planned analysis.

The downstream workflow expects the prepared dataset to be saved as:

`data and statistics/previous_data/GoNo.rds`

The statistical scripts currently reside on a teammate's branch and have not yet been integrated into this branch. The data-preparation script must be checked to ensure that it generates the expected output at the correct location.

### 3. Statistical analysis

The statistical workflow includes `data and statistics/analysis.R`, which fits a binomial generalised linear mixed-effects model (GLMM) to examine commission-error counts across emotional-valence conditions and levels of trait anxiety.

The planned model includes:

- Emotional valence (`Express`).
- Centred trait anxiety (`STAI_c`).
- The interaction between emotional valence and trait anxiety.
- A participant-level random intercept.

The interaction is evaluated by comparing the full model with a reduced model that excludes the interaction, using a likelihood-ratio test.

The analysis also includes model diagnostics, plots, and statistical summaries.

Model diagnostics indicated significant overdispersion and excess outliers. A sensitivity analysis using a beta-binomial GLMM showed improved overall fit, although some overdispersion remained. The substantive conclusion was unchanged: the interaction between emotional condition and trait anxiety was not statistically significant. The original binomial GLMM was retained as the primary model and as the basis for the simulation-based power analysis.

The power analysis uses parameters estimated from the original binomial GLMM and assumes binomial variability. Because the simulations do not incorporate the additional dispersion observed in the preliminary data, their power estimates may be optimistic if similar extra-binomial variability is present in future data. These limitations should be considered when interpreting the results.

The workflow expects a fitted model to be saved at:

`data and statistics/results/bi_model.rds`

The analysis scripts and their file dependencies must be verified after integration.

### 4. Monte Carlo power analysis

The statistical workflow includes `data and statistics/simulation_power_analysis.R`. It uses Monte Carlo simulation to estimate power for detecting the planned interaction.

The simulation depends on the analysis data and model-fitting procedure. Its inputs, execution, and outputs must be checked against the final analysis workflow before the results can be interpreted.

The simulation uses parameters estimated from the original binomial GLMM and does not incorporate the additional dispersion observed in the preliminary data. Consequently, estimated power is conditional on the binomial model assumptions and may be optimistic if future data exhibit similar extra-binomial variability. Power estimates should not be interpreted as definitive sample-size requirements.

Small diagnostic runs are useful for checking whether the simulation code executes, but they are not substitutes for a sufficiently large simulation and do not establish a final power estimate. The number of successful and failed simulations, convergence behaviour, and final results must be reviewed before recommending a sample size.

### 5. Main report

`main.Rmd` is the main R Markdown report. It is intended to document the research question, dataset, methods, results, interpretation, limitations, and reproducibility information.

The report should be updated to reflect the integrated scripts and their actual outputs. The complete workflow must be tested from a clean R session before the report can be considered a reproducible entry point to the project.

## Repository Structure

The following structure summarises the current project files and the intended location of the statistical components. The statistical folder remains on a teammate's branch until integration is completed.

```text
PIPS_Impulsivity/
├── README.md
├── main.Rmd
├── docs/
│   └── project_status.md
└── tests/
    ├── check_go_nogo_data.R
    ├── check_statistics_data.R
    ├── tests_log.md
    ├── bad_data_test.csv
    └── test_bad_trial_type.csv
```

The following statistical components are planned for integration:

```text
data and statistics/
├── data_preparation.R
├── analysis.R
├── simulation_power_analysis.R
├── previous_data/
│   ├── study_data.csv
│   ├── PREPOST_questionnaires_combined.xlsx
│   └── GoNo.rds
└── results/
    └── bi_model.rds
```

The second structure represents the intended statistical workflow, not a claim that these files are already present on the current branch. Generated `.rds` files should be created by the documented workflow or explicitly identified as required pre-existing files.

## Requirements

The statistical scripts and report use R. Based on the imports identified so far, the expected packages include:

- `readxl` — reading Excel questionnaire data.
- `here` — project-relative file paths.
- `dplyr` — data manipulation.
- `tidyr` — data preparation.
- `ggplot2` — data visualisation.
- `lme4` — fitting generalized linear mixed-effects models.
- `DHARMa` — model diagnostics.
- `scales` — formatting plot axes and labels.
- `knitr` and `rmarkdown` — rendering the main report.

Install the packages if they are not already available:

```r
install.packages(c(
  "readxl",
  "here",
  "dplyr",
  "tidyr",
  "ggplot2",
  "lme4",
  "DHARMa",
  "scales",
  "knitr",
  "rmarkdown"
))
```

The package list should be checked against the final integrated scripts and report.

## Running the Project

### 1. Open the repository

Clone the repository and open its root directory in RStudio. Preserve the folder structure so that project-relative paths resolve correctly.

### 2. Validate the Go/No-Go task data

Run the Go/No-Go validation script:

```r
source("tests/check_go_nogo_data.R")
```

When run interactively in RStudio, the script prompts you to select a CSV file. It can also accept a file path when run from the command line.

### 3. Validate the statistical input data

Once the required statistical input files are available, run:

```r
source("tests/check_statistics_data.R")
```

This script expects the input files at the locations described in the statistical workflow. Check that the files exist before running the validation.

### 4. Run the statistical workflow

After the statistical branch has been integrated, follow the execution order below:

1. Run `data and statistics/data_preparation.R` to prepare the analysis dataset.
2. Confirm that `data and statistics/previous_data/GoNo.rds` has been created.
3. Run `data and statistics/analysis.R` to fit the model and generate the analysis outputs.
4. Confirm that the results directory and fitted-model output are available.
5. Run `data and statistics/simulation_power_analysis.R` after confirming that its required inputs are compatible with the analysis workflow.

These steps describe the intended workflow. They should be tested from a clean R session after integration before being treated as fully reproducible instructions.

### 5. Render the main report

Open `main.Rmd` in RStudio and use **Knit** to render the report.

The report's execution order and dependencies must be verified against the final scripts. Do not assume that rendering it runs the entire workflow until this has been tested.

## Data Management and Reproducibility

- Preserve the provenance of the public dataset and document data transformations.
- Do not commit identifiable participant information or other sensitive data to the public repository.
- Confirm that the group's data-management requirements and dataset terms permit any redistribution of source files.
- Document missing-data handling and analysis decisions transparently.
- Use project-relative paths wherever possible.
- Keep original source data separate from generated and processed data.
- Document package requirements and relevant software versions.
- Ensure that generated files are produced by the documented workflow or clearly identified as required pre-existing files.

## Project Status

**Status: In development.**

- **Statistical input-data validation:** The recorded test run completed 19 checks with zero failures.
- **Go/No-Go validation:** The checker detected deliberately corrupted trial numbering. Testing of the revised script against valid and corrupted files is being completed.
- **Statistical workflow:** Data preparation, analysis, and simulation scripts remain on a teammate's branch and require integration and compatibility checks.
- **Model diagnostics:** The beta-binomial sensitivity analysis showed improved overall fit and did not change the substantive conclusion, although some overdispersion remained.
- **Power analysis:** Diagnostic runs have been performed, but the full simulation and its interpretation remain under validation. The estimates must be interpreted in light of the binomial simulation assumptions and the overdispersion observed in the preliminary data.
- **Main report:** The complete workflow still needs to be tested from a clean R session.

The project status and execution instructions should be updated as integration and testing progress.

## Contributors

PiPS group project at the University of Amsterdam.

Authors listed in the main report: A. Verma, K. Huang, and S. Radeva.
