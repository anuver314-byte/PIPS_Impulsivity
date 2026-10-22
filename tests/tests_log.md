# Error-Checking and Validation Test Log

## Purpose

This document records the validation tests performed for the PiPS group project. It distinguishes tests that deliberately introduce errors to check validation behaviour from checks that assess the structure and consistency of the statistical input data and diagnostic tests of the power-analysis code.

Passing a test means that the implemented check behaved as expected for the tested case. It does not establish the scientific validity of the data, analysis, or model.

## 1. Experimental CSV Validation Tests

### Test 1: Incorrect Trial Number

- **Purpose:** Check whether the script detects incorrect trial numbering.
- **Test data:** `test_bad_data.csv`
- **Deliberate error:** Changed trial number 3 to 99.
- **Expected result:** The trial-number check should fail.
- **Actual result:** Failed as expected with the message `identical(task_data$trial_number, 1:60) is not TRUE`.
- **Status:** PASS — the error check correctly detected the deliberate error.

### Test 2: Invalid Trial Type

- **Purpose:** Check whether the script detects an invalid trial type.
- **Test data:** `bad_test_Trial_Type.csv`
- **Deliberate error:** Changed one trial type from `No-Go` to `Maybe`.
- **Expected result:** The valid-trial-type check should fail.
- **Actual result:** Failed as expected with the message `all(task_data$trial_type %in% c("Go", "No-Go")) is not TRUE`.
- **Status:** PASS — the error check correctly detected the invalid trial type.

## 2. Statistical Input Data Validation

### Test 3: Statistical Input Validation Script

- **Script:** `tests/check_statistics_data.R`
- **Purpose:** Check whether the existing statistical input files meet the structural and data requirements implemented in the validation script.
- **Files checked:**
  - `data and statistics/previous_data/study_data.csv`
  - `data and statistics/previous_data/PREPOST_questionnaires_combined.xlsx`
- **Recorded result:** 19 checks passed, 0 failed.
- **Data inspected:** `study_data.csv` contained 318 rows and 26 columns. The questionnaire workbook contained 106 rows and 126 columns.
- **Checks included:** Required columns, participant identifiers, measurement-time labels, matching participant/time keys, usable trait-anxiety scores, expected emotional-valence conditions, count validity, and placebo-group post-measurement data.
- **Issue identified:** 14 rows had missing or unusable `STAI.total` scores.
- **Status:** PASS — all implemented validation checks passed in the recorded run. The missing or unusable trait-anxiety scores remain an issue requiring transparent handling in the statistical analysis.

## 3. Monte Carlo Power Analysis Debugging

### Test 4: Initial Power Analysis Run

- **Purpose:** Estimate statistical power across the planned sample-size values.
- **Expected result:** Simulations should fit the full and reduced models and calculate interaction-test p-values.
- **Actual result:** All 1,000 attempted simulations failed. Power estimates were unavailable.
- **Reported error:** `models were not all fitted to the same size of dataset`.
- **Interpretation:** The initial run did not provide valid power estimates or a defensible required sample size.
- **Status:** FAIL — the initial power-analysis workflow did not complete successfully.

### Test 5: Corrected Power Analysis Diagnostic

- **Purpose:** Check whether the revised model-fitting procedure resolves the error encountered in the initial run.
- **Code change:** The reduced model was fitted directly to the same simulated dataset as the full model, rather than being created by updating the fitted full model.
- **Test settings:** N = 1,200; 3 simulations.
- **Expected result:** All three simulations should complete without the previous model-comparison error.
- **Actual result:**

| Measure | Result |
|---|---:|
| Simulations attempted | 3 |
| Successful simulations | 3 |
| Failed simulations | 0 |
| Estimated power | 0.667 |
| Runtime | Approximately 0.07 minutes |

- **Status:** PASS — all three diagnostic simulations completed successfully after the code change.
- **Limitation:** Three simulations are insufficient for a reliable power estimate. This test confirms successful execution for the tested run only; it does not validate the full power analysis or establish the required sample size.
- **Integration status:** The change was tested locally and is pending review by the statistics team member before integration into the shared repository.

## 4. Outstanding Validation Tasks

- [ ] Confirm that the validation scripts use the final agreed repository paths.
- [ ] Verify that validation and analysis scripts run from a clean R session.
- [ ] Document and justify the handling of missing or unusable trait-anxiety scores.
- [ ] Review the statistical analysis and its assumptions.
- [ ] Obtain review of the corrected power-analysis code.
- [ ] Confirm reproducible execution of the full power-analysis workflow before reporting final power estimates.
- [ ] Keep the README, `main.Rmd`, project status log, and this tests log consistent with the verified results.

## 5. Summary of Recorded Results

| Test | Result | Scope |
|---|---|---|
| Incorrect trial number | PASS | Detected deliberately corrupted trial numbering. |
| Invalid trial type | PASS | Detected an invalid trial-type label. |
| Statistical input validation | PASS | 19 implemented checks passed; 14 rows with missing or unusable trait-anxiety scores remain an analysis issue. |
| Initial power analysis | FAIL | All 1,000 simulations failed. |
| Corrected power diagnostic | PASS | Three simulations succeeded; the full power analysis remains unvalidated. |

*Test results should be updated only when new runs have been completed and their outputs recorded.*
