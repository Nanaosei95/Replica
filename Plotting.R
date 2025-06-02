library(data.table)
library(dplyr)
library(lubridate)
library(fixest)  # for fixed effects regression (like reghdfe in Stata)
library(tidyr)
library(ggplot2)
library(readr)
library(haven)


# Load data - adapt path as needed
data <- read_dta("C:/Users/attef/OneDrive/Documents/Replicaproject/Replica/analysis/data/analysis_data.dta")
df <- as.data.table(haven::read_dta("C:/Users/attef/OneDrive/Documents/Replicaproject/Replica/analysis/data/analysis_data.dta"))

# Drop rows where price is missing
df <- df[!is.na(price)]

# Encode 'website' as factor and then integer codes (similar to Stata's encode)
df[, website_code := as.integer(factor(website))]

# Check for unique id combinations (equivalent to isid in Stata)
# Ensure unique by website_code, product_id, period_id
stopifnot(nrow(df) == nrow(unique(df[, .(website_code, product_id, period_id)])))

# Keep only relevant variables
df <- df[, .(product_id, website_code, period_id, price, price_change)]

# hour_of_week = period_id mod 168 (hours per week)
df[, hour_of_week := period_id %% 168]

# Check for price_change at specific hours for retailer D (website_code == 4)
table(df[price_change == 1 & website_code == 4, hour_of_week])

# Shift hour of week so that 0 = 5am
pre_period <- 48
df[, did_time := ((period_id + pre_period - 5) %% 168) - pre_period]

table(df[price_change == 1 & website_code == 4, did_time])

# did_week calculation
df[, did_week := floor((period_id + pre_period - 5) / 168)]

# Sort by product_id, period_id (data.table is keyed for speed)
setkey(df, product_id, period_id)

df[, max_price := max(price, na.rm=TRUE), by=.(website_code, product_id, did_week)]
df <- df[!is.na(max_price)]

# has_change = max of price_change where did_time in [0,5] & website_code == 4 by product_id, did_week

df[, has_change := max(
  price_change * (did_time >= 0 & did_time <= 5) * (website_code == 4)
), by=.(product_id, did_week)]

# Remove rows with missing has_change
df <- df[!is.na(has_change)]

# Check uniqueness of id by website_code, product_id, did_week, did_time
stopifnot(nrow(df) == nrow(unique(df[, .(website_code, product_id, did_week, did_time)])))


plot_data <- df[, .(price_change = mean(price_change, na.rm=TRUE)), by=.(did_time, has_change, website_code)]

# Convert long to wide like Stata reshape wide price_change
plot_data_wide <- dcast(plot_data, website_code + did_time ~ has_change, value.var = "price_change")
# has_change 0 -> price_change0, 1 -> price_change1
setnames(plot_data_wide, old = c("0", "1"), new = c("price_change0", "price_change1"))

# Calculate coef_pr = price_change1 - price_change0
plot_data_wide[, coef_pr := price_change1 - price_change0]

# mean coef_pr in pre-period did_time <= -1, grouped by website_code
plot_data_wide[, temp_pre_pr := mean(coef_pr[did_time <= -1], na.rm = TRUE), by = website_code]

# max pre_pr by website_code
plot_data_wide[, pre_pr := max(temp_pre_pr), by = website_code]

# Cumulative sums for baseline_pr and treatment_pr (like Stata bysort + gen sum())
setorder(plot_data_wide, website_code, did_time)
plot_data_wide[, baseline_pr := cumsum(price_change0), by = website_code]
plot_data_wide[, treatment_pr := cumsum(price_change1 - pre_pr), by = website_code]

# Export specific did_time rows
subset_export <- plot_data_wide[did_time %in% c(-48, -1, 0, 23, 47, 71, 95, 119)]
write_csv(subset_export, "price_response_figure_data_D.csv")



for(i in 1:5) {
  plot_i <- plot_data_wide[website_code == i]
  
  p <- ggplot(plot_i) +
    geom_line(aes(x = did_time, y = treatment_pr), color = "yellow") +
    geom_line(aes(x = did_time, y = baseline_pr), color = "black", linetype = "dashed", alpha = 0.6) +
    geom_vline(xintercept = 0, linetype = "dashed", color = "gray") +
    labs(
      y = "Cumulative Price Changes",
      x = paste("Hours After Price Change Opportunity for D (Website", i, ")")
    ) +
    scale_x_continuous(breaks = seq(-48, 120, 24)) +
    theme_minimal(base_size = 14) +
    theme(
      legend.position = "bottom",
      axis.title = element_text(size = 16)
    )
  
  ggsave(filename = paste0("pr_price_response_D_", i, ".pdf"), plot = p, width = 8, height = 5)
}


# Create variables for regression
df[, post := (did_time >= 0)]
df[, post_has_change := post * has_change]

# Create product_week group
df[, product_week := .GRP, by = .(product_id, did_week)]

cutoff <- 72

results <- list()

for (wc in 1:4) {
  temp <- df[website_code == wc & did_time < cutoff]
  
  # Scale price_change by 72 hours
  temp[, price_change_scaled := price_change * 72]
  
  # Run fixed effects regression like Stata's reghdfe (absorbing product_week and did_time)
  # In fixest: fe ~ fixed effects (absorbed variables)
  fe_model <- feols(price_change_scaled ~ post_has_change | product_week + did_time, data = temp)
  
  # Store result
  results[[wc]] <- fe_model
  
  print(summary(fe_model))
}
