library(ggplot2)
setwd("WE-C3S")

lf <- list.files("v.1.0.0/data/ERA5Land/daily", pattern = ".Rdata")

for (i in lf) {
  load(paste0("v.1.0.0/data/ERA5Land/daily/", i))
  print(plot(y[1, 1, ], main = i, type = "l"))
  print(plot(y[50, 60, ], main = i, type = "l"))
  df <- as.data.frame(cbind(rep(dimnames(y)[[2]], each = dim(y)[1]),
                            rep(dimnames(y)[[1]], dim(y)[2])))
  names(df)<-c("lon","lat")
  df$lat <- as.numeric(df$lat)
  df$lon <- as.numeric(df$lon)
  df$y1 <- c(y[,,1])
  df$y100 <- c(y[,,100])
  df$y250 <- c(y[,,250])
  print(ggplot(df)+
    geom_tile(aes(lon,lat,fill=y1))+
    ggtitle(label = i)+
    scale_fill_continuous(type = "viridis"))
  print(ggplot(df)+
    geom_tile(aes(lon,lat,fill=y100))+
    ggtitle(label = i)+
    scale_fill_continuous(type = "viridis"))
  print(ggplot(df)+
    geom_tile(aes(lon,lat,fill=y250))+
    ggtitle(label = i)+
    scale_fill_continuous(type = "viridis"))
}
