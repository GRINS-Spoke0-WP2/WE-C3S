
# Import packages --------------------------------------------------------------

rm(list = ls())
setwd("GitHub/GRINS-Spoke0-WP2")
setwd("WE-C3S/v.1.0.0")
library(reshape2)
library(devtools)
library(tictoc)
library(geotools)

# Configuration items ----------------------------------------------------------

VARIABLES <- c(
  # "blh"
  "lai_hv",
  "lai_lv",
  "rh",
  "ssr",
  "t2m",
  "tp",
  "windspeed"
)
RESOLUTION <- .05

# Run --------------------------------------------------------------------------

library(doParallel)
registerDoParallel(cores = 2)
counter <- 1
for (variable_i in VARIABLES) {
  # variable_i <- VARIABLES[1]
  # import raw (array) data
  print(
    sprintf("%s.a) Import raw (array) data, variable '%s'", counter, variable_i)
  )
  
  ## iteration by directory
  src_array <- list()
  for (dir_i in c("ERA5SL", "ERA5Land")){
    
    # import
    tic()
    load(
      sprintf("data/%s/daily/daily_%s.Rdata", dir_i, variable_i)
    )
    src_array[[dir_i]] <- y
    print(
      sprintf("- %s done, %s.", dir_i, toc(quiet=TRUE)$callback_msg)
    )
  }
  
  t_days <- seq.Date(as.Date(min(as.numeric(dimnames(src_array[[1]])[[3]]))),
                     as.Date(max(as.numeric(dimnames(src_array[[1]])[[3]]))),
                     by="days")
  years <- unique(format(t_days,"%Y"))
  
  for (yi in years) { #servono due giorni
  ## perform IDW
  print(
    sprintf("%s.b) Perform IDW, variable '%s'", counter, variable_i)
  )
  idw_array_list <- list()
  for (dir_i in c("ERA5SL", "ERA5Land")){
    
    # run
    sub_t <- which(format(t_days,"%Y") == yi) 
    tic()
    temp <- src_array[[dir_i]][,,sub_t]
    
    idw_df_i <- idw2hr(
      data = temp,
      outgrid_params = list(
        "resolution" = RESOLUTION,
        "min_lon" = min(as.numeric(dimnames(temp)[[2]])),
        "max_lon" = max(as.numeric(dimnames(temp)[[2]])),
        "min_lat" = min(as.numeric(dimnames(temp)[[1]])),
        "max_lat" = max(as.numeric(dimnames(temp)[[1]]))
      ),
      ncores = 64,
      idp = 2,
      restore_NA = TRUE
    )
    
    # from data.frame to array
    # idw_df_i <- idw_df_i[order(idw_df_i$latitude,decreasing = T),]
    # idw_df_i <- idw_df_i[order(idw_df_i$longitude),]
    idw_df_i$time <- as.numeric(idw_df_i$time)
    idw_array_list[[dir_i]] <- acast(idw_df_i, latitude ~ longitude ~ time,
                                value.var = "var")
    idw_array_list[[dir_i]] <- idw_array_list[[dir_i]][dim(idw_array_list[[dir_i]])[1]:1,,]
    print(
      sprintf("- %s %s done, %s.", dir_i, yi, toc(quiet=TRUE)$callback_msg)
    )
  }
  
  ## process high-resolution data
  print(
    sprintf("%s.c) Process high-res. data, variable '%s' year %s", 
            counter, variable_i, yi)
  )
  tic()
  hr_df <- geomatching(
    data = idw_array_list,
    settings = list(
      "format"=list(
        "matrix",
        "matrix"
      ),
      "type"=list(
        "grid",
        "grid"
      ),
      "crs"=list(
        4326,
        4326
      )
    )
  )
  names(hr_df)[names(hr_df) == "var1"] <- "ERA5SL_var"
  names(hr_df)[names(hr_df) == "matrix_2"] <- "ERA5Land_var"
  print(
    sprintf("- Geo-matching done, %s.", toc(quiet=TRUE)$callback_msg)
  )
  
  # fill NA
  tic()
  hr_df$ERA5Land_var[is.na(hr_df$ERA5Land_var)] <- 
    hr_df$ERA5SL_var[is.na(hr_df$ERA5Land_var)]
  print(
    sprintf("- NA filled, %s.", toc(quiet=TRUE)$callback_msg)
  )
  
  # export high-resolution data
  tic()
  hr_array <- hr_df
  hr_array$time <- as.numeric(hr_array$time)
  hr_array <- acast(hr_array, latitude ~ longitude ~ time,
                    value.var = "ERA5Land_var")
  saveRDS(hr_array, file = sprintf("data/HRs/daily_%s_005x005_%s.rds",
                                   variable_i,yi))
  print(
    sprintf("- High-res. data exported, %s.", toc(quiet=TRUE)$callback_msg)
  )
  names(hr_df)[names(hr_df) == "ERA5Land_var"] <- variable_i
  
  ## aggregate high-res. grid data onto LAUs (Local Administrative Units)
  print(
    sprintf("%s.d) Aggregate high-res. data onto LAUs, variable '%s'",
            counter, variable_i)
  )
  tic()
  lau_df <- hr2poly(
    data = hr_df[, c("longitude", "latitude", "time", variable_i)],
    stats = setNames(
      list(list("min", "1st_percent", "mean", "median", "3rd_percent", "max", "std")),
      variable_i
    ),
    ncores = 64
  )
  print(
    sprintf("- Aggregation done, %s.", toc(quiet=TRUE)$callback_msg)
  )
  
  # export aggregated data
  tic()
  saveRDS(lau_df, file = sprintf("data/LAUs/daily_aggr_%s_LAUs_%s.rds",
                                 variable_i,yi))
  print(
    sprintf("- Aggr. data exported, %s.", toc(quiet=TRUE)$callback_msg)
  )
  
  counter <- counter + 1
  print("")
  gc()
  }}




veg_i <- c(daily_lai_hv_005x005_2013[,,1])
lat <- dimnames(daily_lai_hv_005x005_2013)[[1]]
lon <- dimnames(daily_lai_hv_005x005_2013)[[2]]
# time <- dimnames(daily_lai_hv_005x005_2013)[[3]]

df <- data.frame(var = veg_i,
           lat = rep(lat[order(lat,decreasing = T)],length(lon)),
           lon = rep(lat[order(lat,decreasing = F)],each=length(lat)))


# ggplot(df)+
#   geom_tile(aes(x=lon,y=lat,fill=var))
