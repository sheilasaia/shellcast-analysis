# shellcast-analysis


## script run order (daily)

1. ndfd_get_forecast_data_script.py

2. ndfd_convert_df_to_raster_script.R

3. ndfd_analyze_forecast_data_script.R


## script run order (weekly)

4. ncdmf_get_lease_data_script.R (when REST API is available)

5. ncdmf_tidy_lease_data_script.R (when REST API is available)


## others scripts (used for initial data wrangling but do not need to be run every day)

6. ncdmf_init_tidy_sga_bounds_script.R

7. ncdmf_tidy_sga_bounds_script.R

8. ncdmf_tidy_cmu_bounds_script.R

9. ncdmf_tidy_state_bounds_script.R

10. ncdmf_rainfall_threshold_check.R

 