library(doParallel)
registerDoParallel()
library(ncdf4)

vers <- "v.0.0.1"
ssd_path <- "/Volumes/Extreme SSD/Lavoro/GRINS/GitHub/WE-C3S" #local
versD <- paste0(ssd_path,"/",vers)

#listfiles
lf <- list.files(paste0(versD,"/data/ERA5Land/hourly/raw"),pattern = ".nc")
fileslist <- foreach (i = lf, .combine = rbind) %dopar% {
  nc <- nc_open(paste0(versD,"/data/ERA5Land/hourly/raw/",i))
  var <- nc$var[[1]][2][[1]]
  t <-
    as.POSIXct(nc$dim[[3]]$vals * 3600,
               origin = as.POSIXct("1900-01-01 00:00:00"),
               tz = "Etc/GMT-1")
  y <- unique(substr(t, 1, 4))
  m <- unique(months(t))
  if (length(m) == 12) {
    m <- "all"
  }
  fileslist <- data.frame(
    nc_file = i,
    var = var,
    year = y,
    month = m
  )
  fileslist
}

#the filelist object is a table with the following header:
# -> name of the netcdf file | variable | year | month <- #
# these infomation are used to run the functions

source(paste0(vers,"/script/functions.R"))
path <- paste0(versD,"/data/ERA5Land/hourly/raw")
variable <- c("u10", "v10")
y <- ERA5Land(variable = variable,
              fileslist = fileslist,
              path = path)
save(y, file = paste0(versD,"/data/ERA5Land/daily/daily_wind.Rdata"))
load("v.0.0.1/data/ERA5Land/daily/daily_wind.Rdata")
yt <- y
y <- yt[1:131, 1:131, ]
save(y, file = "v.0.0.1/data/ERA5Land/daily/daily_windspeed.Rdata")
y <- yt[1:131, 132:262, ]
save(y, file = "v.0.0.1/data/ERA5Land/daily/daily_winddir.Rdata") #1sud, 2ovest, 3nord, 4est

variable <- c("t2m", "d2m")
y <- ERA5Land(variable = variable,
              fileslist = fileslist,
              path = path)
save(y, file = "v.0.0.1/data/ERA5Land/daily/daily_rh.Rdata")

variable <- c("t2m")
y <- ERA5Land(variable = variable,
              fileslist = fileslist,
              path = path)
save(y, file = "v.0.0.1/data/ERA5Land/daily/daily_t2m.Rdata")

variables <- c("lai_lv", "lai_hv", "tp", "ssr") #STORTE!
for (vv in variables) {
  y <- ERA5Land(variable = vv,
                fileslist = fileslist,
                path = path)
  save(y, file = paste0("v.0.0.1/data/ERA5Land/daily/daily_", vv, ".Rdata"))
}

