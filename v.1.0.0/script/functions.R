ERA5Land <- function(variable, fileslist, path) {
  library(abind)
  fileslist <-
    fileslist[order(fileslist$year, fileslist$month, fileslist$var),]
  variable <- variable[order(variable)]
  v <-
    matrix(which(fileslist$var %in% variable),
           ncol = length(variable),
           # nrow = nrow(unique(fileslist[, c(3, 4)])),
           byrow = T)
  for (i in 1:nrow(v)) {
    nc <- list()
    for (j in 1:ncol(v)) {
      print(paste(fileslist$var[v[i, j]], fileslist$year[v[i, j]], fileslist$month[v[i, j]]))
      nc[[j]] <-
        nc_open(paste0(path, "/", fileslist$nc_file[v[i, j]]))
    }
    lon <- nc[[1]]$dim$longitude$vals
    lat <- nc[[1]]$dim$latitude$vals
    time <- nc[[1]]$dim$valid_time$vals
    if (all(c("d2m", "t2m") %in% variable)) {
      #relative humidity
      y1 <- ncvar_get(nc[[1]], "d2m")
      y2 <- ncvar_get(nc[[2]], "t2m")
      y1 <- y1 - 273.15
      y2 <- y2 - 273.15
      y_rh <-
        100 * (exp(((17.625 * y1) / (243.04 + y1)) - ((17.625 * y2) / (243.04 +
                                                                         y2))))
      y_rh <- flip_nc(y_rh)
      y_d <- to_daily(y_rh, "mean")
    } else if ("t2m" %in% variable) {
      y <- ncvar_get(nc[[1]], "t2m")
      y <- y - 273.15
      y <- flip_nc(y)
      y_d <- to_daily(y, "mean")
    } else if ("ssr" %in% variable) {
      y <- ncvar_get(nc[[1]], "ssr")
      y <- flip_nc(y)
      y_d <- to_daily(y, "max")
    } else if (any(c("lai_lv", "lai_hv", "tp") %in% variable)) {
      y <- ncvar_get(nc[[1]], variable)
      y <- flip_nc(y)
      y_d <- to_daily(y, "fix")
    } else if (all(c("u10", "v10") %in% variable)) {
      y1 <- ncvar_get(nc[[1]], "u10")
      y2 <- ncvar_get(nc[[2]], "v10")
      y_ws <- sqrt((y1 ^ 2) + (y2 ^ 2))
      y_wd <- atan2(y1 / y_ws, y2 / y_ws) #wind direction in radius
      y_wd <- 180 - (y_wd * 180 / pi) #wind direction in angle
      y_ws <- flip_nc(y_ws)
      y_wd <- flip_nc(y_wd)
      y_d <- to_daily(y_ws, "mean")
      y_d2 <- to_daily(y_wd, "getmode")
    } else {
      stop("variable not recognized")
    }
    colnames(y_d) <- round(lon, 2)
    rownames(y_d) <- round(lat, 2)
    dimnames(y_d)[[3]] <- as.Date(time/(24*60*60))[seq(1,length(time),24)]
    if ("y_d2" %in% ls()) {
      colnames(y_d2) <- round(lon, 2)
      rownames(y_d2) <- round(lat, 2)
      dimnames(y_d2)[[3]] <- as.Date(time/(24*60*60))[seq(1,length(time),24)]
      y_d <- abind(y_d, y_d2, along = 2)
      rm(y_d2)
    }
    if (i == 1) {
      y_d_tot <- y_d
    } else{
      y_d_tot <- abind(y_d_tot, y_d, along = 3)
    }
  }
  return(y_d_tot)
}

acomb <- function(...)
  abind(..., along = 3)

to_daily <- function(arr, f) {
  y_d <-
    foreach (d = 1:(dim(arr)[3] / 24), .combine = "acomb") %dopar% {
      print(d)
      idx <- ((24 * (d - 1)) + 1):(24 * d)
      if (f == "fix") {
        y_d <- arr[, , idx[length(idx)]]
      } else {
        if (f == "getmode") {
          arr[, , idx] <- class_degree(arr[, , idx])
        }
        y_d <- apply(arr[, , idx], c(1, 2), f)
      }
      y_d
    }
  return(y_d)
}

class_degree <- function(arr) {
  classi <- seq(0, 360, by = 45)
  arr_class <- array(NA, dim = dim(arr))
  arr_class[arr >= classi[1] & arr < classi[2]] <- 1
  arr_class[arr >= classi[2] & arr < classi[4]] <- 2
  arr_class[arr >= classi[4] & arr < classi[6]] <- 3
  arr_class[arr >= classi[6] & arr < classi[8]] <- 4
  arr_class[arr >= classi[8] & arr < classi[9]] <- 1
  return(arr_class)
}

getmode <- function(v) {
  uniqv <- unique(v)
  uniqv[which.max(tabulate(match(v, uniqv)))]
}


ERA5SL <-
  function(variable, fileslist, path) {
    #le variabili multiple WE si bindano nella terza dimensione
    library(abind)
    fileslist <-
      fileslist[order(fileslist$year, fileslist$month, fileslist$var),]
    variable <- variable[order(variable)]
    v <-
      matrix(which(fileslist$var %in% variable),
             ncol = length(variable),
             byrow = T)
    # if (variable == "u10,v10,t2m,tp") {
    #   v <- matrix(6)
    # } #manuale
    for (i in 1:nrow(v)) {
      nc <- list()
      for (j in 1:ncol(v)) {
        print(paste(fileslist$var[v[i, j]], fileslist$year[v[i, j]], fileslist$month[v[i, j]]))
        nc[[j]] <-
          nc_open(paste0(path, "/", fileslist$nc_file[v[i, j]]))
      }
      lon <- nc[[1]]$dim$longitude$vals
      lat <- nc[[1]]$dim$latitude$vals
      time <- nc[[1]]$dim$valid_time$vals
      if ("blh" %in% variable) {
        y <- ncvar_get(nc[[1]], "blh")
        y <- flip_nc(y)
        y_d <- to_daily(y, "mean")
      } else if ("u10,v10,t2m,tp" %in% variable) {
        y1 <- ncvar_get(nc[[1]], "u10")
        y2 <- ncvar_get(nc[[1]], "v10")
        y_ws <- sqrt((y1 ^ 2) + (y2 ^ 2))
        y_wd <- atan2(y1 / y_ws, y2 / y_ws) #wind direction in radius
        y_wd <- 180 - (y_wd * 180 / pi) #wind direction in angle
        y_ws <- flip_nc(y_ws)
        y_wd <- flip_nc(y_wd)
        y_d1 <- to_daily(y_ws, "mean")
        y_d2 <- to_daily(y_wd, "getmode")
        y3 <- ncvar_get(nc[[1]], "t2m")
        y3 <- y3 - 273.15
        y3 <- flip_nc(y3)
        y_d3 <- to_daily(y3, "mean")
        y4 <- ncvar_get(nc[[1]], "tp")
        y4 <- flip_nc(y4)
        y_d4 <- to_daily(y4, "fix")
        y_d <- abind(y_d1, y_d2, y_d3, y_d4, along = 4)
      } else {
        stop("variable not recognized")
      }
      colnames(y_d) <- round(lon, 2)
      rownames(y_d) <- round(lat, 2)
      dimnames(y_d)[[3]] <- as.Date(time/(24*60*60))[seq(1,length(time),24)]
      if (i == 1) {
        y_d_tot <- y_d
      } else{
        y_d_tot <- abind(y_d_tot, y_d, along = 3)
      }
    }
    return(y_d_tot)
  }

flip_nc <- function(arr) {
  aperm(arr,c(2,1,3))
}


