# ---- script header ----
# script name: ncdmf_get_lease_data_script.R
# purpose of script:
# author:
# date created: 20200626
# email:


# ---- notes ----
# notes:
 

# ---- to do ----
# to do list


# ----
lease_bounds_raw <- st_read(paste0(lease_data_spatial_input_path, "lease_bounds_raw.shp"))
lease_bounds_raw_wgs84 <- lease_bounds_raw %>%
  st_transform(wgs84_epsg)
st_crs(lease_bounds_raw_wgs84)
st_write(lease_bounds_raw_wgs84, paste0(lease_data_spatial_input_path, "lease_bounds_raw_wgs84.shp"))

# export wgs84 toooo!
# export to "/Users/sheila/Documents/bae_shellcast_project/shellcast_analysis/data/web_app_data/spatial/ncdmf_raw/lease_bounds_raw/"