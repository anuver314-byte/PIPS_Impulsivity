
# Error checks for the statistics input data
# Run from the local copy of TM's working-branch project.

# Locate the two input files in the local project.
gonogo_file <- here::here(
  "data and statistics", "previous_data", "study_data.csv"
)

questionnaire_file <- here::here(
  "data and statistics", "previous_data",
  "PREPOST_questionnaires_combined.xlsx"
)

# STAI validation threshold.
# Confirm this threshold with the statistics partner before finalising.
min_stai_proportion <- 0.80

# Store the result of each check so that a final report can be printed.
check_results <- data.frame(
  Check = character(),
  Status = character(),
  Details = character(),
  Critical = logical(),
  stringsAsFactors = FALSE
)

# Track failed critical checks so the script can stop before analysis.
critical_failures <- character()

# Record each check as PASS or FAIL.
# Critical checks stop the workflow if they fail.
record_check <- function(name, passed, details = "",
                         critical = TRUE) {
  status <- if (isTRUE(passed)) "PASS" else "FAIL"

  check_results <<- rbind(
    check_results,
    data.frame(
      Check = name,
      Status = status,
      Details = details,
      Critical = critical,
      stringsAsFactors = FALSE
    )
  )

  if (status == "FAIL" && critical) {
    critical_failures <<- c(critical_failures, name)
  }

  cat(status, "-", name, "-", details, "\n")
}

# Print the report and stop if any critical check failed.
finish_checks <- function() {
  cat("\n========== FINAL CHECK REPORT ==========\n")
  print(check_results, row.names = FALSE)

  cat(
    "\nPassed:", sum(check_results$Status == "PASS"),
    "\nFailed:", sum(check_results$Status == "FAIL"),
    "\nTotal:", nrow(check_results), "\n"
  )

  if (length(critical_failures) > 0) {
    cat("\nCRITICAL VALIDATION FAILURE(S):\n")
    cat(paste0("- ", unique(critical_failures)), sep = "\n")
    cat("\n\nAnalysis must not proceed with these inputs.\n")

    stop(
      "Input validation failed. Correct the critical failures ",
      "before running the statistical analysis.",
      call. = FALSE
    )
  }

  cat("\nAll critical checks passed. Input validation is complete.\n")
}

cat("Project root:", here::here(), "\n\n")

# Check whether both required input files exist.
gonogo_exists <- file.exists(gonogo_file)
questionnaire_exists <- file.exists(questionnaire_file)

record_check(
  "Go/No-Go CSV exists",
  gonogo_exists,
  gonogo_file
)

record_check(
  "Questionnaire Excel file exists",
  questionnaire_exists,
  questionnaire_file
)

# Stop if either input file is missing.
if (!gonogo_exists || !questionnaire_exists) {
  finish_checks()
}

# Check that the package needed to read Excel files is installed.
if (!requireNamespace("readxl", quietly = TRUE)) {
  stop(
    "Package 'readxl' is missing. Run install.packages('readxl').",
    call. = FALSE
  )
}

# Read both input files and record any errors that occur.
gonogo <- tryCatch(
  read.csv(gonogo_file, stringsAsFactors = FALSE),
  error = function(e) {
    record_check(
      "Go/No-Go CSV can be read",
      FALSE,
      conditionMessage(e)
    )
    NULL
  }
)

questionnaires <- tryCatch(
  as.data.frame(
    readxl::read_excel(questionnaire_file),
    stringsAsFactors = FALSE
  ),
  error = function(e) {
    record_check(
      "Questionnaire Excel file can be read",
      FALSE,
      conditionMessage(e)
    )
    NULL
  }
)

# Stop if either file could not be read successfully.
if (is.null(gonogo) || is.null(questionnaires)) {
  finish_checks()
}

record_check(
  "Go/No-Go CSV can be read",
  TRUE,
  paste(nrow(gonogo), "rows;", ncol(gonogo), "columns")
)

record_check(
  "Questionnaire Excel file can be read",
  TRUE,
  paste(nrow(questionnaires), "rows;", ncol(questionnaires), "columns")
)

# List the columns required for the planned statistical analysis.
required_gonogo <- c(
  "Participant.ID", "PRE.POST", "Express", "Allocation",
  "AccurateNoPress", "InaccuratePress"
)

required_questionnaire <- c(
  "Participant ID", "PRE.POST", "STAI.total"
)

# Identify any required columns that are missing.
missing_gonogo <- setdiff(required_gonogo, names(gonogo))
missing_questionnaire <- setdiff(
  required_questionnaire, names(questionnaires)
)

record_check(
  "Required Go/No-Go columns exist",
  length(missing_gonogo) == 0,
  if (length(missing_gonogo) == 0) {
    "All required columns present"
  } else {
    paste("Missing:", paste(missing_gonogo, collapse = ", "))
  }
)

record_check(
  "Required questionnaire columns exist",
  length(missing_questionnaire) == 0,
  if (length(missing_questionnaire) == 0) {
    "All required columns present"
  } else {
    paste("Missing:", paste(missing_questionnaire, collapse = ", "))
  }
)

# Stop before further checks if a required column is unavailable.
if (length(missing_gonogo) > 0 ||
    length(missing_questionnaire) > 0) {
  finish_checks()
}

# Check that participant IDs are present and not blank.
record_check(
  "Go/No-Go participant IDs are present",
  !anyNA(gonogo$Participant.ID) &&
    all(nzchar(trimws(as.character(gonogo$Participant.ID)))),
  "Participant IDs should not be blank"
)

record_check(
  "Questionnaire participant IDs are present",
  !anyNA(questionnaires[["Participant ID"]]) &&
    all(nzchar(trimws(as.character(questionnaires[["Participant ID"]])))),
  "Participant IDs should not be blank"
)

# Standardise time-point labels so PRE/POST and Baseline/Post
# can be compared using the same labels.
normalise_time <- function(x) {
  x <- trimws(as.character(x))
  x[x == "PRE"] <- "Baseline"
  x[x == "POST"] <- "Post"
  x
}

gonogo_time <- normalise_time(gonogo$PRE.POST)
questionnaire_time <- normalise_time(questionnaires$PRE.POST)

valid_times <- c("Baseline", "Post")

# Every row must have a non-missing, recognised time-point label.
record_check(
  "Go/No-Go time-point labels are recognised",
  !anyNA(gonogo_time) && all(gonogo_time %in% valid_times),
  paste("Found:", paste(unique(gonogo_time), collapse = ", "))
)

record_check(
  "Questionnaire time-point labels are recognised",
  !anyNA(questionnaire_time) &&
    all(questionnaire_time %in% valid_times),
  paste("Found:", paste(unique(questionnaire_time), collapse = ", "))
)

# Create unique participant/time-point combinations in each file.
gonogo_keys <- unique(data.frame(
  id = trimws(as.character(gonogo$Participant.ID)),
  time = gonogo_time,
  stringsAsFactors = FALSE
))

questionnaire_keys <- unique(data.frame(
  id = trimws(as.character(questionnaires[["Participant ID"]])),
  time = questionnaire_time,
  stringsAsFactors = FALSE
))

# Exclude incomplete keys before comparing the two datasets.
gonogo_keys <- gonogo_keys[
  !is.na(gonogo_keys$id) & !is.na(gonogo_keys$time) &
    nzchar(gonogo_keys$id),
]

questionnaire_keys <- questionnaire_keys[
  !is.na(questionnaire_keys$id) & !is.na(questionnaire_keys$time) &
    nzchar(questionnaire_keys$id),
]

# Combine participant ID and time point into a comparison key.
gonogo_key <- paste(gonogo_keys$id, gonogo_keys$time, sep = "||")
questionnaire_key <- paste(
  questionnaire_keys$id, questionnaire_keys$time, sep = "||"
)

matched_keys <- intersect(gonogo_key, questionnaire_key)

# This is an overlap check, not a requirement that every key matches.
# Keep it non-critical so unmatched keys are reported without
# automatically stopping the workflow.
record_check(
  "Participant/time-point keys overlap across files",
  length(matched_keys) > 0,
  paste(
    length(matched_keys), "matching keys;",
    length(setdiff(gonogo_key, questionnaire_key)),
    "Go/No-Go keys unmatched;",
    length(setdiff(questionnaire_key, gonogo_key)),
    "questionnaire keys unmatched"
  ),
  critical = FALSE
)

# Check that questionnaire anxiety scores are numeric and finite.
anxiety <- suppressWarnings(
  as.numeric(as.character(questionnaires$STAI.total))
)

n_stai_expected <- length(anxiety)
n_stai_valid <- sum(is.finite(anxiety))
stai_proportion <- if (n_stai_expected > 0) {
  n_stai_valid / n_stai_expected
} else {
  0
}

record_check(
  "Sufficient questionnaire anxiety scores are usable",
  n_stai_expected > 0 &&
    stai_proportion >= min_stai_proportion,
  paste0(
    n_stai_valid, " of ", n_stai_expected,
    " questionnaire rows have usable scores (",
    round(stai_proportion * 100, 1), "%; minimum ",
    min_stai_proportion * 100, "%)"
  )
)

# Check that all expected expression conditions are represented.
expression_values <- unique(na.omit(as.character(gonogo$Express)))
expected_expression <- c("Neutral", "Happy", "Fear")

record_check(
  "Expected expression conditions are present",
  all(expected_expression %in% expression_values),
  paste("Found:", paste(expression_values, collapse = ", "))
)

# Verify that outcome counts are numeric, finite, non-negative,
# and whole numbers.
count_names <- c("AccurateNoPress", "InaccuratePress")

counts <- lapply(gonogo[count_names], function(x) {
  suppressWarnings(as.numeric(as.character(x)))
})

counts_matrix <- do.call(cbind, counts)

count_values_valid <- all(is.finite(counts_matrix))
counts_nonnegative <- count_values_valid && all(counts_matrix >= 0)
counts_integer <- count_values_valid &&
  all(abs(counts_matrix - round(counts_matrix)) < 1e-8)

record_check(
  "Outcome counts are numeric and non-missing",
  count_values_valid,
  "Checks AccurateNoPress and InaccuratePress"
)

record_check(
  "Outcome counts are non-negative",
  counts_nonnegative,
  "Counts should be zero or greater"
)

record_check(
  "Outcome counts are whole numbers",
  counts_integer,
  "Trial counts should be integers"
)

# Check that each row contains at least one counted response.
if (count_values_valid) {
  total_counts <- rowSums(counts_matrix)

  record_check(
    "Each row has at least one counted response",
    all(total_counts > 0),
    paste(sum(total_counts == 0), "rows have zero total counts")
  )
}

# Confirm that the dataset contains the required allocation group
# and post-intervention observations.
record_check(
  "Placebo allocation is present",
  any(as.character(gonogo$Allocation) == "PLACEBO", na.rm = TRUE),
  "Expected allocation label: PLACEBO"
)

record_check(
  "Post-intervention rows are present",
  any(gonogo_time == "Post", na.rm = TRUE),
  "Expected time-point label: Post or POST"
)

# Print the final report and stop if any critical check failed.
finish_checks()
