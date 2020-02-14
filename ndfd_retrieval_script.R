# script to get ndfd data

# load libraries
library(tidyverse)
library(ndfd)

# ndfd pacakge page
# https://github.com/BigelowLab/ndfd

# install first time
# library(devtools)
# install_github("BigelowLab/ndfd")

# querey ndfd locations along nc coast
nc_coast_bbox <- c(-80, -75, 33, 37)
nc_ndfd_loc_query <- ndfd::list_this(what = "points_in_subgrid",  
                            listLon1 = nc_coast_bbox[1], 
                            listLon2 = nc_coast_bbox[2], 
                            listLat1 = nc_coast_bbox[3], 
                            listLat2 = nc_coast_bbox[4])
nc_ndfd_loc_query_obj <- ndfd::NDFD(nc_ndfd_loc_query)

# top right 36.629031, -75.184528
# bottom right 33.744582, -75.184528
# top left 36.629031, -79.349893
# bottom left 33.744582, -79.349893

# get data frame of locations
# nc_ndfd_loc <- my_ndfd_points_obj$latLonList$get_location() # makes dataframe
nc_ndfd_loc <- my_ndfd_points_obj$latLonList$get_location(form = "as_is") # makes character string

# query data at locations
my_element <- "temp" # 'qpf' # liquid precip amount
# see element codes here: https://graphical.weather.gov/xml/docs/elementInputNames.php
nc_ndfd_data_query <- ndfd::query_this(what = "subgrid",
                                       lon1 = nc_coast_bbox[1], 
                                       lon2 = nc_coast_bbox[2], 
                                       lat1 = nc_coast_bbox[3],
                                       lat2 = nc_coast_bbox[4],
                                       product = "time-series",
                                       element = my_element,
                                       begin = "2019-01-14T12:00",
                                       end = "2019-01-15T12:00",
                                       resolutionSub = 75)
nc_ndfd_data_query_obj <- ndfd::NDFD(nc_ndfd_data_query)



# ---- test vignette code ----
# list sites in bbox
my_query <- list_this(what = "points_in_subgrid",
                      listLon1 = -72,
                      listLon2 = -63,
                      listLat1 = 39,
                      listLat2 = 46)
"whichClient=NDFDgenSubgrid&lon1=-72.00000&lon2=-63.00000&lat1=39.00000&lat2=46.00000&product=time-series&begin=2016-05-14T12:00&end=2016-05-17T12:00&resolutionSub=75.00000&Unit=m&temp=temp"
X <- NDFD(my_query)
X
# getting results but they have no head like in the vignette
xy <- X$latLonList$get_location()
str(xy)
# looks ok, getting more observations than the vignette
loc <- X$latLonList$get_location(form = 'as_is')
my_query <- query_this(what = "multipoint", 
                       listLonLat = loc, 
                       element = 'temp', 
                       begin ='2016-05-14T12:00', 
                       end = '2016-05-16T12:00')
X2 <- NDFD(my_query)
# getting error (same as vignette)
my_query <- query_this(what = "subgrid",  
                       lon1 = -72, 
                       lon2 = -63, 
                       lat1 = 39, 
                       lat2 = 46, 
                       product = 'time-series', 
                       element = 'temp',
                       begin = '2016-05-14T12:00', 
                       end = '2016-05-17T12:00', 
                       resolutionSub = 75)
X3 <- NDFD(my_query)
# i'm getting an error from the sample code so something must be 
# happening on ndfd's end
# error message 500 = internal server error


"whichClient=LatLonListSubgrid&lon1=-72.00000&lon2=-63.00000&lat1=39.00000&lat2=46.00000&product=time-series&begin=2016-05-14T12:00&end=2016-05-17T12:00&resolutionSub=75.00000&Unit=m&temp=temp"

# other info on the ndfd server
# https://graphical.weather.gov/xml/#generate_it
