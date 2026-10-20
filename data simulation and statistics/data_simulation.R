

library(readxl)
library(here)
library(dplyr)

#Get all necessary data

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
  rename(Participant.ID = `Participant ID`)


GoNo <- GoNo %>%
  left_join(anxiety %>%
              select(Participant.ID, STAI.total), by = "Participant.ID") %>%
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


