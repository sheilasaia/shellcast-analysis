
# ---- script header ----
# script name: ncdmf_tidy_state_bounds_script.R
# purpose of script: tidying regional and state bounds for later calcs
# author: sheila saia
# date created: 20200604
# email: ssaia@ncsu.edu


# ---- notes ----
# notes:
 

# ---- to do ----
# to do list


# ---- 1. load libraries ----=
# load libraries
library(tidyverse)
library(sf)


# ---- 2. set paths and define projections ----
# set paths
spatial_data_path <- "/Users/sheila/Documents/bae_shellcast_project/shellcast_analysis/data/spatial/"

# export path for cmu bounds spatial data
spatial_data_export_path <- "/Users/sheila/Documents/bae_shellcast_project/shellcast_analysis/data/spatial/sheila_generated/region_state_bounds/"

# define epsg and proj4 for N. America Albers projection (projecting to this)
na_albers_proj4 <- "+proj=aea +lat_1=20 +lat_2=60 +lat_0=40 +lon_0=-96 +x_0=0 +y_0=0 +datum=NAD83 +units=m +no_defs"
na_albers_epsg <- 102008

# define wgs 84 projection
wgs84_epsg <- 4326


# ---- 3. load data ----
# state boundaries spatial data
state_bounds_raw <- st_read(paste0(spatial_data_path, "state_bounds/state_bounds.shp"))


# ---- 4. check spatial data projections and project ----
# check state bounds
st_crs(state_bounds_raw)
# epsg 5070 (albers conic equal area)

# project to na albers
state_bounds_albers <- state_bounds_raw %>%
  st_transform(crs = na_albers_epsg)
# st_crs(state_bounds_albers)
# it checks!

# project to wgs84
state_bounds_wgs84 <- state_bounds_raw %>%
  st_transform(crs = wgs84_epsg)
# st_crs(state_bounds_wgs84)
# it checks!

# export data
st_write(state_bounds_albers, paste0(spatial_data_export_path, "state_bounds_albers.shp"))
st_write(state_bounds_wgs84, paste0(spatial_data_export_path, "state_bounds_wgs84.shp"))


# ---- 5. select only nc bounds and buffer ----
# select and keep only geometry
nc_bounds_geom_albers <- state_bounds_albers %>%
  filter(NAME == "North Carolina") %>%
  st_geometry()

# keep a copy projected to wgs84 too
nc_bounds_geom_wgs84 <- nc_bounds_geom_albers %>%
  st_transform(crs = wgs84_epsg)

# export
st_write(nc_bounds_geom_albers, paste0(spatial_data_export_path, "nc_bounds_albers.shp"))
st_write(nc_bounds_geom_wgs84, paste0(spatial_data_export_path, "nc_bounds_wgs84.shp"))


# ---- 6. buffer bounds ----

# buffer 5 km
# nc_bounds_5kmbuf_albers <- nc_bounds_geom_albers %>%
#  st_buffer(dist = 5000) # distance is in m so 5 * 1000m = 5km

# buffer 10 km
nc_bounds_10kmbuf_albers <- nc_bounds_geom_albers %>%
  st_buffer(dist = 10000) # distance is in m so 10 * 1000m = 10km

# save a copy projected to wgs84
nc_bounds_10kmbuf_wgs84 <- nc_bounds_10kmbuf_albers %>%
  st_transform(crs = wgs84_epsg)

# export
# st_write(nc_bounds_5kmbuf_albers, paste0(spatial_data_export_path, "nc_bounds_5kmbuf_albers.shp"))
st_write(nc_bounds_10kmbuf_albers, paste0(spatial_data_export_path, "nc_bounds_10kmbuf_albers.shp"))
st_write(nc_bounds_10kmbuf_albers, paste0(spatial_data_export_path, "nc_bounds_10kmbuf_wgs84.shp"))

