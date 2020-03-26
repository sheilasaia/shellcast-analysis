# ndfd forecast analysis script

# ---- load libraries ----

library(tidyverse)
library(here)


# ---- load data ----
# path to data
ndfd_data_path <- "/Users/sheila/Documents/bae_shellcast_project/shellcast_analysis/ndfd_get_data/data/AR.midatlan/VP.001-003/"

# pop12 data
ndfd_pop12_data_raw <- read_csv(paste0(ndfd_data_path, "pop12.csv"))

# qpf data
ndfd_qpf_data_raw <- read_csv(paste0(ndfd_data_path, "qpf.csv"))



# ---- wrangle data ----

# max(ndfd_pop12_data_raw$x_index)/2 # = 96.5 so set cutoff at 96?
mirroring_fix = 96

# both diagonals of the matrix are being plotted (just want one)
ndfd_pop12_data <- ndfd_pop12_data_raw %>%
  mutate(longitude_fix = -(360 - longitude)) %>%
  filter(step_index == "0 days 12:00:00.000000000") %>%
  arrange(x_index, y_index) %>%
  #mutate(row_id = seq(1, 38800)) %>%
  filter(x_index > mirroring_fix)

ggplot(data = ndfd_pop12_data) +
  geom_point(aes(x = x_index, y = y_index, color = pop12_value_perc)) +
  scale_color_gradient(low = "white", high = "blue", na.value = "grey90", limits = c(0, 100))

ggplot(data = ndfd_pop12_data) +
  geom_point(aes(x = longitude_fix, y = latitude, color = pop12_value_perc)) +
  scale_color_gradient(low = "white", high = "blue", na.value = "grey90", limits = c(0, 100))



# ---- plot data ----

# ggplot(data = ndfd_pop12_data_raw %>% filter(step_index == "0 days 12:00:00.000000000")) +
#   geom_point(aes(x = x_index, y = y_index, fill = pop12_value_perc))
# 
# ggplot(data = ndfd_pop12_data_raw %>% filter(step_index == "0 days 12:00:00.000000000")) +
#   geom_point(aes(x = x_index, y = y_index, color = pop12_value_perc)) +
#   scale_color_gradient(low = "white", high = "blue", na.value = "grey90", limits = c(0, 100))# +
#   #scale_x_reverse()
# 
# ggplot(data = ndfd_qpf_data_raw %>% filter(step_index == "0 days 12:00:00.000000000")) +
#   geom_point(aes(x = -(longitude), y = latitude, color = qpf_value_in)) +
#   scale_color_gradient(low = "white", high = "blue", na.value = "grey90")


