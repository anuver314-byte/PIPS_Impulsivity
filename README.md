# PIPS Impulsivity Project

## Overview

This repository contains the code and supporting materials for our group project in Programming in Psychological Science (PiPS) at the University of Amsterdam (UvA).

The project investigates whether trait anxiety moderates the relationship between emotional stimulus valence and impulsivity, measured using commission errors in a Go/No-Go task.

The current workflow focuses on analysing an existing public dataset and developing a Monte Carlo simulation for statistical power analysis. R is used for data validation, data preparation, statistical analysis, and simulation-based power analysis.

**Research question:** Does trait anxiety moderate the effect of emotional stimulus valence on impulsivity, as measured by commission errors in a Go/No-Go task?

## Data Source

The project uses the publicly available SSRA and Human Behaviour dataset hosted on Zenodo:

https://doi.org/10.5281/zenodo.12599247

The statistical workflow uses Go/No-Go task data and questionnaire data. The current analysis focuses on the placebo group and post-measurement data, according to the analysis plan.

The original dataset should be interpreted in the context of the study in which it was collected. The main report documents the data-preparation decisions, analysis methods, and limitations.

The source files used by the current validation and preparation scripts are:

- `study_data.csv`
- `PREPOST_questionnaires_combined.xlsx`

These files are expected to be located in `data and statistics/previous_data/`. Both should be included in the final repository if permitted by the dataset's terms and the project's data-management requirements.

## Project Components

### 1. Data preparation

`data and statistics/data_preparation.R` prepares the statistical dataset from the original source files. It reads the Go/No-Go task data and questionnaire data, joins them using participant and measurement identifiers, filters the placebo group, and prepares the trait-anxiety and emotional-valence variables.

The prepared dataset must be saved as an `.rds` file for the downstream scripts. The current workflow expects `GoNo.rds` at:

`data and statistics/previous_data/GoNo.rds`

**Important:** The version of the preparation code reviewed so far does not appear to create this file with `saveRDS()`. This must be corrected before the workflow can run reliably from a fresh clone. The preparation script should save the prepared dataset at the expected location, retaining the measurement occasions required by subsequent analysis steps.

### 2. Statistical analysis

`data and statistics/analysis.R` fits and evaluates a binomial generalized linear mixed-effects model (GLMM) to examine commission-error counts across emotional-valence conditions and levels of trait anxiety.

The planned model includes:

- Emotional valence (`Express`).
- Centred trait anxiety (`STAI_c`).
- The interaction between emotional valence and trait anxiety.
- A participant-level random intercept.

The interaction is evaluated by comparing the full model with a reduced model that excludes the interaction, using a likelihood-ratio test.

The analysis script also performs data checks and model diagnostics, produces plots, and saves model summaries and results. It reads the prepared dataset from `data and statistics/previous_data/GoNo.rds`.

After fitting the model, the script saves the fitted model as:

`data and statistics/results/bi_model.rds`

The `results/` directory must exist before the script attempts to write output files. The script should either create this directory automatically or the repository should include it.

### 3. Monte Carlo power analysis

`data and statistics/simulation_power_analysis.R` estimates statistical power by generating simulated datasets, fitting the planned models, and evaluating the interaction using a likelihood-ratio test.

The simulation depends on the analysis data and model-related inputs. Its file dependencies, model-fitting procedure, and compatibility with the statistical analysis script must be confirmed before the full simulation can be considered reproducible.

The power-analysis code is currently being debugged and validated. A small diagnostic run completed after a change to the reduced-model fitting procedure. However, this does not establish that the full simulation works correctly.

**The diagnostic result is not a final power estimate and must not be used to determine a required sample size.** The full power analysis must be run and reviewed before its results can be interpreted.

### 4. Data validation and testing

`tests/check_statistics_data.R` checks the statistical input files and verifies selected data properties.

The recorded validation run completed 19 checks with zero failures. It also identified 14 rows with missing or unusable trait-anxiety scores, which require transparent handling in the analysis.

Two deliberately corrupted CSV test cases were detected as expected.

These results apply to the checks implemented in the validation script; they do not independently establish the scientific validity of the dataset or analysis.

See the project status and test logs for details of completed checks and outstanding issues.

### 5. Main report

`main.Rmd` is the main R Markdown report. It documents the research question, dataset, methods, results, interpretation, limitations, and reproducibility information.

The final report is intended to provide a reproducible entry point to the project workflow, including data preparation, statistical analysis, and the simulation component. It should execute the relevant code and display the key results and plots, rather than only describe the procedures.

The integrated report and full workflow still need to be tested from a clean R session before this can be considered complete.

## Repository Structure

The following structure describes the intended roles of the main project components. Confirm the exact paths against the final repository before running the code.

```text
PIPS_Impulsivity/
├── README.md
├── main.Rmd
├── data and statistics/
│   ├── data_preparation.R
│   ├── analysis.R
│   ├── simulation_power_analysis.R
│   ├── previous_data/
│   │   ├── study_data.csv
│   │   ├── PREPOST_questionnaires_combined.xlsx
│   │   └── GoNo.rds
│   └── results/
│       └── bi_model.rds
├── tests/
│   └── check_statistics_data.R
└── project and test logs, if included
```

This is an intended overview, not a guarantee that every listed file or folder is currently committed. `GoNo.rds` and `bi_model.rds` are generated files, not original source data. The preparation and analysis scripts should generate them in the locations expected by downstream steps.

Exploratory Python/PsychoPy scripts and related literature available on a teammate's branch are not currently part of the primary statistical-analysis workflow and should not be assumed to be integrated into the shared project.

## Requirements

The project uses R and the following packages based on the imports identified in the current scripts:

- `readxl` — reading Excel questionnaire data.
- `here` — project-relative file paths.
- `dplyr` — data manipulation.
- `tidyr` — filling missing values during data preparation.
- `ggplot2` — data visualisation.
- `lme4` — fitting generalized linear mixed-effects models.
- `DHARMa` — model diagnostics.
- `scales` — formatting plot axes and labels.
- `knitr` and `rmarkdown` — rendering the main report.

Install the listed packages in R if they are not already available:

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

Review the library imports at the beginning of all three statistical scripts and the report to confirm that this list includes every dependency required by the final workflow.

## Running the Project

### 1. Open the repository

Clone or download the repository and open its root directory in RStudio. Keep the folder structure intact so that the project-relative paths used by `here` resolve correctly.

### 2. Check the source data

Confirm that both original input files are present:

- `data and statistics/previous_data/study_data.csv`
- `data and statistics/previous_data/PREPOST_questionnaires_combined.xlsx`

Run the validation script from the repository root:

```r
source("tests/check_statistics_data.R")
```

This command assumes the validation script is located at `tests/check_statistics_data.R` and that R is working from the repository root.

### 3. Prepare the analysis data

Run the data-preparation script:

```r
source("data and statistics/data_preparation.R")
```

The script should read the original source files, prepare the analysis dataset, and save `GoNo.rds` to `data and statistics/previous_data/`.

**This step must be verified:** the version of the preparation code reviewed so far does not appear to save `GoNo.rds`. Add and test the appropriate `saveRDS()` call before relying on this command for a complete workflow.

### 4. Fit and evaluate the statistical model

After confirming that `GoNo.rds` exists at the expected location, run:

```r
source("data and statistics/analysis.R")
```

The analysis script should fit the GLMM, run the diagnostic checks, produce the plots and statistical summaries, and save the fitted model to `data and statistics/results/bi_model.rds`.

Ensure the `results/` directory exists before running the script.

### 5. Run the Monte Carlo power analysis

After confirming the simulation's input requirements and that its required data or model objects are available, run:

```r
source("data and statistics/simulation_power_analysis.R")
```

The simulation remains under validation. Do not interpret the small diagnostic run as a final power estimate. The full simulation must be executed and reviewed before its results are reported.

### 6. Render the main report

Open `main.Rmd` in RStudio and use **Knit** to render the report.

The intended final report should execute the required preparation, analysis, and simulation steps and display the relevant results and plots. The exact integration and execution order must be confirmed in `main.Rmd`; rendering the current report should not be assumed to run the entire workflow until this has been tested.

### Workflow summary

The intended execution sequence is:

**Validate source data → prepare and save data → fit and evaluate the statistical model → run the Monte Carlo power analysis → report the results in `main.Rmd`.**

The complete workflow has not yet been verified from a clean R session. In particular, confirm that the preparation script creates `GoNo.rds`, the analysis script creates `bi_model.rds`, and the simulation uses compatible inputs. Update these instructions after the scripts have been integrated and tested end to end.

## Data Management and Reproducibility

- Preserve the provenance of the public dataset and document all data transformations.
- Do not commit identifiable participant information or other sensitive data to the public repository.
- Document missing-data handling and analysis decisions transparently.
- Use reproducible project-relative paths wherever possible.
- Keep original input data separate from generated and processed data.
- Record package requirements and relevant software-version information.
- Make sure that generated `.rds` files are either produced by the documented workflow or explicitly identified as required pre-existing files.
- Ensure that the main report and README accurately describe which steps have been tested and which remain under development.

## Project Status

**In development.**

The recorded statistical input-validation run completed 19 checks with zero failures. Two deliberately corrupted CSV test cases were detected as expected. A three-simulation diagnostic run of the revised power-analysis code also completed without failures, but this small run is not sufficient to validate the full simulation or provide a reliable power estimate.

The following items remain to be completed or confirmed:

- Ensure the data-preparation script creates `GoNo.rds` at the expected location.
- Confirm all required input files and generated `.rds` files.
- Ensure the analysis script creates its results directory when needed and saves `bi_model.rds`.
- Verify that the power-analysis script uses consistent inputs and completes successfully.
- Integrate the preparation, analysis, and simulation steps into `main.Rmd`.
- Test the complete workflow from a clean R session.
- Finalise the setup and execution instructions after end-to-end testing.

## Contributors

PiPS group project at the University of Amsterdam.

Authors listed in the main report: A. Verma, K. Huang, and S. Radeva.
