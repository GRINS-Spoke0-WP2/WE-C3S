library(doParallel)
registerDoParallel()
library(ncdf4) #version of the package: 1.22

#for local computer
setwd("WE-C3S")
vers <- "v.1.0.0"
# ssd_path <- "/Volumes/Extreme SSD/Lavoro/GRINS/GitHub/WE-C3S" #local
# vers <- paste0(ssd_path,"/",vers)
# 
# for HPC
# setwd("GRINS/WE-C3S")
# vers <- "v.1.0.0"

# ERA5-Land ####
#listfiles
lf <- list.files(paste0(vers,"/data/ERA5Land/hourly/raw"),pattern = ".nc")
fileslist <- foreach (i = lf, .combine = rbind) %dopar% {
  nc <- nc_open(paste0(vers,"/data/ERA5Land/hourly/raw/",i))
  var <- nc$var[[3]][2][[1]]
  t <-
    as.POSIXct(nc$dim[[1]]$vals,
               origin = as.POSIXct("1970-01-01 00:00:00"),
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
path <- paste0(vers,"/data/ERA5Land/hourly/raw")
variable <- c("u10", "v10")
y <- fromHtoD(variable = variable, 
              fileslist = fileslist,
              path = path)
save(y, file = paste0(vers,"/data/ERA5Land/daily/daily_wind.Rdata"))
# load(paste0(vers,"/data/ERA5Land/daily/daily_wind.Rdata"))
yt <- y
y <- yt[1:131, 1:131, ]
save(y, file = paste0(vers,"/data/ERA5Land/daily/daily_windspeed.Rdata"))
y <- yt[1:131, 132:262, ]
save(y, file = paste0(vers,"/data/ERA5Land/daily/daily_winddir.Rdata")) #1sud, 2ovest, 3nord, 4est

variable <- c("t2m", "d2m")
y <- fromHtoD(variable = variable,
              fileslist = fileslist,
              path = path)
save(y, file = paste0(vers,"/data/ERA5Land/daily/daily_rh.Rdata"))

variable <- c("t2m")
y <- fromHtoD(variable = variable,
              fileslist = fileslist,
              path = path)
save(y, file = paste0(vers,"/data/ERA5Land/daily/daily_t2m.Rdata"))

variables <- c("lai_lv", "lai_hv", "tp", "ssr")
for (vv in variables) {
  y <- fromHtoD(variable = vv,
                fileslist = fileslist,
                path = path)
  save(y, file = paste0(vers,"/data/ERA5Land/daily/daily_", vv, ".Rdata"))
}

# ERA5 Single Level ####
lf <- list.files(paste0(vers,"/data/ERA5SL/hourly/raw"),pattern = ".nc")
fileslist <- foreach (i = lf, .combine = rbind) %dopar% {
  nc <- nc_open(paste0(vers,"/data/ERA5SL/hourly/raw/",i))
  var <- nc$var[[3]][2][[1]]
  t <-
    as.POSIXct(nc$dim[[1]]$vals,
               origin = as.POSIXct("1970-01-01 00:00:00"),
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

source(paste0(vers,"/script/functions.R"))
path <- paste0(vers,"/data/ERA5SL/hourly/raw")
variable <- c("u10", "v10")
y <- fromHtoD(variable = variable, 
              fileslist = fileslist,
              path = path)
save(y, file = paste0(vers,"/data/ERA5SL/daily/daily_wind.Rdata"))
yt <- y
y <- yt[1:53, 1:53, ]
save(y, file = paste0(vers,"/data/ERA5SL/daily/daily_windspeed.Rdata"))
y <- yt[1:53, 54:106, ]
save(y, file = paste0(vers,"/data/ERA5SL/daily/daily_winddir.Rdata")) #1sud, 2ovest, 3nord, 4est

variable <- c("t2m", "d2m")
y <- fromHtoD(variable = variable,
              fileslist = fileslist,
              path = path)
save(y, file = paste0(vers,"/data/ERA5SL/daily/daily_rh.Rdata"))

variable <- c("t2m")
y <- fromHtoD(variable = variable,
              fileslist = fileslist,
              path = path)
save(y, file = paste0(vers,"/data/ERA5SL/daily/daily_t2m.Rdata"))

variables <- c("lai_lv", "lai_hv", "tp", "ssr")
for (vv in variables) {
  y <- fromHtoD(variable = vv,
                fileslist = fileslist,
                path = path)
  save(y, file = paste0(vers,"/data/ERA5SL/daily/daily_", vv, ".Rdata"))
}
variable <- c("blh")
y <- fromHtoD(variable = variable,
              fileslist = fileslist,
              path = path)
save(y, file = paste0(vers,"/data/ERA5SL/daily/daily_blh.Rdata"))



