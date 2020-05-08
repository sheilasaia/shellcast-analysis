
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


# ---- 1. load libraries and set paths----
# load libraries
library(tidyverse)
library(sf)

# set paths
spatial_data_path <- "/Users/sheila/Documents/bae_shellcast_project/shellcast_analysis/data/spatial/ncdmf_raw/"

# export path
spatial_data_export_path <- "/Users/sheila/Documents/bae_shellcast_project/shellcast_analysis/data/spatial/sheila_generated/"


# ---- 2. load data ----

# shellfish growing area data
sga_data_raw <- st_read(paste0(spatial_data_path, "SGA_Current_Classifications_may2019/SGA_Current_Classifications.shp"))

# columns
# OBJECTID_1, OBJECTID_2, OBJECTID, OBJECTID_3, SGA_INDEX - not really sure what these are but think these are all artifacts from ArcGIS
# REGION = region of coast (central, north, south) 
# GROW_AREA = growing area (GA) code is a two digits code (e.g., letter + number like A1), first digit (letter) is HA_AREA, second digist (number) is HA_SUBAREA
# DSHA_NAME = full written out name for location (e.g., Calabash Area)
# DSHA_ID = like GA code but has dash between digits (e.g., A-1)
# DSHA_AREA = first digit of GA (e.g., letter like A)
# DSHA_CODE = like GA code but lower case letter (e.g., a1)
# DSHA_LABEL = same as DSHA_ID
# HA_CLASS = describes status of GA (restricted, conditionally approved - open, conditionally approved - closed, approved)
# HA_CLASSID = shorter version of HA_CLASS (R, CA-O, CA-C, APP)
# HA_NAME = full written out name for location given by HA_CODE (e.g., Calabash/Sunset Beach/Boneparte Creek Area)
# HA_NAMEID = like HA_CODE but with dashes and spaces (e.g., A-1 CA-C 1)
# HA_STATUS = GA status (open or closed)
# HA_AREA = first digit letter of GA (e.g., A), A through I
# HA_SUBAREA = second digit number of GA (e.g., 1)
# HA_CODE = like GA code but has additional information including status and subsub area (e.g., a1cac1)
# HA_LABEL = same as HA_NAMEID
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
# SHAPE_Leng = ?
# Shape_Le_1 = ?
# GlobalID = ?
# SHAPE_Le_2 =? 
# GlobalID_2 = ?
# Shape__Are = ?
# Shape__Len = ?
# GlobalID_3 = ?
# Shape__A_1 = ?
# Shape__L_1 = ?

# other observations
# 1. as far as I can tell DSHA_CODE, HA_NAMEID, HA_AREA, HA_SUBAREA all have similar info to GROW_AREA
# 2. HA_LABEL,DSHA_LABEL, and MAP_ID have a lot of NA values (not filled in values) so might not be very helpful
# 3. HA_CODE has a third digit (i.e., letters) that GROW_AREA does not have - will need this
# 4. DSHA_NAME and HA_NAME are similar but looks like HA_NAME has more detail (going along with HA_NAMEID and HA_CODE)
# 5. some of the MAP_NAME and MAP_NUMBER columns are NA values
# 6. what's the details with the UPDATED column?
# 7. sometimes HA_AREA and HA_SUBAREA are not given even though GROW_AREA is
# 8. HA_AREA and HA_SUBAREA are never given if GROW_AREA is not given - basically they're not too helpful

# ---- 3. tidy sga bounds ----

# tidy data
sga_bounds <- sga_data_raw %>%
  select(GROW_AREA, REGION, DSHA_NAME, HA_CLASS, HA_CLASSID, HA_NAME, MAP_NAME, COUNTY, JURISDCTN, WATER_DES, SURFACE, CREATOR) %>%
  filter(is.na(GROW_AREA) != TRUE) %>% # delete rows where no ga given
  mutate(grow_area_class = if_else(HA_CLASSID == "APP", "approved",
                            if_else(HA_CLASSID == "CA-O" | HA_CLASSID == "CA-C", "cond_approved",
                                    if_else(HA_CLASSID == "CSHA-P", "prohibited", "restricted")))) %>% # don't care if they're open or closed, just if they are approved, conditionally approve, prohibited, or restricted
  select(grow_area = GROW_AREA, 
         grow_area_class, 
         region = REGION, 
         dsha_name = DSHA_NAME, 
         ha_name = HA_NAME,
         map_name = MAP_NAME, 
         county = COUNTY, 
         jursidiction = JURISDCTN,
         water_desc = WATER_DES,
         surface = SURFACE,
         creator = CREATOR)# reorder columns

# check validity of polygons
sga_bounds$polygon_valid_check <- st_is_valid(sga_bounds)

# filter by only polygons that are valid
sga_bounds_valid <- sga_bounds %>%
  filter(polygon_valid_check == TRUE)

# steps to get data into polygons (did this in qgis but could i do it in R?)
# 1. group by ga and then ga class
# 2. dissolve
# 3. buffer with units as = 0.00001 (for WGS84 = EPSG 4326)
# 4. project?
# qgis scripting (in python) https://www.qgistutorials.com/en/docs/processing_python_scripts.html

# ---- 4. export tidied data ----

st_write(sga_bounds, paste0(spatial_data_export_path, "sga_bounds_r.shp"))
st_write(sga_bounds_valid, paste0(spatial_data_export_path, "sga_bounds_r_valid.shp"))



  