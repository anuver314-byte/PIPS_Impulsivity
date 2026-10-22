
# Error checks for the statistics input data
# Run from the local copy of TM's working-branch project.

# Locate the two input files in the local project
gonogo_file <- here::here(
  "data and statistics", "previous_data", "study_data.csv"
)

questionnaire_file <- here::here(
  "data and statistics", "previous_data",
  "PREPOST_questionnaires_combined.xlsx"
)

# Record each check
check_results <- data.frame(
  Check = character(),
  Status = character(),
  Details = character(),
  stringsAsFactors = FALSE
)

record_check <- function(name, passed, details = "") {
  status <- if (isTRUE(passed)) "PASS" else "FAIL"
  
  check_results <<- rbind(
    check_results,
    data.frame(
      Check = name,
      Status = status,
      Details = details,
      stringsAsFactors = FALSE
    )
  )
  
  cat(status, "-", name, "-", details, "\n")
}

cat("Project root:", here::here(), "\n\n")

# Check whether the files exist locally
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

# Stop if either input file is missing
if (!gonogo_exists || !questionnaire_exists) {
  print(check_results)
  stop(
    "Input file(s) missing. Check the project root and file paths."
  )
}

# Read the files
if (!requireNamespace("readxl", quietly = TRUE)) {
  stop("Package 'readxl' is missing. Run install.packages('readxl').")
}

gonogo <- tryCatch(
  read.csv(gonogo_file, stringsAsFactors = FALSE),
  error = function(e) {
    record_check("Go/No-Go CSV can be read", FALSE, conditionMessage(e))
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

if (is.null(gonogo) || is.null(questionnaires)) {
  print(check_results)
  stop("Could not read one or both input files.")
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

# Check required columns
required_gonogo <- c(
  "Participant.ID", "PRE.POST", "Express", "Allocation",
  "AccurateNoPress", "InaccuratePress"
)

required_questionnaire <- c(
  "Participant ID", "PRE.POST", "STAI.total"
)

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

# Stop further checks if the columns needed below are absent
if (length(missing_gonogo) > 0 ||
    length(missing_questionnaire) > 0) {
  print(check_results)
  stop("Required columns are missing; check the source files.")
}

# Check participant IDs and time-point labels
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

normalise_time <- function(x) {
  x <- trimws(as.character(x))
  x[x == "PRE"] <- "Baseline"
  x[x == "POST"] <- "Post"
  x
}

gonogo_time <- normalise_time(gonogo$PRE.POST)
questionnaire_time <- normalise_time(questionnaires$PRE.POST)

valid_times <- c("Baseline", "Post")

record_check(
  "Go/No-Go time-point labels are recognised",
  all(na.omit(gonogo_time) %in% valid_times) &&
    !all(is.na(gonogo_time)),
  paste("Found:", paste(unique(gonogo_time), collapse = ", "))
)

record_check(
  "Questionnaire time-point labels are recognised",
  all(na.omit(questionnaire_time) %in% valid_times) &&
    !all(is.na(questionnaire_time)),
  paste("Found:", paste(unique(questionnaire_time), collapse = ", "))
)

# Check whether participant/time-point keys can match across files
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

gonogo_keys <- gonogo_keys[
  !is.na(gonogo_keys$id) & !is.na(gonogo_keys$time),
]
questionnaire_keys <- questionnaire_keys[
  !is.na(questionnaire_keys$id) & !is.na(questionnaire_keys$time),
]

gonogo_key <- paste(gonogo_keys$id, gonogo_keys$time, sep = "||")
questionnaire_key <- paste(
  questionnaire_keys$id, questionnaire_keys$time, sep = "||"
)

matched_keys <- intersect(gonogo_key, questionnaire_key)

record_check(
  "Participant/time-point keys overlap across files",
  length(matched_keys) > 0,
  paste(
    length(matched_keys), "matching keys;",
    length(setdiff(gonogo_key, questionnaire_key)),
    "Go/No-Go keys unmatched"
  )
)

# Check questionnaire anxiety scores
anxiety <- suppressWarnings(
  as.numeric(as.character(questionnaires$STAI.total))
)

record_check(
  "Questionnaire anxiety scores contain usable numeric values",
  any(is.finite(anxiety)),
  paste(sum(is.finite(anxiety)), "usable scores")
)

# Check Go/No-Go expression labels
expression_values <- unique(na.omit(as.character(gonogo$Express)))
expected_expression <- c("Neutral", "Happy", "Fear")

record_check(
  "Expected expression conditions are present",
  all(expected_expression %in% expression_values),
  paste("Found:", paste(expression_values, collapse = ", "))
)

# Check outcome counts
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

if (count_values_valid) {
  total_counts <- rowSums(counts_matrix)
  
  record_check(
    "Each row has at least one counted response",
    all(total_counts > 0),
    paste(sum(total_counts == 0), "rows have zero total counts")
  )
}

# Check allocation and post-intervention data
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

# Print the final report
cat("\n========== FINAL CHECK REPORT ==========\n")
print(check_results, row.names = FALSE)

cat(
  "\nPassed:", sum(check_results$Status == "PASS"),
  "\nFailed:", sum(check_results$Status == "FAIL"),
  "\nTotal:", nrow(check_results), "\n"
)
