
# ---- script header ----
# script name: ncdmf_tidy_cmu_bounds_script.R
# purpose of script: reformats the Conditional Management Units shapefile for downstream use
# author: sheila saia
# date created: 20200416
# email: ssaia@ncsu.edu


# ----
# notes:
 

# ----
# to do list


# ---- 1. load libraries -----
# load libraries
library(tidyverse)
library(sf)


# ---- 2. define base paths ----
# base path to data
# data_base_path = "...analysis/data/" # set this and uncomment!
data_base_path = "/Users/sheila/Documents/bae_shellcast_project/shellcast_analysis/web_app_data/" 


# ---- 3. use base paths and define projections ----
# path to cmu spatial inputs
cmu_spatial_data_input_path <- paste0(data_base_path, "spatial/inputs/ncdmf_data/cmu_bounds/")

# path to rainfall threshold tabular inputs
rainfall_thresh_tabular_data_input_path <- paste0(data_base_path, "tabular/inputs/ncdmf_rainfall_thresholds/")


# path to cmu spatial outputs
cmu_spatial_data_output_path <- paste0(data_base_path, "spatial/inputs/ncdmf_data/cmu_bounds/")

# path to rainfall threshold tabular outputs
rainfall_thresh_tabular_data_output_path <- paste0(data_base_path, "tabular/inputs/ncdmf_rainfall_thresholds/")


# define epsg and proj4 for N. America Albers projection (projecting to this)
na_albers_proj4 <- "+proj=aea +lat_1=20 +lat_2=60 +lat_0=40 +lon_0=-96 +x_0=0 +y_0=0 +datum=NAD83 +units=m +no_defs"
na_albers_epsg <- 102008

# define wgs 84 projection
wgs84_epsg <- 4326


# ---- 4. load data ----
# cmu spatial data
cmu_bounds_raw <- st_read(paste0(cmu_spatial_data_input_path, "cmu_bounds_fix_bs10obx9a_valid.shp"))

# the file "cmu_bounds_fix_bs10obx9a_valid.shp" came from "Conditional_Management_Units.shp" from ncdmf
# i used the 'multipart split' editing tool to rename one of the two BS_1 cmu's
# i used the 'multipart merge' editing tool to merge two OBX_9A cmu's
# i then used 'fix geometires' and 'check validity' tools in QGIS to fix invalid geometries

# QGIS 'fix geometries' and 'check validity' tools version requirements
# QGIS version: 3.10.3-A Coruña
# QGIS code revision: 0e1f846438
# Qt version: 5.12.3
# GDAL version: 2.4.1
# GEOS version: 3.7.2-CAPI-1.11.2 b55d2125
# PROJ version: Rel. 5.2.0, September 15th, 2018

# run these two tools and fixed all invalid polygons
# saved fixed (and checked) file in QGIS as 'sga_bounds_raw_valid_wgs84.shp' in the 'data/spatial/sheila_generated/sga_bounds/' directory

# rainfall thresholds for cmu's
rain_thresh_full_data_raw <- read_csv(paste0(rainfall_thresh_tabular_data_input_path, "rainfall_thresholds.csv"), col_names = TRUE)


# ---- 5. tidy rainfall thresholds and join to cmu data ----
# select only columns we need
rain_thresh_data <- rain_thresh_full_data_raw %>%
  dplyr::select(HA_CLASS, rain_in = rainfall_threshold_in, rain_lab = rainfall_threshold_class) %>%
  distinct()
# length(unique(rain_thresh_data$HA_CLASS))
# 144 unique HA_CLASS values 

# check unique HA_CLASS values in cmu_bounds_raw
# length(unique(cmu_bounds_raw$HA_CLASS))
# 144 unique HA_CLASS values! it's fine!

# join to cmu_bounds_raw
cmu_bounds_raw_join <- cmu_bounds_raw %>%
  left_join(rain_thresh_data, by = "HA_CLASS")

# check that it joined
# names(cmu_bounds_raw_join)
# it checks!


# ---- 6. check spatial data projections ----
# check cmu data
# st_crs(cmu_bounds_raw_join)
# epsg 32119 (nc nad83)

# project to na albers
cmu_bounds_albers <- cmu_bounds_raw_join %>%
  st_transform(crs = na_albers_epsg)
# st_crs(cmu_bounds_albers)
# it checks!

# project to wgs84
cmu_bounds_wgs84 <- cmu_bounds_raw_join %>%
  st_transform(crs = wgs84_epsg)
# st_crs(cmu_bounds_wgs84)
# it checks!

# export data
st_write(cmu_bounds_albers, paste0(cmu_spatial_data_output_path, "cmu_bounds_albers.shp"), delete_layer = TRUE)
st_write(cmu_bounds_wgs84, paste0(cmu_spatial_data_output_path, "cmu_bounds_wgs84.shp"), delete_layer = TRUE)


# ---- 7. calculate simple buffer around cmu bounds ----
# cmu buffer
cmu_bounds_buffer_albers <- cmu_bounds_albers %>%
  st_convex_hull() %>% # for each cmu
  summarize() %>% # dissolve cmu bounds
  st_buffer(dist = 10000) %>% # buffer distance is in m so 10 * 1000m = 10km
  st_convex_hull() # simple buffer

# pdf(paste0(figure_path, "cmu_bounds_buffer.pdf"), width = 11, height = 8.5)
# ggplot(data = cmu_bounds_buffer_albers) +
#   geom_sf()
# dev.off()

# save a copy projected to wgs84
cmu_bounds_buffer_wgs84 <- cmu_bounds_buffer_albers %>%
  st_transform(crs = wgs84_epsg)

# export
st_write(cmu_bounds_buffer_albers, paste0(cmu_spatial_data_output_path, "cmu_bounds_10kmbuf_albers.shp"), delete_layer = TRUE)
st_write(cmu_bounds_buffer_wgs84, paste0(cmu_spatial_data_output_path, "cmu_bounds_10kmbuf_wgs84.shp"), delete_layer = TRUE)


# ---- 8. simplify rainfall threshhold data ----
# simplify rainfall thresholds for sharing with Andy
rain_thresh_short <- rain_thresh_full_data_raw %>%
  dplyr::select(-grow_area) %>%
  distinct()

# export data
write_csv(rain_thresh_short, paste0(rainfall_thresh_tabular_data_output_path, "rainfall_thresholds_no_ga.csv"))


