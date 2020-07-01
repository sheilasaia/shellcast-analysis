# ---- script header ----
# script name: ncdmf_tidy_lease_data_script.R
# purpose of script: tidy up lease data from nc dmf
# author: sheila saia
# date created: 20200617
# email: ssaia@ncsu.edu


# ---- notes ----
# notes:
 
# raw data column metadata
# ProductNbr - lease id
# Assoc_ID - another id associated with the lease id (we don't need to worry about this)
# Owner - owner/business name
# Bus_Agent - business agent
# County - NC county that the business is in
# WB_Name - waterbody name (this is not the same as growing area)
# Type_ - lease type (bottom - rent rights to bottom, water column, franchise - own rights to bottom, research sanctuary, proposed, terminated)
# Status - status of the lease (there are lots of different unique values here)
# A_Granted - acres granted in the lease
# EffectiveD - date approved/renewed
# Expiration - expiration date of lease, 9996 and 9994 indicate a franchise - these have no expiration dates and if part or all is not in a cmu then can't harvest from it
# Term_Date - termination date (i.e., date when the leased area was terminated)


# ---- to do ----
# to do list

# TODO get this read to run in real-time
# TODO error if no no recent lease data available
# TODO need to export file with lease_id and geo bounds for database


# ---- 1. load libraries ----
library(tidyverse)
library(sf)
library(geojsonsf)
# library(here)


# ---- 2. defining paths and projections ----
# path to raw data
lease_raw_data_path <- "/Users/sheila/Documents/bae_shellcast_project/shellcast_analysis/data/web_app/spatial/ncdmf_raw/lease_bounds_raw/"

# export path
lease_export_data_path <- "/Users/sheila/Documents/bae_shellcast_project/shellcast_analysis/data/web_app/spatial/sheila_generated/lease_bounds/"

# define epsg and proj4 for N. America Albers projection (projecting to this)
na_albers_proj4 <- "+proj=aea +lat_1=20 +lat_2=60 +lat_0=40 +lon_0=-96 +x_0=0 +y_0=0 +datum=NAD83 +units=m +no_defs"
na_albers_epsg <- 102008

# define wgs 84 projection
wgs84_epsg <- 4326
wgs84_proj4 <- "+proj=longlat +datum=WGS84 +no_defs"


# ---- 3. load in latest least data ----
# list files in lease_bounds_raw
# lease_files <- list.files(lease_raw_data_path, pattern = "*.shp") # if there is a pop12 dataset there's a qpf dataset
lease_files <- c(lease_files, "leases_20200401.shp") # to test with multiple

# pull out date strings
lease_file_dates_str <- gsub("leases_", "", gsub(".shp", "", lease_files))

# convert date strings to dates
lease_file_dates <- lubridate::ymd(lease_file_dates_str)

# get today's date
today_date_uct <- lubridate::today(tzone = "UCT")

# calcualte difference
diff_file_dates <- as.numeric(today_date_uct - lease_file_dates) # in days

# find position of smallest difference
latest_date_uct <- lease_file_dates[diff_file_dates == min(diff_file_dates)]

# convert to string
latest_date_uct_str <- strftime(latest_date_uct, format = "%Y%m%d")

# need if statement that if length(date_check) < 1 then don't run this script

# use latest date to read in most recent data
lease_data_raw <- st_read(paste0(lease_raw_data_path, "leases_", latest_date_uct_str, ".shp"))

# check projection
# st_crs(lease_data_raw) # epsg = 2264


# ---- 3. project and tidy up lease data ----
lease_data_albers <- lease_data_raw %>%
  st_transform(crs = na_albers_epsg) %>% # project
  dplyr::select(lease_id = ProductNbr, # tidy
                owner = Owner,
                type = Type_,
                area_ac = A_Granted,
                status = Status,
                water_body = WB_Name,
                county = County)

# check projection
# st_crs(lease_data_albers)


# ---- 4. find centroids of leases ----
# calculate centroids of leases for map pins
lease_data_centroid_albers <- lease_data_albers %>%
  st_centroid()


# ---- 5. project data ----
# project data and centroids to wgs84 projection
lease_data_wgs94 <- lease_data_albers %>%
  st_transform(crs = wgs84_epsg)
lease_data_centroid_wgs94 <- lease_data_centroid_albers %>%
  st_transform(crs = wgs84_epsg)

# project data to geojson file type (need this for the web app)
lease_data_wgs94_geojson <- sf_geojson(lease_data_wgs94, atomise = FALSE, simplify = TRUE, digits = 5)
lease_data_centroid_wgs94_geojson <- sf_geojson(lease_data_centroid_wgs94, atomise = FALSE, simplify = TRUE, digits = 5)


# ---- 6. export data ----
# export data as shape file for record keeping
st_write(lease_data_albers, paste0(lease_export_data_path, "leases_albers_", latest_date_uct_str, ".shp"))
st_write(lease_data_centroid_albers, paste0(lease_export_data_path, "leases_centroids_albers_", latest_date_uct_str, ".shp"))

# select leases (ignore in production)
# st_write(lease_data_albers, paste0(lease_export_data_path, "leases_select_albers.shp"))
# st_write(lease_data_centroid_albers, paste0(lease_export_data_path, "leases_select_centroid_albers.shp"))

# export data as geojson for web app
write_file(lease_data_wgs94_geojson, paste0(lease_export_data_path, "leases_wgs84.geojson"))
write_file(lease_data_centroid_wgs94_geojson, paste0(lease_export_data_path, "leases_centroid_wgs84.geojson"))

# select leases (ignore in production)
# write_file(lease_data_wgs94_geojson, paste0(lease_export_data_path, "leases_select_wgs84.geojson"))
# write_file(lease_data_centroid_wgs94_geojson, paste0(lease_export_data_path, "leases_select_centroid_wgs84.geojson"))


# raw lease data to wgs84 and geojson (for stanton)
# lease_data_raw_wgs84 <- lease_data_raw %>%
#   st_transform(crs = wgs84_epsg)
# st_crs(lease_data_raw_wgs84)
# lease_data_raw_wgs84_geojson <- sf_geojson(lease_data_raw_wgs84, atomise = FALSE, simplify = TRUE, digits = 5)
# write_file(lease_data_raw_wgs84_geojson, paste0(lease_data_path, "leases_select_raw_wgs84.geojson"))
