library(data.table)
library(haven)
library(ggplot2)
library(dplyr)
library(tidyr)
library(zoo)
library(lubridate)

data <- read_dta("C:/Users/attef/OneDrive/Documents/Replicaproject/Replica/analysis/data/analysis_data.dta")
df <- as.data.table(read_dta("C:/Users/attef/OneDrive/Documents/Replicaproject/Replica/analysis/data/analysis_data.dta"))

xyzal <- df[brand == "Xyzal" & form == "Tablet" & size == 80 & multipack == 1]
xyzal <- xyzal[, .SD[.N == 1], by = .(website, period_id)]  # equivalent to 'assert _n == 1'
xyzal[flag_imputed_price == 1, price := NA]

ggplot(xyzal, aes(x = period_id, y = price, color = website)) +
  geom_line(alpha = 0.8) +
  scale_color_manual(values = c("A" = "black", "B" = "darkolivegreen", 
                                "C" = "navy", "D" = "maroon", "E" = "orange")) +
  labs(y = "Price", x = "Hours Elapsed in Sample") +
  theme_minimal()
ggsave("C:/Users/attef/OneDrive/Documents/Replicaproject/Replica/xyzal_tablet_80.pdf")


claritin <- df[brand == "Claritin" & form == "Tablet" & size == 70 & multipack == 1]
claritin <- claritin[, .SD[.N == 1], by = .(website, period_id)]
claritin[flag_imputed_price == 1, price := NA]

ggplot(claritin, aes(x = period_id, y = price, color = website)) +
  geom_line(alpha = 0.8) +
  scale_color_manual(values = c("A" = "black", "B" = "darkolivegreen", 
                                "C" = "navy", "D" = "maroon", "E" = "orange")) +
  labs(y = "Price", x = "Hours Elapsed in Sample") +
  theme_minimal()
ggsave("C:/Users/attef/OneDrive/Documents/Replicaproject/Replica/xyzal_tablet_70.pdf")


# Create necessary variables
df <- df[order(website, product_website_id, date)]
df$price_change <- as.numeric(df$price_change)
df$abs_price_change <- abs(df$price - dplyr::lag(df$price)) * (df$price_change == 1)

# Create is_observed: 1 if price is not missing
df$is_observed <- ifelse(!is.na(df$price), 1, 0)

# First collapse by website, product_website_id, and date
collapsed1 <- df %>%
  group_by(website, product_website_id, date) %>%
  summarise(
    n_price_change = sum(price_change, na.rm = TRUE),
    abs_price_change = sum(abs_price_change, na.rm = TRUE),
    observations = sum(is_observed, na.rm = TRUE),
    has_price_change = max(price_change, na.rm = TRUE),
    is_observed = max(is_observed, na.rm = TRUE),
    price = mean(price, na.rm = TRUE),
    .groups = "drop"
  )

# Second collapse by website and date
collapsed2 <- collapsed1 %>%
  group_by(website, date) %>%
  summarise(
    n_price_change = sum(n_price_change, na.rm = TRUE),
    abs_price_change = sum(abs_price_change, na.rm = TRUE),
    has_price_change = sum(has_price_change, na.rm = TRUE),
    observations = sum(observations, na.rm = TRUE),
    n_products = sum(is_observed, na.rm = TRUE),
    price = mean(price, na.rm = TRUE),
    sd_price = sd(price, na.rm = TRUE),
    price_10 = quantile(price, probs = 0.10, na.rm = TRUE),
    price_90 = quantile(price, probs = 0.90, na.rm = TRUE),
    .groups = "drop"
  )

# Derived variables
collapsed2 <- collapsed2 %>%
  mutate(
    price_change_per_product = n_price_change / n_products,
    has_price_change_per_product = has_price_change / n_products,
    price_changes_conditional = n_price_change / ifelse(has_price_change == 0, NA, has_price_change),
    obs_per_product = observations / n_products,
    avg_abs_price_change = abs_price_change / ifelse(n_price_change == 0, NA, n_price_change),
    dow = wday(date)
  )

# Optional: Format numeric variables for table/reporting
collapsed2 <- collapsed2 %>%
  mutate(
    obs_per_product = round(obs_per_product, 1),
    price_change_per_product = round(price_change_per_product, 2),
    has_price_change_per_product = round(has_price_change_per_product, 2),
    price = round(price, 2),
    avg_abs_price_change = round(avg_abs_price_change, 2)
  )

# View a sample
head(collapsed2)


weekly <- copy(df)
weekly[, week := date - wday(date)]
weekly <- weekly[, .(n_products = mean(is_observed, na.rm = TRUE)), by = .(website, week)]

ggplot(weekly, aes(x = week, y = n_products, color = website)) +
  geom_line() +
  labs(y = "Count of Products", x = "Date") +
  theme_minimal()
ggsave("C:/Users/attef/OneDrive/Documents/Replicaproject/Replica/count_products_weekly.pdf")


brand_tab <- df[!is.na(price), .N, by = .(website, brand)] %>%
  pivot_wider(names_from = brand, values_from = N, values_fill = 0)

write.csv(brand_tab, "website_brand.csv", row.names = FALSE)
