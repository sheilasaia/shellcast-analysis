# -*- coding: utf-8 -*-
"""
# ---- script header ----
script name: ndfd_get_latest_sco_data_script.py
purpose of script: This script grabs latest National Digital Forecast Dataset (NDFD) data from the NC State Climate Office (SCO) TDS server, reformats it, and stores it in a local directory.
author: sheila saia
email: ssaia@ncsu.edu
date created: 20200427


# ---- notes ----
notes:
ndfd catalog website: https://tds.climate.ncsu.edu/thredds/catalog/nws/ndfd/catalog.html

help: 
pydap help: https://pydap.readthedocs.io/en/latest/developer_data_model.html
thredds help (with python code): https://oceanobservatories.org/thredds-quick-start/#python
to see the nc sco catalog website: https://tds.climate.ncsu.edu/thredds/catalog/nws/ndfd/catalog.html


"""

# %% to do list



# %% load libraries

import pandas # for data mgmt
import numpy # for data mgmt
import datetime as dt # for datetime mgmt
from pydap.client import open_url # to convert bin file
import requests # to check if website exists


# %% set paths

# define data directory path (for export)
data_dir = "/Users/sheila/Documents/bae_shellcast_project/shellcast_analysis/data/tabular/ndfd_sco_latest_raw/"

# define function directory path
functions_dir = "/Users/sheila/Documents/github/shellcast-analysis/functions/"


# %% load custom functions

exec(open((functions_dir + "convert_sco_ndfd_datetime_str.py")).read())
exec(open((functions_dir + "get_sco_ndfd_data.py")).read())
exec(open((functions_dir + "tidy_sco_ndfd_data.py")).read())

# %% get latest ndfd data function

#def get_latest_sco_ndfd_data():
#    """
#    Description: Returns the latest dataframe of SCO NDFD data,
#                 if url does not exist then will give empty dataset
#    Parameters:
#        none
#    Returns:
#        ndfd_data (pydap Dataset): Pydap dataset object for specified datetime,
#        if url does not exist then will give empty dataset
#    Required:
#        import open_url from pydap.client
#        import requests
#    """
#    # data url (always the same link to data...but data itself will change with time)
#    data_url = "https://tds.climate.ncsu.edu/thredds/dodsC/nws/ndfd/ndfd_latest.midatlan.oper.bin"
#    data_url_to_check = data_url + ".html"
#
#    # check if url exisits
#    url_check = requests.get(data_url_to_check)
#    url_status = url_check.status_code
#
#    if url_status == 200: # 200 means that everything is ok
#        # get data from SCO server url and store it on pc
#        ndfd_data = open_url(data_url)
#
#    else: # 404 or any other number means that url is not ok
#        ndfd_data = []
#
#    return ndfd_data #, url_status, data_url_to_check

# works but not sure how to pull the date time out of this





# %% test functions

# get latest data
# ndfd_data = get_latest_sco_ndfd_data()
# not sure how to pull the date time out of this

# date now
datetime_now = pandas.to_datetime(dt.datetime.now(), format = "%Y-%m-%d %H:%M") # this is local time (ET) but server is in UCT
datetime_now_nyc = datetime_now.tz_localize(tz = "America/New_York")
datetime_now_uct = datetime_now_nyc.tz_convert(tz = "UCT")
datetime_now_uct_str_full = datetime_now_uct.strftime("%Y-%m-%d %H:%M")
datetime_now_uct_str_short = datetime_now_uct.strftime("%Y-%m-%d")

# date now (midnight)
test_midnight_datetime_str = datetime_now_uct_str_short + " 00:00"

# test function
test_midnight_ym_str, test_midnight_ymd_str, test_midnight_ymdh_str = convert_sco_ndfd_datetime_str(datetime_str = test_midnight_datetime_str)

# define serve path
ndfd_sco_server_url = 'https://tds.climate.ncsu.edu/thredds/dodsC/nws/ndfd/'
# this is the server path for latest ndfd forecasts
# to see the catalog website: https://tds.climate.ncsu.edu/thredds/catalog/nws/ndfd/catalog.html

# get today's midnitght data
test_midnight_data = get_sco_ndfd_data(base_server_url = ndfd_sco_server_url, datetime_uct_str = test_midnight_datetime_str)

# tidy today's midnight qpf data
test_midnight_qpf_data_pd, test_midnight_qpf_datetime_ymdh_str = tidy_sco_ndfd_data(ndfd_data = test_midnight_data, datetime_uct_str = test_midnight_datetime_str, ndfd_var = "qpf")

# tidy today's midnight pop12 data
test_midnight_pop12_data_pd, test_midnight_pop12_datetime_ymdh_str = tidy_sco_ndfd_data(ndfd_data = test_midnight_data, datetime_uct_str = test_midnight_datetime_str, ndfd_var = "pop12")



# date now (noon)
test_noon_datetime_str = datetime_now_uct_str_short + " 12:00"

# test function
test_noon_ym_str, test_noon_ymd_str, test_noon_ymdh_str = convert_sco_ndfd_datetime_str(datetime_str = test_noon_datetime_str)

# define serve path
ndfd_sco_server_url = 'https://tds.climate.ncsu.edu/thredds/dodsC/nws/ndfd/'
# this is the server path for latest ndfd forecasts
# to see the catalog website: https://tds.climate.ncsu.edu/thredds/catalog/nws/ndfd/catalog.html

# get today's noon data
test_noon_data = get_sco_ndfd_data(base_server_url = ndfd_sco_server_url, datetime_uct_str = test_noon_datetime_str)

# tidy today's noon qpf data
test_noon_qpf_data_pd, test_noon_qpf_datetime_ymdh_str = tidy_sco_ndfd_data(ndfd_data = test_noon_data, datetime_uct_str = test_noon_datetime_str, ndfd_var = "qpf")

# tidy today's noon pop12 data
test_noon_pop12_data_pd, test_noon_pop12_datetime_ymdh_str = tidy_sco_ndfd_data(ndfd_data = test_noon_data, datetime_uct_str = test_noon_datetime_str, ndfd_var = "pop12")

# %% real deal

# define serve path
ndfd_sco_server_url = 'https://tds.climate.ncsu.edu/thredds/dodsC/nws/ndfd/'
# this is the server path for historic ndfd forecasts
# to see the catalog website: https://tds.climate.ncsu.edu/thredds/catalog/nws/ndfd/catalog.html

# keep track of available dates
data_available_pd = pandas.DataFrame(columns = ['datetime_uct_str', 'status'])

# get time now
#datetime_now_nyc = pandas.to_datetime(dt.datetime.now(), format = "%Y-%m-%d %H:%M").tz_localize(tz = "America/New_York") # this is local time (ET) but server is in UCT
datetime_now_nyc = pandas.to_datetime("2020-06-17 07:00", format = "%Y-%m-%d %H:%M").tz_localize(tz = "America/New_York") # force midnight uct grab at 8am et
#datetime_now_nyc = pandas.to_datetime("2020-05-28 15:00", format = "%Y-%m-%d %H:%M").tz_localize(tz = "America/New_York") # force noon uct grab at 8pm et

# convert to uct
datetime_now_uct = datetime_now_nyc.tz_convert(tz = "UCT")

# round up to nearest hour in uct
datetime_now_uct_td = dt.timedelta(hours = datetime_now_uct.hour, minutes = datetime_now_uct.minute, seconds=datetime_now_uct.second, microseconds = datetime_now_uct.microsecond)
to_hour = dt.timedelta(hours=round(datetime_now_uct_td.total_seconds()/3600))
datetime_now_round_uct = pandas.to_datetime((dt.datetime.combine(datetime_now_uct, dt.time(0)) + to_hour), format = "%Y-%m-%d %H:%M").tz_localize(tz = "UCT")

# calc other bounds
datetime_midnighttoday_uct = pandas.to_datetime((datetime_now_round_uct.strftime("%Y-%m-%d") + " 00:00")).tz_localize("UCT")
datetime_noontoday_uct = pandas.to_datetime((datetime_now_round_uct.strftime("%Y-%m-%d") + " 12:00")).tz_localize("UCT")
datetime_midnightnextd_uct = datetime_midnighttoday_uct + pandas.DateOffset(days = 1)

# determine datetime string to use for query using bounds
if (datetime_now_round_uct >= datetime_midnighttoday_uct) & (datetime_now_round_uct < datetime_noontoday_uct): # between midnight and noon
    temp_datetime_uct_str = datetime_midnighttoday_uct.strftime("%Y-%m-%d %H:%M")
elif (datetime_now_round_uct >= datetime_noontoday_uct) & (datetime_now_round_uct < datetime_midnightnextd_uct): # between noon and midnight
    temp_datetime_uct_str = datetime_noontoday_uct.strftime("%Y-%m-%d %H:%M")

# convert datetime to simple string for later data export
temp_datetime_ymdh_str = convert_sco_ndfd_datetime_str(temp_datetime_uct_str)[2]
temp_datetime_ymdh_str

# %% 

# get data
temp_data = get_sco_ndfd_data(base_server_url = ndfd_sco_server_url, datetime_uct_str = temp_datetime_uct_str)

# only append data when it exists
if (len(temp_data) > 0):
    # tidy qpf and pop12 data
    temp_qpf_data_pd, temp_qpf_datetime_ymdh_str = tidy_sco_ndfd_data(ndfd_data = temp_data, datetime_uct_str = temp_datetime_uct_str, ndfd_var = "qpf")
    temp_pop12_data_pd, temp_pop12_datetime_ymdh_str = tidy_sco_ndfd_data(ndfd_data = temp_data, datetime_uct_str = temp_datetime_uct_str, ndfd_var = "pop12")

    # check if desired times were available, only keep when we have both
    if ((len(temp_qpf_data_pd) > 0) and (len(temp_pop12_data_pd) > 0)):

        # define export path
        temp_qpf_data_path = data_dir + "qpf_" + temp_datetime_ymdh_str +  ".csv" # data_dir definited at top of script
        temp_pop12_data_path = data_dir + "pop12_" + temp_datetime_ymdh_str + ".csv" # data_dir definited at top of script

        # export results
        temp_qpf_data_pd.to_csv(temp_qpf_data_path, index = False)
        temp_pop12_data_pd.to_csv(temp_pop12_data_path, index = False)

        # keep track of available data
        temp_data_available_pd = pandas.DataFrame({'datetime_uct_str':[temp_datetime_uct_str], 'status':["available"]})
        data_available_pd = data_available_pd.append(temp_data_available_pd, ignore_index = True)
        
        # export data availability
        data_availability_path = data_dir + "data_available_" + temp_datetime_ymdh_str +  ".csv"
        data_available_pd.to_csv(data_availability_path, index = False)

        # print status
        print("exported " + temp_datetime_uct_str + " data")

    else:
        # keep track of available data
        temp_data_available_pd = pandas.DataFrame({'datetime_uct_str':[temp_datetime_uct_str], 'status':["not_available"]})
        data_available_pd = data_available_pd.append(temp_data_available_pd, ignore_index = True)
        
        # export data availability
        data_availability_path = data_dir + "data_available_" + temp_datetime_ymdh_str +  ".csv"
        data_available_pd.to_csv(data_availability_path, index = False)

        # print status
        print("did not append " + temp_datetime_uct_str + " data")

else:
    # keep track of available data
    temp_data_available_pd = pandas.DataFrame({'datetime_uct_str':[temp_datetime_uct_str], 'status':["not_available"]})
    data_available_pd = data_available_pd.append(temp_data_available_pd, ignore_index = True)
    
    # export data availability
    data_availability_path = data_dir + "data_available_" + temp_datetime_ymdh_str +  ".csv"
    data_available_pd.to_csv(data_availability_path, index = False)

    # print status
    print("did not append " + temp_datetime_uct_str + " data")


# %% testing times
base_server_url = 'https://tds.climate.ncsu.edu/thredds/dodsC/nws/ndfd/'
datetime_uct_str = '2020-05-27 12:00'
ndfd_var = "qpf"
#ndfd_var = "pop12"
ndfd_data = get_sco_ndfd_data(base_server_url = base_server_url, datetime_uct_str = datetime_uct_str)
ndfd_children_str = str(ndfd_data.children)
qpf_var_check = ndfd_children_str.find('Total_precipitation_surface_6_Hour_Accumulation')
#pop12_var_check = ndfd_children_str.find('Total_precipitation_surface_12_Hour_Accumulation_probability_above_0p254')
var_data = ndfd_data['Total_precipitation_surface_6_Hour_Accumulation']
#var_data = ndfd_data['Total_precipitation_surface_12_Hour_Accumulation_probability_above_0p254']
var_data_dims = var_data.dimensions
var_data_time_dim = var_data_dims[0]
var_time_np = numpy.array(var_data[var_data_time_dim][:])
var_time_np

# looks like pop12 is available at 00:00 and 12:00 for 24, 48, and 72 hr forecasts
# looks like qpf is available at 00:00 for all three forecasts but 12:00 72 hr forecast is missing

# 00:00 UCT = 8pm the day before ET
# 12:00 UCT = 8am that day ET
