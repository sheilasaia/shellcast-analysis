# cocorahs data retrieval script

# load libraries
library(tidyverse)
library(xml2)
# devtools::install_github("r-lib/xml2")
# https://github.com/r-lib/xml2
# helpful blog: https://blog.rstudio.com/2015/04/21/xml2/
# more helpful blog: https://lecy.github.io/Open-Data-for-Nonprofit-Research/Quick_Guide_to_XML_in_R.html


# example
address <- "http://data.cocorahs.org/export/exportreports.aspx?ReportType=Daily&dtf=1&Format=XML&State=NC&ReportDateType=reportdate&Date=2/14/2020&TimesInGMT=False"	

test <- xml2::download_xml(url = address)
test_xml <- read_xml(test)
test_structure <- xml_structure(test_xml)
test_text <- xml_text(test_xml)
test_name <- xml_name(test_xml) # from cocorahs
test_children <- xml_children(test_xml)
test_children2 <- xml_children(test_children[[1]]) # this is all the stations in NC (539 of them)
test_children3 <- xml_children(test_children2[[1]]) # each of these is one of 13 variables for the first of the 539 sites
# test_children4 <- xml_children(test_children3[[1]])
# test_children3[[2]][1]
xml_name(test_children2) # gives all report headers for each site...not too helpful
xml_name(test_children3) # gives all headers for each report! (13 of them)

# find station number nodes
stations <- xml_find_all(test_children2, ".//StationNumber")
xml_attr(stations, attr = )


xml_parent(test_xml)
xml_name(xml_parent(test_xml))
xml_name(xml_children(xml_children(test_xml)))
station1 <- xml_find_first(xml_children(xml_children(test_xml)), "//DailyPrecipReport" )
xml_text()


