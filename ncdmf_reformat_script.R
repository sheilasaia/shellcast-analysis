# ncdmf reformatting spatial data script

# ---- to do list ----

# TODO check out what's going on with 2 digit growing area numbers
# 

# ---- 1. load libraries and set paths----
# load libraries
library(tidyverse)
library(sf)

# set paths
spatial_data_path <- "/Users/sheila/Documents/bae_shellcast_project/shellcast_analysis/data/spatial/ncdmf_raw/"

# export path
spatial_data_export_path <- "/Users/sheila/Documents/bae_shellcast_project/shellcast_analysis/data/spatial/ncdmf_raw/sheila_generated/"


# ---- 2. load data ----

# growing area (GA) data
ga_data_raw <- st_read(paste0(spatial_data_path, "SGA_Current_Classifications/SGA_Current_Classifications.shp"))

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

# check lengths
length(ga_data_raw$OBJECTID_1)
length(unique(ga_data_raw$OBJECTID_1))
# all are unique, lengths are equal

length(ga_data_raw$OBJECTID_2)
length(unique(ga_data_raw$OBJECTID_2))
# all are not unique, some repetition

length(ga_data_raw$OBJECTID_3)
length(unique(ga_data_raw$OBJECTID_3))
# all are not unique, some repetion (more than ID_2)

length(ga_data_raw$OBJECTID)
length(unique(ga_data_raw$OBJECTID))
# all are not unique, some repetion (more than ID_1, less than ID_2)


# ---- 3. checking variables ----

# drop geometry for now
ga_data_raw_att <- st_drop_geometry(ga_data_raw)

# unique grow area list
ga_unique_list <- unique(ga_data_raw$GROW_AREA)
length(ga_unique_list) # 74 unique values

# count number of each
ga_obs_count <- ga_data_raw_att %>%
  group_by(GROW_AREA) %>%
  count()
# there are 2448 NA rows...
# ranges from D3 with 508 observations to H3 with 3

# select D3 and export so can look at shape file for one GA
ga_sel_d3_data_raw <- ga_data_raw %>%
  filter(GROW_AREA == "D3")
st_write(ga_sel_d3_data_raw, paste0(spatial_data_export_path, "ga_sel_d3_data_raw.shp"))




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


# ---- 3. reformatting data ----

# check crs
st_crs(ga_data_raw)
# wgs84

# project and rename
ga_data_albers <- ga_data_raw %>%
  st_transform(crs = 102008) %>% # Albers Equal Area Conic projection
  select(grow_area = GROW_AREA,
         ha_code = HA_CODE,
         dsha_desc = DSHA_NAME,
         ha_desc = HA_NAME,
         ha_class_long = HA_CLASS,
         ha_class_short = HA_CLASSID,
         ha_status = HA_STATUS,
         map_desc = MAP_NAME,
         map_number = MAP_NUMBER,
         region = REGION,
         ga_acres = ACRES,
         ga_sqmi = SQ_MILES,
         ga_county = COUNTY,
         ga_jurisdiction = JURISDCTN,
         ga_water_desc = WATER_DES,
         ga_surf_desc = SURFACE,
         relay = RELAY,
         creator = CREATOR,
         date_created = CREATED,
         date_updated = UPDATED)

# check
st_crs(ga_data_albers)
names(ga_data_albers)

# remove data with na growing areas
ga_data <- ga_data_albers %>%
  filter(is.na(grow_area) == FALSE) %>%
  mutate(grow_area_trim = str_trim(grow_area, side = "both"),
         grow_area_str_len = str_count(grow_area_trim),
         ha_area_fix = str_to_upper(str_sub(grow_area_trim, start = 1, end = 1)), # original HA_AREA has some NAs so generate from scratch
         ha_subarea_fix = str_pad(str_sub(grow_area_trim, start = 2, end = -1), 2, side = "left", "0"), # original HA_SUBAREA has some NAs so generate from scratch
         ha_code_fix = if_else(is.na(str_trim(ha_code)) == TRUE, grow_area_trim, str_trim(ha_code)), # some of the ha_code values are missing despite grow_area being defined
         grow_area_short = paste0(ha_area_fix, ha_subarea_fix), # want to make all 3 digits so bind with padded subarea
         ha_subsubarea_fix = str_to_upper(str_sub(ha_code_fix, start = grow_area_str_len + 1, end = str_count(ha_code_fix))),
         ha_subsubarea_str_len = str_count(ha_subsubarea_fix))

test_1 <- ga_data %>%
  filter(ha_subsubarea_str_len == 1) # 2467 are equal to 1 digit, 2287 are 4 or 5 digits

test_2 <- ga_data %>%
  filter(ha_subsubarea_str_len > 3) # 2467 are equal to 1 digit, 2287 are 4 or 5 digits

 # keep a copy of data without growing area specified
ga_data_nas <- ga_data_albers %>%
  filter(is.na(grow_area) == TRUE)
  








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



