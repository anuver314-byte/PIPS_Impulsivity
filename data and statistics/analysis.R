
library(here)
library(dplyr)
library(ggplot2)
library(lme4)
library(DHARMa)

#this is where analysis results will be saved

results_dir <- here::here("data and statistics", "results")

#1. Loading analysis data

GoNo <- readRDS(
  here("data and statistics", "previous_data", "GoNo.rds")
)

#2. Analysis

#Selectting the time point we are working with

GoNo <- GoNo %>%
  filter(PRE.POST == "Post")

#Creating the outcome variable commission_error to use with assumption checks

GoNo <- GoNo %>%
  mutate(commission_error = InaccuratePress /
           (InaccuratePress + AccurateNoPress))

#Centering anxiety for easier interpretation of results

GoNo <- GoNo %>%
  mutate(STAI_c = STAI.total - mean(STAI.total, na.rm = TRUE))

#2.1 functions for data and assumption checks and model interpretation (binomial generalised mixed effects model)

#Defining a function that checks for missing values, variable types, repeated observations and the dependent variable


check_data_main <- function(data, id_var, condition_var,
                            continuous_var, outcome_var,
                            results_dir,
                            proportion = TRUE) {
  
  output <- capture.output({
    
    cat("MISSING VALUES\n")
    print(colSums(is.na(data)))
    
    cat("\nOBSERVATIONS PER PARTICIPANT\n")
    print(table(table(data[[id_var]])))
    
    cat("\nOBSERVATIONS PER CONDITION\n")
    print(table(data[[condition_var]], useNA = "ifany"))
    
    cat("\nCONTINUOUS PREDICTOR\n")
    print(summary(data[[continuous_var]]))
    
    cat("\nOUTCOME\n")
    print(summary(data[[outcome_var]]))
    
    if (proportion) {
      cat("\nINVALID OUTCOME PROPORTIONS\n")
      print(sum(
        data[[outcome_var]] < 0 |
          data[[outcome_var]] > 1,
        na.rm = TRUE
      ))
    }
  })
  
  cat(output, sep = "\n")
  
  writeLines(
    output,
    file.path(results_dir, "data_checks.txt")
  )
  
  # Save histogram
  png(
    file.path(results_dir, "outcome_distribution.png"),
    width = 1600, height = 1000, res = 200
  )
  
  tryCatch(
    hist(data[[outcome_var]],
         main = paste(outcome_var, "distribution"),
         xlab = outcome_var),
    finally = dev.off()
  )
  
  # Display histogram
  hist(
    data[[outcome_var]],
    main = paste(outcome_var, "distribution"),
    xlab = outcome_var
  )
  
  invisible(output)
}


#Defining a function looking at predictors' distributions and relationships


check_predictors_main <- function(data, id_var,
                                  continuous_var,
                                  condition_var,
                                  outcome_var,
                                  results_dir) {
  
  # One observation per participant
  predictor_data <- data[
    !duplicated(data[[id_var]]), ,
    drop = FALSE
  ]
  
  # Continuous predictor distribution
  p1 <- ggplot(
    predictor_data,
    aes(x = .data[[continuous_var]])
  ) +
    geom_histogram(bins = 20) +
    theme_classic() +
    labs(
      title = paste(continuous_var, "distribution"),
      x = continuous_var,
      y = "Number of participants"
    )
  
  # Predictor-outcome relationship by condition
  p2 <- ggplot(
    data,
    aes(
      x = .data[[continuous_var]],
      y = .data[[outcome_var]]
    )
  ) +
    geom_point(alpha = 0.4) +
    geom_smooth(method = "loess", se = TRUE) +
    facet_wrap(vars(.data[[condition_var]])) +
    theme_classic() +
    labs(
      title = paste(continuous_var, "and", outcome_var),
      x = continuous_var,
      y = outcome_var
    )
  
  print(p1)
  print(p2)
  
  ggsave(
    file.path(results_dir, "predictor_distribution.png"),
    plot = p1, width = 7, height = 5, dpi = 300
  )
  
  ggsave(
    file.path(results_dir, "predictor_outcome.png"),
    plot = p2, width = 8, height = 5, dpi = 300
  )
  
  invisible(list(distribution = p1, relationship = p2))
}



#Defining a function to check model assumptions


model_check_main <- function(model, results_dir,
                             nsim = 1000) {
  
  # Simulate residuals
  res <- DHARMa::simulateResiduals(
    fittedModel = model,
    n = nsim
  )
  
  # Save diagnostic plot
  png(
    file.path(results_dir, "model_diagnostics.png"),
    width = 1800, height = 900, res = 200
  )
  
  tryCatch(
    plot(res),
    finally = dev.off()
  )
  
  plot(res)
  
  # Diagnostic tests
  tests <- list(
    dispersion = DHARMa::testDispersion(res, plot = FALSE),
    outliers = DHARMa::testOutliers(res, plot = FALSE),
    uniformity = DHARMa::testUniformity(res, plot = FALSE),
    zero_inflation = DHARMa::testZeroInflation(res, plot = FALSE)
  )
  
  test_table <- data.frame(
    Test = names(tests),
    Statistic = sapply(
      tests,
      function(x) unname(x$statistic[1])
    ),
    p_value = sapply(
      tests,
      function(x) x$p.value
    )
  )
  
  print(test_table)
  
  write.csv(
    test_table,
    file.path(results_dir, "model_diagnostics.csv"),
    row.names = FALSE
  )
  
  capture.output(
    summary(model),
    file = file.path(results_dir, "model_summary.txt")
  )
  
  invisible(res)
}


#Creating a function to extract the most important statistics for the model into a table



results_model_main <- function(model, results_dir,
                               digits = 3) {
  
  results <- as.data.frame(
    summary(model)$coefficients
  )
  
  results$OR <- exp(results$Estimate)
  
  results$CI_lower <- exp(
    results$Estimate - 1.96 * results$`Std. Error`
  )
  
  results$CI_upper <- exp(
    results$Estimate + 1.96 * results$`Std. Error`
  )
  
  results$Predictor <- rownames(results)
  
  results <- results[, c(
    "Predictor", "Estimate", "Std. Error",
    "z value", "Pr(>|z|)", "OR",
    "CI_lower", "CI_upper"
  )]
  
  names(results) <- c(
    "Predictor", "Estimate", "SE", "z",
    "p", "OR", "CI_lower", "CI_upper"
  )
  
  # Round only for display and CSV
  displayed <- results
  displayed[, -1] <- round(
    displayed[, -1], digits
  )
  
  print(displayed, row.names = FALSE)
  
  write.csv(
    displayed,
    file.path(results_dir, "model_results.csv"),
    row.names = FALSE
  )
  
  # Return unrounded values
  invisible(results)
}


#Defining a function which interprets the results for us


interpret_model_main <- function(results, results_dir,
                                 alpha = 0.05) {
  
  interpretations <- capture.output({
    
    for (i in seq_len(nrow(results))) {
      
      predictor <- results$Predictor[i]
      OR <- results$OR[i]
      p <- results$p[i]
      
      significance <- if (is.na(p)) {
        "could not be evaluated"
      } else if (p < alpha) {
        "statistically significant"
      } else {
        "not statistically significant"
      }
      
      direction <- if (is.na(OR)) {
        "unknown"
      } else if (OR > 1) {
        "higher"
      } else if (OR < 1) {
        "lower"
      } else {
        "unchanged"
      }
      
      if (predictor == "(Intercept)") {
        
        interpretation <- paste(
          "Baseline odds of the outcome:",
          round(OR, 3)
        )
        
      } else if (grepl(":", predictor, fixed = TRUE)) {
        
        interpretation <- paste(
          "Interaction term:", predictor,
          "- the estimated odds ratio for this",
          "interaction is", round(OR, 3)
        )
        
      } else {
        
        interpretation <- paste(
          predictor, "is associated with",
          direction, "odds of the outcome,",
          "holding other predictors constant",
          "at their reference or zero values."
        )
      }
      
      cat(
        "\n", predictor, "\n",
        interpretation, "\n",
        "OR =", round(OR, 3),
        "| 95% CI [",
        round(results$CI_lower[i], 3), ",",
        round(results$CI_upper[i], 3), "]",
        "| p =", format.pval(p, digits = 3),
        "|", significance, "\n"
      )
    }
  })
  
  cat(interpretations, sep = "\n")
  
  writeLines(
    interpretations,
    file.path(results_dir, "model_interpretation.txt")
  )
  
  invisible(interpretations)
}


#Defining a function that interprets the interaction



interpret_interaction <- function(model, var1, var2,
                                  results_dir,
                                  alpha = 0.05) {
  
  # Construct interaction term
  interaction_term <- paste(var1, var2, sep = ":")
  
  # Fit model without interaction
  model_no_interaction <- update(
    model,
    as.formula(paste(". ~ . -", interaction_term))
  )
  
  # Compare models
  interaction_test <- anova(
    model_no_interaction,
    model,
    test = "Chisq"
  )
  
  chi2 <- interaction_test$Chisq[2]
  df <- interaction_test$`Chi Df`[2]
  p <- interaction_test$`Pr(>Chisq)`[2]
  
  # Generate interpretation
  if (is.na(p)) {
    
    interpretation <- "The interaction could not be evaluated."
    
  } else if (p < alpha) {
    
    interpretation <- paste(
      "The interaction between", var1, "and", var2,
      "was statistically significant.",
      "Including the interaction improved model fit."
    )
    
  } else {
    
    interpretation <- paste(
      "The interaction between", var1, "and", var2,
      "was not statistically significant.",
      "There was insufficient evidence that",
      "including the interaction improved model fit."
    )
  }
  
  output <- paste0(
    "OVERALL INTERACTION TEST\n\n",
    "Interaction: ", interaction_term, "\n",
    "Chi-square = ", round(chi2, 3), "\n",
    "Degrees of freedom = ", df, "\n",
    "p-value = ", format.pval(p, digits = 3),
    "\n\n", interpretation
  )
  
  cat(output, "\n")
  
  write.csv(
    as.data.frame(interaction_test),
    file.path(results_dir, "interaction_test.csv"),
    row.names = TRUE
  )
  
  writeLines(
    output,
    file.path(results_dir, "interaction_interpretation.txt")
  )
  
  invisible(interaction_test)
}


#Finally, defining a function that plots the interaction



plot_interaction <- function(model, data,
                             continuous_var,
                             condition_var,
                             results_dir) {
  
  # Create predictor values
  continuous_values <- seq(
    min(data[[continuous_var]], na.rm = TRUE),
    max(data[[continuous_var]], na.rm = TRUE),
    length.out = 100
  )
  
  # Match factor levels
  condition_values <- levels(
    factor(data[[condition_var]])
  )
  
  # Construct prediction grid
  new_data <- expand.grid(
    continuous_values,
    condition_values
  )
  
  names(new_data) <- c(
    continuous_var,
    condition_var
  )
  
  new_data[[condition_var]] <- factor(
    new_data[[condition_var]],
    levels = condition_values
  )
  
  # Population-level predictions
  new_data$predicted <- predict(
    model,
    newdata = new_data,
    type = "response",
    re.form = NA
  )
  
  # Plot
  p <- ggplot(
    new_data,
    aes(
      x = .data[[continuous_var]],
      y = predicted,
      colour = .data[[condition_var]]
    )
  ) +
    geom_line(linewidth = 1.2) +
    scale_y_continuous(
      labels = scales::label_percent(),
      limits = c(0, 1)
    ) +
    labs(
      title = paste(
        "Interaction between",
        continuous_var, "and", condition_var
      ),
      x = continuous_var,
      y = "Predicted probability",
      colour = condition_var
    ) +
    theme_classic(base_size = 12)
  
  print(p)
  
  ggsave(
    file.path(results_dir, "interaction_plot.png"),
    plot = p,
    width = 9,
    height = 6,
    dpi = 300
  )
  
  invisible(p)
}



#2.2 Main Analysis (binomial generalised mixed effects model)

#Data checks
check_data_main(
  GoNo, "Participant.ID", "Express",
  "STAI.total", "commission_error",
  results_dir
)

#Predictor checks
check_predictors_main(
  GoNo, "Participant.ID", "STAI.total",
  "Express", "commission_error",
  results_dir
)

#Fitting the model

bi_model <- lme4::glmer(
  cbind(InaccuratePress, AccurateNoPress) ~
    Express * STAI_c +
    (1 | Participant.ID),
  data = GoNo,
  family = binomial
)

#Model diagnostics
model_check_main(bi_model, results_dir)

#Extract model results
results <- results_model_main(bi_model, results_dir)

#Interpret coefficients
interpret_model_main(results, results_dir)

#Interpret interaction
interpret_interaction(
  bi_model, "Express", "STAI_c", results_dir
)

#Plot interaction
plot_interaction(
  bi_model, GoNo, "STAI_c", "Express",
  results_dir
)

#Saving the model for the power analysis

saveRDS(
  bi_model,
  file = here::here("data and statistics", "results", "bi_model.rds")
)

