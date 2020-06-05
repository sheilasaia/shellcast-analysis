
# ---- script header ----
# script name: ncdmf_tidy_sga_bounds_script.R
# purpose of script: wrangling nc dmf shellfish growing area (sga) data
# author: sheila saia
# date created: 20200508
# email: ssaia@ncsu.edu


# ---- notes ----
# notes:
 

# ---- to do ----
# to do list


# ---- 1. load libraries ----
# load libraries
library(tidyverse)
library(sf)
library(geojsonsf)


# ---- 2. define paths and projections ----
# data path
spatial_data_path <- "/Users/sheila/Documents/bae_shellcast_project/shellcast_analysis/data/spatial/sheila_generated/sga_bounds/"

# export path
# same as spatial_data_path for now
spatial_data_export_path <- "/Users/sheila/Documents/bae_shellcast_project/shellcast_analysis/data/spatial/sheila_generated/sga_bounds/"

# figure export path
figure_path <- "/Users/sheila/Documents/bae_shellcast_project/shellcast_analysis/results/figures/"

# define epsg and proj4 for N. America Albers projection
na_albers_proj4 <- "+proj=aea +lat_1=20 +lat_2=60 +lat_0=40 +lon_0=-96 +x_0=0 +y_0=0 +datum=NAD83 +units=m +no_defs"
na_albers_epsg <- 102008

# define wgs 84 projection
wgs84_epsg <- 4326


# ---- 3. load data ----
# shellfish growing area data that's been initially cleaned (see ncdmf_init_tidy_sga_bounds_script.R)
sga_bounds_raw <- st_read(paste0(spatial_data_path, "sga_bounds_raw_valid_wgs84.shp"))

# columns
# OBJECTID_1 - not really sure what these are but think these are all artifacts from ArcGIS
# REGION = region of coast (central, north, south) 
# GROW_AREA = growing area (GA) code is a two digits code (e.g., letter + number like A1), first digit (letter) is HA_AREA, second digist (number) is HA_SUBAREA
# DSHA_NAME = full written out name for location (e.g., Calabash Area)
# HA_NAME = full written out name for location given by HA_CODE (e.g., Calabash/Sunset Beach/Boneparte Creek Area)
# HA_CLASS = describes status of GA (restricted, conditionally approved - open, conditionally approved - closed, approved)
# HA_CLASSID = shorter version of HA_CLASS (R, CA-O, CA-C, APP)
# HA_STATUS = GA status (open or closed)
# MAP_NAME = contributing watershed/river (61 unique values)
# MAP_NUMBER = map number corresponding to MAP_NAME (51 unique values)
# MAP_ID = number from MAP_NUMBER and letter (?)
# COUNTY = county
# JURISDCTN = jursdiction (WRC, DMF)
# WATER_DES = inland, coastal, joint, land
# SURFACE = canal, land, water, mhw (?)
# RELAY = ? (NA, N/A, YES, LAND, NO)
# CREATOR = who created the area/data
# CREATED = date of creation of the area/data?
# UPDATED = date the area/data was updated?
# ACRES = area of grow area in acres
# SQ_MILES = area of grow area in sqare miles


# ---- 4. tidy sga bounds attribute data ----
# tidy data
sga_bounds <- sga_bounds_raw %>%
  mutate(grow_area_class = if_else(HA_CLASSID == "APP", "approved",
                            if_else(HA_CLASSID == "CA-O" | HA_CLASSID == "CA-C", "cond_approved",
                                    if_else(HA_CLASSID == "CSHA-P", "prohibited", "restricted"))), # don't care if they're open or closed, just if they are approved, conditionally approve, prohibited, or restricted
         grow_area_trim = str_trim(GROW_AREA, side = "both"),
         ha_area_fix = str_to_upper(str_sub(grow_area_trim, start = 1, end = 1)), # original HA_AREA has some NAs so generate from scratch
         ha_subarea_fix = str_pad(str_sub(grow_area_trim, start = 2, end = -1), 2, side = "left", "0"), # original HA_SUBAREA has some NAs so generate from scratch
         grow_area = paste0(ha_area_fix, ha_subarea_fix), 
         ha_name_fix = if_else(is.na(HA_NAME) == TRUE, as.character(DSHA_NAME), as.character(HA_NAME))) %>% # if there's no name use general name (i.e., DSHA_NAME)
  select(grow_area,
         grow_area_class, 
         region = REGION, 
         dsha_name = DSHA_NAME, 
         ha_name = HA_NAME,
         ha_name_fix,
         map_name = MAP_NAME, 
         county = COUNTY, 
         jursidiction = JURISDCTN,
         water_desc = WATER_DES,
         surface = SURFACE,
         creator = CREATOR) %>% # reorder columns
  arrange(grow_area, grow_area_class, ha_name) %>%
  mutate(row_id = seq(1:7033))

# filter out row 5399 and fix (only row with NULL ha_name_fix)
sga_bounds_row_5399_fix <- sga_bounds %>%
  filter(row_id == 5399)
sga_bounds_row_5399_fix$dsha_name <- "North River"
sga_bounds_row_5399_fix$ha_name_fix <- "North River"

# take out and add fixed version of row 5399 back and project
sga_bounds_albers <- sga_bounds %>%
  filter(row_id != 5399) %>%
  rbind(sga_bounds_row_5399_fix) %>%
  st_transform(crs = na_albers_epsg)
st_crs(sga_bounds_albers)

# check validity of polygons (shouldn't be a problem but just in case)
sga_bounds_albers$polygon_valid_check <- st_is_valid(sga_bounds_albers)

# look at invalid sga's
sga_bounds_albers_invalid_tabular <- sga_bounds_albers %>% 
  st_drop_geometry() %>%
  filter(polygon_valid_check == FALSE)
# there should be no invalid polygons which is true, so, check!

# save as wgs84 too
sga_bounds_wgs84 <- sga_bounds_albers %>%
  st_transform(crs = wgs84_epsg)

# export
# st_write(sga_bounds_albers, paste0(spatial_data_export_path, "sga_bounds_tidy_albers.shp"))
# st_write(sga_bounds_wgs84, paste0(spatial_data_export_path, "sga_bounds_tidy_wgs84.shp"))

# ---- 5. tidy sga boundaries by sga (simple boundary line) ----
# summarize boundaries (equivalent to spatial dissolve)
sga_bounds_simple_albers <- sga_bounds_albers %>%
  group_by(grow_area) %>% # group by sga name
  summarize() %>%
  st_buffer(dist = 1) %>% # distance units are meters
  st_simplify(preserveTopology = TRUE, dTolerance = 100) # in units of meters

# export data
# st_write(sga_bounds_simple_albers, paste0(spatial_data_export_path, "sga_bounds_simple_albers.shp"))

# save as wgs84 too
sga_bounds_simple_wgs84 <- sga_bounds_simple_albers %>%
  st_transform(crs = wgs84_epsg)

# export data
# st_write(sga_bounds_simple_wgs84, paste0(spatial_data_export_path, "sga_bounds_simple_wgs84.shp"))

# simplify further to reduce geoJSON size for the web app
sga_bounds_simple_wgs84_geojson <- sf_geojson(sga_bounds_simple_wgs84, atomise = FALSE, simplify = TRUE, digits = 5)

# export geoJSON
# write_file(sga_bounds_simple_wgs84_geojson, paste0(spatial_data_export_path, "sga_bounds_simple_wgs84.geojson"))


# ---- 6. calculate simple buffer around sga bounds ----
# sga buffer
sga_bounds_buffer_albers <- sga_bounds_simple_albers %>%
  st_convex_hull() %>% # for each sga
  summarize() %>% # dissolve sga bounds
  st_buffer(dist = 10000) %>% # buffer distance is in m so 10 * 1000m = 10km
  st_convex_hull() # simple buffer

# pdf(paste0(figure_path, "sga_bounds_buffer.pdf"), width = 11, height = 8.5)
# ggplot(data = sga_bounds_buffer_albers) +
#   geom_sf()
# dev.off()

# save a copy projected to wgs84
sga_bounds_buffer_wgs84 <- sga_bounds_buffer_albers %>%
  st_transform(crs = wgs84_epsg)

# export
st_write(sga_bounds_buffer_albers, paste0(spatial_data_export_path, "sga_bounds_buffer_albers.shp"))
st_write(sga_bounds_buffer_wgs84, paste0(spatial_data_export_path, "sga_bounds_buffer_wgs84.shp"))


# ---- 7. tidy sga boundaries by sga and class ----
# summarize boundaries (equivalent to spatial dissolve)
sga_bounds_class_albers <- sga_bounds_albers %>%
  group_by(grow_area, grow_area_class, ha_name_fix) %>% # group by sga name and class
  summarize() %>%
  st_buffer(dist = 1) # buffer 1 m

# export data
# st_write(sga_bounds_class_albers, paste0(spatial_data_export_path, "sga_bounds_class_albers.shp"))

# save as wgs84 too
sga_bounds_class_wgs84 <- sga_bounds_class_albers %>%
  st_transform(crs = wgs84_epsg)

# export data
# st_write(sga_bounds_class_wgs84, paste0(spatial_data_export_path, "sga_bounds_class_wgs84.shp"))





