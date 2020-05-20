
# script name: ncdmf_reformat_cmu_script.R
# purpose of script: reformats the Conditional Management Units shapefile for downstream use
# author: sheila saia
# date created: 202004016
# email: ssaia@ncsu.edu


# ----
# notes:
 

# ----
# to do list

# TODO ask andy why BS_10, NPT1, NPT2A, NPT2B, NPT3, NPT4, and NPT5 are missing from the cmu shp file
# TODO fix projection, don't use 5070, use 102008 instead

# ---- load libraries ----=
# load libraries
library(tidyverse)
library(sf)


# ---- setup ----
# set paths
spatial_data_path <- "/Users/sheila/Documents/bae_shellcast_project/shellcast_analysis/data/spatial/"
tabular_data_path <- "/Users/sheila/Documents/bae_shellcast_project/shellcast_analysis/data/tabular/"

# export path
spatial_data_export_path <- "/Users/sheila/Documents/bae_shellcast_project/shellcast_analysis/data/spatial/sheila_generated/"
tabular_data_export_path <- "/Users/sheila/Documents/bae_shellcast_project/shellcast_analysis/data/tabular/sheila_generated/"


# ---- load data ----
# cmu spatial data
cmu_shp_raw <- st_read(paste0(spatial_data_path, "ncdmf_raw/Conditional_Management_Units/Conditional_Management_Units.shp"))

# rainfall thresholds for cmu's
rain_thresh_data_raw <- read_csv(paste0(tabular_data_path, "sheila_generated/rainfall_thresholds.csv"), col_names = TRUE)

# state boundaries spatial data
state_bounds_shp_raw <- st_read(paste0(spatial_data_path, "state_bounds/state_bounds.shp"))


# ---- check spatial data projections (and project, if needed) ----
# check cmu data
st_crs(cmu_shp_raw)
# epsg 32119 (nc nad83)

# check state bounds
st_crs(state_bounds_shp_raw)
# epsg 5070 (albers conic equal area)

# define epsg and proj4 for N. America Albers projection (projecting to this)
na_albers_proj4 <- "+proj=aea +lat_1=20 +lat_2=60 +lat_0=40 +lon_0=-96 +x_0=0 +y_0=0 +datum=NAD83 +units=m +no_defs"
na_albers_epsg <- 102008

# FIX!
# projectd cmu data to albers conic equal area
#cmu_shp_raw_albers <- cmu_shp_raw %>%
#  st_transform(crs = 5070)
#st_crs(cmu_shp_raw_albers)
# ok!


# ---- select only nc bounds and buffer ----
# select and keep only geometry
nc_bounds_geom <- state_bounds_shp_raw %>%
  filter(NAME == "North Carolina") %>%
  st_geometry()

# buffer 5 km
nc_bounds_5km_buf <- nc_bounds_geom %>%
  st_buffer(dist = 5000) # distance is in m so 5 * 1000m = 5km

# export
st_write(obj = nc_bounds_geom, paste0(spatial_data_export_path, "nc_bounds.shp"))
st_write(obj = nc_bounds_5km_buf, paste0(spatial_data_export_path, "nc_bounds_5km_buf.shp"))



# ---- join rainfall thresholds with spatial cmu data ----
# check HA_CLASS in both
length(unique(cmu_shp_raw_albers$HA_CLASS)) # 143
length(unique(rain_thresh_data_raw$HA_CLASS)) #144

# not the same length use antijoin to find ones in common
cmu_tabular <- cmu_shp_raw_albers %>% 
  st_drop_geometry()
cmu_antijoin <- anti_join(rain_thresh_data_raw, cmu_tabular, by = "HA_CLASS")
cmu_antijoin
# spatial data is missing BS_10, NPT1, NPT2A, NPT2B, NPT3, NPT4, and NPT5


 