library(haven)
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


# Filter for Retailer A
retailer_A <- df_hourly[website == "A"]

ggplot(retailer_A, aes(x = hourofweek, y = hourly_dist)) +
  geom_line(color = "black", linewidth = 1) +
  
  # X-axis: tick every 24 hours (no labels)
  scale_x_continuous(
    breaks = seq(0, 168, by = 24),
    limits = c(0, 168),
    expand = c(0, 0)
  ) +
  
  # Y-axis: 0% to 1% for Retailer A
  scale_y_continuous(
    limits = c(0, 1),
    breaks = seq(0, 1, by = 0.2),
    labels = function(x) sprintf("%.1f", x)
  ) +
  
  # Vertical dashed lines at day boundaries
  geom_vline(xintercept = seq(24, 144, by = 24), linetype = "dashed", color = "gray60") +
  
  # Add day labels as text (not tick labels)
  annotate("text", x = 12, y = 0, label = "Sat", vjust = 1.5, size = 4) +
  annotate("text", x = 36, y = 0, label = "Sun", vjust = 1.5, size = 4) +
  annotate("text", x = 60, y = 0, label = "Mon", vjust = 1.5, size = 4) +
  annotate("text", x = 84, y = 0, label = "Tue", vjust = 1.5, size = 4) +
  annotate("text", x = 108, y = 0, label = "Wed", vjust = 1.5, size = 4) +
  annotate("text", x = 132, y = 0, label = "Thu", vjust = 1.5, size = 4) +
  annotate("text", x = 156, y = 0, label = "Fri", vjust = 1.5, size = 4) +
  
  labs(
    title = "Panel A. Retailer A",
    x = "Hour of Week",
    y = "Percent of Price Changes"
  ) +
  theme_minimal(base_size = 14) +
  theme(
    panel.grid.minor = element_blank(),
    axis.text.x = element_blank(),   # Hide tick labels
    axis.ticks.x = element_blank(),
    plot.title = element_text(hjust = 0.5)
  )


ggplot(df_hourly[website == "B"], aes(x = hourofweek, y = hourly_dist)) +
  geom_line(color = "black", linewidth = 1) +
  scale_x_continuous(
    breaks = seq(0, 168, by = 24),
    limits = c(0, 168),
    expand = c(0, 0)
  ) +
  scale_y_continuous(
    limits = c(0, 1),
    breaks = seq(0, 1, by = 0.2),
    labels = function(x) sprintf("%.1f", x)
  ) +
  geom_vline(xintercept = seq(24, 144, by = 24), linetype = "dashed", color = "gray60") +
  annotate("text", x = seq(12, 156, by = 24), y = 0, label = c("Sat", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri"), vjust = 1.5, size = 4) +
  labs(
    title = "Panel B. Retailer B",
    x = "Hour of Week",
    y = "Percent of Price Changes"
  ) +
  theme_minimal(base_size = 14) +
  theme(
    axis.text.x = element_blank(),
    axis.ticks.x = element_blank(),
    axis.text.y = element_text(size = 10),
    plot.title = element_text(hjust = 0.5),
  )


ggplot(df_hourly[website == "C"], aes(x = hourofweek, y = hourly_dist)) +
  geom_line(color = "black", linewidth = 1) +
  scale_x_continuous(
    breaks = seq(0, 168, by = 24),
    limits = c(0, 168),
    expand = c(0, 0)
  ) +
  scale_y_continuous(
    limits = c(0, 8),
    breaks = seq(0, 8, by = 2),
    labels = function(x) sprintf("%.0f", x)
  ) +
  geom_vline(xintercept = seq(24, 144, by = 24), linetype = "dashed", color = "gray60") +
  annotate("text", x = seq(12, 156, by = 24), y = 0, label = c("Sat", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri"), vjust = 1.5, size = 4) +
  labs(
    title = "Panel C. Retailer C",
    x = "Hour of Week",
    y = "Percent of Price Changes"
  ) +
  theme_minimal(base_size = 14) +
  theme(
    axis.text.x = element_blank(),
    axis.ticks.x = element_blank(),
    axis.text.y = element_text(size = 10),
    plot.title = element_text(hjust = 0.5),
  )

ggplot(df_hourly[website == "D"], aes(x = hourofweek, y = hourly_dist)) +
  geom_line(color = "black", linewidth = 1) +
  scale_x_continuous(
    breaks = seq(0, 168, by = 24),
    limits = c(0, 168),
    expand = c(0, 0)
  ) +
  scale_y_continuous(
    limits = c(0, 25),
    breaks = seq(0, 25, by = 5),
    labels = function(x) sprintf("%.0f", x)
  ) +
  geom_vline(xintercept = seq(24, 144, by = 24), linetype = "dashed", color = "gray60") +
  annotate("text", x = seq(12, 156, by = 24), y = 0, label = c("Sat", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri"), vjust = 1.5, size = 4) +
  labs(
    title = "Panel D. Retailer D",
    x = "Hour of Week",
    y = "Percent of Price Changes"
  ) +
  theme_minimal(base_size = 14) +
  theme(
    axis.text.x = element_blank(),
    axis.ticks.x = element_blank(),
    axis.text.y = element_text(size = 10),
    plot.title = element_text(hjust = 0.5),
  )


ggplot(df_hourly[website == "E"], aes(x = hourofweek, y = hourly_dist)) +
  geom_line(color = "black", linewidth = 1) +
  scale_x_continuous(
    breaks = seq(0, 168, by = 24),
    limits = c(0, 168),
    expand = c(0, 0)
  ) +
  scale_y_continuous(
    limits = c(0, 60),
    breaks = seq(0, 60, by = 10),
    labels = function(x) sprintf("%.0f", x)
  ) +
  geom_vline(xintercept = seq(24, 144, by = 24), linetype = "dashed", color = "gray60") +
  annotate("text", x = seq(12, 156, by = 24), y = 0, label = c("Sat", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri"), vjust = 1.5, size = 4) +
  labs(
    title = "Panel E. Retailer E",
    x = "Hour of Week",
    y = "Percent of Price Changes"
  ) +
  theme_minimal(base_size = 14) +
  theme(
    axis.text.x = element_blank(),
    axis.ticks.x = element_blank(),
    axis.text.y = element_text(size = 10),
    plot.title = element_text(hjust = 0.5),
  )






