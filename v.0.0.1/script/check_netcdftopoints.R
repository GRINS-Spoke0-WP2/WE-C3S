library(ggplot2)
ggplot(df[df$time==df$time[1],])+
  geom_tile(aes(x=lon,y=lat,fill=u10))
