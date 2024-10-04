if(!require(remotes)){install.packages("remotes")}
remotes::install_github("bluegreen-labs/ecmwfr", build_vignettes = TRUE)
library("ecmwfr") #v.2.0.2 or more

# library(foreach)
# library(doParallel)
# registerDoParallel()


boundary <- c(48, 6, 35, 19)

# ERA5Land ####
variables<-c("10m_u_component_of_wind","2m_dewpoint_temperature",
             "2m_temperature", "surface_pressure",
             "leaf_area_index_high_vegetation","leaf_area_index_low_vegetation",
             "total_precipitation",
             "surface_net_solar_radiation")

years<-c(2013:2023)
months <- c("01","02","03","04","05","06","07","08","09","10","11","12")
time_wait <- 1 #seconds
for (v in variables) {
  for (y in years) {
    for (m in months) {
    data<-tryCatch({
      setTimeLimit(elapsed=time_wait)
      request <- list(
        dataset_short_name = "reanalysis-era5-land",
        product_type = "reanalysis",
        variable = v,
        year = y,
        month = months,
        day = c("01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20", "21", "22", "23", "24", "25", "26", "27", "28", "29", "30", "31"),
        time = c("00:00", "01:00", "02:00", "03:00", "04:00", "05:00", "06:00", "07:00", "08:00", "09:00", "10:00", "11:00", "12:00", "13:00", "14:00", "15:00", "16:00", "17:00", "18:00", "19:00", "20:00", "21:00", "22:00", "23:00"),
        data_format = "netcdf",
        download_format = "unarchived",
        area = boundary,
        target = "TMPFILE"
      )
      wf_request(request = request)
      setTimeLimit(elapsed = Inf)
      c(iter = c(v,y), slp = era5[v,y])
    },error=function(e)NULL)}}
}

#files need to be downloaded manually from the website and saved
#in the folder "data/ERA5Land/hourly/raw

# ERA5 Single Level ####
library("ecmwfr") #v.2.0.2 or more
wf_set_key("333dea74-065a-4165-b158-376939a21a5d")
boundary <- c(48, 6, 35, 19)
variables<- c("boundary_layer_height")
years<-c(2013:2023)
time_wait<-2#seconds
for (v in variables) {
  for (y in years) {
    data<-tryCatch({
      setTimeLimit(elapsed=time_wait)
      request <- list(
        dataset_short_name = "reanalysis-era5-single-levels",
        product_type = "reanalysis",
        variable = "boundary_layer_height",
        year = y,
        month = c("01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12"),
        day = c("01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20", "21", "22", "23", "24", "25", "26", "27", "28", "29", "30", "31"),
        time = c("00:00", "01:00", "02:00", "03:00", "04:00", "05:00", "06:00", "07:00", "08:00", "09:00", "10:00", "11:00", "12:00", "13:00", "14:00", "15:00", "16:00", "17:00", "18:00", "19:00", "20:00", "21:00", "22:00", "23:00"),
        data_format = "netcdf",
        download_format = "unarchived",
        area = c(48, 6, 35, 19),
        target = "TMPFILE"
      )
      wf_request(request = request)
      setTimeLimit(elapsed = Inf)
      c(iter = c(d,y,b), slp = era5[d,y,b])
    },error=function(e)NULL)}}

#files need to be downloaded manually from the website and saved
#in the folder "data/ERA5SL/hourly/raw (da fare)