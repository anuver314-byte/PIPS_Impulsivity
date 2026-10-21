# Error-Checking Test Log

## Test 1: Incorrect Trial Number

- **Purpose:** Check whether the script detects incorrect trial numbering.
- **Test data:** `test_bad_data.csv`
- **Deliberate error:** Changed trial number 3 to 99.
- **Expected result:** The trial-number check should fail.
- **Actual result:** Failed as expected with the message `identical(task_data$trial_number, 1:60) is not TRUE`.
- **Status:** PASS — the error check correctly detected the deliberate error.

