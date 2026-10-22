# PIPS Impulsivity Project

## Overview

This repository contains the code and supporting materials for our group project in Programming in Psychological Science (PIPS) at the University of Amsterdam (UvA).

The project investigates whether trait anxiety moderates the relationship between emotional stimulus valence and impulsivity, measured using commission errors in a Go/No-Go task.

The current workflow focuses on analysing an existing public dataset and developing a Monte Carlo simulation for statistical power analysis. The project uses R for data validation, statistical analysis, and simulation-based power analysis.

**Research question:** Does trait anxiety moderate the effect of emotional stimulus valence on impulsivity, as measured by commission errors in a Go/No-Go task?

## Data Source

The project uses the publicly available SSRA and Human Behaviour dataset hosted on Zenodo:

https://doi.org/10.5281/zenodo.12599247

The statistical workflow uses existing Go/No-Go task data and questionnaire data. The analysis focuses on the placebo group and post-measurement data, according to the current analysis plan.

The dataset and its variables should be interpreted in the context of the original study. See the final report for the analysis decisions, limitations, and data-preparation procedures.

## Project Components

### Statistical analysis

The statistical analysis uses a binomial generalized linear mixed-effects model (GLMM) to examine commission-error counts across emotional-valence conditions and levels of trait anxiety.

The planned model includes:
- Emotional valence (`Express`).
- Centred trait anxiety (`STAI_c`).
- The interaction between emotional valence and trait anxiety.
- A participant-level random intercept.

The interaction is evaluated by comparing the full model with a reduced model that excludes the interaction.

### Monte Carlo power analysis

A simulation script estimates statistical power by generating simulated datasets, fitting the planned models, and evaluating the interaction using a likelihood-ratio test.

The power-analysis code is currently being debugged and reviewed. A small diagnostic test completed successfully after a change to the reduced-model fitting procedure. However, the full power analysis has not yet been validated, so no final required sample size should be inferred from the diagnostic result.

### Data validation and testing

The repository includes validation checks for statistical input files and tests that deliberately introduce invalid values to confirm that the relevant checks detect them.

The recorded statistical input-validation run completed 19 checks with 0 failures. The checks also identified 14 rows with missing or unusable trait-anxiety scores, which require transparent handling in the analysis.

See the project status log and tests log for details of completed checks and outstanding issues.

### Main report

`main.Rmd` is the main R Markdown report. It will document the research question, data, methods, results, interpretation, limitations, and reproducibility information.

## Repository Structure

The following describes the intended roles of the main project components. Confirm the exact paths against the current repository before running the code.

- `main.Rmd` — Main R Markdown report.
- `README.md` — Project overview and setup instructions.
- `R/` — R scripts and related materials, where applicable.
- `data and statistics/` — Statistical input data, analysis scripts, results, and power-analysis materials, according to the current project structure.
- `tests/` — Data-validation scripts and related tests.
- Project status log — Records development decisions, progress, and outstanding tasks.
- Tests log — Records test procedures, expected results, actual results, and limitations.

Exploratory Python/PsychoPy scripts and related literature are available on a teammate's branch. They are not currently part of the primary statistical-analysis workflow and should not be assumed to be integrated into the shared project.

## Requirements

The statistical workflow uses R. The scripts currently use packages including:

- `lme4` — Fitting generalized linear mixed-effects models.
- `dplyr` — Data manipulation.
- `here` — Project-relative file paths.
- `readxl` — Reading Excel questionnaire data, where required.

Additional packages may be needed by individual scripts. Check the library imports at the top of each script before running it.

A complete dependency list and installation instructions should be finalised after the scripts have been reviewed and tested from a clean R session.

## Running the Project

### 1. Open the project

Clone or download the repository and open the project in RStudio. Ensure that the working directory and folder structure match the paths used by the scripts.

### 2. Check the input data

Ensure that the required dataset files are available at the paths expected by the validation and analysis scripts.

Run the statistical input-validation script:

```r
source("tests/check_statistics_data.R")
```

This command assumes the repository is opened at its root and the script is located at `tests/check_statistics_data.R`.

### 3. Run the statistical analysis

Run the statistical analysis script provided in the repository after checking its required input files and dependencies. Refer to the script's comments and the final report for the model specification and analysis decisions.

### 4. Run the power analysis

Run the power-analysis script only after confirming that its input model, dataset paths, and dependencies are available.

The power-analysis workflow is still under review. Its complete execution and final estimates have not yet been validated.

**Note:** These are provisional instructions. Confirm the actual filenames and paths in the shared repository before treating this section as final.

## Data Management and Reproducibility

- Do not commit identifiable participant information or other sensitive data to the public repository.
- Preserve the provenance of the public dataset and document any data transformations.
- Record missing-data handling and analysis decisions transparently.
- Use reproducible project-relative paths where possible.
- Keep generated results distinct from original input data.
- Document the software and package requirements needed to reproduce the analysis.

## Project Status

**In development.**

Statistical input validation has been completed for the recorded test run, and two deliberately corrupted CSV test cases were detected as expected. A three-simulation diagnostic test of the revised power-analysis code also completed without failures.

The full power analysis remains unvalidated. The analysis workflow, missing-data handling, report, and reproducibility instructions require further review before the project is finalised.

## Contributors

PiPS group project at the University of Amsterdam.

Authors listed in the main report: A. Verma, K. Huang, and S. Radeva.
