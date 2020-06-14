# ---- script header ----
# script name: ndfd_forecast_analysis_script.R
# purpose of script: takes raw ndfd tabular data and calculates probability of closure
# author: sheila saia 
# date created: 20200525
# email: ssaia@ncsu.edu


# ---- notes ----
# notes:
 

# ---- to do ----
# to do list

# TODO create function for section 10
# TODO functionalize sections 4 and 5

# ---- 1. load libraries ----
library(tidyverse)
library(here)
library(sf)
library(raster)


# ---- 2. defining paths and projections
# path to data
ndfd_data_path <- "/Users/sheila/Documents/bae_shellcast_project/shellcast_analysis/data/tabular/ndfd_sco_latest_raw/"

# sga buffer data path
sga_data_path <- "/Users/sheila/Documents/bae_shellcast_project/shellcast_analysis/data/spatial/sheila_generated/sga_bounds/"

# cmu data path
cmu_data_path <- "/Users/sheila/Documents/bae_shellcast_project/shellcast_analysis/data/spatial/sheila_generated/cmu_bounds/"


# figure export path
figure_path <- "/Users/sheila/Documents/bae_shellcast_project/shellcast_analysis/results/figures/"

# exporting ndfd spatial data path
ndfd_sco_spatial_data_export_path <- "/Users/sheila/Documents/bae_shellcast_project/shellcast_analysis/data/spatial/sheila_generated/ndfd_sco_latest_nccoast/"

# define proj4 string for ndfd data
ndfd_proj4 = "+proj=lcc +lat_1=25 +lat_2=25 +lat_0=25 +lon_0=-95 +x_0=0 +y_0=0 +a=6371000 +b=6371000 +units=m +no_defs"
# source: https://spatialreference.org/ref/sr-org/6825/

# define epsg and proj4 for N. America Albers projection (projecting to this)
na_albers_proj4 <- "+proj=aea +lat_1=20 +lat_2=60 +lat_0=40 +lon_0=-96 +x_0=0 +y_0=0 +datum=NAD83 +units=m +no_defs"
na_albers_epsg <- 102008

# define wgs 84 projection
wgs84_epsg <- 4326
wgs84_proj4 <- "+proj=longlat +datum=WGS84 +no_defs"


# ---- 2. load data ----
# pop12 tabular data
ndfd_pop12_data_raw <- read_csv(paste0(ndfd_data_path, "pop12_2020052800.csv"),
                                col_types = list(col_double(), col_double(), col_double(), col_double(), col_double(), col_double(), col_double(),
                                                 col_character(), col_character(), col_character(), col_character(), col_character()))

# qpf tabular data
ndfd_qpf_data_raw <- read_csv(paste0(ndfd_data_path, "qpf_2020052800.csv"),
                              col_types = list(col_double(), col_double(), col_double(), col_double(), col_double(), col_double(), col_double(),
                                               col_character(), col_character(), col_character(), col_character(), col_character()))
# sga buffer bounds vector
sga_buffer_albers <- st_read(paste0(sga_data_path, "sga_bounds_buffer_albers.shp"))

# cmu buffer bounds vector
cmu_buffer_albers <- st_read(paste0(cmu_data_path, "cmu_bounds_buffer_albers.shp"))

# cmu bounds vector
cmu_bounds_albers <- st_read(paste0(cmu_data_path, "cmu_bounds_albers.shp"))


# ---- load functions ----




# ---- 3. wrangle ndfd tabular data ----
# initial clean up pop12
ndfd_pop12_data <- ndfd_pop12_data_raw %>%
  dplyr::select(x_index, y_index, latitude_km, longitude_km, time_uct, time_nyc, pop12_value_perc, valid_period_hrs) %>%
  dplyr::mutate(latitude_m = latitude_km * 1000,
                longitude_m = longitude_km * 1000)

# initial clean up qpf
ndfd_qpf_data <- ndfd_qpf_data_raw %>%
  dplyr::select(x_index, y_index, latitude_km, longitude_km, time_uct, time_nyc, qpf_value_kmperm2, valid_period_hrs) %>%
  dplyr::mutate(latitude_m = latitude_km * 1000,
                longitude_m = longitude_km * 1000,
                qpf_value_in = qpf_value_kmperm2 * (1/1000) * (100) * (1/2.54)) # convert to inches, density of water is 1000 kg/m3


# ---- 4. convert tabular ndfd data to (vector) spatial data ----
# pop12
# convert pop12 to spatial data
ndfd_pop12_albers <- st_as_sf(ndfd_pop12_data, 
                              coords = c("longitude_m", "latitude_m"), 
                              crs = ndfd_proj4, 
                              dim = "XY") %>%
  st_transform(crs = na_albers_epsg)

# check pop12 projection
# st_crs(ndfd_pop12_albers)
# look good!

# pop12 periods available
# unique(ndfd_pop12_albers$valid_period_hrs)

# select 1-day pop12
ndfd_pop12_albers_1day <- ndfd_pop12_albers %>%
  dplyr::filter(valid_period_hrs == 24)

# select 2-day pop12
ndfd_pop12_albers_2day <- ndfd_pop12_albers %>%
  dplyr::filter(valid_period_hrs == 48)

# select 3-day pop12
ndfd_pop12_albers_3day <- ndfd_pop12_albers %>%
  dplyr::filter(valid_period_hrs == 72)

# qpf
# convert qpf to spatial data
ndfd_qpf_albers <- st_as_sf(ndfd_qpf_data, 
                            coords = c("longitude_m", "latitude_m"), 
                            crs = ndfd_proj4, 
                            dim = "XY") %>%
  st_transform(crs = na_albers_epsg)

# check qpf projection
# st_crs(ndfd_qpf_albers)
# look good!

# qpf periods available
# unique(ndfd_qpf_albers$valid_period_hrs)

# select 1-day qpf
ndfd_qpf_albers_1day <- ndfd_qpf_albers %>%
  dplyr::filter(valid_period_hrs == 24)

# select 2-day qpf
ndfd_qpf_albers_2day <- ndfd_qpf_albers %>%
  dplyr::filter(valid_period_hrs == 48)

# select 3-day qpf
ndfd_qpf_albers_3day <- ndfd_qpf_albers %>%
  dplyr::filter(valid_period_hrs == 72)


# ---- 5. convert vector ndfd data to raster data ----
# make empty pop12 raster for 1-day, 2-day, and 3-day forecasts
ndfd_pop12_grid_1day <- raster(ncol = length(unique(ndfd_pop12_albers_1day$longitude_km)), 
                               nrows = length(unique(ndfd_pop12_albers_1day$latitude_km)), 
                               crs = na_albers_proj4,
                               ext = extent(ndfd_pop12_albers_1day))
ndfd_pop12_grid_2day <- raster(ncol = length(unique(ndfd_pop12_albers_2day$longitude_km)), 
                               nrows = length(unique(ndfd_pop12_albers_2day$latitude_km)), 
                               crs = na_albers_proj4,
                               ext = extent(ndfd_pop12_albers_2day))
ndfd_pop12_grid_3day <- raster(ncol = length(unique(ndfd_pop12_albers_3day$longitude_km)), 
                               nrows = length(unique(ndfd_pop12_albers_3day$latitude_km)), 
                               crs = na_albers_proj4,
                               ext = extent(ndfd_pop12_albers_3day))

# make empty qpf raster for 1-day, 2-day, and 3-day forecasts
ndfd_qpf_grid_1day <- raster(ncol = length(unique(ndfd_qpf_albers_1day$longitude_km)), 
                             nrows = length(unique(ndfd_qpf_albers_1day$latitude_km)), 
                             crs = na_albers_proj4,
                             ext = extent(ndfd_qpf_albers_1day))
ndfd_qpf_grid_2day <- raster(ncol = length(unique(ndfd_qpf_albers_2day$longitude_km)), 
                             nrows = length(unique(ndfd_qpf_albers_2day$latitude_km)), 
                             crs = na_albers_proj4,
                             ext = extent(ndfd_qpf_albers_2day))
ndfd_qpf_grid_3day <- raster(ncol = length(unique(ndfd_qpf_albers_3day$longitude_km)), 
                             nrows = length(unique(ndfd_qpf_albers_3day$latitude_km)), 
                             crs = na_albers_proj4,
                             ext = extent(ndfd_qpf_albers_3day))

# rasterize pop12 for 1-day, 2-day, and 3-day forecasts
ndfd_pop12_raster_1day_albers <- rasterize(ndfd_pop12_albers_1day, ndfd_pop12_grid_1day, field = ndfd_pop12_albers_1day$pop12_value_perc, fun = mean)
# crs(ndfd_pop12_grid_1day_albers)
ndfd_pop12_raster_2day_albers <- rasterize(ndfd_pop12_albers_2day, ndfd_pop12_grid_2day, field = ndfd_pop12_albers_2day$pop12_value_perc, fun = mean)
ndfd_pop12_raster_3day_albers <- rasterize(ndfd_pop12_albers_3day, ndfd_pop12_grid_3day, field = ndfd_pop12_albers_3day$pop12_value_perc, fun = mean)

# rasterize qpf for 1-day, 2-day, and 3-day forecasts
ndfd_qpf_raster_1day_albers <- rasterize(ndfd_qpf_albers_1day, ndfd_qpf_grid_1day, field = ndfd_qpf_albers_1day$qpf_value_in, fun = mean)
# crs(ndfd_qpf_grid_1day_albers)
# na_albers_proj4 # it's missing the ellps-GRS80, not sure why...
ndfd_qpf_raster_2day_albers <- rasterize(ndfd_qpf_albers_2day, ndfd_qpf_grid_2day, field = ndfd_qpf_albers_2day$qpf_value_in, fun = mean)
ndfd_qpf_raster_3day_albers <- rasterize(ndfd_qpf_albers_3day, ndfd_qpf_grid_3day, field = ndfd_qpf_albers_3day$qpf_value_in, fun = mean)

# plot to check
# plot(ndfd_pop12_raster_1day_albers)
# plot(ndfd_qpf_raster_1day_albers)
# plot(ndfd_pop12_raster_2day_albers)
# plot(ndfd_qpf_raster_2day_albers)
# plot(ndfd_pop12_raster_3day_albers)
# plot(ndfd_qpf_raster_3day_albers)


# ---- 6. crop raster ndfd data to sga bounds ----
# pop12 for 1-day, 2-day, and 3-day forecasts
ndfd_pop12_raster_1day_sga_albers <- crop(ndfd_pop12_raster_1day_albers, sga_buffer_albers)
ndfd_pop12_raster_2day_sga_albers <- crop(ndfd_pop12_raster_2day_albers, sga_buffer_albers)
ndfd_pop12_raster_3day_sga_albers <- crop(ndfd_pop12_raster_3day_albers, sga_buffer_albers)

# qpf for 1-day, 2-day, and 3-day forecasts
ndfd_qpf_raster_1day_sga_albers <- crop(ndfd_qpf_raster_1day_albers, sga_buffer_albers)
ndfd_qpf_raster_2day_sga_albers <- crop(ndfd_qpf_raster_2day_albers, sga_buffer_albers)
ndfd_qpf_raster_3day_sga_albers <- crop(ndfd_qpf_raster_3day_albers, sga_buffer_albers)

# plot to check
# plot(ndfd_pop12_raster_1day_sga_albers)
# plot(ndfd_qpf_raster_1day_sga_albers)
# plot(ndfd_pop12_raster_2day_sga_albers)
# plot(ndfd_qpf_raster_2day_sga_albers)
# plot(ndfd_pop12_raster_3day_sga_albers)
# plot(ndfd_qpf_raster_3day_sga_albers)

# project pop12 to wgs84 toofor 1-day, 2-day, and 3-day forecasts
ndfd_pop12_raster_1day_sga_wgs84 <- projectRaster(ndfd_pop12_raster_1day_sga_albers, crs = wgs84_proj4)
ndfd_pop12_raster_2day_sga_wgs84 <- projectRaster(ndfd_pop12_raster_2day_sga_albers, crs = wgs84_proj4)
ndfd_pop12_raster_3day_sga_wgs84 <- projectRaster(ndfd_pop12_raster_3day_sga_albers, crs = wgs84_proj4)

# project qpf to wgs84 too for 1-day, 2-day, and 3-day forecasts
ndfd_qpf_raster_1day_sga_wgs84 <- projectRaster(ndfd_qpf_raster_1day_sga_albers, crs = wgs84_proj4)
ndfd_qpf_raster_2day_sga_wgs84 <- projectRaster(ndfd_qpf_raster_2day_sga_albers, crs = wgs84_proj4)
ndfd_qpf_raster_3day_sga_wgs84 <- projectRaster(ndfd_qpf_raster_3day_sga_albers, crs = wgs84_proj4)

# plot to check
# plot(ndfd_pop12_raster_1day_sga_wgs84)
# plot(ndfd_qpf_raster_1day_sga_wgs84)
# plot(ndfd_pop12_raster_2day_sga_wgs84)
# plot(ndfd_qpf_raster_3day_sga_wgs84)
# plot(ndfd_pop12_raster_3day_sga_wgs84)
# plot(ndfd_qpf_raster_3day_sga_wgs84)


# ---- 7. export sga raster ndfd data ----
# export pop12 rasters for 1-day, 2-day, and 3-day forecasts
# writeRaster(ndfd_pop12_raster_1day_sga_albers, paste0(ndfd_sco_spatial_data_export_path, "pop12_2020052800_24hr_sga_albers.tif"), overwrite = TRUE)
# writeRaster(ndfd_pop12_raster_2day_sga_albers, paste0(ndfd_sco_spatial_data_export_path, "pop12_2020052800_48hr_sga_albers.tif"), overwrite = TRUE)
# writeRaster(ndfd_pop12_raster_3day_sga_albers, paste0(ndfd_sco_spatial_data_export_path, "pop12_2020052800_78hr_sga_albers.tif"), overwrite = TRUE)

# export qpf rasters for 1-day, 2-day, and 3-day forecasts
# writeRaster(ndfd_qpf_raster_1day_sga_albers, paste0(ndfd_sco_spatial_data_export_path, "qpf_2020052800_24hr_sga_albers.tif"), overwrite = TRUE)
# writeRaster(ndfd_qpf_raster_2day_sga_albers, paste0(ndfd_sco_spatial_data_export_path, "qpf_2020052800_48hr_sga_albers.tif"), overwrite = TRUE)
# writeRaster(ndfd_qpf_raster_3day_sga_albers, paste0(ndfd_sco_spatial_data_export_path, "qpf_2020052800_72hr_sga_albers.tif"), overwrite = TRUE)

# export pop12 rasters as wgs84 too for 1-day, 2-day, and 3-day forecasts
# writeRaster(ndfd_pop12_raster_1day_sga_wgs84, paste0(ndfd_sco_spatial_data_export_path, "pop12_2020052800_24hr_sga_wgs84.tif"), overwrite = TRUE)
# writeRaster(ndfd_pop12_raster_2day_sga_wgs84, paste0(ndfd_sco_spatial_data_export_path, "pop12_2020052800_48hr_sga_wgs84.tif"), overwrite = TRUE)
# writeRaster(ndfd_pop12_raster_3day_sga_wgs84, paste0(ndfd_sco_spatial_data_export_path, "pop12_2020052800_72hr_sga_wgs84.tif"), overwrite = TRUE)

# export qpf rasters as wgs84 too for 1-day, 2-day, and 3-day forecasts
# writeRaster(ndfd_qpf_raster_1day_sga_wgs84, paste0(ndfd_sco_spatial_data_export_path, "qpf_2020052800_24hr_sga_wgs94.tif"), overwrite = TRUE)
# writeRaster(ndfd_qpf_raster_2day_sga_wgs84, paste0(ndfd_sco_spatial_data_export_path, "qpf_2020052800_48hr_sga_wgs94.tif"), overwrite = TRUE)
# writeRaster(ndfd_qpf_raster_3day_sga_wgs84, paste0(ndfd_sco_spatial_data_export_path, "qpf_2020052800_72hr_sga_wgs94.tif"), overwrite = TRUE)


# ---- 8. crop sga raster ndfd data to cmu bounds ----

# 1-day pop12 for 1-day, 2-day, and 3-day forecasts
ndfd_pop12_raster_1day_cmu_albers <- mask(ndfd_pop12_raster_1day_sga_albers, mask = cmu_buffer_albers)
ndfd_pop12_raster_2day_cmu_albers <- mask(ndfd_pop12_raster_2day_sga_albers, mask = cmu_buffer_albers)
ndfd_pop12_raster_3day_cmu_albers <- mask(ndfd_pop12_raster_3day_sga_albers, mask = cmu_buffer_albers)

# 1-day qpf for 1-day, 2-day, and 3-day forecasts
ndfd_qpf_raster_1day_cmu_albers <-  mask(ndfd_qpf_raster_1day_sga_albers, mask = cmu_buffer_albers)
ndfd_qpf_raster_2day_cmu_albers <-  mask(ndfd_qpf_raster_2day_sga_albers, mask = cmu_buffer_albers)
ndfd_qpf_raster_3day_cmu_albers <-  mask(ndfd_qpf_raster_3day_sga_albers, mask = cmu_buffer_albers)

# plot to check
# plot(ndfd_pop12_raster_1day_cmu_albers)
# plot(ndfd_qpf_raster_1day_cmu_albers)
# plot(ndfd_pop12_raster_2day_cmu_albers)
# plot(ndfd_qpf_raster_2day_cmu_albers)
# plot(ndfd_pop12_raster_3day_cmu_albers)
# plot(ndfd_qpf_raster_3day_cmu_albers)

# project pop12 to wgs84 too for 1-day, 2-day, and 3-day forecasts
# ndfd_pop12_raster_1day_cmu_wgs84 <- projectRaster(ndfd_pop12_raster_1day_cmu_albers, crs = wgs84_proj4)
# ndfd_pop12_raster_2day_cmu_wgs84 <- projectRaster(ndfd_pop12_raster_2day_cmu_albers, crs = wgs84_proj4)
# ndfd_pop12_raster_3day_cmu_wgs84 <- projectRaster(ndfd_pop12_raster_3day_cmu_albers, crs = wgs84_proj4)

# project qpf to wgs84 too for 1-day, 2-day, and 3-day forecasts
# ndfd_qpf_raster_1day_cmu_wgs84 <- projectRaster(ndfd_qpf_raster_1day_cmu_albers, crs = wgs84_proj4)
# ndfd_qpf_raster_2day_cmu_wgs84 <- projectRaster(ndfd_qpf_raster_2day_cmu_albers, crs = wgs84_proj4)
# ndfd_qpf_raster_3day_cmu_wgs84 <- projectRaster(ndfd_qpf_raster_3day_cmu_albers, crs = wgs84_proj4)

# plot to check
# plot(ndfd_pop12_raster_1day_cmu_wgs84)
# plot(ndfd_qpf_raster_1day_cmu_wgs84)


# ---- 9. export cmu raster ndfd data ----
# export rasters
# writeRaster(ndfd_pop12_raster_1day_cmu_albers, paste0(ndfd_sco_spatial_data_export_path, "pop12_2020052800_24hr_cmu_albers.tif"), overwrite = TRUE)
# writeRaster(ndfd_qpf_raster_1day_cmu_albers, paste0(ndfd_sco_spatial_data_export_path, "qpf_2020052800_24hr_cmu_albers.tif"), overwrite = TRUE)

# export rasters as wgs84 too
# writeRaster(ndfd_pop12_raster_1day_cmu_wgs84, paste0(ndfd_sco_spatial_data_export_path, "pop12_2020052800_24hr_cmu_wgs84.tif"), overwrite = TRUE)
# writeRaster(ndfd_qpf_raster_1day_cmu_wgs84, paste0(ndfd_sco_spatial_data_export_path, "qpf_2020052800_24hr_cmu_wgs94.tif"), overwrite = TRUE)


# ---- 10. area weighted calcs for each cmu ----

# need to do this for pop12 and qpf and for 1-day, 2-day, and 3-day forecasts
cmu_calcs_data <- data.frame(HA_CLASS = as.character(),
                             date = as.character(),
                             valid_period_hrs = as.numeric(),
                             pop12_perc = as.numeric(),
                             qpf_in = as.numeric())

# valid period list
valid_period_list <- c(24, 48, 72)

# rasters lists
pop12_raster_list <- c(ndfd_pop12_raster_1day_cmu_albers, ndfd_pop12_raster_2day_cmu_albers, ndfd_pop12_raster_3day_cmu_albers)
qpf_raster_list <- c(ndfd_qpf_raster_1day_cmu_albers, ndfd_qpf_raster_2day_cmu_albers, ndfd_qpf_raster_3day_cmu_albers)

# number of cmu's
num_cms <- length(cmu_bounds_albers$HA_CLASS)

# i denotes valid period (3 values), j denotes HA_CLASS (145 values)
# save raster
temp_pop12_raster <- pop12_raster_list[i]
temp_qpf_raster <- qpf_raster_list[i]

# save raster resolution
temp_pop12_raster_res <- res(temp_pop12_raster)
temp_qpf_raster_res <- res(temp_qpf_raster)

# save cmu name
temp_cmu_name <- as.character(cmu_bounds_albers$HA_CLASS[j])

# save cmu rainfall threshold value
temp_cmu_rain_in <- as.numeric(cmu_bounds_albers$rain_in[j])

# get cmu bounds vector
temp_cmu_bounds <- cmu_bounds_albers %>%
  filter(HA_CLASS == temp_cmu_name)

# cmu bounds area
temp_cmu_area <- as.numeric(st_area(temp_cmu_bounds))

# make this a funciton that takes ndfd raster and temp_cmu_bounds and gives area wtd raster result
temp_pop12_cmu_raster_empty <- raster()
extent(temp_pop12_cmu_raster_empty) <- extent(temp_pop12_raster)
res(temp_pop12_cmu_raster_empty) <- res(temp_pop12_raster)
crs(temp_pop12_cmu_raster_empty) <- crs(temp_pop12_raster)

temp_qpf_cmu_raster_empty <- raster()
extent(temp_qpf_cmu_raster_empty) <- extent(temp_qpf_raster)
res(temp_qpf_cmu_raster_empty) <- res(temp_qpf_raster)
crs(temp_qpf_cmu_raster_empty) <- crs(temp_qpf_raster)

# calculate percent cover cmu over raster
temp_pop12_cmu_raster_perc_cover <- rasterize(temp_cmu_bounds, temp_pop12_cmu_raster_empty, getCover = TRUE) # getCover give percentage of the cover of the cmu boundary in the raster
temp_qpf_cmu_raster_perc_cover <- rasterize(temp_cmu_bounds, temp_qpf_cmu_raster_empty, getCover = TRUE) # getCover give percentage of the cover of the cmu boundary in the raster

# 
temp_pop12_cmu_df <- data.frame(perc_cover = temp_pop12_cmu_raster_perc_cover@data@values, raster_value = temp_pop12_raster@data@values)
temp_qpf_cmu_df <- data.frame(perc_cover = temp_qpf_cmu_raster_perc_cover@data@values, raster_value = temp_qpf_raster@data@values)

#
temp_pop12_cmu_df_short <- temp_pop12_cmu_df %>%
  na.omit() %>%
  mutate(flag = if_else(perc_cover == 0, "no_data", "data")) %>%
  filter(flag == "data") %>%
  dplyr::select(-flag) %>%
  mutate(perc_cover_rescale = (perc_cover*(temp_pop12_raster_res[1]*temp_pop12_raster_res[2]))/temp_cmu_area,
         raster_value_wtd = perc_cover_rescale * raster_value)


temp_cmu_pop12_result <- round(sum(temp_pop12_cmu_df_short$raster_value_wtd), 1)



cmu_calcs_data$HA_CLASS[j] <- 
cmu_calcs_data$date[j] <- 
cmu_calcs_data$valid_period_hrs[i] <- 
cmu_calcs_data$pop12_perc[j] <- temp_cmu_pop12_result
cmu_calcs_data$qpf_in[j] <- temp_cmu_qpf_result
# got 19.46 for cmu PAM_1





# ---- ??? wrangle data ----

# max(ndfd_pop12_data_raw$x_index)/2 # = 96.5 so set cutoff at 96?
# mirroring_fix = 96
# 
# # both diagonals of the matrix are being plotted (just want one)
# ndfd_pop12_data <- ndfd_pop12_data_raw %>%
#   mutate(longitude_fix = -(360 - longitude)) %>%
#   filter(step_index == "0 days 12:00:00.000000000") %>%
#   arrange(x_index, y_index) %>%
#   #mutate(row_id = seq(1, 38800)) %>%
#   filter(x_index > mirroring_fix)
# 
# ggplot(data = ndfd_pop12_data) +
#   geom_point(aes(x = x_index, y = y_index, color = pop12_value_perc)) +
#   scale_color_gradient(low = "white", high = "blue", na.value = "grey90", limits = c(0, 100))
# 
# ggplot(data = ndfd_pop12_data) +
#   geom_point(aes(x = longitude_fix, y = latitude, color = pop12_value_perc)) +
#   scale_color_gradient(low = "white", high = "blue", na.value = "grey90", limits = c(0, 100))


# ---- ??? plot data ----

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

