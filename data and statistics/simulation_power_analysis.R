library(readxl)
library(here)
library(dplyr)
library(lme4)

set.seed(999)

#Where all the results go
results_dir <- here("data and statistics", "results")

#We are going to use monte carlo simulations to conduct power analysis based on 
#the preliminary analyses we conducted
#The power analysis uses the original binomial GLMM as its
#data-generating model. Although preliminary diagnostics indicated
#overdispersion, the binomial specification was retained to estimate
#power under a clearly defined modelling assumption.
#The simulations do not account for the additional dispersion
#observed in the preliminary data. Power estimates may therefore
#be optimistic and should not be interpreted as definitive
#sample-size requirements.


#1. Loading analysis data and model

GoNo <- readRDS(
  here("data and statistics", "previous_data", "GoNo.rds")
)

bi_model <- readRDS(
  here("data and statistics", "results", "bi_model.rds")
)

#2.Example simulation of one dataset to show logic 

#creating a function which simulates vriables needed for a Go-NoGo analysis like ours
simulate_gonogo <- function(n_participants, model, data) {
  
  #Sample trait anxiety scores from existing participants
  participant_data <- data[
    !duplicated(data$Participant.ID),
  ]
  
  anxiety_scores <- sample(
    participant_data$STAI_c,
    size = n_participants,
    replace = TRUE
  )
  
  #Create three observations per participant
  sim_data <- expand.grid(
    Participant.ID = seq_len(n_participants),
    Express = levels(data$Express)
  )
  
  sim_data$Participant.ID <- factor(
    sim_data$Participant.ID
  )
  
  sim_data$Express <- factor(
    sim_data$Express,
    levels = levels(data$Express)
  )
  
  sim_data$STAI_c <- rep(
    anxiety_scores,
    times = nlevels(data$Express)
  )
  
  #Sample number of No-Go trials
  sim_data$n_trials <- sample(
    data$InaccuratePress + data$AccurateNoPress,
    size = nrow(sim_data),
    replace = TRUE
  )
  
  #Extract fixed effects
  beta <- fixef(model)
  
  #Construct design matrix
  X <- model.matrix(
    ~ Express * STAI_c,
    data = sim_data
  )
  
  #Extract random-intercept SD
  random_sd <- as.data.frame(
    VarCorr(model)
  )$sdcor[1]
  
  #Generate participant random intercepts
  random_intercepts <- rnorm(
    n_participants,
    mean = 0,
    sd = random_sd
  )
  
  #Linear predictor
  eta <- as.vector(X %*% beta) +
    random_intercepts[
      as.integer(sim_data$Participant.ID)
    ]
  
  #Predicted commission-error probabilities
  probability <- plogis(eta)
  
  #Generate binomial outcomes
  sim_data$InaccuratePress <- rbinom(
    nrow(sim_data),
    size = sim_data$n_trials,
    prob = probability
  )
  
  sim_data$AccurateNoPress <-
    sim_data$n_trials - sim_data$InaccuratePress
  
  sim_data$commission_error <-
    sim_data$InaccuratePress / sim_data$n_trials
  
  return(sim_data)
}

#2.1 Testing out a single simulation (optional)

sim_data <- simulate_gonogo(
  n_participants = 50,
  model = bi_model,
  data = GoNo
)

rm(sim_data)

#3.Power estimation

#3.1 Making a function which estimates power



estimate_power <- function(
    n_participants,
    model,
    data,
    simulate_fun,
    interaction,
    nsim = 100,
    alpha = 0.05,
    pb = NULL,
    progress = NULL
) {
  
  p_values <- rep(NA_real_, nsim)
  
  # Create progress bar if none was provided
  if (is.null(pb)) {
    
    pb <- txtProgressBar(
      min = 0,
      max = nsim,
      style = 3
    )
    
    progress <- new.env(parent = emptyenv())
    progress$count <- 0
    
    # Close progress bar when function finishes
    on.exit(close(pb), add = TRUE)
  }
  
  # Extract original model formula
  full_formula <- formula(model)
  
  # Remove specified interaction
  reduced_formula <- update(
    full_formula,
    paste(". ~ . -", interaction)
  )
  
  for (i in seq_len(nsim)) {
    
    p_values[i] <- tryCatch({
      
      # Generate simulated dataset
      sim_data <- simulate_fun(
        n_participants = n_participants,
        model = model,
        data = data
      )
      
      # Fit full model
      full_model <- lme4::glmer(
        formula = full_formula,
        data = sim_data,
        family = binomial,
        control = lme4::glmerControl(
          optimizer = "bobyqa",
          optCtrl = list(maxfun = 100000)
        )
      )
      
      # Fit reduced model without interaction
      reduced_model <- lme4::glmer(
        formula = reduced_formula,
        data = sim_data,
        family = binomial,
        control = lme4::glmerControl(
          optimizer = "bobyqa",
          optCtrl = list(maxfun = 100000)
        )
      )
      
      # Likelihood-ratio test
      comparison <- anova(
        reduced_model,
        full_model,
        test = "Chisq"
      )
      
      comparison$`Pr(>Chisq)`[2]
      
    }, error = function(e) {
      message("Simulation ", i, " failed: ", conditionMessage(e))
      NA_real_
    })
    
    # Update progress bar after each simulation
    if (!is.null(pb) && !is.null(progress)) {
      progress$count <- progress$count + 1
      setTxtProgressBar(pb, progress$count)
    }
  }
  
  # Identify successful simulations
  # Successful simulation = one that produces a valid p-value (between 0 and 1)
  # Failed simulations return NA (not incl. in power estimate)

  valid <- is.finite(p_values) & p_values >= 0 & p_values <= 1
  
  # Power = simulations (p < alpha) / total n simulations
  # Having few successful simulations can make this estimate unreliable
  
  n_success <- sum(valid)
  success_rate <- n_success / nsim
  
  # Require at least 90% of simulations to succeed.
  min_success_rate <- 0.90
  
  if (success_rate < min_success_rate) {
    warning(
      "Only ", n_success, " out of ", nsim,
      " simulations succeeded (",
      round(success_rate * 100, 1),
      "%). Power will be reported as NA."
    )
  }

  # Calculate power given the min success rate
  data.frame(
    N = n_participants,
    Power = if (n_success > 0 && success_rate >= min_success_rate) {
      mean(p_values[valid] < alpha)
    } else {
      NA_real_
    },
    Successful = n_success,
    Failed = nsim - n_success,
    Success_rate = round(success_rate, 3)
)
}
#This function can be used to try out different sample sizes and figure out 
#with which one you will approximately reach th desired power
#Example

power_100 <- estimate_power(
  n_participants = 100,
  model = bi_model,
  data = GoNo,
  simulate_fun = simulate_gonogo,
  interaction = "Express:STAI_c",
  nsim = 100
)
print(power_100)


rm(power_100)

#Finally, a function which runs the whole power analysis at once

run_power_analysis <- function(
    model,
    data,
    simulate_fun,
    interaction,
    sample_sizes,
    results_dir,
    nsim = 100,
    alpha = 0.05,
    seed = 123,
    filename = "power_results.csv"
) {
  
  set.seed(seed)
  
  # Set up progress bar
  progress <- new.env(parent = emptyenv())
  progress$count <- 0
  
  pb <- txtProgressBar(
    min = 0,
    max = length(sample_sizes) * nsim,
    style = 3
  )
  
  start_time <- Sys.time()
  
  # Run power simulations
  power_results <- tryCatch({
    
    do.call(
      rbind,
      lapply(sample_sizes, function(n) {
        
        estimate_power(
          n_participants = n,
          model = model,
          data = data,
          simulate_fun = simulate_fun,
          interaction = interaction,
          nsim = nsim,
          alpha = alpha,
          pb = pb,
          progress = progress
        )
      })
    )
    
  }, finally = close(pb))
  
  # Display runtime
  runtime <- as.numeric(
    difftime(Sys.time(), start_time, units = "mins")
  )
  
  cat(
    "\nTotal runtime:",
    round(runtime, 2),
    "minutes\n"
  )
  
  # Display results
  print(power_results)
  
  # Save results
  write.csv(
    power_results,
    file.path(results_dir, filename),
    row.names = FALSE
  )
  
  return(invisible(power_results))
}

#3.2 Using the function with our data

power_final <- run_power_analysis(
  model = bi_model,
  data = GoNo,
  simulate_fun = simulate_gonogo,
  interaction = "Express:STAI_c",
  sample_sizes = seq(1200, 1400, by = 50),
  results_dir = results_dir,
  nsim = 200,
  seed = 999,
  filename = "power_final.csv"
)


#Determining required sample size (if it is reached in Power_final)

required_N <- min(
  power_final$N[power_final$Power >= 0.80],
  na.rm = TRUE
)

if (is.finite(required_N)) {
  cat(
    "Estimated required sample size:",
    required_N,
    "participants\n"
  )
} else {
  cat("80% power was not reached.\n")
}
