ERA5Land <- function(variable, fileslist, path) {
  library(abind)
  fileslist <-
    fileslist[order(fileslist$year, fileslist$month, fileslist$var),]
  variable <- variable[order(variable)]
  v <-
    matrix(which(fileslist$var %in% variable),
           nrow = nrow(unique(fileslist[, c(3, 4)])),
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
    if ("y_d2" %in% ls()) {
      colnames(y_d2) <- round(lon, 2)
      rownames(y_d2) <- round(lat, 2)
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
        y_d <- arr[, , length(idx)]
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
             nrow = nrow(unique(fileslist[, c(3, 4)])),
             byrow = T)
    if (variable == "u10,v10,t2m,tp") {
      v <- matrix(6)
    } #manuale
    for (i in 1:nrow(v)) {
      nc <- list()
      for (j in 1:ncol(v)) {
        print(paste(fileslist$var[v[i, j]], fileslist$year[v[i, j]], fileslist$month[v[i, j]]))
        nc[[j]] <-
          nc_open(paste0(path, "/", fileslist$nc_file[v[i, j]]))
      }
      lon <- nc[[1]]$dim$longitude$vals
      lat <- nc[[1]]$dim$latitude$vals
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
      if (i == 1) {
        y_d_tot <- y_d
      } else{
        y_d_tot <- abind(y_d_tot, y_d, along = 3)
      }
    }
    return(y_d_tot)
  }

flip_nc <- function(arr) {
  arr <- aperm(arr, c(2, 1, 3))
  # arr <- arr[, dim(arr)[2]:1, ]
}

# ERA5netcdftopoints <-
#   function(nc_file,
#            path_in,
#            print = T,
#            newfile = F,
#            path_out = NULL,
#            monthly = F) {
#     library(ncdf4)
#     nc <- nc_open(paste0(path_in, "/", nc_file))
#     lat <- ncvar_get(nc, "latitude")
#     lon <- ncvar_get(nc, "longitude")
#     t <- ncvar_get(nc, "time")
#     nvar <- nc$nvars
#     varname <- names(nc$var)
#     matr <- matrix(nrow = length(t) * length(lon) * length(lat),
#                    ncol = 2)
#     matr[, 1] <- rep(rep(lon, length(lat)), length(t))
#     matr[, 2] <- rep(rep(lat, each = length(lon)), length(t))
#     colnames(matr) <- c("lon", "lat")
#     df <- data.frame(matr)
#     matr <- matrix(nrow = length(t) * length(lon) * length(lat),
#                    ncol = nvar)
#     daytime <-
#       as.POSIXct(t * 3600,
#                  origin = as.POSIXct("1900-01-01 00:00:00"),
#                  tz = "Etc/GMT-1")
#     df$time <- rep(daytime, each = length(lon) * length(lat))
#     for (k in 1:nvar) {
#       var <- ncvar_get(nc, varname[k])
#       matr[, k] <- c(var)
#     }
#     colnames(matr) <- c(varname)
#     df <- cbind(df, as.data.frame(matr))
#     if (newfile == T) {
#       year <- unique(substr(df$time[1], 1, 4))
#       output <- paste0(varname, "_", year , ".Rdata")
#       if (monthly == T) {
#         output <-
#           paste0(varname, "_", year, "_", unique(month(df$time)), ".Rdata")
#       }
#       save(df, file = paste0(path_out, "/", output))
#     }
#     if (print == T) {
#       return(df)
#     }
#     rm(df)
#     rm(matr)
#   }
#
# ERA5_Land_fromHourlytoDaily <-
#   function(df,
#            newfile = F,
#            path_out,
#            print = T) {
#     lon <- unique(df$lon)
#     lat <- unique(df$lat)
#     time <- unique(df$time)
#     daily <- seq(1, length(time), by = 24) #first hour of each days
#     # from u10 and v10 to wind speed and direction
#     df$ws <- sqrt((df$u10 ^ 2) + (df$v10 ^ 2)) #wind speed in m/s
#     # df$ws_kmh<-df$ws*3.6 #wind speed in km/h
#     df$wa <-
#       atan2(df$u10 / df$ws, df$v10 / df$ws) #wind direction in radius
#     df$wa_deg <- 180 - (df$wa * 180 / pi) #wind direction in angle
#     classi <- seq(0, 360, by = 22.5)
#     df$wa_deg_cl <- array(NA, nrow(df))
#     df$wa_deg_cl[which(df$wa_deg >= classi[1] &
#                          df$wa_deg <= classi[2])] <- "S"
#     df$wa_deg_cl[which(df$wa_deg >= classi[2] &
#                          df$wa_deg <= classi[4])] <- "SW"
#     df$wa_deg_cl[which(df$wa_deg >= classi[4] &
#                          df$wa_deg <= classi[6])] <- "W"
#     df$wa_deg_cl[which(df$wa_deg >= classi[6] &
#                          df$wa_deg <= classi[8])] <- "NW"
#     df$wa_deg_cl[which(df$wa_deg >= classi[8] &
#                          df$wa_deg <= classi[10])] <- "N"
#     df$wa_deg_cl[which(df$wa_deg >= classi[10] &
#                          df$wa_deg <= classi[12])] <- "NE"
#     df$wa_deg_cl[which(df$wa_deg >= classi[12] &
#                          df$wa_deg <= classi[14])] <- "E"
#     df$wa_deg_cl[which(df$wa_deg >= classi[14] &
#                          df$wa_deg <= classi[16])] <- "SE"
#     df$wa_deg_cl[which(df$wa_deg >= classi[16] &
#                          df$wa_deg <= classi[17])] <- "S"
#     df$t2m <- df$t2m - 273.15
#     df$d2m <- df$d2m - 273.15
#     df$rh <-
#       100 * (exp(((17.625 * df$d2m) / (243.04 + df$d2m)) - ((17.625 * df$t2m) /
#                                                               (243.04 + df$t2m))))
#     df <-
#       df[, c("lon",
#              "lat",
#              "time",
#              "hvi",
#              "lvi",
#              "ssr",
#              "t2m",
#              "tp",
#              "ws",
#              "wa_deg_cl",
#              "rh")]
#     year <- unique(substr(df$time, 1, 4))
#     # ------- daily trasformation --------- #
#     nws <- which(names(df) == "ws")
#     nwa <- which(names(df) == "wa_deg_cl")
#     nt2m <- which(names(df) == "t2m")
#     nhvi <- which(names(df) == "hvi")
#     nlvi <- which(names(df) == "lvi")
#     nssr <- which(names(df) == "ssr")
#     ntp <- which(names(df) == "tp")
#     nrh <- which(names(df) == "rh")
#     getmode <- function(v) {
#       uniqv <- unique(v)
#       uniqv[which.max(tabulate(match(v, uniqv)))]
#     }
#     daily_values_1 <- list()
#     for (x in 1:length(lon)) {
#       sub1 <- subset(df, round(lon, 2) == round(lon[x], 2))
#       daily_values_2 <- list()
#       for (y in 1:length(lat)) {
#         sub2 <- subset(sub1, round(lat, 2) == round(lat[y], 2))
#         sub2 <- sub2[order(sub2$time),]
#         daily_values_3 <- list()
#         for (d in 1:length(daily)) {
#           daily_values_4 <- list()
#           for (sm in c(nws, nt2m)) {
#             #wind speed, temperature
#             daily_values_4[[sm]] <-
#               mean(sub2[c(daily[d]:(daily[d] + 23)), sm])
#             ifelse(
#               d == 1,
#               daily_values_3[[sm]] <- daily_values_4[[sm]],
#               daily_values_3[[sm]] <- c(daily_values_3[[sm]],
#                                         daily_values_4[[sm]])
#             )
#           }
#           daily_values_4[[1]] <-
#             max(sub2[c((daily[d]):(daily[d] + 23)), nws]) #max of wind speed
#           ifelse(
#             d == 1,
#             daily_values_3[[1]] <- daily_values_4[[1]],
#             daily_values_3[[1]] <- c(daily_values_3[[1]],
#                                      daily_values_4[[1]])
#           )
#           for (w in nwa) {
#             #mode of wind direction
#             daily_values_4[[w]] <-
#               getmode(sub2[c(daily[d]:(daily[d] + 23)), w])
#             ifelse(
#               d == 1,
#               daily_values_3[[w]] <- daily_values_4[[w]],
#               daily_values_3[[w]] <- c(daily_values_3[[w]],
#                                        daily_values_4[[w]])
#             )
#           }
#           for (fd in c(nhvi, nlvi)) {
#             #vegetation index, fixed daily value
#             daily_values_4[[fd]] <- sub2[(daily[d] + 1), fd]
#             ifelse(
#               d == 1,
#               daily_values_3[[fd]] <- daily_values_4[[fd]],
#               daily_values_3[[fd]] <- c(daily_values_3[[fd]],
#                                         daily_values_4[[fd]])
#             )
#           }
#           sr <- sub2[c((daily[d] + 1):(daily[d] + 23)), nssr]
#           daily_values_4[[nssr]] <-
#             max(sr[!is.na(sr)]) #surface solar radiation
#           ifelse(
#             d == 1,
#             daily_values_3[[nssr]] <- daily_values_4[[nssr]],
#             daily_values_3[[nssr]] <- c(daily_values_3[[nssr]],
#                                         daily_values_4[[nssr]])
#           )
#           daily_values_4[[ntp]] <-
#             sub2[(daily[d] + 23), ntp] #total precipitation
#           ifelse(
#             d == 1,
#             daily_values_3[[ntp]] <- daily_values_4[[ntp]],
#             daily_values_3[[ntp]] <- c(daily_values_3[[ntp]],
#                                        daily_values_4[[ntp]])
#           )
#           daily_values_4[[13]] <-
#             min(sub2[c(daily[d]:(daily[d] + 23)), nrh]) #min relative humidity
#           ifelse(
#             d == 1,
#             daily_values_3[[13]] <- daily_values_4[[13]],
#             daily_values_3[[13]] <- c(daily_values_3[[13]],
#                                       daily_values_4[[13]])
#           )
#           daily_values_4[[14]] <-
#             mean(sub2[c(daily[d]:(daily[d] + 23)), nrh]) #mean relative humidity
#           ifelse(
#             d == 1,
#             daily_values_3[[14]] <- daily_values_4[[14]],
#             daily_values_3[[14]] <- c(daily_values_3[[14]],
#                                       daily_values_4[[14]])
#           )
#           daily_values_4[[15]] <-
#             max(sub2[c(daily[d]:(daily[d] + 23)), nrh]) #max relative humidity
#           ifelse(
#             d == 1,
#             daily_values_3[[15]] <- daily_values_4[[15]],
#             daily_values_3[[15]] <- c(daily_values_3[[15]],
#                                       daily_values_4[[15]])
#           )
#
#         }
#         for (dv2 in c(nws, nt2m, 1, nwa, nhvi, nlvi, nssr, ntp, 13:15)) {
#           ifelse(
#             y == 1,
#             daily_values_2[[dv2]] <- daily_values_3[[dv2]],
#             daily_values_2[[dv2]] <- c(daily_values_2[[dv2]],
#                                        daily_values_3[[dv2]])
#           )
#         }
#       }
#       for (dv1 in c(nws, nt2m, 1, nwa, nhvi, nlvi, nssr, ntp, 13:15)) {
#         ifelse(
#           x == 1,
#           daily_values_1[[dv1]] <- daily_values_2[[dv1]],
#           daily_values_1[[dv1]] <- c(daily_values_1[[dv1]],
#                                      daily_values_2[[dv1]])
#         )
#       }
#     }
#     days <- seq(min(as_date(df$time)),
#                 max(as_date(df$time)),
#                 by = "day")
#     df_daily <- data.frame(
#       lon = rep(lon, each = (length(lat) * length(days))),
#       lat = rep(lat, length(lon), each = length(days)),
#       time = days,
#       WE_temp = daily_values_1[[nt2m]],
#       WE_ws_avg = daily_values_1[[nws]],
#       WE_ws_max = daily_values_1[[1]],
#       WE_wd = daily_values_1[[nwa]],
#       WE_tp = daily_values_1[[ntp]],
#       WE_ssr = daily_values_1[[nssr]],
#       LA_hvi = daily_values_1[[nhvi]],
#       LA_lvi = daily_values_1[[nlvi]],
#       WE_rh_min = daily_values_1[[13]],
#       WE_rh_avg = daily_values_1[[14]],
#       WE_rh_max = daily_values_1[[15]]
#     )
#     # --- saving output
#     if (newfile == T) {
#       if (length(unique(months(df_daily$time))) == 1) {
#         m <- unique(months(df_daily$time))
#         output <- paste0("ERA5Land_", year, "_", m, ".Rdata")
#       } else{
#         output <- paste0("ERA5Land_", year, ".Rdata")
#       }
#       save(df_daily, file = paste0(path_out, "/", output))
#     }
#     if (print == T) {
#       return(df_daily)
#     }
#   }
