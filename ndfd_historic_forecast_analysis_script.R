
# script name: ndfd historic forecast analysis script
# purpose of script: analyze historic ndfd data
# author: sheila saia 
# date created: 20200401
# email: ssaia@nscu.edu


# ----
# notes:
 

# ----
# to do list
# TODO for now set date as characture but figure out why ymd_hm("2016-01-01 00:00", tz = "UCT") gives result without time but ymd_hm("2016-01-01 13:00", tz = "UCT") gives it with the time
# TODO need to loop through all 1095 days
# TODO use here package for path stuff
# TODO figure out how to get raster to be 5000x5000 right now if i set this when i make the empty raster, the final raster has lines in it


# ---- load libraries ----
library(tidyverse)
library(here)
library(lubridate)
library(sf)
library(raster)


# ---- define paths ----
# paths to data
ndfd_sco_data_path <- "/Users/sheila/Documents/bae_shellcast_project/shellcast_analysis/ndfd_get_data/data/ndfd_sco_data/"
state_bounds_data_path <- "/Users/sheila/Documents/bae_shellcast_project/shellcast_analysis/data/spatial/state_bounds/"

# exporting figure path
figure_path <- "/Users/sheila/Documents/bae_shellcast_project/shellcast_analysis/results/figures/"

# exporting spatial data path
spatial_data_exort_path <- ""


# ---- load data ----
# historic pop12 data
ndfd_pop12_data_raw <- read_csv(paste0(ndfd_sco_data_path, "pop12_2016010100.csv"),
                                col_types = list(col_double(), col_double(), col_double(), col_double(), col_double(), col_double(), col_double(),
                                                 col_character(), col_character(), col_character(), col_character(), col_character()))

# historic qpf data
ndfd_qpf_data_raw <- read_csv(paste0(ndfd_sco_data_path, "qpf_2016010100.csv"),
                              col_types = list(col_double(), col_double(), col_double(), col_double(), col_double(), col_double(), col_double(),
                                               col_character(), col_character(), col_character(), col_character(), col_character()))

# state boundaries
state_bounds_shp_raw <- st_read(paste0(state_bounds_data_path, "state_bounds.shp"))
st_crs(state_bounds_shp_raw) # 5070 will need to convert to 102008


# ---- wrangle pop12 data ----
# initial clean up
ndfd_pop12_data <- ndfd_pop12_data_raw %>%
  dplyr::select(x_index, y_index, latitude_km, longitude_km, time_uct, time_nyc, pop12_value_perc, valid_period_hrs) %>%
  dplyr::mutate(latitude_m = latitude_km * 1000,
         longitude_m = longitude_km * 1000)


# ---- wrangle qpf data ----
# initial clean up
ndfd_qpf_data <- ndfd_qpf_data_raw %>%
  dplyr::select(x_index, y_index, latitude_km, longitude_km, time_uct, time_nyc, qpf_value_kmperm2, valid_period_hrs) %>%
  dplyr::mutate(latitude_m = latitude_km * 1000,
         longitude_m = longitude_km * 1000,
         qpf_value_in = qpf_value_kmperm2 * (1/1000) * (100) * (1/2.54)) # convert to inches, density of water is 1000 kg/m3


# ---- convert tabular data to spatial data ----
# define proj4 string for ndfd data
ndfd_proj4 = "+proj=lcc +lat_1=25 +lat_2=25 +lat_0=25 +lon_0=-95 +x_0=0 +y_0=0 +a=6371000 +b=6371000 +units=m +no_defs"
# source: https://spatialreference.org/ref/sr-org/6825/

# define epsg and proj4 for N. America Albers projection (projecting to this)
na_albers_proj4 <- "+proj=aea +lat_1=20 +lat_2=60 +lat_0=40 +lon_0=-96 +x_0=0 +y_0=0 +datum=NAD83 +units=m +no_defs"
na_albers_epsg <- 102008

# pop12
# convert pop12 to spatial data
ndfd_pop12_shp <- st_as_sf(ndfd_pop12_data, coords = c("longitude_m", "latitude_m"), crs = ndfd_proj4, dim = "XY") %>%
  st_transform(crs = na_albers_epsg)
st_crs(ndfd_pop12_shp)

# periods available
unique(ndfd_pop12_shp$valid_period_hrs)

# select 1-day
ndfd_pop12_shp_1day <- ndfd_pop12_shp %>%
  dplyr::filter(valid_period_hrs == 24)

# select 2-day
ndfd_pop12_shp_2day <- ndfd_pop12_shp %>%
  dplyr::filter(valid_period_hrs == 48)

# select 3-day
ndfd_pop12_shp_3day <- ndfd_pop12_shp %>%
  dplyr::filter(valid_period_hrs == 72)


# qpf
# convert qpf to spatial data
ndfd_qpf_shp <- st_as_sf(ndfd_qpf_data, coords = c("longitude_m", "latitude_m"), crs = ndfd_proj4, dim = "XY") %>%
  st_transform(crs = na_albers_epsg)
st_crs(ndfd_qpf_shp)

# periods available
unique(ndfd_qpf_shp$valid_period_hrs)

# select 1-day
ndfd_qpf_shp_1day <- ndfd_qpf_shp %>%
  dplyr::filter(valid_period_hrs == 24)

# select 2-day
ndfd_qpf_shp_2day <- ndfd_qpf_shp %>%
  dplyr::filter(valid_period_hrs == 48)

# select 3-day
ndfd_qpf_shp_3day <- ndfd_qpf_shp %>%
  dplyr::filter(valid_period_hrs == 72)


# ---- wrangle other spatial data ----
# state bounds
state_bounds_shp <- state_bounds_shp_raw %>%
  st_transform(crs = na_albers_epsg)
st_crs(state_bounds_shp)

# list of mid atlantic states
midatlan_states_list <- c("IN", "OH", "KY", "WV", "PA", "MD", "DE", "NJ", "VA", "TN", "NC", "SC", "GA", "AL")
# source: https://www.weather.gov/images/mdl/midatlan.gif

# select ndfd mid atlantic states bounds only
midatlantic_bounds_shp <- state_bounds_shp %>%
  filter(STUSPS %in% midatlan_states_list)

# keep only geometry
midatlantic_bounds_geom <- midatlantic_bounds_shp %>%
  st_geometry()

# export mid atlantic states
#st_write(midatlantic_bounds_shp, paste0(spatial_data_exort_path, "midatlantic_state_bounds.shp"))


# ---- calculate bounding box of ndfd data to check spatial bounds ----
# keep pop12 1-day geometry
ndfd_pop12_geom_1day <- ndfd_pop12_shp %>% 
  dplyr::filter(valid_period_hrs == 24) %>% 
  st_geometry()

# keep qpf 1-day geometry
ndfd_qpf_geom_1day <- ndfd_qpf_shp %>% 
  dplyr::filter(valid_period_hrs == 24) %>% 
  st_geometry()

# calculate bounding box of ndfd data
ndfd_pop12_bbox_1day <- st_bbox(ndfd_pop12_geom_1day)

# convert to spatial object
ndfd_pop12_bbox_shp_1day <- st_as_sfc(ndfd_pop12_bbox_1day, crs = na_albers_epsg) 
st_crs(ndfd_pop12_bbox_shp_1day)

# try manually making a spatial object from the bbox
# ndfd_pop12_bbox_tab_1day <- data.frame(long = c(ndfd_pop12_bbox_1day[1], ndfd_pop12_bbox_1day[3], ndfd_pop12_bbox_1day[3], ndfd_pop12_bbox_1day[1]),
#                                 lat = c(ndfd_pop12_bbox_1day[4], ndfd_pop12_bbox_1day[4], ndfd_pop12_bbox_1day[2], ndfd_pop12_bbox_1day[2]))
# ndfd_pop12_bbox_shp_1day <- st_as_sf(ndfd_pop12_bbox_tab_1day, coords = c("long", "lat"), crs = na_albers_epsg, dim = "XY")
# st_crs(ndfd_pop12_bbox_shp_1day)

# plot to check
pdf(file = paste0(figure_path, "spatial_extent_check_pop12.pdf"), width = 11, height = 8.5)
ggplot() +
  geom_sf(data = midatlantic_bounds_geom) +
  geom_sf(data = ndfd_pop12_bbox_shp_1day, fill = NA, color = "red", lwd = 2)
dev.off()
# should look like: https://www.weather.gov/images/mdl/midatlan.gif
# check!

# export to check
#st_write(ndfd_pop12_bbox_shp_1day, paste0(spatial_data_exort_path, "ndfd_pop12_bbox.shp"))



# ---- make vector data into a raster ----
# make empty pop12 raster
ndfd_pop12_grid_1day <- raster(ncol = length(unique(ndfd_pop12_shp_1day$longitude_km)), 
                               nrows = length(unique(ndfd_pop12_shp_1day$latitude_km)), 
                               crs = na_albers_proj4,
                               ext = extent(ndfd_pop12_shp_1day)) #, 
                               #res = c(5000, 5000)) # b/c coordinates are in m this is 5km x 5km

# make empty qpf raster
ndfd_qpf_grid_1day <- raster(ncol = length(unique(ndfd_qpf_shp_1day$longitude_km)), 
                               nrows = length(unique(ndfd_qpf_shp_1day$latitude_km)), 
                               crs = na_albers_proj4,
                               ext = extent(ndfd_qpf_shp_1day)) #, 
                               #res = c(5000, 5000)) # b/c coordinates are in m this is 5km x 5km

# ndfd_pop12_grid_1day <- ndfd_pop12_shp_1day %>%
#   st_make_grid(cellsize = c(5000, 5000), what = "centers")
#st_make_grid() isn't going to work b/c this doesn't let you keep a third value

# rasterize pop12
ndfd_pop12_grid_1day_ra <- rasterize(ndfd_pop12_shp_1day, ndfd_pop12_grid_1day, field = ndfd_pop12_shp_1day$pop12_value_perc, fun = mean)

# rasterize qpf
ndfd_qpf_grid_1day_ra <- rasterize(ndfd_qpf_shp_1day, ndfd_qpf_grid_1day, field = ndfd_qpf_shp_1day$qpf_value_in, fun = mean)

# plot to check
plot(ndfd_pop12_grid_1day_ra)
plot(ndfd_qpf_grid_1day_ra)

# export to check in qgis
# writeRaster(ndfd_pop12_grid_1day, paste0(figure_path, "pop12_1day.tif"))
# writeRaster(ndfd_qpf_grid_1day, paste0(figure_path, "qpf_1day.tif"))

# help for editing maps in r: https://nceas.github.io/oss-lessons/spatial-data-gis-law/3-mon-intro-gis-in-r.html
# help: https://gis.stackexchange.com/questions/273233/create-spatial-polygon-grid-from-spatial-points-in-r
# more help: https://gis.stackexchange.com/questions/24588/converting-point-data-into-gridded-dataframe-for-histogram-analysis-using-r



# ---- mask ndfd data ----



# ---- calculate propability of closure ----



# ---- write loop for 1-, 2-, 3-day calcs ----








