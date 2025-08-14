# from line 64
temp2 <- temp
data = temp2

outgrid_params = list(
  "resolution" = RESOLUTION,
  "min_lon" = min(as.numeric(dimnames(temp)[[2]])),
  "max_lon" = max(as.numeric(dimnames(temp)[[2]])),
  "min_lat" = min(as.numeric(dimnames(temp)[[1]])),
  "max_lat" = max(as.numeric(dimnames(temp)[[1]]))
)
ncores = 10
idp = 2
restore_NA = TRUE
crs = 4326
col_names = NULL
interest_vars = NULL
nmax = 4

if (is.array(data) && is.numeric(data)) {
  data <- geotools:::.array2df(data)
}

data <- geotools:::.check_colnames_idw2hr(data, col_names)
interest_vars <- geotools:::.check_interest_vars(data, interest_vars)

# cast to sp and reshape
sp_data <- geotools:::.reshape(data, crs)

# build output grid #commentato da me
outgrid <- geotools:::.check_outgrid(sp_data, outgrid_params)

max_cores <- parallel::detectCores()
if (ncores > max_cores) {
  warning(
    sprintf("Requested %d cores, but only %d available. Using %d cores.",
            ncores, max_cores, max_cores)
  )
  ncores <- max_cores
}
cl <- parallel::makeCluster(ncores)
doParallel::registerDoParallel(cl)

# stop cluster (on exit)
on.exit(
  {
    parallel::stopCluster(cl)
  },
  add = TRUE
)

# dal foreach - riga 132 dello script su github
library(sp)

for (time_i in unique(sp_data@data$time)[1:2]) {
  df <- subset(sp_data, time == time_i)
  sp_div <- seq(1,nrow(df),by=130)
}
hr_data <- foreach::foreach(sp_i = ,
                            .combine = 'rbind',
                            .packages = c("sp", "gstat", "dplyr")) %dopar% {
                              
                              hr_data_i <- data.frame(
                                longitude = coordinates(outgrid)[,1],
                                latitude = coordinates(outgrid)[,2],
                                time = rep(time_i, nrow(coordinates(outgrid)))
                              )
                              
                              for (var_i in interest_vars) {
                                
                                # run IDW
                                obj = gstat::idw(
                                  formula = as.formula(sprintf("%s ~ 1", var_i)),
                                  locations = df[!is.na(df@data[[var_i]]), ],
                                  newdata = outgrid,
                                  debug.level = 0,
                                  idp = idp,
                                  nmax = nmax
                                )
                                
                                # add new column
                                hr_data_i[[var_i]] <- obj@data$var1.pred
                              }
                              return(hr_data_i)
                            }


# see RESTORE NA
lr_df <- data
hr_df <- hr_data
resolution <- outgrid_params$resolution
NA_points <- lr_df[is.na(lr_df$var), ]

