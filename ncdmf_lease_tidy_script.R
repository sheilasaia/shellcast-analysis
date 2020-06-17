# ---- script header ----
# script name: lease_tidy_script.R
# purpose of script: tidy up lease data from nc dmf
# author: sheila saia
# date created: 20200617
# email: ssaia@ncsu.edu


# ---- notes ----
# notes:
 

# ---- to do ----
# to do list


# ---- 1. load libraries ----
library(tidyverse)
library(here)
library(sf)
library(geojsonsf)


# ---- 2. defining paths and projections ----
# path to data
ndfd_data_path <- "/Users/sheila/Documents/bae_shellcast_project/shellcast_analysis/data/spatial/sheila_generated/"

lease_data_raw <- st_read(paste0(ndfd_data_path, "leases_select.shp"))

st_crs(lease_data_raw) # epsg = 2264

# define epsg and proj4 for N. America Albers projection (projecting to this)
na_albers_proj4 <- "+proj=aea +lat_1=20 +lat_2=60 +lat_0=40 +lon_0=-96 +x_0=0 +y_0=0 +datum=NAD83 +units=m +no_defs"
na_albers_epsg <- 102008

# define wgs 84 projection
wgs84_epsg <- 4326
wgs84_proj4 <- "+proj=longlat +datum=WGS84 +no_defs"

lease_data_albers <- lease_data_raw %>%
  st_transform(crs = na_albers_epsg) %>%
  dplyr::select(lease_id = ProductNbr,
                owner = Owner,
                type = Type_,
                area_ac = A_Granted,
                status = Status,
                water_body = WB_Name,
                county = County)

st_crs(lease_data_albers)

lease_data_centroid_albers <- lease_data_albers %>%
  st_centroid()

#st_write(lease_data_albers, paste0(ndfd_data_path, "leases_select_albers.shp"))
#st_write(lease_data_centroid_albers, paste0(ndfd_data_path, "leases_select_centroid_albers.shp"))

lease_data_wgs94 <- lease_data_albers %>%
  st_transform(crs = wgs84_epsg)
lease_data_centroid_wgs94 <- lease_data_centroid_albers %>%
  st_transform(crs = wgs84_epsg)

lease_data_wgs94_geojson <- sf_geojson(lease_data_wgs94, atomise = FALSE, simplify = TRUE, digits = 5)
lease_data_centroid_wgs94_geojson <- sf_geojson(lease_data_centroid_wgs94, atomise = FALSE, simplify = TRUE, digits = 5)

#write_file(lease_data_wgs94_geojson, paste0(ndfd_data_path, "leases_select_wgs84.geojson"))
#write_file(lease_data_centroid_wgs94_geojson, paste0(ndfd_data_path, "leases_select_centroid_wgs84.geojson"))
