
# ---- script header ----
# script name: ncdmf rainfall threshold check
# purpose of script: explorative data analysis of rainfall thresholds
# author: sheila saia
# date created: 20200427
# email: ssaia@ncsu.edu


# ---- notes ----
# notes:
 

# ---- to do ----
# to do list

# TODO use here()


# ---- load libraries ----
library(tidyverse)


# ---- set paths ----
tabular_data_path <- "/Users/sheila/Documents/bae_shellcast_project/shellcast_analysis/data/tabular/sheila_generated/"
  
  
# ---- load data ----
rf_data_raw <- read_csv(paste0(tabular_data_path, "rainfall_thresholds.csv"))


# ---- cleanup data ----
rf_data <- rf_data_raw %>%
  select(-notes)


# ---- plot number of cmu's per ga ----
# count number of cmu's per growing area
cmu_count <- rf_data %>%
  group_by(GROW_AREA) %>%
  count(name = "num_cmu")

# plot
ggplot(data = cmu_count) +
  # geom_col(aes(x = fct_reorder(GROW_AREA, num_cmu, .desc = TRUE), y = num_cmu)) +
  geom_col(aes(x = GROW_AREA, y = num_cmu)) +
  xlab("Growing Area)") +
  ylab("Number of CMUs") +
  theme_classic()


# ---- plot range of rainfall thresholds per ga ----
# get rid of na's
rf_no_na_data <- rf_data %>%
  na.omit()

# find range
rf_range_data <- rf_no_na_data %>%
  group_by(GROW_AREA) %>%
  summarize(min_thresh = min(rainfall_threshold_in),
            max_thresh = max(rainfall_threshold_in))

# plot range of rainfall thresholds
ggplot() +
  geom_point(data = rf_no_na_data, aes(x = GROW_AREA, y = rainfall_threshold_in)) +
  geom_linerange(data = rf_range_data, (aes(x = GROW_AREA, ymin = min_thresh, ymax = max_thresh))) +
  xlab("Growing Area)") +
  ylab("Rainfall Threshold (in)") +
  theme_classic()











    
    
   