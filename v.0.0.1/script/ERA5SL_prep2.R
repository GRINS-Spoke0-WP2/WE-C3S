library(doParallel)
registerDoParallel()
library(ncdf4)

#listfiles
lf <- list.files("data/WE/ERA5SL/hourly/raw", pattern = ".nc")
fileslist <- foreach (i = lf, .combine = rbind) %dopar% {
  nc <- nc_open(paste0("data/WE/ERA5SL/hourly/raw/", i))
  var<-c()
  for (j in 1:length(nc$var)){
  var[j] <- nc$var[[j]][2][[1]]
  }
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
    var = paste(var,collapse = ","),
    year = y,
    month = m
  )
  fileslist
}

source("script/WE/functions.R")
path <- "data/WE/ERA5SL/hourly/raw"
variable <- c("blh")
y <- ERA5SL(variable = variable,
            fileslist = fileslist,
            path = path)
save(y, file = "data/WE/ERA5SL/daily/blh.Rdata")

variable <- "u10,v10,t2m,tp"
y <- ERA5SL(variable = variable,
            fileslist = fileslist,
            path = path)
save(y, file = "data/WE/ERA5SL/daily/we_23.Rdata")
#create netcdf
lf <- list.files("data/WE/ERA5SL/daily",pattern = ".Rdata")
load(paste0("data/WE/ERA5SL/daily/", lf[1]))
lat <- rownames(y)
lon <- colnames(y)
d <- dim(y)
ncname <- "data/WE/ERA5SL/daily/blh_italy.nc"
londim <-
  ncdim_def("longitude", "degree east", as.double(unique(lon)))
latdim <-
  ncdim_def("latitude", "degree north", as.double(unique(lat)))
timedim <- ncdim_def("time", "days from 1/1/2019", 1:1826)
varnames <- sapply(lf, function(x)
  substr(x, 1, nchar(x) - 6))
listvar <- list()
unit <- c("m")
for (i in 1) {
  listvar[[i]] <- ncvar_def(varnames[i],
                            unit[i],
                            list(londim, latdim, timedim),
                            missval = NA)
}
ncout <- nc_create(ncname, listvar)
for (i in 1) {
  ncvar_put(ncout, listvar[[i]], y)
}
ncatt_put(ncout, "longitude", "degree east", "x")
ncatt_put(ncout, "latitude", "degree north", "y")
ncatt_put(ncout, "time", "axis","t")
nc_close(ncout)

