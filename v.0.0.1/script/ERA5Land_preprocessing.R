library(doParallel)
registerDoParallel()
library(ncdf4)
pathSSD <- "/Volumes/Extreme SSD/Lavoro/GRINS/R_GRINS"

#listfiles
lf <- list.files(paste0(pathSSD,"/data/WE/ERA5Land/hourly/raw"),pattern = ".nc")
fileslist <- foreach (i = lf, .combine=rbind) %dopar% {
  nc <- nc_open(paste0(pathSSD,"/data/WE/ERA5Land/hourly/raw/",i))
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

fileslist <- fileslist[fileslist$year<2023,]
fileslist <- fileslist[fileslist$var=="t2m",]

source("v.0.0.1/script/functions.R")
path <- paste0(pathSSD,"/data/WE/ERA5Land/hourly/raw")
variable <- c("u10","v10")
y <- ERA5Land(variable=variable,fileslist=fileslist,path=path)
save(y,file = paste0(pathSSD,"/data/WE/ERA5Land/daily/daily_wind.Rdata"))

variable <- c("t2m","d2m")
y <- ERA5Land(variable=variable,fileslist=fileslist,path=path)
save(y,file = paste0(pathSSD,"/data/WE/ERA5Land/daily/daily_rh.Rdata"))

variable <- c("t2m")
y <- ERA5Land(variable=variable,fileslist=fileslist,path=path)
save(y,file = paste0(pathSSD,"/data/WE/ERA5Land/daily/daily_t2m.Rdata"))

variable <- c("lai_lv","lai_hv","tp","ssr")
for (i in variable) {
  y <- ERA5Land(variable[i]=variable,fileslist=fileslist,path=path)
  save(y,file = paste0(pathSSD,"/data/WE/ERA5Land/daily/daily_",variable[i],".Rdata"))
}





#by_year
ERA5y <-
  list.files(paste0(pathSSD, "/data/WE/ERA5Land/hourly/by_year/raw"))
for (i in ERA5y) {
  df <-
    ERA5netcdftopoints(
      i,
      paste0(pathSSD, "/data/WE/ERA5Land/hourly/by_year/raw"),
      print = F,
      newfile = T,
      path_out = paste0(pathSSD, "/data/WE/ERA5Land/hourly/by_year/Rdata")
    )
}

#move by_year to by_month (in HPC)
ERA5y <-
  list.files("data/WE/ERA5Land/hourly/by_year/Rdata")
for (i in ERA5y) {
  load(paste0("data/WE/ERA5Land/hourly/by_year/Rdata/", i))
  df$month <- months(df$time)
  mesi <- unique(df$month)[1:12]
  foreach (m = mesi) %dopar% {
    all_df <- subset(df, month == m)
    nm <- which(m==mesi)
    i2 <- paste0(substr(i,1,nchar(i)-6),"_",nm,".Rdata")
    paste0()
    save(all_df,file=paste0("data/WE/ERA5Land/hourly/by_month/Rdata/", i2))
    rm(all_df)
  }
  rm(df)
  gc()
}

# checking raw monthly data
ERA5m <-
  list.files(paste0(pathSSD, "/data/WE/ERA5Land/hourly/by_month/raw"))
for (i in ERA5m) {
  nc <-
    nc_open(paste0(pathSSD, "/data/WE/ERA5Land/hourly/by_month/raw/", i))
  var <- names(nc$var)
  t <-
    substr(as.POSIXct(nc$dim$time$vals[1] * 3600, origin = "1900-01-01 00:00:00"),
           1,
           7)
  dfm <- data.frame(var = var, t = t)
  if (i == ERA5m[1]) {
    DFm <- dfm
  } else{
    DFm <- rbind(DFm, dfm)
  }
}
table(DFm)

#monthly
ERA5m <-
  list.files(paste0(pathSSD, "/data/WE/ERA5Land/hourly/by_month/raw"))

source("script/WE/ERA5Land/functions.R")

for (i in ERA5m) {
  all_df <-
    ERA5netcdftopoints(
      i,
      paste0(pathSSD, "/data/WE/ERA5Land/hourly/by_month/raw"),
      print = F,
      newfile = T,
      path_out = paste0(pathSSD, "/data/WE/ERA5Land/hourly/by_month/Rdata"),
      monthly = T
    )
}


# merging in one file by_month
rm(list=ls())
fls <- list.files("data/WE/ERA5Land/hourly/by_month/Rdata")
fls <- fls[order(fls)]
foreach (m = paste0(rep(2019:2023,each=12),"_", 1:12, ".Rdata")) %dopar% {
  print(paste(m, "started"))
  flss <- fls[grep(m, fls)]
  load(paste0("data/WE/ERA5Land/hourly/by_month/Rdata/", flss[1]))
  if ("all_df" %in% ls()) {
    df<-all_df
    rm(all_df)
  }
  if (names(df)[1]=="Lon") {
    names(df)[1:2]<-c("lon","lat")
  }
  df$lon <- round(df$lon, 2)
  lon <- df$lon
  df$lat <- round(df$lat, 2)
  lat <- df$lat
  time <- df$time
  df <- df[order(df$lon, df$lat, df$time),]
  tot_df <- df[,-5]
  rm(df)
  df <- foreach (i = flss[-1], .combine = cbind) %do% {
    print(i)
    load(paste0("data/WE/ERA5Land/hourly/by_month/Rdata/", i))
    if ("all_df" %in% ls()) {
      df<-all_df
      rm(all_df)
    }
    if (names(df)[1]=="Lon") {
      names(df)[1:2]<-c("lon","lat")
    }
    df$lon <- round(df$lon, 2)
    df$lat <- round(df$lat, 2)
    df <- df[order(df$lon, df$lat, df$time),]
    if (any(df$lon - lon != 0) &
        any(df$lat - lat != 0) &
        length(setdiff(df$time, time)) != 0) {
      stop(paste("file", i, "longitude, latitude or time is changing"))
    }
    df <- df[, 4]
    df <- as.data.frame(df)
    df
  }
  tot_df <- cbind(tot_df, df)
  names(tot_df)[-c(1:4)] <- c("hvi","lvi","ssr","t2m","tp","u10","v10")
  save(tot_df,
       file = paste0("data/WE/ERA5Land/hourly/by_month/Rdata/all_",m,".Rdata"))
}
