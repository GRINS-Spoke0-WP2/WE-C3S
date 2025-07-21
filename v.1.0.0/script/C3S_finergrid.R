library(doParallel)
library(gstat)
library(sp)
library(spacetime)
library(abind)

registerDoParallel(cores = 30)

ERA5Land_ext <- readRDS("WE-Modelling/v.1.0.0/data/ERA5Land_ext.rds") #.nosync

#for HPC
#setwd("/mnt/wp02/FRK-GRINS")

#adesso facciamo downscaling direttamente sulla griglia desiderata.
#come decidere risoluzione griglia?

resolution <- 0.05
c_res <- gsub("\\.","",as.character(resolution))
## era5land+ -> finer grid ####
#create a spatial grid
fgrid_df <- expand.grid(seq(6, 19, resolution), seq(35, 48, resolution))
names(fgrid_df) <- c("Longitude", "Latitude")
fgrid_df <- fgrid_df[order(fgrid_df$Longitude), ]
fgrid_df <- fgrid_df[order(fgrid_df$Latitude, decreasing = T), ]
fgrid_sp <- fgrid_df
coordinates(fgrid_sp) <- c("Longitude", "Latitude")
coord_lon <- unique(fgrid_df$Longitude)
dim_lon <- length(coord_lon)
coord_lat <- unique(fgrid_df$Latitude)
dim_lat <- length(coord_lat)
time_stamp <- as.Date(as.numeric(dimnames(ERA5Land_ext)[[3]]))
dim_time <- length(time_stamp)
years <- list()
for (y in unique(format(time_stamp, format = "%Y"))) {
  idx <- which(unique(format(time_stamp, format = "%Y")) == y)
  years[[idx]] <- seq.Date(from = as.Date(paste0(y, "-01-01")),
                           to = as.Date(paste0(y, "-12-31")),
                           by = "days")
}

acomb <- function(...)
  abind(..., along = 3)

#idw on the finer grid
for (v in 1:dim(ERA5Land_ext)[4]) {
  var_i <- dimnames(ERA5Land_ext)[[4]][v]
  if (var_i == "winddir") {
    next
  }
  for (yi in 1:length(years)) {
    year_iter <- unique(format(years[[yi]], format = "%Y"))
    start <- min(time_stamp)-1
    day_iter <- as.numeric(years[[yi]] - start)
    y_HR <- foreach(t = day_iter, #dim(ERA5Land_ext)[3]
                    .combine = "acomb") %dopar% {
                      print(
                        paste(
                          "IDW variable",
                          var_i,
                          v,
                          "of",
                          dim(ERA5Land_ext)[4],
                          "; year",
                          year_iter,
                          "; day completed:",
                          round(t / max(day_iter), 2) * 100,
                          "%"
                        )
                      )
                      daily_df <- data.frame(
                        Longitude = as.numeric(rep(
                          dimnames(ERA5Land_ext)[[2]], each = dim(ERA5Land_ext)[1]
                        )),
                        Latitude = as.numeric(rep(
                          dimnames(ERA5Land_ext)[[1]], dim(ERA5Land_ext)[2]
                        )),
                        y = c(ERA5Land_ext[, , t, v])
                      )
                      coordinates(daily_df) <- c("Longitude", "Latitude")
                      fgrid_ext <- idw(y ~ 1,
                                       daily_df,
                                       newdata = fgrid_sp,
                                       nmax = 4,
                                       idp = 1) # 8 seconds
                      y_HR <- matrix(
                        fgrid_ext@data$var1.pred,
                        nrow = dim_lon,
                        ncol = dim_lat,
                        byrow = T
                      )
                      rm(fgrid_ext, daily_df)
                      gc()
                      dimnames(y_HR)[[1]] <- coord_lat
                      dimnames(y_HR)[[2]] <- coord_lon
                      print(Sys.time())
                      y_HR
                    }
    dimnames(y_HR)[[3]] <- as.numeric(years[[yi]])
    saveRDS(
      y_HR,
      file = paste0(
        "WE-Modelling/v.1.0.0/data/HR/HR",c_res,"_daily_",
        var_i,
        "_",
        year_iter,
        ".rds"
      )
    )
    rm(y_HR)
    gc()
  }
}

# aggiungere blh

#A_Unito