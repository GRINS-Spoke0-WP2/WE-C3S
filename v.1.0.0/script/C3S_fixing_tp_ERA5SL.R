load("WE-C3S/v.1.0.0/data/ERA5SL/daily/daily_tp.Rdata") #moved to folder
y <- y*24
summary(y)
quantile(c(y),prob=.999)
save(y,file = "WE-C3S/v.1.0.0/data/ERA5SL/daily/daily_tp.Rdata")
