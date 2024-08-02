source("script/WE/functions.R")

library(lubridate)
library(ncdf4)
ERA5SLfiles <- list.files(path = "data/WE/ERA5SL/hourly/by_year/raw")

for (i in ERA5SLfiles) {
  df <-
    ERA5netcdftopoints(
      nc_file = i,
      path_in = "data/WE/ERA5SL/hourly/by_year/raw",
      print = F,
      newfile = T,
      path_out = "data/WE/ERA5SL/hourly/by_year/Rdata",
      monthly = F
    )
}

ERA5SLfiles <- list.files(path = "data/WE/ERA5SL/hourly/by_year/Rdata")
for (i in ERA5SLfiles) {
  load(paste0("data/WE/ERA5SL/hourly/by_year/Rdata/",i))
  df$lon<-round(df$lon,2)
  df$lat<-round(df$lat,2)
  df$days<-as_date(df$time)
  df$month <- months(df$days)
  mm <- unique(months(df$days))
  for (m in mm) {
    sub <- df[df$month==m,]
    head(fromHtoD(sub))
  }
  
}


grid_all <-
  foreach (j = CAMSfiles_p_y,
           .packages = c("ncdf4","abind"),
           .combine = rbind) %dopar% {
             nc <- nc_open(paste0("data/AQ/CAMS/cropped/", j))
             aq_pol <- nc$var[[1]][[2]]
             print(paste(aq_pol, (
               which(CAMSfiles_pi == j) / length(CAMSfiles_pi)
             ) * 100))
             aq <- ncvar_get(nc, aq_pol)
             aq3d <- array(NA,
                           dim = c(nc$dim$lat$len,
                                   nc$dim$lon$len,
                                   nc$dim$time$len / 24,
                                   6))
             for (i in (1:(dim(aq)[3] / 24))) {
               aq3d[, , i , ] <- abind(aperm(apply(aq[, , c(((i - 1) * 24):(i * 24))], c(1, 2), quantile),
                                             c(2, 3, 1)),
                                       apply(aq[, , c(((i - 1) * 24):(i * 24))], c(1, 2), mean),
                                       along = 3)
             }
             lat <- ncvar_get(nc, "lat")
             lon <- ncvar_get(nc, "lon")
             grid <- expand.grid(lon, lat)
             t <- nc$dim$time$len
             grid <-
               data.frame(lon = rep(grid$Var1, t / 24),
                          lat = rep(grid$Var2, t / 24))
             names(grid)[1:2] <- c("lon", "lat")
             first_day <- as.Date(substr(nc$dim$time$units, 13, 100))
             grid$days <-
               rep(
                 seq.Date(
                   from = first_day,
                   length.out = t / 24,
                   by = "days"
                 ),
                 each = length(lon) * length(lat)
               )
             grid <-
               data.frame(cbind(grid, matrix(as.vector(aq3d), ncol = 6)))
             grid <- grid[, c(1:6, 9, 7:8)]
             names(grid)[-c(1:3)] <-
               paste0(c("min_", "1q_", "med_", "mean_", "3q_", "max_"), aq_pol)
             grid_all <- grid
             grid_all
           }
# source(paste0(pathHPC,"/Script/CAMS/HPC/checking_H_t_D_CAMS_HPC.R")) #checking
