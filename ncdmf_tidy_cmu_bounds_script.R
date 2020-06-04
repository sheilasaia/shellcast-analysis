
# ---- script header ----
# script name: ncdmf_tidy_cmu_bounds_script.R
# purpose of script: reformats the Conditional Management Units shapefile for downstream use
# author: sheila saia
# date created: 202004016
# email: ssaia@ncsu.edu


# ----
# notes:
 

# ----
# to do list


# ---- 1. load libraries ----=
# load libraries
library(tidyverse)
library(sf)


# ---- 2. set paths and define projections ----
# set paths
spatial_data_path <- "/Users/sheila/Documents/bae_shellcast_project/shellcast_analysis/data/spatial/sheila_generated/"
tabular_data_path <- "/Users/sheila/Documents/bae_shellcast_project/shellcast_analysis/data/tabular/sheila_generated/"

# export path for cmu bounds spatial data
spatial_data_export_path <- "/Users/sheila/Documents/bae_shellcast_project/shellcast_analysis/data/spatial/sheila_generated/cmu_bounds/"

# export path for rainfall threshold tabular data
tabular_data_export_path <- "/Users/sheila/Documents/bae_shellcast_project/shellcast_analysis/data/tabular/sheila_generated/"

# define epsg and proj4 for N. America Albers projection (projecting to this)
na_albers_proj4 <- "+proj=aea +lat_1=20 +lat_2=60 +lat_0=40 +lon_0=-96 +x_0=0 +y_0=0 +datum=NAD83 +units=m +no_defs"
na_albers_epsg <- 102008

# define wgs 84 projection
wgs84_epsg <- 4326


# ---- 3. load data ----
# cmu spatial data
cmu_bounds_raw <- st_read(paste0(spatial_data_path, "cmu_bounds/cmu_bounds_fix_bs10.shp"))

# rainfall thresholds for cmu's
rain_thresh_full_data_raw <- read_csv(paste0(tabular_data_path, "rainfall_thresholds.csv"), col_names = TRUE)


# ---- 4. check spatial data projections and project ----
# check cmu data
st_crs(cmu_bounds_raw)
# epsg 32119 (nc nad83)

# project to na albers
cmu_bounds_albers <- cmu_bounds_raw %>%
  st_transform(crs = na_albers_epsg)
# st_crs(cmu_bounds_albers)
# it checks!

# project to wgs84
cmu_bounds_wgs84 <- cmu_bounds_albers %>%
  st_transform(crs = wgs84_epsg)
# st_crs(cmu_bounds_wgs84)
# it checks!

# export data
st_write(cmu_bounds_albers, paste0(spatial_data_export_path, "cmu_bounds_albers.shp"))
st_write(cmu_bounds_albers, paste0(spatial_data_export_path, "cmu_bounds_wgs84.shp"))


# ---- 5. simplify rainfall threshhold data ----
# simplify rainfall thresholds for sharing with Andy
rain_thresh_short <- rain_thresh_full_data_raw %>%
  select(-grow_area) %>%
  distinct()

# export data
write_csv(rain_thresh_short, paste0(tabular_data_export_path, "rainfall_thresholds_no_ga.csv"))


# ---- 6. join rainfall thresholds with spatial cmu data ----
# check HA_CLASS in both
length(unique(cmu_bounds_albers$HA_CLASS)) # 144
length(unique(rain_thresh_full_data_raw$HA_CLASS)) #144
# same length, it checks!


 