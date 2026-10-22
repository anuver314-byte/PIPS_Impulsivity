
# Validate the Go/No-Go task data.
# This script checks whether a task-output CSV follows the expected
# format and whether its trial numbers, conditions, error codes,
# and reaction times are consistent with the task design.

# Accept a CSV path from the command line, or let the user
# select a file when running interactively in RStudio.

args <- commandArgs(trailingOnly = TRUE)

if (length(args) == 1) {
  file_path <- args[1]
} else if (length(args) == 0 && interactive()) {
  file_path <- file.choose()
} else {
  stop("Please provide the path to one Go/No-Go CSV file.")
}

# Confirm that the selected or supplied file exists.
if (!file.exists(file_path)) {
  stop("Data file not found: ", file_path)
}


# Read the CSV and convert empty fields to missing values (NA).
task_data <- read.csv(
  file_path,
  stringsAsFactors = FALSE,
  na.strings = ""
)

# Confirm that the file contains every column needed for validation.
required_columns <- c(
  "trial_number",
  "trial_type",
  "error",
  "response_time_ms"
)

missing_columns <- setdiff(required_columns, names(task_data))

if (length(missing_columns) > 0) {
  stop(
    "Missing required columns: ",
    paste(missing_columns, collapse = ", ")
  )
}

# Check that the dataset contains exactly 60 trials, numbered 1 to 60.
# These expectations must match the task's intended design.
if (nrow(task_data) != 60) {
  stop("Expected 60 trials, but found ", nrow(task_data), ".")
}

if (!is.numeric(task_data$trial_number) ||
    !identical(task_data$trial_number, 1:60)) {
  stop("Trial numbers must be numeric and run consecutively from 1 to 60.")
}

# Check that trial types use the expected labels and that the
# experiment contains 30 Go trials and 30 No-Go trials.
if (anyNA(task_data$trial_type) ||
    !all(task_data$trial_type %in% c("Go", "No-Go"))) {
  stop("Trial types must contain only 'Go' and 'No-Go', with no missing values.")
}

if (sum(task_data$trial_type == "Go") != 30 ||
    sum(task_data$trial_type == "No-Go") != 30) {
  stop("Expected 30 Go trials and 30 No-Go trials.")
}

# Check that every trial has a valid error code:
# 0 = correct response; 1 = incorrect response.
if (anyNA(task_data$error) ||
    !is.numeric(task_data$error) ||
    !all(task_data$error %in% c(0, 1))) {
  stop("Error codes must be numeric 0 or 1, with no missing values.")
}

# Create variables to make the response checks easier to read.
rt <- task_data$response_time_ms
go <- task_data$trial_type == "Go"
nogo <- task_data$trial_type == "No-Go"
correct <- task_data$error == 0
incorrect <- task_data$error == 1

# Reaction times should be numeric or missing, not text.
if (!is.numeric(rt)) {
  stop("Reaction times must be numeric.")
}

# Go trials:
# Correct responses should have a recorded reaction time.
if (anyNA(rt[go & correct])) {
  stop("Correct Go trials must have recorded reaction times.")
}

# Missed Go responses (coded as errors) should have missing reaction times.
if (any(!is.na(rt[go & incorrect]))) {
  stop("Incorrect Go trials should have missing reaction times.")
}

# No-Go trials:
# No-Go trials do not generate reaction-time data.
# Validate reaction times only for Go trials.
if (anyNA(rt[go & !is.na(task_data$error) & task_data$error == 0])) {
  stop("Correct Go trials must have a valid reaction time.")
}

if (any(!is.finite(rt[go & !is.na(rt)]))) {
  stop("Go-trial reaction times must be finite.")
}

# Incorrect No-Go responses (commission errors) should occur before timeout.
if (anyNA(rt[nogo & incorrect]) ||
    any(rt[nogo & incorrect] < 0 | rt[nogo & incorrect] >= 2000)) {
  stop("Incorrect No-Go trials should have reaction times from 0 up to, but not including, 2000 ms.")
}

# Check that all recorded reaction times fall within the expected range.
if (any(!is.na(rt) & (rt < 0 | rt > 2000))) {
  stop("Reaction times must be between 0 and 2000 ms.")
}

# Print a success message only if every check above has passed.
cat("All basic Go/No-Go data checks passed.\n")
