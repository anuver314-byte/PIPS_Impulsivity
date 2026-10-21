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
    data$n_trials,
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

#3.1 Making a power est. function (with a progress bar!)

estimate_power <- function(
    n_participants,
    nsim = 100,
    alpha = 0.05,
    pb = NULL,
    progress = NULL
) {
  
  p_values <- rep(NA_real_, nsim)
  
  for (i in seq_len(nsim)) {
    
    sim_data <- simulate_gonogo(
      n_participants = n_participants,
      model = bi_model,
      data = GoNo
    )
    
    p_values[i] <- tryCatch({
      
      full_model <- glmer(
        cbind(InaccuratePress, AccurateNoPress) ~
          Express * STAI_c +
          (1 | Participant.ID),
        data = sim_data,
        family = binomial,
        control = glmerControl(
          optimizer = "bobyqa",
          optCtrl = list(maxfun = 100000)
        )
      )
      
      reduced_model <- update(
        full_model,
        . ~ . - Express:STAI_c
      )
      
      comparison <- anova(
        reduced_model,
        full_model,
        test = "Chisq"
      )
      
      comparison$`Pr(>Chisq)`[2]
      
    }, error = function(e) NA_real_)
    
    #Update shared progress bar
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


#3.2 Power estimation 
#I did this a few times to determine what sample size could achieve power .80
#Since the code is essentially the same each time I've retained the final calculations


#Go make some tea, this will take a while
set.seed(999)

sample_sizes_final <- seq(1200, 1400, by = 50)
nsim <- 200

#Set up progress bar
progress <- new.env(parent = emptyenv())
progress$count <- 0

pb <- txtProgressBar(
  min = 0,
  max = length(sample_sizes_final) * nsim,
  style = 3
)

start_time <- Sys.time()

power_final <- tryCatch({
  
  do.call(
    rbind,
    lapply(sample_sizes_final, function(n) {
      
      estimate_power(
        n_participants = n,
        nsim = nsim,
        pb = pb,
        progress = progress
      )
    })
  )
  
}, finally = close(pb))

#Display runtime
cat(
  "\nRuntime:",
  round(
    as.numeric(difftime(Sys.time(), start_time, units = "mins")),
    2
  ),
  "minutes\n"
)

print(power_final)

#Save results
write.csv(
  power_final,
  file.path(results_dir, "power_final.csv"),
  row.names = FALSE
)


#Plotting a power curve

p_final <- ggplot(
  power_final,
  aes(x = N, y = Power)
) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  geom_hline(
    yintercept = 0.80,
    linetype = "dashed"
  ) +
  scale_y_continuous(
    limits = c(0, 1),
    labels = scales::label_percent()
  ) +
  labs(
    title = "Final simulation-based power analysis",
    subtitle = "Emotional valence × trait anxiety interaction",
    x = "Number of participants",
    y = "Estimated statistical power"
  ) +
  theme_classic()

print(p_final)

ggsave(
  file.path(results_dir, "power_curve_final.png"),
  plot = p_final,
  width = 9,
  height = 6,
  dpi = 300
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
