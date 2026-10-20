
library(readxl)
library(here)
library(dplyr)
library(ggplot2)
library(lme4)
library(DHARMa)



#1. Data preparation (applicable only to the downloaded data set based on problems I've encountered)

#Get all necessary data
#These files where acquired from the publicly available repository for the referenced study* by running the provided .Rmd file and saving the data

GoNo <- read.csv(here(
  "data simulation and statistics",
  "previous_data",
  "study_data.csv"
))

anxiety <- read_excel(
  here(
    "data simulation and statistics",
    "previous_data",
    "PREPOST_questionnaires_combined.xlsx"
  )
)

#Merge the two df and remove unnecessary columns 

anxiety <- anxiety %>%
  rename(Participant.ID = `Participant ID`) %>%
  mutate(
    PRE.POST = dplyr::recode(
      PRE.POST,
      "PRE" = "Baseline",
      "POST" = "Post"
    )
  )


GoNo <- GoNo %>%
  left_join(anxiety %>%
              dplyr::select(all_of(c("Participant.ID", "PRE.POST", "STAI.total"))), by = c("Participant.ID", "PRE.POST")) %>%
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


#remove NA from STAI.total and make it numeric

GoNo <- GoNo %>%
  mutate(STAI.total = na_if(STAI.total, "NA"))

GoNo <- GoNo %>%
  group_by(Participant.ID) %>%
  tidyr::fill(STAI.total, .direction = "downup") %>%
  ungroup()

GoNo <- GoNo %>%
  mutate(
    STAI.total = as.numeric(as.character(STAI.total))
  )



#2. Analysis

#Select the time point we are working with

GoNo <- GoNo %>%
  filter(PRE.POST == "Post") 

#Creating the outcome variable commission_error to use with assumption checks

GoNo <- GoNo %>%
  mutate(
    comission_error = InaccuratePress /
      (InaccuratePress + AccurateNoPress)
  )



#2.1 functions for data and assumption checks (binomial generalised mixed effects model)

#Defining a function that checks for missing values, variable types, repeated observations and the dependent variable

data_check <- function(data) {
  
  #Missing values
  print(colSums(is.na(data)))
  
  #Number of observations per participant
  print(table(table(data$Participant.ID)))
  
  #Number of observations per emotional condition
  print(table(data$Express, useNA = "ifany"))
  
  #Trait anxiety summary
  print(summary(data$STAI.total))
  
  #Commission error summary
  print(summary(data$CommissionError))
  
  #Commission error distribution
  hist(data$comission_error,
       main = "Commission error distribution",
       xlab = "Commission error rate")
  
  #Check whether commission errors are valid proportions
  print(sum(data$comission_error < 0 |
              data$comission_error > 1,
            na.rm = TRUE))
}



#Defining a function looking at the distribution of anxiety and its relationship with comission errors per emotional condition

predictors_check <- function(data) {
  
  
  #Participant-level anxiety distribution
  anxiety_data <- data[!duplicated(data$Participant.ID), ]
  
  print(
    ggplot(anxiety_data, aes(x = STAI.total)) +
      geom_histogram(bins = 20) +
      theme_classic() +
      labs(title = "Trait anxiety distribution")
  )
  
  #Anxiety and commission errors by condition
  print(
    ggplot(data,
           aes(x = STAI.total,
               y = comission_error)) +
      geom_point(alpha = 0.4) +
      geom_smooth(method = "loess", se = TRUE) +
      facet_wrap(~ Express) +
      theme_classic() +
      labs(title = "Trait anxiety and commission errors")
  )
}


#Defining a function to check model assumptions

model_check <- function(model) {
  
  #Convergence messages
  print(model@optinfo$conv$lme4$messages)
  
  #Singular fit
  print(isSingular(model))
  
  #Simulated residuals
  residuals_sim <- simulateResiduals(
    fittedModel = model,
    n = 1000
  )
  
  #Diagnostic plots
  plot(residuals_sim)
  
  #Dispersion
  print(testDispersion(residuals_sim))
  
  #Zero inflation
  print(testZeroInflation(residuals_sim))
  
  #Residual uniformity
  print(testUniformity(residuals_sim))
  
  invisible(residuals_sim)
}


#1.2 Main Analysis (binomial generalised mixed effects model)

#Before fitting
data_check(GoNo)
predictors_check(GoNo)

#Centering anxiety for easier interpretation of results

GoNo <- GoNo %>%
  mutate(
    STAI_c = STAI.total - mean(STAI.total, na.rm = TRUE)
  )

#Fitting the model

model <- lme4::glmer(
  cbind(InaccuratePress, AccurateNoPress) ~
    Express * STAI_c +
    (1 | Participant.ID),
  data = GoNo,
  family = binomial
)

#After fitting

res <- model_check(model)
plotResiduals(res, GoNo$STAI_c)
plotResiduals(res, GoNo$Express)

#The tests show significant dispersion so we need to check the data
DHARMa::testDispersion(res)

#Running further outliers tests and identifying th outliers
DHARMa::testOutliers(res)
outlier_rows <- which(
  res$scaledResiduals == 0 |
    res$scaledResiduals == 1
)

GoNo[outlier_rows, ]

