rm(list=ls())
library(doParallel)
registerDoParallel()
library(lubridate)
#by_months
source("script/WE/functions.R")
fls <- list.files("data/WE/ERA5Land/hourly/by_month/Rdata",pattern = "all_")
foreach (i = fls, .packages="lubridate") %dopar% {
  print(i)
  load(paste0("data/WE/ERA5Land/hourly/by_month/Rdata/",i))
  ERA5_Land_fromHourlytoDaily(df=tot_df,newfile = T,
             path_out="data/WE/ERA5Land/daily/by_month",
             print = F)
}
