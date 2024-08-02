library(ecmwfr)
user<-"266303"
wf_set_key(user = user,key = "f2905536-5da1-4250-9b90-b38f95b10f2b",service = "cds")
boundary <- c(48, 6, 35, 19)
variables<- c("boundary_layer_height")
years<-c(2013:2022)
time_wait<-1#seconds
for (v in variables) {
  for (y in years) {
    data<-tryCatch({
      setTimeLimit(elapsed=time_wait)
      request <- list(
        format = "netcdf",
        variable = v,
        year = y,
        month = c("01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12"),
        day = c("01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20", "21", "22", "23", "24", "25", "26", "27", "28", "29", "30", "31"),
        time = c("00:00", "01:00", "02:00", "03:00", "04:00", "05:00", "06:00", "07:00", "08:00", "09:00", "10:00", "11:00", "12:00", "13:00", "14:00", "15:00", "16:00", "17:00", "18:00", "19:00", "20:00", "21:00", "22:00", "23:00"),
        area = boundary,
        dataset_short_name = "reanalysis-era5-single-levels",
        target = "download.nc"
      )
      ncfile <- wf_request(user = user,
                           request = request,
                           transfer = TRUE,
                           path = "~",
                           verbose = FALSE)
      setTimeLimit(elapsed = Inf)
      c(iter = c(d,y,b), slp = era5[d,y,b])
    },error=function(e)NULL)}}


