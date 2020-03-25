# ndfd historic forecast analysis script

# ---- To Do List ----

# TODO figure out why ymd_hm("2016-01-01 00:00", tz = "UCT") gives result without time but ymd_hm("2016-01-01 13:00", tz = "UCT") gives it with the time
# 


# ---- load libraries ----

library(tidyverse)
library(here)
library(lubridate)


# ---- load data ----
# path to data
ndfd_hist_data_path <- "/Users/sheila/Documents/bae_shellcast_project/shellcast_analysis/ndfd_get_data/data/ndfd_sco_data/"

# historic pop12 data
ndfd_hist_pop12_data_raw <- read_csv(paste0(ndfd_hist_data_path, "pop12_2016010100.csv"),
                                col_types = list(col_double(), col_double(), col_double(), col_double(), col_double(), col_double(), 
                                                 col_character(), col_character(), col_character(), col_character(), col_character()))

# ---- wrangle data ----

ndfd_hist_pop12_data <- ndfd_hist_pop12_data_raw %>%
  select(x_index, y_index, latitude, longitude, time_uct, time_nyc, pop12_value_perc, valid_period_hrs)

ndfd_hist_pop12_data_24hr <- ndfd_hist_pop12_data %>%
  filter(valid_period_hrs == 12)


# ---- plot data ----

ggplot(data = ndfd_hist_pop12_data_24hr) +
  geom_point(aes(x = x_index, y = y_index, color = pop12_value_perc)) +
  scale_color_gradient(low = "white", high = "blue", na.value = "grey90")

ggplot(data = ndfd_hist_pop12_data_24hr) +
  geom_point(aes(x = latitude, y = longitude, color = pop12_value_perc)) +
  scale_color_gradient(low = "black", high = "white", na.value = "grey90", limits = c(0, 100))
