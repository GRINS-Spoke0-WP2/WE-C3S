load("data/WE/ERA5Land/daily/daily_t2m.Rdata")
# y<-y[,131:1,]
y2<-y[,,1]
y2<-c(y2)
y2<-as.data.frame(y2)
y2$lat<-53:1
y2$lon<-rep(1:53,each=53)
library(ggplot2)
ggplot(y2)+
  geom_tile(aes(x=lon,y=lat,fill=y2))
