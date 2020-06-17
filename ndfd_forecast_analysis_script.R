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
# TODO why are some values over 100% for pop12 calcs?

# ---- 1. load libraries ----
library(tidyverse)
library(here)
library(sf)
library(raster)
library(lubridate)


# ---- 2. defining paths and projections ----
# path to data
ndfd_data_path <- "/Users/sheila/Documents/bae_shellcast_project/shellcast_analysis/data/tabular/ndfd_sco_latest_raw/"

# nc buffer data path
nc_data_path <- "/Users/sheila/Documents/bae_shellcast_project/shellcast_analysis/data/spatial/sheila_generated/region_state_bounds/"

# sga buffer data path
sga_data_path <- "/Users/sheila/Documents/bae_shellcast_project/shellcast_analysis/data/spatial/sheila_generated/sga_bounds/"

# cmu data path
cmu_data_path <- "/Users/sheila/Documents/bae_shellcast_project/shellcast_analysis/data/spatial/sheila_generated/cmu_bounds/"

# figure export path
figure_path <- "/Users/sheila/Documents/bae_shellcast_project/shellcast_analysis/results/figures/"

# exporting ndfd spatial data path
ndfd_sco_spatial_data_export_path <- "/Users/sheila/Documents/bae_shellcast_project/shellcast_analysis/data/spatial/sheila_generated/ndfd_sco_latest_nc/"

# exporting ndfd tabular data path
ndfd_sco_tabular_data_export_path <- "/Users/sheila/Documents/bae_shellcast_project/shellcast_analysis/data/tabular/sheila_generated/ndfd_sco_latest_nc/"

# define proj4 string for ndfd data
ndfd_proj4 = "+proj=lcc +lat_1=25 +lat_2=25 +lat_0=25 +lon_0=-95 +x_0=0 +y_0=0 +a=6371000 +b=6371000 +units=m +no_defs"
# source: https://spatialreference.org/ref/sr-org/6825/

# define epsg and proj4 for N. America Albers projection (projecting to this)
na_albers_proj4 <- "+proj=aea +lat_1=20 +lat_2=60 +lat_0=40 +lon_0=-96 +x_0=0 +y_0=0 +datum=NAD83 +units=m +no_defs"
na_albers_epsg <- 102008

# define wgs 84 projection
wgs84_epsg <- 4326
wgs84_proj4 <- "+proj=longlat +datum=WGS84 +no_defs"


# ---- 3. pull latest ndfd file name ----
# list files in ndfd_sco_latest_raw
ndfd_files <- list.files(ndfd_data_path, pattern = "pop12_*") # if there is a pop12 dataset there's a qpf dataset
# ndfd_files <- c(ndfd_files, "pop12_2020061500.csv") # to test with multiple
ndfd_file_dates <- gsub("pop12_", "", gsub(".csv", "", ndfd_files))
today_date_uct <- today(tzone = "UCT")
today_date_uct_str <- paste0(strftime(today_date_uct, format = "%Y%m%d"), "00") # just midnight for now!
date_check <- ndfd_file_dates[ndfd_file_dates == today_date_uct_str]
# if statement that if length(date_check) < 1 then don't run this script
latest_uct_str <- "2020052800" # hardcode for now

# latest ndfd path strings
ndfd_latest_pop12_file_name <- paste0("pop12_", latest_uct_str, ".csv")
ndfd_latest_qpf_file_name <- paste0("qpf_", latest_uct_str, ".csv")


# ---- 4. load data ----
# pop12 tabular data
ndfd_pop12_data_raw <- read_csv(paste0(ndfd_data_path, ndfd_latest_pop12_file_name),
                                col_types = list(col_double(), col_double(), col_double(), col_double(), col_double(), col_double(), col_double(),
                                                 col_character(), col_character(), col_character(), col_character(), col_character()))

# qpf tabular data
ndfd_qpf_data_raw <- read_csv(paste0(ndfd_data_path, ndfd_latest_qpf_file_name),
                              col_types = list(col_double(), col_double(), col_double(), col_double(), col_double(), col_double(), col_double(),
                                               col_character(), col_character(), col_character(), col_character(), col_character()))
# nc buffer bounds vector
nc_buffer_albers <- st_read(paste0(nc_data_path, "nc_bounds_10kmbuf_albers.shp"))

# sga buffer bounds vector
sga_buffer_albers <- st_read(paste0(sga_data_path, "sga_bounds_buffer_albers.shp"))

# cmu buffer bounds vector
cmu_buffer_albers <- st_read(paste0(cmu_data_path, "cmu_bounds_buffer_albers.shp"))

# cmu bounds vector
cmu_bounds_albers <- st_read(paste0(cmu_data_path, "cmu_bounds_albers.shp"))


# ---- load functions ----




# ---- 5. wrangle ndfd tabular data ----
# initial clean up pop12
ndfd_pop12_data <- ndfd_pop12_data_raw %>%
  dplyr::select(x_index, y_index, latitude_km, longitude_km, time_uct, time_nyc, pop12_value_perc, valid_period_hrs) %>%
  dplyr::mutate(latitude_m = latitude_km * 1000,
                longitude_m = longitude_km * 1000)

# initial clean up qpf
ndfd_qpf_data <- ndfd_qpf_data_raw %>%
  dplyr::select(x_index, y_index, latitude_km, longitude_km, time_uct, time_nyc, qpf_value_kgperm2, valid_period_hrs) %>%
  dplyr::mutate(latitude_m = latitude_km * 1000,
                longitude_m = longitude_km * 1000,
                qpf_value_in = qpf_value_kgperm2 * (1/1000) * (100) * (1/2.54)) # convert to m (density of water is 1000 kg/m3) then cm then inches


# ---- 6. convert tabular ndfd data to (vector) spatial data ----
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
ˆ
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


# ---- 7. convert vector ndfd data to raster data ----
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
ndfd_pop12_raster_1day_albers <- raster::rasterize(ndfd_pop12_albers_1day, ndfd_pop12_grid_1day, field = ndfd_pop12_albers_1day$pop12_value_perc, fun = mean)
# crs(ndfd_pop12_grid_1day_albers)
ndfd_pop12_raster_2day_albers <- raster::rasterize(ndfd_pop12_albers_2day, ndfd_pop12_grid_2day, field = ndfd_pop12_albers_2day$pop12_value_perc, fun = mean)
ndfd_pop12_raster_3day_albers <- raster::rasterize(ndfd_pop12_albers_3day, ndfd_pop12_grid_3day, field = ndfd_pop12_albers_3day$pop12_value_perc, fun = mean)

# rasterize qpf for 1-day, 2-day, and 3-day forecasts
ndfd_qpf_raster_1day_albers <- raster::rasterize(ndfd_qpf_albers_1day, ndfd_qpf_grid_1day, field = ndfd_qpf_albers_1day$qpf_value_in, fun = mean)
# crs(ndfd_qpf_grid_1day_albers)
# na_albers_proj4 # it's missing the ellps-GRS80, not sure why...
ndfd_qpf_raster_2day_albers <- raster::rasterize(ndfd_qpf_albers_2day, ndfd_qpf_grid_2day, field = ndfd_qpf_albers_2day$qpf_value_in, fun = mean)
ndfd_qpf_raster_3day_albers <- raster::rasterize(ndfd_qpf_albers_3day, ndfd_qpf_grid_3day, field = ndfd_qpf_albers_3day$qpf_value_in, fun = mean)

# plot to check
# plot(ndfd_pop12_raster_1day_albers)
# plot(ndfd_qpf_raster_1day_albers)
# plot(ndfd_pop12_raster_2day_albers)
# plot(ndfd_qpf_raster_2day_albers)
# plot(ndfd_pop12_raster_3day_albers)
# plot(ndfd_qpf_raster_3day_albers)


# ---- 8. crop midatlantic raster ndfd data to nc bounds ----
# pop12 for 1-day, 2-day, and 3-day forecasts
ndfd_pop12_raster_1day_nc_albers <- raster::crop(ndfd_pop12_raster_1day_albers, nc_buffer_albers)
ndfd_pop12_raster_2day_nc_albers <- raster::crop(ndfd_pop12_raster_2day_albers, nc_buffer_albers)
ndfd_pop12_raster_3day_nc_albers <- raster::crop(ndfd_pop12_raster_3day_albers, nc_buffer_albers)

# qpf for 1-day, 2-day, and 3-day forecasts
ndfd_qpf_raster_1day_nc_albers <- raster::crop(ndfd_qpf_raster_1day_albers, nc_buffer_albers)
ndfd_qpf_raster_2day_nc_albers <- raster::crop(ndfd_qpf_raster_2day_albers, nc_buffer_albers)
ndfd_qpf_raster_3day_nc_albers <- raster::crop(ndfd_qpf_raster_3day_albers, nc_buffer_albers)

# plot to check
# plot(nc_buffer_albers)
# plot(ndfd_pop12_raster_1day_nc_albers)
# plot(ndfd_qpf_raster_1day_nc_albers)
# plot(ndfd_pop12_raster_2day_nc_albers)
# plot(ndfd_qpf_raster_2day_nc_albers)
# plot(ndfd_pop12_raster_3day_nc_albers)
# plot(ndfd_qpf_raster_3day_nc_albers)

# project pop12 to wgs84 toofor 1-day, 2-day, and 3-day forecasts
# ndfd_pop12_raster_1day_nc_wgs84 <- projectRaster(ndfd_pop12_raster_1day_nc_albers, crs = wgs84_proj4)
# ndfd_pop12_raster_2day_nc_wgs84 <- projectRaster(ndfd_pop12_raster_2day_nc_albers, crs = wgs84_proj4)
# ndfd_pop12_raster_3day_nc_wgs84 <- projectRaster(ndfd_pop12_raster_3day_nc_albers, crs = wgs84_proj4)

# project qpf to wgs84 too for 1-day, 2-day, and 3-day forecasts
# ndfd_qpf_raster_1day_nc_wgs84 <- projectRaster(ndfd_qpf_raster_1day_nc_albers, crs = wgs84_proj4)
# ndfd_qpf_raster_2day_nc_wgs84 <- projectRaster(ndfd_qpf_raster_2day_nc_albers, crs = wgs84_proj4)
# ndfd_qpf_raster_3day_nc_wgs84 <- projectRaster(ndfd_qpf_raster_3day_nc_albers, crs = wgs84_proj4)

# plot to check
# plot(ndfd_pop12_raster_1day_nc_wgs84)
# plot(ndfd_qpf_raster_1day_nc_wgs84)
# plot(ndfd_pop12_raster_2day_nc_wgs84)
# plot(ndfd_qpf_raster_2day_nc_wgs84)
# plot(ndfd_pop12_raster_3day_nc_wgs84)
# plot(ndfd_qpf_raster_3day_nc_wgs84)


# ---- 9. export nc raster ndfd data ----
# export pop12 rasters for 1-day, 2-day, and 3-day forecasts
# writeRaster(ndfd_pop12_raster_1day_nc_albers, paste0(ndfd_sco_spatial_data_export_path, "pop12_", latest_uct_str, "_24hr_nc_albers.tif"), overwrite = TRUE)
# writeRaster(ndfd_pop12_raster_2day_nc_albers, paste0(ndfd_sco_spatial_data_export_path, "pop12_", latest_uct_str, "_48hr_nc_albers.tif"), overwrite = TRUE)
# writeRaster(ndfd_pop12_raster_3day_nc_albers, paste0(ndfd_sco_spatial_data_export_path, "pop12_", latest_uct_str, "_78hr_nc_albers.tif"), overwrite = TRUE)

# export qpf rasters for 1-day, 2-day, and 3-day forecasts
# writeRaster(ndfd_qpf_raster_1day_nc_albers, paste0(ndfd_sco_spatial_data_export_path, "qpf_", latest_uct_str, "_24hr_nc_albers.tif"), overwrite = TRUE)
# writeRaster(ndfd_qpf_raster_2day_nc_albers, paste0(ndfd_sco_spatial_data_export_path, "qpf_", latest_uct_str, "_48hr_nc_albers.tif"), overwrite = TRUE)
# writeRaster(ndfd_qpf_raster_3day_nc_albers, paste0(ndfd_sco_spatial_data_export_path, "qpf_", latest_uct_str, "_72hr_nc_albers.tif"), overwrite = TRUE)

# export pop12 rasters as wgs84 too for 1-day, 2-day, and 3-day forecasts
# writeRaster(ndfd_pop12_raster_1day_nc_wgs84, paste0(ndfd_sco_spatial_data_export_path, "pop12_", latest_uct_str, "_24hr_nc_wgs84.tif"), overwrite = TRUE)
# writeRaster(ndfd_pop12_raster_2day_nc_wgs84, paste0(ndfd_sco_spatial_data_export_path, "pop12_", latest_uct_str, "_48hr_nc_wgs84.tif"), overwrite = TRUE)
# writeRaster(ndfd_pop12_raster_3day_nc_wgs84, paste0(ndfd_sco_spatial_data_export_path, "pop12_", latest_uct_str, "_78hr_nc_wgs84.tif"), overwrite = TRUE)

# export qpf rasters as wgs84 too for 1-day, 2-day, and 3-day forecasts
# writeRaster(ndfd_qpf_raster_1day_nc_wgs84, paste0(ndfd_sco_spatial_data_export_path, "qpf_", latest_uct_str, "_24hr_nc_wgs84.tif"), overwrite = TRUE)
# writeRaster(ndfd_qpf_raster_2day_nc_wgs84, paste0(ndfd_sco_spatial_data_export_path, "qpf_", latest_uct_str, "_48hr_nc_wgs84.tif"), overwrite = TRUE)
# writeRaster(ndfd_qpf_raster_3day_nc_wgs84, paste0(ndfd_sco_spatial_data_export_path, "qpf_", latest_uct_str, "_72hr_nc_wgs84.tif"), overwrite = TRUE)


# ---- 10. crop nc raster ndfd data to sga bounds ----
# pop12 for 1-day, 2-day, and 3-day forecasts
ndfd_pop12_raster_1day_sga_albers <- raster::crop(ndfd_pop12_raster_1day_albers, sga_buffer_albers)
ndfd_pop12_raster_2day_sga_albers <- raster::crop(ndfd_pop12_raster_2day_albers, sga_buffer_albers)
ndfd_pop12_raster_3day_sga_albers <- raster::crop(ndfd_pop12_raster_3day_albers, sga_buffer_albers)

# qpf for 1-day, 2-day, and 3-day forecasts
ndfd_qpf_raster_1day_sga_albers <- raster::crop(ndfd_qpf_raster_1day_albers, sga_buffer_albers)
ndfd_qpf_raster_2day_sga_albers <- raster::crop(ndfd_qpf_raster_2day_albers, sga_buffer_albers)
ndfd_qpf_raster_3day_sga_albers <- raster::crop(ndfd_qpf_raster_3day_albers, sga_buffer_albers)

# plot to check
# plot(ndfd_pop12_raster_1day_sga_albers)
# plot(ndfd_qpf_raster_1day_sga_albers)
# plot(ndfd_pop12_raster_2day_sga_albers)
# plot(ndfd_qpf_raster_2day_sga_albers)
# plot(ndfd_pop12_raster_3day_sga_albers)
# plot(ndfd_qpf_raster_3day_sga_albers)

# project pop12 to wgs84 toofor 1-day, 2-day, and 3-day forecasts
# ndfd_pop12_raster_1day_sga_wgs84 <- projectRaster(ndfd_pop12_raster_1day_sga_albers, crs = wgs84_proj4)
# ndfd_pop12_raster_2day_sga_wgs84 <- projectRaster(ndfd_pop12_raster_2day_sga_albers, crs = wgs84_proj4)
# ndfd_pop12_raster_3day_sga_wgs84 <- projectRaster(ndfd_pop12_raster_3day_sga_albers, crs = wgs84_proj4)

# project qpf to wgs84 too for 1-day, 2-day, and 3-day forecasts
# ndfd_qpf_raster_1day_sga_wgs84 <- projectRaster(ndfd_qpf_raster_1day_sga_albers, crs = wgs84_proj4)
# ndfd_qpf_raster_2day_sga_wgs84 <- projectRaster(ndfd_qpf_raster_2day_sga_albers, crs = wgs84_proj4)
# ndfd_qpf_raster_3day_sga_wgs84 <- projectRaster(ndfd_qpf_raster_3day_sga_albers, crs = wgs84_proj4)

# plot to check
# plot(ndfd_pop12_raster_1day_sga_wgs84)
# plot(ndfd_qpf_raster_1day_sga_wgs84)
# plot(ndfd_pop12_raster_2day_sga_wgs84)
# plot(ndfd_qpf_raster_3day_sga_wgs84)
# plot(ndfd_pop12_raster_3day_sga_wgs84)
# plot(ndfd_qpf_raster_3day_sga_wgs84)


# ---- 11. export sga raster ndfd data ----
# export pop12 rasters for 1-day, 2-day, and 3-day forecasts
# writeRaster(ndfd_pop12_raster_1day_sga_albers, paste0(ndfd_sco_spatial_data_export_path, "pop12_", latest_uct_str, "_24hr_sga_albers.tif"), overwrite = TRUE)
# writeRaster(ndfd_pop12_raster_2day_sga_albers, paste0(ndfd_sco_spatial_data_export_path, "pop12_", latest_uct_str, "_48hr_sga_albers.tif"), overwrite = TRUE)
# writeRaster(ndfd_pop12_raster_3day_sga_albers, paste0(ndfd_sco_spatial_data_export_path, "pop12_", latest_uct_str, "_78hr_sga_albers.tif"), overwrite = TRUE)

# export qpf rasters for 1-day, 2-day, and 3-day forecasts
# writeRaster(ndfd_qpf_raster_1day_sga_albers, paste0(ndfd_sco_spatial_data_export_path, "qpf_", latest_uct_str, "_24hr_sga_albers.tif"), overwrite = TRUE)
# writeRaster(ndfd_qpf_raster_2day_sga_albers, paste0(ndfd_sco_spatial_data_export_path, "qpf_", latest_uct_str, "_48hr_sga_albers.tif"), overwrite = TRUE)
# writeRaster(ndfd_qpf_raster_3day_sga_albers, paste0(ndfd_sco_spatial_data_export_path, "qpf_", latest_uct_str, "_72hr_sga_albers.tif"), overwrite = TRUE)

# export pop12 rasters as wgs84 too for 1-day, 2-day, and 3-day forecasts
# writeRaster(ndfd_pop12_raster_1day_sga_wgs84, paste0(ndfd_sco_spatial_data_export_path, "pop12_", latest_uct_str, "_24hr_sga_wgs84.tif"), overwrite = TRUE)
# writeRaster(ndfd_pop12_raster_2day_sga_wgs84, paste0(ndfd_sco_spatial_data_export_path, "pop12_", latest_uct_str, "_48hr_sga_wgs84.tif"), overwrite = TRUE)
# writeRaster(ndfd_pop12_raster_3day_sga_wgs84, paste0(ndfd_sco_spatial_data_export_path, "pop12_", latest_uct_str, "_78hr_sga_wgs84.tif"), overwrite = TRUE)

# export qpf rasters as wgs84 too for 1-day, 2-day, and 3-day forecasts
# writeRaster(ndfd_qpf_raster_1day_sga_wgs84, paste0(ndfd_sco_spatial_data_export_path, "qpf_", latest_uct_str, "_24hr_sga_wgs84.tif"), overwrite = TRUE)
# writeRaster(ndfd_qpf_raster_2day_sga_wgs84, paste0(ndfd_sco_spatial_data_export_path, "qpf_", latest_uct_str, "_48hr_sga_wgs84.tif"), overwrite = TRUE)
# writeRaster(ndfd_qpf_raster_3day_sga_wgs84, paste0(ndfd_sco_spatial_data_export_path, "qpf_", latest_uct_str, "_72hr_sga_wgs84.tif"), overwrite = TRUE)


# ---- 12. crop sga raster ndfd data to cmu bounds ----
# 1-day pop12 for 1-day, 2-day, and 3-day forecasts
ndfd_pop12_raster_1day_cmu_albers <- raster::mask(ndfd_pop12_raster_1day_sga_albers, mask = cmu_buffer_albers)
ndfd_pop12_raster_2day_cmu_albers <- raster::mask(ndfd_pop12_raster_2day_sga_albers, mask = cmu_buffer_albers)
ndfd_pop12_raster_3day_cmu_albers <- raster::mask(ndfd_pop12_raster_3day_sga_albers, mask = cmu_buffer_albers)

# 1-day qpf for 1-day, 2-day, and 3-day forecasts
ndfd_qpf_raster_1day_cmu_albers <-  raster::mask(ndfd_qpf_raster_1day_sga_albers, mask = cmu_buffer_albers)
ndfd_qpf_raster_2day_cmu_albers <-  raster::mask(ndfd_qpf_raster_2day_sga_albers, mask = cmu_buffer_albers)
ndfd_qpf_raster_3day_cmu_albers <-  raster::mask(ndfd_qpf_raster_3day_sga_albers, mask = cmu_buffer_albers)

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

# plot to check
# plot(ndfd_pop12_raster_1day_cmu_wgs84)
# plot(ndfd_qpf_raster_1day_cmu_wgs84)
# plot(ndfd_pop12_raster_2day_cmu_wgs84)
# plot(ndfd_qpf_raster_2day_cmu_wgs84)
# plot(ndfd_pop12_raster_3day_cmu_wgs84)
# plot(ndfd_qpf_raster_3day_cmu_wgs84)


# ---- 13. export cmu raster ndfd data ----
# export pop12 rasters for 1-day, 2-day, and 3-day forecasts
# writeRaster(ndfd_pop12_raster_1day_cmu_albers, paste0(ndfd_sco_spatial_data_export_path, "pop12_", latest_uct_str, "_24hr_cmu_albers.tif"), overwrite = TRUE)
# writeRaster(ndfd_pop12_raster_2day_cmu_albers, paste0(ndfd_sco_spatial_data_export_path, "pop12_", latest_uct_str, "_48hr_cmu_albers.tif"), overwrite = TRUE)
# writeRaster(ndfd_pop12_raster_3day_cmu_albers, paste0(ndfd_sco_spatial_data_export_path, "pop12_", latest_uct_str, "_78hr_cmu_albers.tif"), overwrite = TRUE)

# export qpf rasters for 1-day, 2-day, and 3-day forecasts
# writeRaster(ndfd_qpf_raster_1day_cmu_albers, paste0(ndfd_sco_spatial_data_export_path, "qpf_", latest_uct_str, "_24hr_cmu_albers.tif"), overwrite = TRUE)
# writeRaster(ndfd_qpf_raster_2day_cmu_albers, paste0(ndfd_sco_spatial_data_export_path, "qpf_", latest_uct_str, "_48hr_cmu_albers.tif"), overwrite = TRUE)
# writeRaster(ndfd_qpf_raster_3day_cmu_albers, paste0(ndfd_sco_spatial_data_export_path, "qpf_", latest_uct_str, "_72hr_cmu_albers.tif"), overwrite = TRUE)

# export pop12 rasters as wgs84 too for 1-day, 2-day, and 3-day forecasts
# writeRaster(ndfd_pop12_raster_1day_cmu_wgs84, paste0(ndfd_sco_spatial_data_export_path, "pop12_", latest_uct_str, "_24hr_cmu_wgs84.tif"), overwrite = TRUE)
# writeRaster(ndfd_pop12_raster_2day_cmu_wgs84, paste0(ndfd_sco_spatial_data_export_path, "pop12_", latest_uct_str, "_48hr_cmu_wgs84.tif"), overwrite = TRUE)
# writeRaster(ndfd_pop12_raster_3day_cmu_wgs84, paste0(ndfd_sco_spatial_data_export_path, "pop12_", latest_uct_str, "_78hr_cmu_wgs84.tif"), overwrite = TRUE)

# export qpf rasters as wgs84 too for 1-day, 2-day, and 3-day forecasts
# writeRaster(ndfd_qpf_raster_1day_cmu_wgs84, paste0(ndfd_sco_spatial_data_export_path, "qpf_", latest_uct_str, "_24hr_cmu_wgs84.tif"), overwrite = TRUE)
# writeRaster(ndfd_qpf_raster_2day_cmu_wgs84, paste0(ndfd_sco_spatial_data_export_path, "qpf_", latest_uct_str, "_48hr_cmu_wgs84.tif"), overwrite = TRUE)
# writeRaster(ndfd_qpf_raster_3day_cmu_wgs84, paste0(ndfd_sco_spatial_data_export_path, "qpf_", latest_uct_str, "_72hr_cmu_wgs84.tif"), overwrite = TRUE)


# ---- 14. area weighted calcs for each cmu ----

# need to do this for pop12 and qpf and for 1-day, 2-day, and 3-day forecasts
ndfd_cmu_calcs_data <- data.frame(row_num = as.numeric(),
                             HA_CLASS = as.character(),
                             rainfall_thresh_in = as.numeric(),
                             datetime_uct = as.character(),
                             valid_period_hrs = as.numeric(),
                             pop12_perc = as.numeric(),
                             qpf_in = as.numeric(),
                             prob_close_perc = as.numeric())

# valid period list
valid_period_list <- c(24, 48, 72)

# rasters lists
pop12_raster_list <- c(ndfd_pop12_raster_1day_cmu_albers, ndfd_pop12_raster_2day_cmu_albers, ndfd_pop12_raster_3day_cmu_albers)
qpf_raster_list <- c(ndfd_qpf_raster_1day_cmu_albers, ndfd_qpf_raster_2day_cmu_albers, ndfd_qpf_raster_3day_cmu_albers)

# number of cmu's
num_cmu <- length(cmu_bounds_albers$HA_CLASS)

# row dimentions
num_row <- length(valid_period_list)*num_cmu

# set row number and start iterator
row_num_list <- seq(1:num_row)
row_num <- row_num_list[1]

# record start time
start_time <- now()

# for loop
# i denotes valid period (3 values), j denotes HA_CLASS (145 values)
for (i in 1:length(valid_period_list)) {
  for (j in 1:num_cmu) {
    # valid period
    temp_valid_period <- valid_period_list[i]
    
    # save raster
    temp_pop12_raster <- pop12_raster_list[i][[1]]
    temp_qpf_raster <- qpf_raster_list[i][[1]]
    
    # save raster resolution
    temp_pop12_raster_res <- raster::res(temp_pop12_raster)
    temp_qpf_raster_res <- raster::res(temp_qpf_raster)
    
    # save cmu name
    temp_cmu_name <- as.character(cmu_bounds_albers$HA_CLASS[j])
    
    # save cmu rainfall threshold value
    temp_cmu_rain_in <- as.numeric(cmu_bounds_albers$rain_in[j])
    
    # get cmu bounds vector
    temp_cmu_bounds <- cmu_bounds_albers %>%
      dplyr::filter(HA_CLASS == temp_cmu_name)
    
    # cmu bounds area
    temp_cmu_area <- as.numeric(st_area(temp_cmu_bounds)) # in m^2
    
    # make this a funciton that takes ndfd raster and temp_cmu_bounds and gives area wtd raster result
    temp_pop12_cmu_raster_empty <- raster()
    raster::extent(temp_pop12_cmu_raster_empty) <- raster::extent(temp_pop12_raster)
    raster::res(temp_pop12_cmu_raster_empty) <- raster::res(temp_pop12_raster)
    raster::crs(temp_pop12_cmu_raster_empty) <- raster::crs(temp_pop12_raster)
    
    temp_qpf_cmu_raster_empty <- raster()
    raster::extent(temp_qpf_cmu_raster_empty) <- raster::extent(temp_qpf_raster)
    raster::res(temp_qpf_cmu_raster_empty) <- raster::res(temp_qpf_raster)
    raster::crs(temp_qpf_cmu_raster_empty) <- raster::crs(temp_qpf_raster)
    
    # calculate percent cover cmu over raster
    temp_pop12_cmu_raster_perc_cover <- raster::rasterize(temp_cmu_bounds, temp_pop12_cmu_raster_empty, getCover = TRUE) # getCover give percentage of the cover of the cmu boundary in the raster
    temp_qpf_cmu_raster_perc_cover <- raster::rasterize(temp_cmu_bounds, temp_qpf_cmu_raster_empty, getCover = TRUE) # getCover give percentage of the cover of the cmu boundary in the raster
    
    # convert raster to dataframe
    temp_pop12_cmu_df <- data.frame(perc_cover = temp_pop12_cmu_raster_perc_cover@data@values, raster_value = temp_pop12_raster@data@values)
    temp_qpf_cmu_df <- data.frame(perc_cover = temp_qpf_cmu_raster_perc_cover@data@values, raster_value = temp_qpf_raster@data@values)
    
    # keep only dataframe entries with values and do spatial averaging calcs
    temp_pop12_cmu_df_short <- temp_pop12_cmu_df %>%
      na.omit() %>%
      dplyr::mutate(flag = if_else(perc_cover == 0, "no_data", "data")) %>%
      dplyr::filter(flag == "data") %>%
      dplyr::select(-flag) %>%
      dplyr::mutate(cmu_raster_area_m2 = perc_cover*(temp_qpf_raster_res[1]*temp_qpf_raster_res[2]))
    temp_qpf_cmu_df_short <- temp_qpf_cmu_df %>%
      na.omit() %>%
      dplyr::mutate(flag = if_else(perc_cover == 0, "no_data", "data")) %>%
      dplyr::filter(flag == "data") %>%
      dplyr::select(-flag) %>%
      dplyr::mutate(cmu_raster_area_m2 = perc_cover*(temp_qpf_raster_res[1]*temp_qpf_raster_res[2]))
    
    # find total area of raster represented
    temp_pop12_cmu_raster_area_sum_m2 = sum(temp_qpf_cmu_df_short$cmu_raster_area_m2)
    temp_qpf_cmu_raster_area_sum_m2 = sum(temp_qpf_cmu_df_short$cmu_raster_area_m2)
    
    # use total area to calculated weighted value
    temp_pop12_cmu_df_fin <- temp_pop12_cmu_df_short %>%
      dplyr::mutate(cmu_raster_area_perc = cmu_raster_area_m2/temp_pop12_cmu_raster_area_sum_m2,
                    raster_value_wtd = cmu_raster_area_perc * raster_value)
    temp_qpf_cmu_df_fin <- temp_qpf_cmu_df_short %>%
      dplyr::mutate(cmu_raster_area_perc = cmu_raster_area_m2/temp_qpf_cmu_raster_area_sum_m2,
                    raster_value_wtd = cmu_raster_area_perc * raster_value)
    
    # sum weighted values to get result
    temp_cmu_pop12_result <- round(sum(temp_pop12_cmu_df_fin$raster_value_wtd), 2)
    temp_cmu_qpf_result <- round(sum(temp_qpf_cmu_df_fin$raster_value_wtd), 2)
    
    # calculate probability of closure
    temp_cmu_prob_close_result <- round((temp_cmu_pop12_result * exp(-temp_cmu_rain_in/temp_cmu_qpf_result)), 1) # from equation 1 in proposal
    
    # save data
    temp_ndfd_cmu_calcs_data <- data.frame(row_num = row_num,
                                           HA_CLASS = temp_cmu_name,
                                           rainfall_thresh_in = temp_cmu_rain_in,
                                           datetime_uct = latest_uct_str,
                                           valid_period_hrs = temp_valid_period,
                                           pop12_perc = temp_cmu_pop12_result,
                                           qpf_in = temp_cmu_qpf_result,
                                           prob_close_perc = temp_cmu_prob_close_result)
    
    # bind results
    ndfd_cmu_calcs_data <-  rbind(ndfd_cmu_calcs_data, temp_ndfd_cmu_calcs_data)
    
    # next row
    print(paste0("finished row: ", row_num))
    row_num <- row_num + 1
  }
}

# print time now
stop_time <- now()

# time to run loop
stop_time - start_time
# Time difference of 3.33797 mins


# ---- 15. export calcs ----
# export calcs for 1-day, 2-day, and 3-day forecasts
write_csv(ndfd_cmu_calcs_data, paste0(ndfd_sco_tabular_data_export_path, "ndfd_cmu_calcs_", latest_uct_str, ".csv"))


# ----- text exp function ----
my_pop12 <- 50
my_qpf <- seq(from = 0, to = 5, by = 0.5)
my_thresh <- 4
my_pc <- my_pop12 * exp(-my_thresh/my_qpf)
plot(my_pc ~ my_qpf)


# ----- find values for leases ----
lease_data_path <- "/Users/sheila/Documents/bae_shellcast_project/shellcast_analysis/data/spatial/sheila_generated/"
lease_data <- st_read(paste0(lease_data_path, "leases_select_albers.shp"))

lease_cmu_data <- cmu_bounds_albers %>%
  st_intersection(lease_data) %>%
  dplyr::select(lease_id, HA_CLASS) %>%
  st_drop_geometry() %>%
  dplyr::left_join(ndfd_cmu_calcs_data, by = "HA_CLASS")

lease_cmu_prob_data <- lease_cmu_data %>%
  dplyr::mutate(day = ymd(str_sub(datetime_uct, start = 1, end = 8))) %>%
  dplyr::select(lease_id, day, valid_period_hrs, prob_close_perc) %>%
  dplyr::mutate(valid_period = case_when(valid_period_hrs == 24 ~ "prob_1d_perc",
                                         valid_period_hrs == 48 ~ "prob_2d_perc",
                                         valid_period_hrs == 72 ~ "prob_3d_perc")) %>%
  dplyr::select(lease_id, day, valid_period, prob_close_perc) %>%
  tidyr::pivot_wider(id_cols = c(lease_id, day), names_from = valid_period, values_from = prob_close_perc)


lease_cmu_rain_data <- lease_cmu_data %>%
  dplyr::mutate(day = ymd(str_sub(datetime_uct, start = 1, end = 8))) %>%
  dplyr::select(lease_id, day, valid_period_hrs, qpf_in) %>%
  dplyr::mutate(valid_period = case_when(valid_period_hrs == 24 ~ "rain_forecast_1d_in",
                                         valid_period_hrs == 48 ~ "rain_forecast_2d_in",
                                         valid_period_hrs == 72 ~ "rain_forecast_3d_in")) %>%
  dplyr::select(lease_id, valid_period, qpf_in) %>%
  tidyr::pivot_wider(id_cols = lease_id, names_from = valid_period, values_from = qpf_in)


lease_cmu_data_fin <- lease_cmu_prob_data %>%
  dplyr::left_join(lease_cmu_rain_data, by = "lease_id") %>%
  dplyr::select(lease_id, day, rain_forecast_1d_in:rain_forecast_3d_in, prob_1d_perc:prob_3d_perc)

write_csv(lease_cmu_data_fin, paste0(ndfd_sco_tabular_data_export_path, "ndfd_lease_calcs_", latest_uct_str, ".csv"))

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

