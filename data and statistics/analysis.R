library(readxl)
library(here)
library(dplyr)
library(ggplot2)
library(lme4)
library(DHARMa)

#this is where analysis results will be saved

results_dir <- here("data and statistics", "results")

#1. Data preparation (applicable only to the downloaded data set based on problems I've encountered)

#Get all necessary data
#These files where acquired from the publicly available repository for the referenced study* by running the provided .Rmd file and saving the data

GoNo <- read.csv(here("data and statistics", "previous_data", "study_data.csv"))

anxiety <- read_excel(
  here(
    "data and statistics",
    "previous_data",
    "PREPOST_questionnaires_combined.xlsx"
  )
)

#Merge the two df and remove unnecessary columns

anxiety <- anxiety %>%
  rename(Participant.ID = `Participant ID`) %>%
  mutate(PRE.POST = dplyr::recode(PRE.POST, "PRE" = "Baseline", "POST" = "Post"))


GoNo <- GoNo %>%
  left_join(anxiety %>%
              dplyr::select(all_of(
                c("Participant.ID", "PRE.POST", "STAI.total")
              )),
            by = c("Participant.ID", "PRE.POST")) %>%
  select(
    Participant.ID,
    PRE.POST,
    RealorPractice,
    HotorColdTrial,
    Express,
    GoRTmean,
    GoRTsd,
    RT_hits_corr,
    AccuratePress,
    AccurateNoPress,
    InaccuratePress,
    InaccurateNoPress,
    Allocation,
    STAI.total
  ) %>%
  filter(Allocation == "PLACEBO")

rm(anxiety)


#removing NA from STAI.total and making it numeric

GoNo <- GoNo %>%
  mutate(STAI.total = na_if(STAI.total, "NA"))

GoNo <- GoNo %>%
  group_by(Participant.ID) %>%
  tidyr::fill(STAI.total, .direction = "downup") %>%
  ungroup()

GoNo <- GoNo %>%
  mutate(STAI.total = as.numeric(as.character(STAI.total)))

#Turning Express into a factor so the analysis can be carried out

GoNo <- GoNo %>%
  mutate(Express = factor(Express, levels = c("Neutral", "Happy", "Fear")))

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

check_data_main <- function(data) {
  #Save summary statistics
  output <- capture.output({
    cat("MISSING VALUES\n")
    print(colSums(is.na(data)))
    
    cat("\nOBSERVATIONS PER PARTICIPANT\n")
    print(table(table(data$Participant.ID)))
    
    cat("\nOBSERVATIONS PER CONDITION\n")
    print(table(data$Express, useNA = "ifany"))
    
    cat("\nTRAIT ANXIETY\n")
    print(summary(data$STAI.total))
    
    cat("\nCOMMISSION ERROR RATE\n")
    print(summary(data$commission_error))
    
    cat("\nINVALID COMMISSION ERROR PROPORTIONS\n")
    print(sum(data$commission_error < 0 |
                data$commission_error > 1, na.rm = TRUE))
    
  })
  
  #Display summaries
  cat(output, sep = "\n")
  
  #Save summaries
  writeLines(output, file.path(results_dir, "data_checks.txt"))
  
  #Save histogram
  png(
    file.path(results_dir, "commission_error_distribution.png"),
    width = 1600,
    height = 1000,
    res = 200
  )
  
  hist(data$commission_error, main = "Commission error distribution", xlab = "Commission error rate")
  
  dev.off()
  
  #Display histogram
  hist(data$commission_error, main = "Commission error distribution", xlab = "Commission error rate")
}


#Defining a function looking at the distribution of anxiety and its relationship with comission errors per emotional condition


check_predictors_main <- function(data) {
  #One row per participant
  anxiety_data <- data[!duplicated(data$Participant.ID), ]
  
  #Trait anxiety histogram
  p1 <- ggplot(anxiety_data, aes(x = STAI.total)) +
    geom_histogram(bins = 20) +
    theme_classic() +
    labs(title = "Trait anxiety distribution", x = "STAI-T score", y = "Number of participants")
  
  #Anxiety and commission errors
  p2 <- ggplot(data, aes(x = STAI.total, y = commission_error)) +
    geom_point(alpha = 0.4) +
    geom_smooth(method = "loess", se = TRUE) +
    facet_wrap( ~ Express) +
    theme_classic() +
    labs(title = "Trait anxiety and commission errors", x = "STAI-T score", y = "Commission error rate")
  
  #Display plots
  print(p1)
  print(p2)
  
  #Save plots
  ggsave(
    file.path(results_dir, "anxiety_distribution.png"),
    plot = p1,
    width = 7,
    height = 5,
    dpi = 300
  )
  
  ggsave(
    file.path(results_dir, "anxiety_commission_errors.png"),
    plot = p2,
    width = 8,
    height = 5,
    dpi = 300
  )
}



#Defining a function to check model assumptions


model_check_main <- function(model) {
  #Simulate residuals
  res <- simulateResiduals(fittedModel = model, n = 1000)
  
  #Save diagnostic plot
  png(
    file.path(results_dir, "model_diagnostics.png"),
    width = 1800,
    height = 900,
    res = 200
  )
  
  plot(res)
  dev.off()
  
  #Display diagnostic plot
  plot(res)
  
  #Diagnostic tests
  tests <- list(
    dispersion = testDispersion(res, plot = FALSE),
    outliers = testOutliers(res, plot = FALSE),
    uniformity = testUniformity(res, plot = FALSE),
    zero_inflation = testZeroInflation(res, plot = FALSE)
  )
  
  #Create results table
  test_table <- data.frame(
    Test = names(tests),
    Statistic = sapply(tests, function(x)
      unname(x$statistic[1])),
    p_value = sapply(tests, function(x)
      x$p.value)
  )
  
  print(test_table)
  
  #Save table
  write.csv(test_table,
            file.path(results_dir, "model_diagnostics.csv"),
            row.names = FALSE)
  
  #Save model summary
  capture.output(summary(model), file = file.path(results_dir, "model_summary.txt"))
  
  invisible(res)
}


#Creating a function to extract the most important statistics for the model into a table


results_model_main <- function(model) {
  results <- as.data.frame(summary(model)$coefficients)
  
  #Odds ratios
  results$OR <- exp(results$Estimate)
  
  #95% Wald confidence intervals
  results$CI_lower <- exp(results$Estimate - 1.96 * results$`Std. Error`)
  
  results$CI_upper <- exp(results$Estimate + 1.96 * results$`Std. Error`)
  
  #Predictor names
  results$Predictor <- rownames(results)
  
  #Select columns
  results <- results[, c(
    "Predictor",
    "Estimate",
    "Std. Error",
    "z value",
    "Pr(>|z|)",
    "OR",
    "CI_lower",
    "CI_upper"
  )]
  
  names(results) <- c("Predictor",
                      "Estimate",
                      "SE",
                      "z",
                      "p",
                      "OR",
                      "CI_lower",
                      "CI_upper")
  
  #Round values
  results[, -1] <- round(results[, -1], 3)
  
  #Display
  print(results, row.names = FALSE)
  
  #Save
  write.csv(results,
            file.path(results_dir, "model_results.csv"),
            row.names = FALSE)
  
  return(invisible(results))
}


#Defining a function which interprets the results for us

interpret_model_main <- function(results, alpha = 0.05) {
  #Generate interpretations
  interpretations <- capture.output({
    for (i in seq_len(nrow(results))) {
      predictor <- results$Predictor[i]
      OR <- results$OR[i]
      p <- results$p[i]
      
      # Statistical significance
      significance <- if (is.na(p)) {
        "could not be evaluated"
      } else if (p < alpha) {
        "statistically significant"
      } else {
        "not statistically significant"
      }
      
      # Direction of effect
      direction <- if (OR > 1) {
        "higher"
      } else if (OR < 1) {
        "lower"
      } else {
        "unchanged"
      }
      
      #Interpret predictors
      interpretation <- if (predictor == "(Intercept)") {
        paste(
          "For an average-anxiety participant in the neutral",
          "condition, the baseline odds of a commission error are",
          round(OR, 3)
        )
        
      } else if (grepl("Express", predictor) &&
                 grepl("STAI_c", predictor)) {
        paste(
          "The association between trait anxiety and commission",
          "errors differs between this emotional condition and",
          "the neutral condition.",
          "Interaction OR =",
          round(OR, 3)
        )
        
      } else if (grepl("Express", predictor)) {
        paste(
          "Compared with neutral trials, this emotional condition",
          "is associated with",
          direction,
          "odds of commission errors at average trait anxiety."
        )
        
      } else if (predictor == "STAI_c") {
        paste(
          "In neutral trials, higher trait anxiety is associated",
          "with",
          direction,
          "odds of commission errors."
        )
        
      } else {
        "No interpretation available for this predictor."
        
      }
      
      # Print each interpretation
      cat(
        "\n",
        predictor,
        "\n",
        interpretation,
        "\n",
        "OR =",
        OR,
        "| 95% CI [",
        results$CI_lower[i],
        ",",
        results$CI_upper[i],
        "]",
        "| p =",
        p,
        "|",
        significance,
        "\n"
      )
    }
  })
  
  #Display interpretations
  cat(interpretations, sep = "\n")
  
  #Automatically save interpretations
  writeLines(interpretations,
             file.path(results_dir, "model_interpretation.txt"))
  
  invisible(interpretations)
}

#Defining a function that interprets the interaction


interpret_interaction <- function(model, alpha = 0.05) {
  #Fit model without interaction
  model_no_interaction <- update(model, . ~ . - Express:STAI_c)
  
  #Compare models
  interaction_test <- anova(model_no_interaction, model, test = "Chisq")
  
  #Extract statistics
  chi2 <- interaction_test$Chisq[2]
  df <- interaction_test$`Chi Df`[2]
  p <- interaction_test$`Pr(>Chisq)`[2]
  
  #Generate interpretation
  if (is.na(p)) {
    interpretation <- paste("The interaction test could not be evaluated.")
    
  } else if (p < alpha) {
    interpretation <- paste(
      "The overall interaction between emotional valence",
      "and trait anxiety was statistically significant.",
      "Including the interaction significantly improved",
      "model fit, suggesting that the association between",
      "trait anxiety and commission errors differs across",
      "emotional conditions."
    )
    
  } else {
    interpretation <- paste(
      "The overall interaction between emotional valence",
      "and trait anxiety was not statistically significant.",
      "Including the interaction did not significantly improve",
      "model fit. There is insufficient evidence that the",
      "association between trait anxiety and commission errors",
      "differs across emotional conditions."
    )
    
  }
  
  #Format results
  output <- paste0(
    "OVERALL INTERACTION TEST\n\n",
    "Chi-square = ",
    round(chi2, 3),
    "\n",
    "Degrees of freedom = ",
    df,
    "\n",
    "p-value = ",
    format.pval(p, digits = 3),
    "\n\n",
    interpretation
  )
  
  #Display interpretation
  cat(output, "\n")
  
  #Save statistical table
  write.csv(
    as.data.frame(interaction_test),
    file.path(results_dir, "interaction_test.csv"),
    row.names = TRUE
  )
  
  #Save interpretation
  writeLines(output,
             file.path(results_dir, "interaction_interpretation.txt"))
  
  invisible(interaction_test)
}

#Finally, defining a function that plots the interaction


plot_interaction <- function(model, data) {
  #Create a sequence of trait anxiety scores
  new_data <- expand.grid(STAI_c = seq(
    min(data$STAI_c, na.rm = TRUE),
    max(data$STAI_c, na.rm = TRUE),
    length.out = 100
  ),
  Express = levels(data$Express))
  
  #Ensure the factor levels match the original data
  new_data$Express <- factor(new_data$Express, levels = levels(data$Express))
  
  #Predict commission error probabilities
  new_data$predicted <- predict(model,
                                newdata = new_data,
                                type = "response",
                                re.form = NA)
  
  #Create interaction plot
  p <- ggplot(new_data, aes(x = STAI_c, y = predicted, colour = Express)) +
    geom_line(linewidth = 1.2) +
    scale_y_continuous(labels = scales::label_percent(),
                       limits = c(0, 1)) +
    labs(
      title = "Interaction between emotional valence and trait anxiety",
      x = "Trait anxiety (mean-centred STAI-T)",
      y = "Predicted probability of commission errors",
      colour = "Emotional valence"
    ) +
    theme_classic(base_size = 12)
  
  #Display plot
  print(p)
  
  #Automatically save plot
  ggsave(
    filename = file.path(results_dir, "interaction_plot.png"),
    plot = p,
    width = 9,
    height = 6,
    dpi = 300
  )
  
  invisible(p)
}


#2.2 Main Analysis (binomial generalised mixed effects model)

#Before fitting
check_data_main(GoNo)
check_predictors_main(GoNo)

#Fitting the model

bi_model <- lme4::glmer(
  cbind(InaccuratePress, AccurateNoPress) ~
    Express * STAI_c +
    (1 | Participant.ID),
  data = GoNo,
  family = binomial
)

#After fitting

res <- model_check_main(bi_model)

#Save residuals vs STAI
png(
  file.path(results_dir, "residuals_STAI.png"),
  width = 1600,
  height = 1000,
  res = 200
)

DHARMa::plotResiduals(res, GoNo$STAI_c)
dev.off()

#Display in rstudio (optional)

DHARMa::plotResiduals(res, GoNo$STAI_c)

#Save residuals vs emotional valence
png(
  file.path(results_dir, "residuals_Express.png"),
  width = 1600,
  height = 1000,
  res = 200
)

DHARMa::plotResiduals(res, GoNo$Express)
dev.off()

#Also display in rstudio (optional) (optional)
DHARMa::plotResiduals(res, GoNo$Express)


#Model Interpretation

bi_results <- results_model_main(bi_model)
interpret_model_main(bi_results)


#Test of the interaction between anxiety and emotion (main hypothesis) + plot

interpret_interaction(bi_model)
plot_interaction(bi_model, GoNo)







