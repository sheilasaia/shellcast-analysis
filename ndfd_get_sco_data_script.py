# -*- coding: utf-8 -*-
"""
ndfd_get_sco_data_script.py

This script grabs data from the NC State Climate Office TDS server (), reformats it, and stores it in a local directory.

Last Updated: 20200326
Created By: Sheila (ssaia@ncsu.edu)
"""

# %% To Do List

# TODO figure out lat/long vs x/y issues


# %% Help

# pydap help: https://pydap.readthedocs.io/en/latest/developer_data_model.html
# thredds help (with python code): https://oceanobservatories.org/thredds-quick-start/#python

# %% Load Libraries

import pandas
import numpy
import datetime as dt
from pydap.client import open_url

# %% Set Paths

# define data directory path (for export)
data_dir = '/Users/sheila/Documents/bae_shellcast_project/shellcast_analysis/ndfd_get_data/data/ndfd_sco_data/'

# define serve path
ndfd_sco_server_url = 'https://tds.climate.ncsu.edu/thredds/dodsC/nws/ndfd/'

# %% Get (pop12) Data Function

def get_sco_ndfd_pop12_data(base_server_url, temp_datetime_uct_str):
    """
    Description: Returns a dataframe of pop12 NDFD data for a specified date
    Parameters:
        base_server_url (str): Base URL (string) for the SCO NDFD TDS server
        temp_datetime_uct_str (str): Datetime (string) in "%Y-%m-%d %H:%M" format (e.g., "2016-01-01 00:00") with timezone = UCT
    Returns: 
        temp_pop12_data_pd (data frame): A pandas dataframe
        temp_year_month_day_hour (str): A string of the datetime in "%Y%m%d%H" format (e.g, "2016010100") with timezone = UCT
    """
    
    temp_date_str, temp_time_str = temp_datetime_uct_str.split()
    temp_year_str, temp_month_str, temp_day_str = temp_date_str.split("-")
    temp_hour_str, temp_sec_str = temp_time_str.split(":")
    
    # define datetime combinations
    temp_year_month = temp_year_str + temp_month_str
    temp_year_month_day = temp_year_str + temp_month_str + temp_day_str
    temp_year_month_day_hour = temp_year_str + temp_month_str + temp_day_str + temp_hour_str
    
    # define data url
    temp_date_url = temp_year_month + "/" + temp_year_month_day + "/" + temp_year_month_day_hour
    temp_data_url = base_server_url + temp_date_url + "ds.midatlan.oper.bin"
    
    # get data from SCO server url and store it on pc
    temp_ndfd_data = open_url(temp_data_url)
    
    # save x, y, and pop12 data
    temp_x = temp_ndfd_data['x'][:]
    temp_y = temp_ndfd_data['y'][:]
    temp_pop12 = temp_ndfd_data['Total_precipitation_surface_12_Hour_Accumulation_probability_above_0p254'] # pop12
    
    # save pop12 dimentions
    temp_pop12_dims = temp_pop12.dimensions
    temp_pop12_time_dim = temp_pop12_dims[0]
    
    # save list of pop12 time dimentions
    temp_pop12_time_np = numpy.array(temp_pop12[temp_pop12_time_dim][:])
    # we want 24 hr (1-day), 48 hr (2-day), and 72 hr (3-day) data
    
    # create indeces for hrs of interest
    hr12_index = int(numpy.where(temp_pop12_time_np == 12)[0][0]) # 0.5day forecast
    hr24_index = int(numpy.where(temp_pop12_time_np == 24)[0][0]) # 1-day forecast
    hr48_index = int(numpy.where(temp_pop12_time_np == 48)[0][0]) # 2-day forecast
    hr72_index = int(numpy.where(temp_pop12_time_np == 72)[0][0]) # 3-day forecast
    
    # for four loop will need if statement for each if length is zero
    # len(numpy.where(temp_pop12_time_np == 6)[0])
    
    # convert data to array (200 x 194)
    temp_pop12_12hr_np = numpy.array(temp_pop12.data[0][hr12_index][0])
    temp_pop12_24hr_np = numpy.array(temp_pop12.data[0][hr24_index][0])
    temp_pop12_48hr_np = numpy.array(temp_pop12.data[0][hr48_index][0])
    temp_pop12_72hr_np = numpy.array(temp_pop12.data[0][hr72_index][0])
    
    # convert data to dataframe (3 x 38800)
    temp_pop12_12hr_pd_raw = pandas.DataFrame(temp_pop12_12hr_np).stack(dropna = False).reset_index()
    temp_pop12_24hr_pd_raw = pandas.DataFrame(temp_pop12_24hr_np).stack(dropna = False).reset_index()
    temp_pop12_48hr_pd_raw = pandas.DataFrame(temp_pop12_48hr_np).stack(dropna = False).reset_index()
    temp_pop12_72hr_pd_raw = pandas.DataFrame(temp_pop12_72hr_np).stack(dropna = False).reset_index()
    
    # add valid period column
    temp_pop12_12hr_pd_raw['valid_period_hrs'] = numpy.repeat("12", len(temp_pop12_12hr_pd_raw), axis=0)
    temp_pop12_24hr_pd_raw['valid_period_hrs'] = numpy.repeat("24", len(temp_pop12_24hr_pd_raw), axis=0)
    temp_pop12_48hr_pd_raw['valid_period_hrs'] = numpy.repeat("48", len(temp_pop12_48hr_pd_raw), axis=0)
    temp_pop12_72hr_pd_raw['valid_period_hrs'] = numpy.repeat("72", len(temp_pop12_72hr_pd_raw), axis=0)
    
    # rename columns
    temp_pop12_12hr_pd_rename = temp_pop12_12hr_pd_raw.rename(columns={"level_0": "y_index", "level_1": "x_index", 0: "pop12_value_perc"})
    temp_pop12_24hr_pd_rename = temp_pop12_24hr_pd_raw.rename(columns={"level_0": "y_index", "level_1": "x_index", 0: "pop12_value_perc"})
    temp_pop12_48hr_pd_rename = temp_pop12_48hr_pd_raw.rename(columns={"level_0": "y_index", "level_1": "x_index", 0: "pop12_value_perc"})
    temp_pop12_72hr_pd_rename = temp_pop12_72hr_pd_raw.rename(columns={"level_0": "y_index", "level_1": "x_index", 0: "pop12_value_perc"})
    
    # create long and lat columns (12 hr)
    # it's possible that long and lat are the same for all these times but am not 100% sure so repeating them
    longitude_12hr = []
    latitude_12hr = []
    for row in range(0, 38800):
        x_index_val = temp_pop12_12hr_pd_rename['x_index'][row]
        y_index_val = temp_pop12_12hr_pd_rename['y_index'][row]
        latitude_12hr.append(temp_x.data[x_index_val]) # x is latitude
        longitude_12hr.append(temp_y.data[y_index_val]) # y is longitude
    
    # create long and lat columns (24 hr)
    longitude_24hr = []
    latitude_24hr = []
    for row in range(0, 38800):
        x_index_val = temp_pop12_24hr_pd_rename['x_index'][row]
        y_index_val = temp_pop12_24hr_pd_rename['y_index'][row]
        latitude_24hr.append(temp_x.data[x_index_val]) # x is latitude
        longitude_24hr.append(temp_y.data[y_index_val]) # y is longitude
        
    # create long and lat columns (48 hr)
    longitude_48hr = []
    latitude_48hr = []
    for row in range(0, 38800):
        x_index_val = temp_pop12_24hr_pd_rename['x_index'][row]
        y_index_val = temp_pop12_24hr_pd_rename['y_index'][row]
        latitude_48hr.append(temp_x.data[x_index_val]) # x is latitude
        longitude_48hr.append(temp_y.data[y_index_val]) # y is longitude
        
    # create long and lat columns (72 hr)
    longitude_72hr = []
    latitude_72hr = []
    for row in range(0, 38800):
        x_index_val = temp_pop12_24hr_pd_rename['x_index'][row]
        y_index_val = temp_pop12_24hr_pd_rename['y_index'][row]
        latitude_72hr.append(temp_x.data[x_index_val]) # x is latitude
        longitude_72hr.append(temp_y.data[y_index_val]) # y is longitude
        
    # add to data frame
    temp_pop12_12hr_pd_rename['longitude'] = longitude_12hr
    temp_pop12_12hr_pd_rename['latitude']  = latitude_12hr
    
    temp_pop12_24hr_pd_rename['longitude'] = longitude_24hr
    temp_pop12_24hr_pd_rename['latitude']  = latitude_24hr
    
    temp_pop12_48hr_pd_rename['longitude'] = longitude_48hr
    temp_pop12_48hr_pd_rename['latitude']  = latitude_48hr
    
    temp_pop12_72hr_pd_rename['longitude'] = longitude_72hr
    temp_pop12_72hr_pd_rename['latitude']  = latitude_72hr
    
    # create and wrangle time columns
    # server time is in UCT but changing it to something that's local for NC (use NYC timezone)
    temp_pop12_12hr_pd_rename['time'] = pandas.to_datetime(numpy.repeat(temp_datetime_uct_str, len(temp_pop12_12hr_pd_rename), axis=0), format = "%Y-%m-%d %H:%M")
    temp_pop12_12hr_pd_rename['time_uct_long'] = temp_pop12_12hr_pd_rename.time.dt.tz_localize(tz = 'UCT')
    temp_pop12_12hr_pd_rename['time_uct'] = temp_pop12_12hr_pd_rename.time_uct_long.dt.strftime("%Y-%m-%d %H:%M")
    temp_pop12_12hr_pd_rename['time_nyc_long'] = temp_pop12_12hr_pd_rename.time_uct_long.dt.tz_convert(tz = 'America/New_York')
    temp_pop12_12hr_pd_rename['time_nyc'] = temp_pop12_12hr_pd_rename.time_nyc_long.dt.strftime("%Y-%m-%d %H:%M")
    
    temp_pop12_24hr_pd_rename['time'] = pandas.to_datetime(numpy.repeat(temp_datetime_uct_str, len(temp_pop12_24hr_pd_rename), axis=0), format = "%Y-%m-%d %H:%M")
    temp_pop12_24hr_pd_rename['time_uct_long'] = temp_pop12_24hr_pd_rename.time.dt.tz_localize(tz = 'UCT')
    temp_pop12_24hr_pd_rename['time_uct'] = temp_pop12_24hr_pd_rename.time_uct_long.dt.strftime("%Y-%m-%d %H:%M")
    temp_pop12_24hr_pd_rename['time_nyc_long'] = temp_pop12_24hr_pd_rename.time_uct_long.dt.tz_convert(tz = 'America/New_York')
    temp_pop12_24hr_pd_rename['time_nyc'] = temp_pop12_24hr_pd_rename.time_nyc_long.dt.strftime("%Y-%m-%d %H:%M")
    
    temp_pop12_48hr_pd_rename['time'] = pandas.to_datetime(numpy.repeat(temp_datetime_uct_str, len(temp_pop12_48hr_pd_rename), axis=0), format = "%Y-%m-%d %H:%M")
    temp_pop12_48hr_pd_rename['time_uct_long'] = temp_pop12_48hr_pd_rename.time.dt.tz_localize(tz = 'UCT')
    temp_pop12_48hr_pd_rename['time_uct'] = temp_pop12_48hr_pd_rename.time_uct_long.dt.strftime("%Y-%m-%d %H:%M")
    temp_pop12_48hr_pd_rename['time_nyc_long'] = temp_pop12_48hr_pd_rename.time_uct_long.dt.tz_convert(tz = 'America/New_York')
    temp_pop12_48hr_pd_rename['time_nyc'] = temp_pop12_48hr_pd_rename.time_nyc_long.dt.strftime("%Y-%m-%d %H:%M")
    
    temp_pop12_72hr_pd_rename['time'] = pandas.to_datetime(numpy.repeat(temp_datetime_uct_str, len(temp_pop12_72hr_pd_rename), axis=0), format = "%Y-%m-%d %H:%M")
    temp_pop12_72hr_pd_rename['time_uct_long'] = temp_pop12_72hr_pd_rename.time.dt.tz_localize(tz = 'UCT')
    temp_pop12_72hr_pd_rename['time_uct'] = temp_pop12_72hr_pd_rename.time_uct_long.dt.strftime("%Y-%m-%d %H:%M")
    temp_pop12_72hr_pd_rename['time_nyc_long'] = temp_pop12_72hr_pd_rename.time_uct_long.dt.tz_convert(tz = 'America/New_York')
    temp_pop12_72hr_pd_rename['time_nyc'] = temp_pop12_72hr_pd_rename.time_nyc_long.dt.strftime("%Y-%m-%d %H:%M")
    
    # bind rows
    temp_pop12_data_pd = temp_pop12_12hr_pd_rename.append([temp_pop12_24hr_pd_rename, temp_pop12_48hr_pd_rename, temp_pop12_72hr_pd_rename])
    
    return temp_pop12_data_pd, temp_year_month_day_hour
    
# %% Test Function
    
# test_data, test_data_time_str = get_sco_ndfd_pop12_data(base_server_url = ndfd_sco_server_url, temp_datetime_uct_str = "2016-01-01 00:00")

# %% Generate DateTime List for Looping

# define start datetime
start_datetime_str = "2016-01-01 00:00"

# create list with start datetime as first value
datetime_list = [start_datetime_str]

# define length of list (number of days for however many years)
num_years = 2
num_days_per_year = 365

# loop to fill in datetime_list
for i in range(1, (num_days_per_year * num_years + 1)):
    start_step = pandas.to_datetime(time_list[i-1], format = "%Y-%m-%d %H:%M").tz_localize(tz = "UCT")
    next_step = start_step + pandas.Timedelta('1 days')
    next_step_str = next_step.strftime("%Y-%m-%d %H:%M")
    datetime_list.append(next_step_str)

# convert datetime_list to a pandas dataframe
datetime_list_pd = pandas.DataFrame(datetime_list, columns = {'datatime_str_uct'})

# %% Loop 

for i in range(0, 5): #len(datetime_list_pd)):
    
    # grab datetime
    datetime_uct_str = datetime_list_pd['datatime_str_uct'][i]
    
    # grab data and wrangle
    temp_data_pd, temp_date_time_str = get_sco_ndfd_pop12_data(base_server_url = ndfd_sco_server_url, temp_datetime_uct_str = datetime_uct_str)
    
    # define data export path
    temp_data_path = data_dir + "pop12" + "_" + temp_date_time_str + ".csv"
    
    # export data
    temp_data_pd.to_csv(temp_data_path, index = False)
    
    # print status
    print("completed ", temp_date_time_str, " download")
    
# it works! :)