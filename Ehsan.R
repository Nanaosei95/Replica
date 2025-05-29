library(tidyverse)
library(haven) 
library(modelsummary) 

theme_set(theme_minimal()) 

list.files(DATA)

rlang::last_trace()
rlang::last_trace(drop = FALSE)


BASE <- "C:/Users/attef/OneDrive/Documents/Replica"
DATA <- file.path(BASE, "analysis", "data")
RESULTS <- file.path(BASE, "analysis", "results")
FIGURES <- file.path(BASE, "paper", "figures")
TABLES <- file.path(BASE, "paper", "tables")
SIM <- file.path(BASE, "analysis", "simulation")

retailer1 <- read_csv(file.path(DATA, "google_search_shares.csv")) %>%
  mutate(price = as.numeric(price)) %>%
  filter(!is.na(price))
write_csv(retailer1, file.path(DATA, "google_search_shares.csv"))
