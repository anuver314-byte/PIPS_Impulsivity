# Project Status and Development Log

## 1. Project Purpose

This document tracks the development, validation, and integration of the PiPS group project, *Impact of Emotion on Impulsivity in Inhibition Tasks*.

The current project focuses on analysing existing Go/No-Go task data and developing a Monte Carlo simulation for power analysis. The project investigates whether trait anxiety moderates the relationship between emotional stimulus valence and impulsivity, measured using commission errors.

**Research question:** Does trait anxiety moderate the effect of emotional stimulus valence on impulsivity, as measured by commission errors in a Go/No-Go task?

The project uses an existing public dataset rather than relying on a newly implemented PsychoPy experiment for its primary statistical analysis.

## 2. Current Project Components

| Component | Current status | Notes |
|---|---|---|
| Main R Markdown report (`main.Rmd`) | In development | Requires a complete and coherent report structure, including methods, results, limitations, and reproducibility information. |
| Statistical input validation | Initial checks completed | `tests/check_statistics_data.R` completed 19 checks with 0 failures in the recorded run. |
| Statistical analysis | Developed by statistics team member | Includes a binomial generalized linear mixed-effects model (GLMM). Requires review and reproducibility checks. |
| Monte Carlo power analysis | Debugging in progress | The initial run failed in all 1,000 simulations. A subsequent three-simulation diagnostic test succeeded after a code change. |
| README.md | Requires revision | Must describe the current analysis workflow, actual repository contents, dependencies, and instructions for running the project. |
| Tests log | In progress | Records data-validation checks, deliberately corrupted test cases, and power-analysis debugging. |
| PsychoPy scripts | Exploratory/reference work | Five scripts exist on a teammate's branch. They are not currently part of the primary statistical analysis workflow. |

## 3. Data Sources and Preparation

### Public dataset

The project uses the SSRA and Human Behaviour dataset available through Zenodo:

https://doi.org/10.5281/zenodo.12599247

The statistical workflow uses existing Go/No-Go task data and questionnaire data.

### Analysis decisions

The current statistical approach includes the following decisions, which should be documented in the final report:

- Restricting the analysis to the placebo group because the active group received a pharmacological intervention.
- Using post-measurement data for the planned analysis.
- Using trait-anxiety scores from the other measurement occasion to fill missing scores where the analysis assumes trait anxiety is relatively stable.
- Modelling commission-error counts with a binomial GLMM to account for repeated observations within participants.
- Including emotional valence, centred trait anxiety, and their interaction in the full model.

These decisions and their implications must be explained transparently in the final report. In particular, the handling of missing questionnaire scores requires justification and a clear account of how many observations are affected.

## 4. Data Validation and Error Checking

### Statistical input validation

The script `tests/check_statistics_data.R` completed 19 checks with 0 failures in the recorded test run.

The checks covered:

- Expected input files and data structures.
- Required columns and participant identifiers.
- Normalisation of Go/No-Go measurement-time labels.
- Matching participant and measurement-time keys across data sources.
- Availability and numeric usability of trait-anxiety scores.
- Presence of the expected emotional-valence conditions.
- Numeric, nonnegative, integer-valued counts and positive trial totals.
- Availability of placebo-group post-measurement observations.

The validation run identified 14 rows with missing or unusable `STAI.total` scores. These require transparent handling in the analysis.

### Experimental CSV validation

An earlier validation script was tested using a Go/No-Go CSV file.

- [x] Confirmed that deliberately changing a trial number to an invalid value caused the expected validation error.
- [x] Confirmed that an invalid trial type was detected in a separate corrupted test case.
- [x] Recorded the successful corrupted-data tests in the testing notes.
- [ ] Confirm that all validation scripts use the agreed final repository paths.
- [ ] Verify that the validation scripts run from a clean R session.

Passing these checks establishes only that the implemented rules work for the tested cases. It does not independently verify the correctness of the original participant responses or establish scientific validity.

## 5. Statistical Analysis

The current analysis uses a binomial GLMM to examine commission errors across emotional-valence conditions and levels of trait anxiety.

The model includes:

- Emotional valence (`Express`).
- Centred trait anxiety (`STAI_c`).
- The interaction between emotional valence and trait anxiety.
- A participant-level random intercept.

The overall interaction is evaluated by comparing the full model with a reduced model that excludes the interaction.

### Current status

- [x] Statistical analysis code developed by the statistics team member.
- [x] Statistical input validation completed in the recorded run.
- [ ] Review model assumptions, diagnostics, and missing-data handling.
- [ ] Confirm that the analysis runs reproducibly from a clean session.
- [ ] Document the final model specification, results, and limitations in `main.Rmd`.

The analysis is intended to inform the group's investigation and power analysis. Conclusions should account for the sample size, model diagnostics, and the limitations of the existing dataset.

## 6. Monte Carlo Power Analysis

### Initial problem

The initial power-analysis run attempted 1,000 simulations across the specified sample-size values. All simulations failed, producing unavailable power estimates.

The reported error was:

`models were not all fitted to the same size of dataset`

Consequently, the initial results did not provide a valid estimate of statistical power or the required sample size.

### Debugging update — 22 October 2026

The power-analysis code was modified locally to fit the full and reduced models directly to the same simulated dataset, rather than fitting the reduced model by updating the full model.

A diagnostic run was then conducted at N = 1,200 using three simulations.

| Diagnostic measure | Result |
|---|---:|
| Sample size | 1,200 |
| Simulations attempted | 3 |
| Successful simulations | 3 |
| Failed simulations | 0 |
| Estimated power | 0.667 |
| Runtime | Approximately 0.07 minutes |

This test confirms that the modified code completed three simulations without the previous error. The estimated power of 0.667 is not a reliable final estimate because it is based on only three simulations.

### Current status and next steps

- [x] Identify and investigate the original model-comparison error.
- [x] Modify the reduced-model fitting procedure locally.
- [x] Confirm that three diagnostic simulations complete without failures.
- [ ] Send the corrected code to the statistics team member (TM) for review.
- [ ] Agree on the changes before integrating them into the shared repository.
- [ ] Establish that the complete power-analysis workflow runs reproducibly.
- [ ] Evaluate and report power estimates only when the simulations and their assumptions have been appropriately validated.

**The power analysis is not yet complete.** The initial estimate of a required sample size of N = 1,200 should not be reported as a valid finding. The diagnostic test does not establish the sample size needed to achieve 80% power.

## 7. README and Reproducibility

The README should reflect the actual project structure and explain:

- The research question and dataset provenance.
- The purpose of the analysis and power-analysis scripts.
- The required R packages and any additional software dependencies.
- The expected input files and their locations.
- The steps for running validation, analysis, and power analysis.
- The location of generated outputs.
- Known limitations and outstanding validation tasks.

The report in `main.Rmd` should provide the substantive methods, results, interpretation, and limitations, while the README should prioritise project setup and execution instructions.

## 8. Existing Work on the Teammate's Branch

**Branch:** `working_branch_Knox`

**Location:** `PiPS final project/`

The branch contains five exploratory PsychoPy scripts, a sample Go/No-Go CSV, and two research-literature PDFs.

These materials were developed during an earlier stage of the project. They are not currently part of the primary statistical analysis workflow.

Any future integration should be based on an explicit group decision about whether the experimental implementation remains relevant to the final submission. The existing files should not be described as validated or final unless that status is independently confirmed.

## 9. Outstanding Project Tasks

- [ ] Obtain TM's review of the corrected power-analysis code.
- [ ] Resolve and document the handling of missing or unusable trait-anxiety scores.
- [ ] Review the statistical model, diagnostics, and interpretation.
- [ ] Confirm that the analysis and validation scripts work from a clean session.
- [ ] Complete the README with accurate paths, dependencies, and execution instructions.
- [ ] Develop `main.Rmd` into a coherent final report.
- [ ] Keep the project log and tests log consistent with actual results.
- [ ] Confirm which exploratory materials, if any, belong in the final repository.
- [ ] Check that all claims in the final report are supported by reproducible results.

## 10. Update Log

### 22 October 2026
- Updated the project description to reflect the current statistical-analysis workflow rather than the earlier PsychoPy-focused plan.
- Recorded the completed statistical input-validation run: 19 checks passed, 0 failed.
- Documented the 14 rows with missing or unusable trait-anxiety scores as an issue requiring transparent handling.
- Recorded the original power-analysis failure and the subsequent three-simulation diagnostic test.
- Clarified that the corrected power-analysis code remains local pending review and integration.
- Identified README, report, reproducibility, and testing documentation as outstanding work.

*This document records development status. Completed tasks should be marked only when supported by actual test results or confirmed repository changes.*
