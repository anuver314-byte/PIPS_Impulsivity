#In case you want to clear the results folder from any previous data analysis and simulations

results_dir <- here::here("data and statistics", "results")
file.remove(list.files(results_dir, full.names = TRUE))