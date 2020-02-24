# ncdmf reformatting spatial data script

# ---- 1. load libraries and set paths----
# load libraries
library(tidyverse)
library(sf)

# set paths
spatial_data_path <- "/Users/sheila/Documents/bae_shellcast_project/shellcast_analysis/data/spatial/ncdmf_raw/"


# ---- 2. load data ----

# growing area (GA) classes
ga_class_data_raw <- st_read(paste0(spatial_data_path, "SGA_Current_Classifications/SGA_Current_Classifications.shp"))

# GROW_AREA, REGION, DSHA_NAME, HA_CLASS, HA_NAME, HA_NAMEID, MAP_NAME,
# COUNTY, JURISDICTION, WATER_DES, SURFACE, ACRES, SQ_MILES

# GROW_AREA = dsha code/label
# HA_CLASS = restricted, conditionally approved, approved
# HA_NAMEID? same as HA_CODE (area, subarea, and what is third letter?)
# MAP_NAME = contributing watershed/river
# JURISDICTION = WRC or DMF
# WATER_DES = inland, coastal, joint, land
# SURFACE = canal, land, water
# ACRES = area of grow area in acres
# SQ_MILES = area of grow area in sqare miles

# HA stands for?
# HA_CODE name is like GROW_AREA but has extra character sometimes, why?

# ---- 3. reformatting data ----

# check crs
st_crs(ga_class_data_raw)
# wgs84

# project and clean-up
ga_class_data <- ga_class_data_raw %>%
  st_transform(crs = 102008) %>% # Albers Equal Area Conic projection
  select(GROW_AREA, REGION, DSHA_NAME, HA_CLASS, HA_CLASSID, HA_NAME, HA_NAMEID, HA_CODE, MAP_NAME, COUNTY, JURISDCTN, WATER_DES, SURFACE, ACRES, SQ_MILES)
st_crs(ga_class_data)
names(ga_class_data)
ga_list <- unique(ga_class_data$GROW_AREA) # 73 unique GAs
ha_list <- unique(ga_class_data$HA_CODE) # 499 unique HAs

# TODO make a look-up table for which GAs are in which CMUs




