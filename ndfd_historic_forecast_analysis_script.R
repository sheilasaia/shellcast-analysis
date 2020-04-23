# ndfd historic forecast analysis script

# ---- To Do List ----
# TODO for now set date as characture but figure out why ymd_hm("2016-01-01 00:00", tz = "UCT") gives result without time but ymd_hm("2016-01-01 13:00", tz = "UCT") gives it with the time
# TODO need to loop through all 1095 days
# TODO use here package for path stuff

# ---- load libraries ----
library(tidyverse)
library(here)
library(lubridate)
library(sf)


# ---- define paths ----
# paths to data
ndfd_sco_data_path <- "/Users/sheila/Documents/bae_shellcast_project/shellcast_analysis/ndfd_get_data/data/ndfd_sco_data/"
state_bounds_data_path <- "/Users/sheila/Documents/bae_shellcast_project/shellcast_analysis/data/spatial/state_bounds/"

# exporting figure path
figure_path <- "/Users/sheila/Documents/bae_shellcast_project/shellcast_analysis/results/figures/"


# ---- load data ----
# historic pop12 data
ndfd_hist_pop12_data_raw <- read_csv(paste0(ndfd_sco_data_path, "pop12_2016010100.csv"),
                                     col_types = list(col_double(), col_double(), col_double(), col_double(), col_double(), col_double(), col_double(),
                                                      col_character(), col_character(), col_character(), col_character(), col_character()))

# historic qpf data
ndfd_hist_qpf_data_raw <- read_csv(paste0(ndfd_sco_data_path, "qpf_2016010100.csv"),
                                   col_types = list(col_double(), col_double(), col_double(), col_double(), col_double(), col_double(), col_double(),
                                                    col_character(), col_character(), col_character(), col_character(), col_character()))

# state boundaries
state_bounds_albers_shp <- st_read(paste0(state_bounds_data_path, "state_bounds.shp"))


# ---- wrangle data ----
# wrangle
ndfd_hist_pop12_data <- ndfd_hist_pop12_data_raw %>%
  select(x_index, y_index, latitude, longitude, time_uct, time_nyc, pop12_value_perc, valid_period_hrs) %>%
  mutate(latitude_m = latitude * 1000,
         longitude_m = longitude * 1000)
# ndfd_hist_qpf_data <- ndfd_hist_qpf_data_raw %>%
#   select(x_index, y_index, latitude, longitude, time_uct, time_nyc, qpf_value_kmperm2, valid_period_hrs) %>%
#   mutate(qpf_value_in = qpf_value_kmperm2 * (1/1000) * (100) * (1/2.54)) # convert to inches, density of water is 1000 kg/m3

# select only 12 hr output
ndfd_hist_pop12_data_12hr <- ndfd_hist_pop12_data %>%
  filter(valid_period_hrs == 12) %>%
  mutate(latitude_m = latitude * 1000,
         longitude_m = longitude * 1000)
# ndfd_hist_qpf_data_12hr <- ndfd_hist_qpf_data %>%
#   filter(valid_period_hrs == 12)

# define proj4 string for ndfd data
ndfd_proj4 = "+proj=lcc +lat_1=25 +lat_2=25 +lat_0=25 +lon_0=-95 +x_0=0 +y_0=0 +a=6371000 +b=6371000 +units=m +no_defs"
# source: https://spatialreference.org/ref/sr-org/6825/

# ndfd_proj4 = "+proj=lcc +lat_1=32 +lat_2=42 +lat_0=35 +lon_0=-80 +x_0=0 +y_0=0 +a=6371000 +b=6371000 +datum=WGS84 +units=m +no_defs"

# range(ndfd_hist_pop12_data$latitude)
# 741.9331 to 1752.7349
# range(ndfd_hist_pop12_data$longitude)
# 878.7302 to 1859.0555

# range(ndfd_hist_pop12_data$latitude_m)
# 741933.1 to 1752734.9
# range(ndfd_hist_pop12_data$longitude_m)
# 878730.2 to 1859055.5

# is this helpful?: https://gis.stackexchange.com/questions/345714/creating-custom-proj4-string-from-components
# or this?: http://geotiff.maptools.org/proj_list/lambert_conic_conformal_2sp.html
# 

# define epsg and proj4 for N. America Albers projection (projecting to this)
na_albers_proj4 <- "+proj=aea +lat_1=20 +lat_2=60 +lat_0=40 +lon_0=-96 +x_0=0 +y_0=0 +datum=NAD83 +units=m +no_defs"
na_albers_epsg <- 102008

# convert to spatial data
ndfd_hist_pop12_data_albers_shp <- st_as_sf(ndfd_hist_pop12_data, coords = c("longitude_m", "latitude_m"), crs = ndfd_proj4, dim = "XY") #%>%
  #st_transform(crs = na_albers_proj4) %>%
  #st_set_crs(na_albers_epsg)
st_crs(ndfd_hist_pop12_data_albers_shp)

# ndfd_hist_qpf_data_albers_shp <- st_as_sf(ndfd_hist_qpf_data, coords = c("longitude", "latitude"), crs = ndfd_proj4, dim = "XY") %>%
#   st_transform(crs = na_albers_proj4) %>%
#   st_set_crs(na_albers_epsg)
# st_crs(ndfd_hist_qpf_data_albers_shp)

# calculate bounding box of ndfd data
ndfd_pop12_data_bbox <- st_bbox(ndfd_hist_pop12_data_albers_shp)
ndfd_pop12_data_bbox_shp <- st_as_sfc(ndfd_pop12_data_bbox, crs = ndfd_proj4) %>%
  st_transform(crs = 4326)
ndfd_pop12_data_bbox_shp <- st_as_sfc(ndfd_pop12_data_bbox, crs = na_albers_epsg)
ndfd_pop12_data_bbox_shp
# this isn't working for some reason....

# try manually making a box
ndfd_pop12_bounds <- data.frame(long = c(ndfd_pop12_data_bbox[1], ndfd_pop12_data_bbox[3], ndfd_pop12_data_bbox[3], ndfd_pop12_data_bbox[1]),
                                lat = c(ndfd_pop12_data_bbox[4], ndfd_pop12_data_bbox[4], ndfd_pop12_data_bbox[2], ndfd_pop12_data_bbox[2]))
ndfd_pop12_bounds_shp <- st_as_sf(ndfd_pop12_bounds, coords = c("long", "lat"), crs = ndfd_proj4, dim = "XY")  %>%
  st_transform(crs = na_albers_epsg)



# ---- select mid atlantic state bounds ----
# list of mid atlantic states
midatlan_states_list <- c("IN", "OH", "KY", "WV", "PA", "MD", "DE", "NJ", "VA", "TN", "NC", "SC", "GA", "AL", "TX", "LA", "MS", "FL")
# source: https://www.weather.gov/images/mdl/midatlan.gif

# select ndfd mid atlantic states bounds only
midatlantic_bounds_shp <- state_bounds_albers_shp %>%
  filter(STUSPS %in% midatlan_states_list)
  
#st_write(ndfd_pop12_bounds_shp, paste0(figure_path, "pop12_bbox.shp"))
#st_write(midatlantic_bounds_shp, paste0(figure_path, "southeast_states.shp"))

# ---- make data a grid ----

#st_make_grid()

# ---- plot data ----
# ggplot(data = ndfd_hist_pop12_data_12hr) +
#   geom_point(aes(x = x_index, y = y_index, color = pop12_value_perc)) +
#   scale_color_gradient(low = "white", high = "blue", na.value = "grey90")

# plot pop12 data
ggplot(data = ndfd_hist_pop12_data_12hr) +
  geom_point(aes(x = longitude, y = latitude, color = pop12_value_perc)) +
  scale_color_gradient(low = "white", high = "blue", na.value = "grey90", limits = c(0, 100))

# plot qpf data
#max(ndfd_hist_qpf_data$qpf_value_in, na.rm = TRUE)
ggplot(data = ndfd_hist_qpf_data_12hr) +
  geom_point(aes(x = longitude, y = latitude, color = qpf_value_in)) +
  scale_color_gradient(low = "white", high = "blue", na.value = "grey90", limits = c(0, 1))


# ----- plot spatial data ----
# plot state bounds
pdf(file = paste0(figure_path, "test_1.pdf"), width = 11, height = 8.5)
ggplot(data = ndfd_pop12_data_bbox_shp) +
  geom_sf(data = midatlantic_bounds_shp) +
  geom_sf(data = ndfd_pop12_data_bbox_shp, fill= NA, lwd = 2)
dev.off()

