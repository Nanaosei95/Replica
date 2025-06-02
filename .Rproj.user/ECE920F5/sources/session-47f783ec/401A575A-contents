library(data.table)
library(dplyr)
library(ggplot2)


data <- read_dta("C:/Users/attef/OneDrive/Documents/Replicaproject/Replica/analysis/data/analysis_data.dta")
df <- as.data.table(haven::read_dta("C:/Users/attef/OneDrive/Documents/Replicaproject/Replica/analysis/data/analysis_data.dta"))

# Encode website as numeric (if needed)
df[, website_code := as.integer(factor(website))]

# Keep only rows with valid product_id and price
df <- df[!is.na(product_id) & !is.na(price)]

# Create log(price)
df[, ln_price := log(price)]

# Check uniqueness by product_id, period_id, website (like Stata's isid)
stopifnot(nrow(df) == nrow(unique(df[, .(product_id, period_id, website)])))

# Count how many sites list the same product at the same time
df[, temp_count_sites := .N, by = .(product_id, period_id)]
df[, product_count_sites := max(temp_count_sites), by = product_id]


# Estimate log(price) ~ website_code, with product_id and period_id fixed effects
library(fixest)

model1 <- feols(ln_price ~ i(website_code) | product_id + period_id, data = df)

# Get predicted ln_premium
df[, ln_premium := predict(model1)]

# Normalize by removing constant (intercept is absorbed, so subtract Retailer A baseline)
df[, ln_premium := ln_premium - mean(ln_premium[website == "A"], na.rm = TRUE)]



# Keep only rows with a price change
df_freq <- df[price_change == 1]

# Compute price change count per website and date
freq_summary <- df_freq[, .(
  min_period = min(period_id),
  max_period = max(period_id),
  count_price_change = .N
), by = .(website, date)]

# Sort and compute time between updates (hour_gap)
freq_summary <- freq_summary[order(website, date)]
freq_summary[, hour_gap := min_period - shift(max_period), by = website]

# Compute median hour_gap for each website
website_gaps <- freq_summary[, .(
  hour_gap = median(hour_gap, na.rm = TRUE)
), by = website]


# Average ln_premium per website
website_premium <- df[, .(ln_premium = mean(ln_premium, na.rm = TRUE)), by = website]

# Merge both
combined <- merge(website_premium, website_gaps, by = "website")

# Create price index
combined[, price_index := exp(ln_premium) * 100]


ggplot(combined, aes(x = hour_gap, y = price_index, label = website)) +
  geom_point(color = "black", size = 3) +
  geom_text(vjust = -0.5, size = 5) +
  scale_x_log10(
    breaks = c(1, 2, 24, 168),
    labels = c("1", "2", "24", "168"),
    limits = c(0.5, 200)
  ) +
  scale_y_continuous(
    limits = c(95, 140),
    breaks = seq(100, 140, 10)
  ) +
  labs(
    x = "Pricing Frequency: Median Hours Between Updates (Log Scale)",
    y = "Price Index"
  ) +
  theme_minimal(base_size = 14)

# Save to file
ggsave("C:/Users/attef/OneDrive/Documents/Replicaproject/Replica/plot_technology_premium.pdf")


# Ensure relevant columns exist
df <- df[!is.na(price_change)]

# Adjust hour to Eastern Time (subtract 4 hours)
df[, hour_eastern := (hour + 24 - 4) %% 24]

# Calculate day of week (0 = Sunday, 6 = Saturday)
df[, dow := as.integer(lubridate::wday(date, week_start = 7)) - 1]  # Stata's dow: 0 = Sunday

# Optional: shift Saturday from 6 → -1 (if replicating exact alignment)
df[dow == 6, dow := -1]

# Calculate hour of week
df[, hourofweek := 24 + dow * 24 + hour_eastern]


df_hourly <- df[, .(
  price_change = sum(price_change, na.rm = TRUE),
  is_observed = .N
), by = .(website, hourofweek)]

# Calculate total changes per website
df_hourly[, total_price_change := sum(price_change), by = website]

# Calculate hourly percent of changes
df_hourly[, hourly_dist := (price_change / total_price_change) * 100]


ggplot(df_hourly[website == "A"], aes(x = hourofweek, y = hourly_dist)) +
  geom_line(color = "red") +
  scale_x_continuous(
    breaks = seq(0, 168, by = 24),
    labels = c("Sat", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat")
  ) +
  labs(
    x = "Hour of Week",
    y = "Percent of Price Changes"
  ) +
  theme_minimal(base_size = 14)

ggsave("C:/Users/attef/OneDrive/Documents/Replicaproject/Replica/price_change_fraction_hourofweek_A.pdf")


unique_websites <- unique(df_hourly$website)

for (retailer in unique(df_hourly$website)) {
  plot_data <- df_hourly[website == retailer]
  
  p <- ggplot(plot_data, aes(x = hourofweek, y = hourly_dist)) +
    geom_line(color = "red") +
    scale_x_continuous(
      breaks = seq(0, 168, by = 24),
      labels = c("Sat", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat")
    ) +
    labs(
      title = paste("Retailer", retailer),
      x = "Hour of Week",
      y = "Percent of Price Changes"
    ) +
    theme_minimal(base_size = 14)
  
  ggsave(paste0("price_change_fraction_hourofweek_", retailer, ".pdf"),
         plot = p, width = 8, height = 5)
}


# Filter data for retailers A and B
plot_ab <- df_hourly[website %in% c("A", "B")]

ggplot(plot_ab, aes(x = hourofweek, y = hourly_dist, color = website)) +
  geom_line(size = 1) +
  scale_color_manual(values = c("A" = "black", "B" = "sienna")) +
  scale_x_continuous(
    breaks = seq(0, 168, by = 24),
    labels = c("Sat", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat")
  ) +
  labs(
    x = "Hour of Week",
    y = "Percent of Price Changes",
    title = "Retailers A and B"
  ) +
  theme_minimal(base_size = 14) +
  theme(legend.position = "top")

ggsave("price_change_fraction_hourofweek_AB.pdf", width = 8, height = 5)


# Filter data for retailers D and E
plot_de <- df_hourly[website %in% c("D", "E")]

ggplot(plot_de, aes(x = hourofweek, y = hourly_dist, color = website)) +
  geom_line(size = 1) +
  scale_color_manual(values = c("D" = "black", "E" = "sienna")) +
  scale_x_continuous(
    breaks = seq(0, 168, by = 24),
    labels = c("Sat", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat")
  ) +
  labs(
    x = "Hour of Week",
    y = "Percent of Price Changes",
    title = "Retailers D and E"
  ) +
  theme_minimal(base_size = 14) +
  theme(legend.position = "top")

ggsave("price_change_fraction_hourofweek_DE.pdf", width = 8, height = 5)

