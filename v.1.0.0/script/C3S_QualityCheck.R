library(ggplot2)
setwd("WE-C3S")

# daily ####
lf <- list.files("v.1.0.0/data/ERA5Land/daily", pattern = ".Rdata")

for (i in lf) {
  load(paste0("v.1.0.0/data/ERA5Land/daily/", i))
  print(plot(y[1, 1, ], main = i, type = "l"))
  print(plot(y[50, 60, ], main = i, type = "l"))
  df <- as.data.frame(cbind(rep(dimnames(y)[[2]], each = dim(y)[1]), rep(dimnames(y)[[1]], dim(y)[2])))
  names(df) <- c("lon", "lat")
  df$lat <- as.numeric(df$lat)
  df$lon <- as.numeric(df$lon)
  df$y1 <- c(y[, , 1])
  df$y100 <- c(y[, , 100])
  df$y250 <- c(y[, , 250])
  print(
    ggplot(df) +
      geom_tile(aes(lon, lat, fill = y1)) +
      ggtitle(label = i) +
      scale_fill_continuous(type = "viridis")
  )
  print(
    ggplot(df) +
      geom_tile(aes(lon, lat, fill = y100)) +
      ggtitle(label = i) +
      scale_fill_continuous(type = "viridis")
  )
  print(
    ggplot(df) +
      geom_tile(aes(lon, lat, fill = y250)) +
      ggtitle(label = i) +
      scale_fill_continuous(type = "viridis")
  )
}

# HRs ####
path_in <- "v.1.0.0/data/HRs"
lf <- list.files(path_in, pattern = ".rds")
for (i in lf) {
  y <- readRDS(paste0(path_in, "/", i))
  print(plot(y[1, 1, ], main = i, type = "l"))
  print(plot(y[50, 60, ], main = i, type = "l"))
  df <- as.data.frame(cbind(rep(dimnames(y)[[2]], each = dim(y)[1]), rep(dimnames(y)[[1]], dim(y)[2])))
  names(df) <- c("lon", "lat")
  df$lat <- as.numeric(df$lat)
  df$lon <- as.numeric(df$lon)
  df$y1 <- c(y[, , 1])
  df$y100 <- c(y[, , 100])
  df$y250 <- c(y[, , 250])
  print(
    ggplot(df) +
      geom_tile(aes(lon, lat, fill = y1)) +
      ggtitle(label = i) +
      scale_fill_continuous(type = "viridis")
  )
  print(
    ggplot(df) +
      geom_tile(aes(lon, lat, fill = y100)) +
      ggtitle(label = i) +
      scale_fill_continuous(type = "viridis")
  )
  print(
    ggplot(df) +
      geom_tile(aes(lon, lat, fill = y250)) +
      ggtitle(label = i) +
      scale_fill_continuous(type = "viridis")
  )
  rm(y, df)
}

# LAUs ####
library(dplyr)
gc()
load("v.1.0.0/data/LAUs/IT_adm_bounds_2025.RData")
short_mun_bounds <- mun_bounds[,"PRO_COM"]
path_in <- "v.1.0.0/data/LAUs"
lf <- list.files(path_in, pattern = ".rds")
for (i in lf) {
  LAUs_df <- readRDS(paste0(path_in, "/", i))
  print(length(unique(LAUs_df$PRO_COM)))
  # var_i <- sub("daily_aggr_(.*)_LAUs_.*", "\\1", i)
  # LAUs_df <- LAUs_df[, c("PRO_COM", "time", paste0(
  #   var_i,
  #   c(
  #     "_min",
  #     "_1st_percent",
  #     "_mean",
  #     "_median",
  #     "_3rd_percent",
  #     "_max",
  #     "_std"
  #   )
  # ))]
  # # time fixed
  # d <- sample(unique(LAUs_df$time),1)
  # LAUs_df_d <- LAUs_df[LAUs_df$time == d,]
  # print(paste0("summary",var_i,d))
  # summary(LAUs_df_d)
  # LAUs_df_d <- left_join(LAUs_df_d,short_mun_bounds)
  # LAUs_df_d <- st_as_sf(LAUs_df_d)
  # ggplot()+
  #   geom_sf(data=LAUs_df_d,aes(fill=lai_hv_mean))
}
