library(doParallel)
registerDoParallel()
library(ncdf4)

#listfiles
lf <- list.files("data/WE/ERA5Land/hourly/raw", pattern = ".nc")
fileslist <- foreach (i = lf, .combine = rbind) %dopar% {
  nc <- nc_open(paste0("data/WE/ERA5Land/hourly/raw/", i))
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

#per SIS
fileslist <- fileslist[fileslist$year >= 2019, ]

source("script/WE/functions.R")
path <- "data/WE/ERA5Land/hourly/raw"
variable <- c("u10", "v10")
y <- ERA5Land(variable = variable,
              fileslist = fileslist,
              path = path)
save(y, file = "data/WE/ERA5Land/daily/daily_wind.Rdata")
load("data/WE/ERA5Land/daily/daily_wind.Rdata")
yt <- y
y <- yt[1:131, 1:131, ]
save(y, file = "data/WE/ERA5Land/daily/daily_windspeed.Rdata")
y <- yt[1:131, 132:262, ]
save(y, file = "data/WE/ERA5Land/daily/daily_winddir.Rdata") #1sud, 2ovest, 3nord, 4est

variable <- c("t2m", "d2m")
y <- ERA5Land(variable = variable,
              fileslist = fileslist,
              path = path)
save(y, file = "data/WE/ERA5Land/daily/daily_rh.Rdata")

variable <- c("t2m")
y <- ERA5Land(variable = variable,
              fileslist = fileslist,
              path = path)
save(y, file = "data/WE/ERA5Land/daily/daily_t2m.Rdata")

variables <- c("lai_lv", "lai_hv", "tp", "ssr") #STORTE!
for (vv in variables) {
  y <- ERA5Land(variable = vv,
                fileslist = fileslist,
                path = path)
  save(y, file = paste0("data/WE/ERA5Land/daily/daily_", vv, ".Rdata"))
}

#create netcdf --> #alcune variabili sono rimaste storte!! (tp, ssr, ecc.)
lf <- list.files("data/WE/ERA5Land/daily",pattern = ".Rdata")
load(paste0("data/WE/ERA5Land/daily/", lf[1]))
lat <- rownames(y)
lon <- colnames(y)
d <- dim(y)
lf <- lf[lf!="daily_wind.Rdata"]
for (i in lf[-1]) {
  load(paste0("data/WE/ERA5Land/daily/", i))
  lat <- c(lat, rownames(y))
  lon <- c(lon, colnames(y))
  d <- c(d, dim(y))
}
acomb <- function(...) abind(..., along = 4)
y <- foreach(i = lf, .combine = "acomb") %dopar% {
  load(paste0("data/WE/ERA5Land/daily/", i))
  y
}
ncname <- "data/WE/ERA5Land/daily/WE_italy.nc"
londim <-
  ncdim_def("longitude", "degree east", as.double(unique(lon)))
latdim <-
  ncdim_def("latitude", "degree north", as.double(unique(lat)))
timedim <- ncdim_def("time", "days from 1/1/2019", 1:1826)
varnames <- sapply(lf, function(x)
  substr(x, 7, nchar(x) - 6))
dimnames(y)[[4]] <- varnames
listvar <- list()
unit <- c("m2/m2","m2/m2","%","J/m2","C","m","1sud.2ovest.3nord.4est","m/s")
for (i in 1:dim(y)[4]) {
  listvar[[i]] <- ncvar_def(varnames[i],
                            unit[i],
                            list(londim, latdim, timedim),
                            missval = NA)
}
ncout <- nc_create(ncname, listvar)
for (i in 1:dim(y)[4]) {
  ncvar_put(ncout, listvar[[i]], y[,,,i])
}
ncatt_put(ncout, "longitude", "degree east", "x")
ncatt_put(ncout, "latitude", "degree north", "y")
ncatt_put(ncout, "time", "axis","t")
nc_close(ncout)
