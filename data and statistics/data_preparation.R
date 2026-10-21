library(readxl)
library(here)
library(dplyr)

#Data preparation (applicable only to the downloaded data set based on problems I've encountered)

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

#saving data

saveRDS(
  GoNo,
  file = here::here("data and statistics", "previous_data", "GoNo.rds")
)
