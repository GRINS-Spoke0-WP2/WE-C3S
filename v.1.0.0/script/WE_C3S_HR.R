
# Import packages --------------------------------------------------------------

rm(list = ls())
library(devtools)
devtools::document(
  pkg = "~/Desktop/geotools"
)
library(tictoc)
install.packages(
  "~/Desktop/geotools", 
  repos = NULL,
  type = "source"
)
library(geotools)

# Configuration items ----------------------------------------------------------

VARIABLES <- c(
  # "blh"
  "lai_hv",
  "lai_lv"
  # "rh",
  # "ssr",
  # "t2m",
  # "tp",
  # "windspeed"
)
RESOLUTION <- .05

# Run --------------------------------------------------------------------------

counter <- 1
for (variable_i in VARIABLES) {
  
  # import raw (array) data
  print(
    sprintf("%s.a) Import raw (array) data, variable '%s'", counter, variable_i)
  )
  
  ## iteration by directory
  src_array <- list()
  for (dir_i in c("ERA5Land", "ERA5SL")){
    
    # import
    tic()
    load(
      sprintf("data/src/%s/daily_%s.Rdata", dir_i, variable_i)
    )
    src_array[[dir_i]] <- y
    print(
      sprintf("- %s done, %s.", dir_i, toc(quiet=TRUE)$callback_msg)
    )
  }
  
  # perform IDW
  print(
    sprintf("%s.b) Perform IDW, variable '%s'", counter, variable_i)
  )
  idw_df <- list()
  for (dir_i in c("ERA5Land", "ERA5SL")){
    
    # import
    tic()
    temp <- src_array[[dir_i]][,,1:10]
    idw_df[[dir_i]] <- idw2hr(
      data = temp,
      outgrid_params = list(
        "resolution" = RESOLUTION,
        "min_lon" = min(as.numeric(dimnames(temp)[[2]])),
        "max_lon" = max(as.numeric(dimnames(temp)[[2]])),
        "min_lat" = min(as.numeric(dimnames(temp)[[1]])),
        "max_lat" = max(as.numeric(dimnames(temp)[[1]]))
      ),
      ncores = 10,
      idp = 2,
      restore_NA = TRUE
    )
    print(
      sprintf("- %s done, %s.", dir_i, toc(quiet=TRUE)$callback_msg)
    )
  }
  
  counter <- counter + 1
  print("")
}
