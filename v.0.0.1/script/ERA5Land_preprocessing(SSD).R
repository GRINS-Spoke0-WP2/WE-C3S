library(doParallel)
registerDoParallel()
library(ncdf4)

vers <- "v.0.0.1"
# vers_loc <- "/Volumes/Extreme SSD/Lavoro/GRINS/R_GRINS/GitHub" #local
# vers <- paste0(vers_loc,"/",vers)

#listfiles
lf <- list.files(paste0(vers,"/data/ERA5Land/hourly/raw"),pattern = ".nc")
fileslist <- foreach (i = lf, .combine=rbind) %dopar% {
  nc <- nc_open(paste0(vers,"/data/ERA5Land/hourly/raw/",i))
  var <- nc$var[[1]][2][[1]]
  t <- as.POSIXct(nc$dim[[3]]$vals*3600,origin=as.POSIXct("1900-01-01 00:00:00"), tz="Etc/GMT-1")
  y <- unique(substr(t,1,4))
  m <- unique(months(t))
  if(length(m)==12){m<-"all"}
  fileslist <- data.frame(nc_file=i,
                          var=var,
                          year=y,
                          month=m)
  fileslist
}

source("v.0.0.1/script/functions.R")
path <- paste0(vers,"/data/WE/ERA5Land/hourly/raw")
variable <- c("u10","v10")
y <- ERA5Land(variable=variable,fileslist=fileslist,path=path)
save(y,file = paste0(vers,"/data/WE/ERA5Land/daily/daily_wind.Rdata"))

variable <- c("t2m","d2m")
y <- ERA5Land(variable=variable,fileslist=fileslist,path=path)
save(y,file = paste0(vers,"/data/WE/ERA5Land/daily/daily_rh.Rdata"))

variable <- c("t2m")
y <- ERA5Land(variable=variable,fileslist=fileslist,path=path)
save(y,file = paste0(vers,"/data/WE/ERA5Land/daily/daily_t2m.Rdata"))

variable <- c("lai_lv","lai_hv","tp","ssr")
for (i in variable) {
  y <- ERA5Land(variable=variable[i],fileslist=fileslist,path=path)
  save(y,file = paste0(vers,"/data/WE/ERA5Land/daily/daily_",variable[i],".Rdata"))
}

