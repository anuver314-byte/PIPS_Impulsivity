# Project Status and Script Overview

## Purpose

This document tracks the development status of the PsychoPy scripts used in our PIPS group project. It identifies the purpose of each version and the work required before the experimental implementation can be finalised.

## Experimental Script Development

| Script | Purpose | Current status |
|---|---|---|
| Script 1 | Test whether the PsychoPy window opens | Early prototype |
| Script 2 | Add instructions and a Start button | Early prototype |
| Script 3 | Develop the Go/No-Go instruction screen | Prototype |
| Script 4 | Test a single trial and CSV output | Prototype |
| Script 5 | Implement practice trials, official trials, feedback, and CSV output | Leading candidate; validation pending |

## Outstanding Tasks

- [ ] Confirm which script will be used as the final experimental implementation.
- [ ] Test the trial sequence and response recording.
- [ ] Verify the CSV output structure and data integrity.
- [ ] Confirm how emotional valence is represented in the task.
- [ ] Confirm how trait-anxiety scores will be collected or linked to participant data.
- [ ] Coordinate the experimental implementation with the group's final research question.
- [ ] Document the final script's requirements and instructions for running it.

## Dependencies

The final statistical analysis and interpretation depend on confirmation of the experimental design, relevant dataset variables, and the statistical plan.


## Existing Work on Teammate's Branch

Branch: working_branch_Knox

Location: Pips final project/

### Experiment

Five PsychoPy scripts, including the current candidate for the Go/No-Go experiment.

A data/ subfolder containing Go_NoGo_task_data_20261018_104456.csv.

The final script and CSV output require validation before integration into the shared project.

### Research literature

Two PDF papers relevant to the research topic.

Their bibliographic details and relevance to the research question need to be documented.

### Integration status

Existing work has been located but has not yet been integrated into the shared project structure.

Confirm the final experimental script, data provenance, and appropriate file locations before merging.


## Data Validation and Error Checking

### Current status

- [x] Ran the R validation script on the existing Go/No-Go CSV; all current checks passed.
- [x] Tested the trial-number validation by deliberately changing trial number 3 to 99 in a separate test copy.
- [x] Confirmed that the check detected the incorrect trial numbering and stopped with the expected error.
- [ ] Test additional validation rules using deliberately corrupted test data.
- [ ] Confirm that the validation script works with the agreed final repository file paths.
- [ ] Integrate and document the final validation script in the shared project structure.

### Validation scope

The R script checks the CSV structure and whether the recorded values are consistent with the expected Go/No-Go task rules. Passing these checks does not independently verify the original participant responses.


## Update Log

- Initial data-validation test completed successfully: the trial-number check detected the deliberately introduced error.


*Note: Script descriptions and statuses must be verified against the actual files before the project is finalised.*
