library(readxl)
library(here)
library(dplyr)
library(lme4)

set.seed(999)

#Where all the results go
results_dir <- here("data and statistics", "results")

#We are going to use monte carlo simulations to conduct power analysis based on the preliminary analyses we conducted
#A single-simulation example is included


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

#Fitting model
sim_model <- glmer(
  cbind(InaccuratePress, AccurateNoPress) ~
    Express * STAI_c +
    (1 | Participant.ID),
  data = sim_data,
  family = binomial
)

#Fittng model without the interaction
sim_model_reduced <- update(
  sim_model,
  . ~ . - Express:STAI_c
)

#Comparing
anova(
  sim_model_reduced,
  sim_model,
  test = "Chisq"
)


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
  
  # Extract the original model formula
  full_formula <- formula(model)
  
  # Remove the specified interaction
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
      
      # Fit model without interaction
      reduced_model <- update(
        full_model,
        formula = reduced_formula
      )
      
      # Likelihood-ratio test
      comparison <- anova(
        reduced_model,
        full_model,
        test = "Chisq"
      )
      
      comparison$`Pr(>Chisq)`[2]
      
    }, error = function(e) NA_real_)
    
    # Update progress bar
    if (!is.null(pb) && !is.null(progress)) {
      progress$count <- progress$count + 1
      setTxtProgressBar(pb, progress$count)
    }
  }
  
  valid <- !is.na(p_values)
  
  data.frame(
    N = n_participants,
    Power = if (any(valid)) {
      mean(p_values[valid] < alpha)
    } else {
      NA_real_
    },
    Successful = sum(valid),
    Failed = sum(!valid)
  )
}


#Finally, a function which runs the whole power analysis a once

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


#Determining required sample size

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
