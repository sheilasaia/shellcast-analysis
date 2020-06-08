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

# cmu buffer data path
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


# ---- 3. load data ----
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

# cmu bounds vector
cmu_buffer_albers <- st_read(paste0(cmu_data_path, "cmu_bounds_buffer_albers.shp"))

# cmu data vector
cmu_bouns_albers <- st_read(paste0(cmu_data_path, "cmu_bounds_albers.shp"))


# ---- 4. wrangle ndfd tabular data ----
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


# ---- 5. convert tabular ndfd data to (vector) spatial data ----
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
unique(ndfd_pop12_albers$valid_period_hrs)

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
unique(ndfd_qpf_albers$valid_period_hrs)

# select 1-day qpf
ndfd_qpf_albers_1day <- ndfd_qpf_albers %>%
  dplyr::filter(valid_period_hrs == 24)

# select 2-day qpf
ndfd_qpf_albers_2day <- ndfd_qpf_albers %>%
  dplyr::filter(valid_period_hrs == 48)

# select 3-day qpf
ndfd_qpf_albers_3day <- ndfd_qpf_albers %>%
  dplyr::filter(valid_period_hrs == 72)


# ---- 6. convert vector ndfd data to raster data ----
# make empty pop12 raster 1-day
ndfd_pop12_grid_1day <- raster(ncol = length(unique(ndfd_pop12_albers_1day$longitude_km)), 
                               nrows = length(unique(ndfd_pop12_albers_1day$latitude_km)), 
                               crs = na_albers_proj4,
                               ext = extent(ndfd_pop12_albers_1day)) #, 
#res = c(5000, 5000)) # b/c coordinates are in m this is 5km x 5km

# make empty qpf raster 1-day
ndfd_qpf_grid_1day <- raster(ncol = length(unique(ndfd_qpf_albers_1day$longitude_km)), 
                             nrows = length(unique(ndfd_qpf_albers_1day$latitude_km)), 
                             crs = na_albers_proj4,
                             ext = extent(ndfd_qpf_albers_1day)) #, 
#res = c(5000, 5000)) # b/c coordinates are in m this is 5km x 5km


# rasterize pop12
ndfd_pop12_raster_1day_albers <- rasterize(ndfd_pop12_albers_1day, ndfd_pop12_grid_1day, field = ndfd_pop12_albers_1day$pop12_value_perc, fun = mean)
# crs(ndfd_pop12_grid_1day_albers)

# rasterize qpf
ndfd_qpf_raster_1day_albers <- rasterize(ndfd_qpf_albers_1day, ndfd_qpf_grid_1day, field = ndfd_qpf_albers_1day$qpf_value_in, fun = mean)
# crs(ndfd_qpf_grid_1day_albers)
# na_albers_proj4 # it's missing the ellps-GRS80, not sure why...

# plot to check
plot(ndfd_pop12_raster_1day_albers)
plot(ndfd_qpf_raster_1day_albers)


# ---- 7. crop raster ndfd data to sga bounds ----
# 1-day pop12
ndfd_pop12_raster_1day_sga_albers <- crop(ndfd_pop12_raster_1day_albers, sga_buffer_albers)

# 1-day qpf
ndfd_qpf_raster_1day_sga_albers <- crop(ndfd_qpf_raster_1day_albers, sga_buffer_albers)

# plot to check
plot(ndfd_pop12_raster_1day_sga_albers)
plot(ndfd_qpf_raster_1day_sga_albers)

# project to wgs84 too
ndfd_pop12_raster_1day_sga_wgs84 <- projectRaster(ndfd_pop12_raster_1day_nc_albers, crs = wgs84_proj4)
ndfd_qpf_raster_1day_sga_wgs84 <- projectRaster(ndfd_qpf_raster_1day_nc_albers, crs = wgs84_proj4)
  
# plot to check
plot(ndfd_pop12_raster_1day_sga_wgs84)
plot(ndfd_qpf_raster_1day_sga_wgs84)


# ---- 8. export sga raster ndfd data ----
# export rasters
writeRaster(ndfd_pop12_raster_1day_sga_albers, paste0(ndfd_sco_spatial_data_export_path, "pop12_2020052800_24hr_sga_albers.tif"))
writeRaster(ndfd_qpf_raster_1day_sga_albers, paste0(ndfd_sco_spatial_data_export_path, "qpf_2020052800_24hr_sga_albers.tif"))

# export rasters as wgs84 too
writeRaster(ndfd_pop12_raster_1day_sga_wgs84, paste0(ndfd_sco_spatial_data_export_path, "pop12_2020052800_24hr_sga_wgs84.tif"))
writeRaster(ndfd_qpf_raster_1day_sga_wgs84, paste0(ndfd_sco_spatial_data_export_path, "qpf_2020052800_24hr_sga_wgs94.tif"))


# ---- 9. crop sga raster ndfd data to cmu bounds ----

# 1-day pop12
ndfd_pop12_raster_1day_cmu_albers <- mask(ndfd_pop12_raster_1day_sga_albers, mask = cmu_buffer_albers)

# 1-day qpf
ndfd_qpf_raster_1day_cmu_albers <-  mask(ndfd_qpf_raster_1day_sga_albers, mask = cmu_buffer_albers)

# plot to check
plot(ndfd_pop12_raster_1day_cmu_albers)
plot(ndfd_qpf_raster_1day_cmu_albers)

# project to wgs84 too
ndfd_pop12_raster_1day_cmu_wgs84 <- projectRaster(ndfd_pop12_raster_1day_cmu_albers, crs = wgs84_proj4)
ndfd_qpf_raster_1day_cmu_wgs84 <- projectRaster(ndfd_qpf_raster_1day_cmu_albers, crs = wgs84_proj4)

# plot to check
plot(ndfd_pop12_raster_1day_cmu_wgs84)
plot(ndfd_qpf_raster_1day_cmu_wgs84)


# ---- 8. export cmu raster ndfd data ----
# export rasters
writeRaster(ndfd_pop12_raster_1day_cmu_albers, paste0(ndfd_sco_spatial_data_export_path, "pop12_2020052800_24hr_cmu_albers.tif"))
writeRaster(ndfd_qpf_raster_1day_cmu_albers, paste0(ndfd_sco_spatial_data_export_path, "qpf_2020052800_24hr_cmu_albers.tif"))

# export rasters as wgs84 too
writeRaster(ndfd_pop12_raster_1day_cmu_wgs84, paste0(ndfd_sco_spatial_data_export_path, "pop12_2020052800_24hr_cmu_wgs84.tif"))
writeRaster(ndfd_qpf_raster_1day_cmu_wgs84, paste0(ndfd_sco_spatial_data_export_path, "qpf_2020052800_24hr_cmu_wgs94.tif"))


# ---- 9. area weighted calcs for each cmu ----

# need to do this for pop12 and qpf and for 1-day, 2-day, and 3-day forecasts
temp_cmu_name <- as.character(cmu_bounds_albers$HA_CLASS[1])
temp_cmu <- cmu_bounds_albers %>%
  filter(HA_CLASS == temp_cmu_name) %>%
  st_transform(crs = wgs84_epsg)
temp_cmu_buffer <- cmu_bounds_albers %>%
  filter(HA_CLASS == temp_cmu_name) %>%
  st_buffer(dist = 5000) # buffer distance is in m so 5 * 1000m = 5km
# temp_cmu_bbox <- st_bbox(temp_cmu_buffer)
temp_cmu_raster_empty <- raster()
extent(temp_cmu_raster_empty) <- extent(ndfd_pop12_raster_1day_cmu_albers)
res(temp_cmu_raster_empty) <- res(ndfd_pop12_raster_1day_cmu_albers)
crs(temp_cmu_raster_empty) <- crs(ndfd_pop12_raster_1day_cmu_albers)
temp_cmu_raster_mask <- rasterize(temp_cmu_buffer, temp_cmu_raster_empty)
plot(temp_cmu_raster_mask)
temp_pop12_1day_cmu_data <- mask(ndfd_pop12_raster_1day_cmu_albers, mask = temp_cmu_raster_mask)
# extent(temp_pop12_1day_cmu_data) <- c(as.numeric(temp_cmu_bbox[1]), as.numeric(temp_cmu_bbox[3]), as.numeric(temp_cmu_bbox[2]), as.numeric(temp_cmu_bbox[4]))
plot(temp_pop12_1day_cmu_data)

temp_pop12_1day_cmu_data_wgs84 <- projectRaster(temp_pop12_1day_cmu_data, crs = wgs84_proj4)
# writeRaster(temp_pop12_1day_cmu_data_wgs84, paste0(ndfd_sco_spatial_data_export_path, "test.tif"), overwrite=TRUE)
test <- rasterToPolygons(temp_pop12_1day_cmu_data_wgs84)
test_sf <- st_as_sf(test)
# st_write(test_sf, paste0(ndfd_sco_spatial_data_export_path, "test2.shp"), overwrite=TRUE)
test_clip <- st_intersection(test_sf, temp_cmu)
# cmu has some non-valid geometries need to go back and fix these!




# ---- wrangle data ----

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

