library(ncdf4)

nc <- nc_open("WE-C3S/v.1.0.0/data/VHR_REA_IT/output.nc")
nc$var$lon_rounded$dim

a <- ncvar_get(nc,"lon_rounded")

summary(a)
a<-a[order(a)]
a<-unique(a)
a<-a[order(a)]
b <- diff(a)
table(b)
a <- ncvar_get(nc,"rlon")


nclight <- nc_open("WE-C3S/ds_daily_float16.nc")
ncvar_get(nclight,"RH_mean")


