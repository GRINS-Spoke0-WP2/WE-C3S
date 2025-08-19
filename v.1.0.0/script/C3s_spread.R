library(ncdf4)

nc <- nc_open("WE-C3S/v.1.0.0/data/ERA5SL/spread/prova.nc")

nc$var$expver
t2m_spread <- ncvar_get(nc,"t2m")

ncvar_get(nc,"longitude")
ncvar_get(nc,"latitude")
ncvar_get(nc,"valid_time")
summary(t2m_spread)
as.POSIXct(ncvar_get(nc,"valid_time"),
           origin=as.POSIXct("1970-01-01 00:00:00"))
