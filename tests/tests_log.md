# Error-Checking Test Log

## Test 1: Incorrect Trial Number

- **Purpose:** Check whether the script detects incorrect trial numbering.
- **Test data:** `test_bad_data.csv`
- **Deliberate error:** Changed trial number 3 to 99.
- **Expected result:** The trial-number check should fail.
- **Actual result:** Failed as expected with the message `identical(task_data$trial_number, 1:60) is not TRUE`.
- **Status:** PASS — the error check correctly detected the deliberate error.

## Test 2: Invalid Trial Type

- **Purpose:** Check whether the script detects an invalid trial type.
- **Test data:** `bad_test_Trial_Type.csv`
- **Deliberate error:** Changed one trial type from `No-Go` to `Maybe`.
- **Expected result:** The valid-trial-type check should fail.
- **Actual result:** Failed as expected with the message `all(task_data$trial_type %in% c("Go", "No-Go")) is not TRUE`.
- **Status:** PASS — the error check correctly detected the invalid trial type.
