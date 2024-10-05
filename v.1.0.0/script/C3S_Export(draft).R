setwd("WE-C3S")

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
