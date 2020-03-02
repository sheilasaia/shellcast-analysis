# ncdmf reformatting spatial data script

# ---- 1. load libraries and set paths----
# load libraries
library(tidyverse)
library(sf)

# set paths
spatial_data_path <- "/Users/sheila/Documents/bae_shellcast_project/shellcast_analysis/data/spatial/ncdmf_raw/"


# ---- 2. load data ----

# growing area (GA) data
ga_data_raw <- st_read(paste0(spatial_data_path, "SGA_Current_Classifications/SGA_Current_Classifications.shp"))

# columns
# REGION = region of coast (central, north, south) 
# GROW_AREA = growing area (GA) code is a two digits code (e.g., letter + number like A1)
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
# CREATED = date of creation of the area/data
# UPDATED = date the area/data was updated
# ACRES = area of grow area in acres
# SQ_MILES = area of grow area in sqare miles


# ---- 3. checking variables ----

# drop geometry for now
ga_data_raw_att <- st_drop_geometry(ga_data_raw)

# check ga, ha, dsha, and map codes
dsha_code <- ga_data_raw_att$DSHA_CODE
ga_code <- ga_data_raw_att$GROW_AREA
ha_area <- ga_data_raw_att$HA_AREA
ha_subarea <- str_pad(ga_data_raw_att$HA_SUBAREA, width = 2, pad = "0")
ha_nameid <- ga_data_raw_att$HA_NAMEID
map_code <- ga_data_raw_att$MAP_ID

compare_codes <- data.frame(row_id = seq(1:dim(ga_data_raw_att)[1]),
                            dsha_code = dsha_code,
                            ga_code = ga_code,
                            ha_area = ha_area,
                            ha_subarea = ha_subarea,
                            ha_nameid = ha_nameid,
                            ha_nameid_fix = str_replace_all(str_replace_all(ha_nameid, pattern = " ", replacement = ","), pattern = "-", replacement = ""),
                            map_code = map_code,
                            map_code_fix = str_replace_all(map_code, patter = " ", replacement = ",")) %>%
  separate(ha_nameid_fix, c("ha_nameid_ga", "ha_nameid_letter", "ha_nameid_unknown"), sep = ",", remove = FALSE) %>%
  separate(map_code_fix, c("map_code_num", "map_code_unknown"), sep = ",", remove = FALSE)

# notes
# 1. HA_CODE doesn't match with HA_CLASS, HA_CLASSID, HA_NAMEID, HA_STATUS (don't use HA_CODE)
# 2. DSHA_CODE and GROW_AREA seem to be the same
# 3. cosider that some data are repeated b/c row is added when data is updated (closed becomes open?)
# 4. Use GROW_AREA to get area (lette) and subarea (number)


# ---- 3. reformatting data ----

# check crs
st_crs(ga_class_data_raw)
# wgs84

# project and clean-up
ga_data <- ga_class_data_raw %>%
  st_transform(crs = 102008) %>% # Albers Equal Area Conic projection
  select(GROW_AREA, REGION, DSHA_NAME, DSHA_CODE, HA_CLASS, HA_CLASSID, HA_NAME, HA_NAMEID, HA_STATUS, HA_AREA, HA_SUBAREA, HA_CODE, MAP_NAME, MAP_NUMBER, MAP_ID, COUNTY, JURISDCTN, WATER_DES, SURFACE, ACRES, SQ_MILES)
st_crs(ga_data)
names(ga_data)

dsha_code <- as.character(ga_data$DSHA_CODE)
ga_code <- str_to_lower(ga_data$GROW_AREA)
ha_code <- ga_data$HA_CODE

compare_df <- data.frame(row_id = seq(1:dim(ga_data)[1]),
                         dsha_code = dsha_code,
                         ga_code = ga_code,
                         ha_code = ha_code) %>%
  mutate(comp_dsha_ga = if_else(dsha_code == ga_code, "match", "non-match"))

ga_list <- unique(ga_data$GROW_AREA) # 73 unique GAs
ha_list <- unique(ga_data$HA_CODE) # 499 unique HAs


# ---- TO DO LIST ----
# TODO make a look-up table for which GAs are in which CMUs
# TODO fix region coding so South and SOUTH are the same
# TODO fix conditional approved labels (don't care if they're currently open or not)
# TODO what's the deal with MAP_NAME vs MAP_NUMBER?
# TODO is letter from MAP_ID the same as the letter in HA_CODE?
# TODO what is RELAY? and fix NA vs N/A
# TODO fix line 2971 HA_NAMEID is "D 4" but should be "D-4"
# TODO fix line 4225 HA_AREA is "I-4 j" but should be "I-4"



