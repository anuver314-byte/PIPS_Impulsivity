
# Validate the Go/No-Go task data

file_path <- file.choose()

if (!file.exists(file_path)) {
  stop("Data file not found: ", file_path)
}

task_data <- read.csv(
  file_path,
  stringsAsFactors = FALSE,
  na.strings = ""
)

required_columns <- c(
  "trial_number",
  "trial_type",
  "error",
  "response_time_ms"
)

missing_columns <- setdiff(required_columns, names(task_data))

if (length(missing_columns) > 0) {
  stop("Missing columns: ", paste(missing_columns, collapse = ", "))
}

# Check trial count and numbering
stopifnot(nrow(task_data) == 60)
stopifnot(identical(task_data$trial_number, 1:60))

# Check trial types and balance
stopifnot(all(task_data$trial_type %in% c("Go", "No-Go")))
stopifnot(sum(task_data$trial_type == "Go") == 30)
stopifnot(sum(task_data$trial_type == "No-Go") == 30)

# Check error codes
stopifnot(!anyNA(task_data$error))
stopifnot(all(task_data$error %in% c(0, 1)))

rt <- task_data$response_time_ms
go <- task_data$trial_type == "Go"
nogo <- task_data$trial_type == "No-Go"
correct <- task_data$error == 0
incorrect <- task_data$error == 1

# Go: correct responses need a recorded RT
stopifnot(all(!is.na(rt[go & correct])))

# Go: missed responses should have a missing RT
stopifnot(all(is.na(rt[go & incorrect])))

# No-Go: correct withholding should reach the timeout
stopifnot(all(
  !is.na(rt[nogo & correct]) &
    rt[nogo & correct] == 2000
))

# No-Go: incorrect presses should have an RT below timeout
stopifnot(all(
  !is.na(rt[nogo & incorrect]) &
    rt[nogo & incorrect] >= 0 &
    rt[nogo & incorrect] < 2000
))

# Check for impossible or unexpected reaction times
stopifnot(all(is.na(rt) | (rt >= 0 & rt <= 2000)))

cat("All basic Go/No-Go data checks passed.\n")
