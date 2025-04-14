B_IT <- c(6, 19, 35, 48) 
library(sp)
library(gstat)

#for HPC
#setwd("/mnt/wp02/FRK-GRINS")

#import ####
## era5land ####
library(abind)
lf <- list.files("WE-C3S/v.1.0.0/data/ERA5Land/daily")
lf <- lf[lf != "daily_wind.Rdata"]
ndata <- length(lf)
for (i in 1:ndata) {
  load(paste0("WE-C3S/v.1.0.0/data/ERA5Land/daily/", lf[i]))
  if (i == 1) {
    Y_era5land <- y
  } else{
    Y_era5land <- abind(Y_era5land, y, along = 4)
  }
}
na_idx_era5land <- is.na(Y_era5land[, , 1, 1])

varnames <- unlist(lapply(lf, function(x)
  substr(x, 7, nchar(x) - 6)))
dimnames(Y_era5land)[[4]] <- varnames
rm(y)

grid_era5land <- data.frame(Longitude = as.numeric(rep(
  dimnames(Y_era5land)[[2]], each = dim(Y_era5land)[1]
)), Latitude = as.numeric(rep(dimnames(Y_era5land)[[1]], dim(Y_era5land)[2])))
coordinates(grid_era5land) <- c("Longitude", "Latitude")

## era5 single level ####
lf <- list.files("WE-C3S/v.1.0.0/data/ERA5SL/daily")
lf <- lf[-8]
ndata <- length(lf)
for (i in 1:ndata) {
  load(paste0("WE-C3S/v.1.0.0/data/ERA5SL/daily/", lf[i]))
  if (i == 1) {
    Y_era5sl <- y
  } else{
    Y_era5sl <- abind(Y_era5sl, y, along = 4)
  }
}
varnames <- unlist(lapply(lf, function(x)
  substr(x, 7, nchar(x) - 6)))
dimnames(Y_era5sl)[[4]] <- varnames
rm(y)

# IDW ####
## era5sl -> era5land ####
# filling sea cells with era5sl values
nv_era5sl_in_era5land <- which(dimnames(Y_era5sl)[[4]] %in% dimnames(Y_era5land)[[4]])

Y_d_era5land <- Y_era5land[,,1,1] #initialising


#da rifare con foreach per parallelizzare
for (v in nv_era5sl_in_era5land) {
  if(dimnames(Y_era5sl)[[4]][v] == "winddir"){next}
  for (t in 1:dim(Y_era5sl)[3]) {
    print(paste("IDW variable",v,"on",dim(Y_era5sl)[4],"; time",round(t / dim(Y_era5sl)[3], 2), "%"))
    daily_data <- Y_era5sl[, , t, v]
    daily_df <- data.frame(
      Longitude = as.numeric(rep(
        dimnames(Y_era5sl)[[2]], each = dim(Y_era5sl)[1]
      )),
      Latitude = as.numeric(rep(dimnames(Y_era5sl)[[1]], dim(Y_era5sl)[2])),
      y = c(daily_data)
    )
    coordinates(daily_df) <- c("Longitude", "Latitude")
    era5sl_on_era5land <- idw(y ~ 1,
                              daily_df,
                              newdata = grid_era5land,
                              nmax = 4,
                              idp = 1)
    y_era5sl_on_era5land <- matrix(
      c(era5sl_on_era5land@data$var1.pred),
      nrow = dim(Y_era5land)[1],
      ncol = dim(Y_era5land)[2]
    )
    nv_era5land <- which(dimnames(Y_era5land)[[4]] == dimnames(Y_era5sl)[[4]][v])
    Y_d_era5land <- Y_era5land[,,t,nv_era5land]
    Y_d_era5land[na_idx_era5land]<-y_era5sl_on_era5land[na_idx_era5land]
    Y_era5land[,,t,nv_era5land] <- Y_d_era5land
  }
}

saveRDS(ERA5Land_ext, file = "WE-Modelling/v.1.0.0/data/ERA5Land_ext.rds")
