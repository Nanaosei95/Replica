library(tidyverse)  # For pipes (%>%), read_csv(), mutate(), etc.
library(haven)      # For reading Stata (.dta) files
library(readxl)
library(modelsummary) 
library(tidyr)
library(ggplot2)


theme_set(theme_minimal()) 

list.files(DATA)
colnames(excel_data)



rlang::last_trace()
rlang::last_trace(drop = FALSE)


BASE <- "C:/Users/attef/OneDrive/Documents/Replicaproject/Replica"
DATA <- file.path(BASE, "analysis", "data")
RESULTS <- file.path(BASE, "analysis", "results")
FIGURES <- file.path(BASE, "paper", "figures")
TABLES <- file.path(BASE, "paper", "tables")
SIM <- file.path(BASE, "analysis", "simulation")

# Load the CSV file
google_data <- read_csv(file.path(DATA, "google_search_shares.csv"))
# Check what's inside
glimpse(google_data) 

df <- read_dta(file.path(DATA, "analysis_data.dta"))
stata_data <- read_dta(file.path(DATA, "analysis_data.dta"))
# View column names or structure
glimpse(stata_data)
glimpse(df)
rm(df)
df %>%
  filter(!is.na(price)) %>%
  group_by(date) %>%
  summarise(avg_price = mean(price)) %>%
  ggplot(aes(x = date, y = avg_price)) +
  geom_line() +
  labs(title = "Average Price Over Time")

df %>%
  filter(!is.na(price)) %>%
  group_by(date) %>%
  summarise(avg_price = mean(price)) %>%
  ggplot(aes(x = date, y = avg_price)) +
  geom_line(color = "steelblue") +
  labs(title = "Average Price Over Time",
       x = "Date",
       y = "Average Price") +
  theme_minimal()

df %>%
  filter(!is.na(price)) %>%
  group_by(date, website) %>%
  summarise(avg_price = mean(price), .groups = "drop") %>%
  ggplot(aes(x = date, y = avg_price, color = website)) +
  geom_line() +
  labs(title = "Price Trends by Website",
       x = "Date",
       y = "Average Price") +
  theme_minimal()

df %>%
  filter(!is.na(price)) %>%
  ggplot(aes(x = price)) +
  geom_histogram(bins = 50, fill = "skyblue", color = "white") +
  labs(title = "Distribution of Prices",
       x = "Price",
       y = "Count") +
  theme_minimal()

df %>%
  filter(!is.na(price)) %>%
  group_by(brand) %>%
  summarise(avg_price = mean(price), .groups = "drop") %>%
  arrange(desc(avg_price)) %>%
  top_n(10, avg_price) %>%
  ggplot(aes(x = reorder(brand, avg_price), y = avg_price)) +
  geom_col(fill = "darkgreen") +
  coord_flip() +
  labs(title = "Top 10 Brands by Average Price",
       x = "Brand",
       y = "Average Price") +
  theme_minimal()


excel_data <- read_excel(file.path(DATA, "ecommerce_revenue_data.xlsx"))
# Check structure
glimpse(excel_data)
excel_data <- excel_data %>%

    


print(google_data)

google_long <- google_data %>%
  pivot_longer(cols = -website, names_to = "search_type", values_to = "share")

head(google_long)

ggplot(google_long, aes(x = website, y = share, fill = search_type)) +
  geom_col(position = "dodge") +
  labs(title = "Google Search Share by Website and Search Type")

