library(sf)

com24 <-
  st_read(dsn = "geo_tools/geo_matching/v.1.0.0/dati/confini/extract_zip/Limiti01012024/Com01012024",
          layer = "Com01012024_WGS84")
com24 <- st_transform(com24, 4326)

source("geo_tools/geo_matching/geo_matching.R")

lf <- list.files("WE-C3S/v.1.0.0/data/ERA5Land/daily")
lf <- lf[-7]
for (i in lf) {
  load(paste0("WE-C3S/v.1.0.0/data/ERA5Land/daily/",i))
  x0 = seq(min(as.numeric(dimnames(y)[[2]]) - 0.05),
          max(as.numeric(dimnames(y)[[2]]) + 0.05),
          0.025)
  y0 = seq(min(as.numeric(dimnames(y)[[1]]) - 0.05),
          max(as.numeric(dimnames(y)[[1]]) + 0.05),
          0.025)
  df_downsc <- data.frame(x=rep(x0,each=length(y0)),
                          y=rep(y0,length(x0)))
  df_downsc <- df_downsc[rep(1:nrow(df_downsc),dim(y)[3]),]
  df_downsc$t <- rep(dimnames(y)[[3]], each = nrow(df_downsc)/dim(y)[3])
  df_downsc$t <- as.Date(as.numeric(df_downsc$t))
  # ... da aggiornare
  df_downsc_t2m <- geo_matching(data = list(df_downsc, t2m),
                                settings = list(
                                  format = c("xyt", "matrix"),
                                  type = c("points", "grid"),
                                  crs = c(4326, 4326)
                                ))
  
  WE_municipality <- geo_matching(data = list(df_downsc_t2m,com24),
                                  settings = list(
                                    format = c("xyt", "shp"),
                                    type = c("points", "polygons"),
                                    crs = c(4326, 4326)
                                  ))
  }
y_name <- lf

lf <- list.files("WE-C3S/v.1.0.0/data/ERA5SL/daily")
lf <- lf[-8]
for (i in lf) {
  load(paste0("WE-C3S/v.1.0.0/data/ERA5SL/daily/",i))
  name <- which(lf==i)
  assign(paste0("y2_",name),y)
}
y_name2 <- lf

# load("WE-C3S/v.1.0.0/data/ERA5Land/daily/daily_t2m.Rdata")
# y <- y[, , 1:10]
# t2m <- y

#downscaling the grid
t2m <- y_5

df_downsc <- data.frame(x=rep(x,each=length(y)),
                        y=rep(y,length(x)))
df_downsc <- df_downsc[rep(1:nrow(df_downsc),dim(t2m)[3]),]
df_downsc$t <- rep(dimnames(t2m)[[3]], each = nrow(df_downsc)/dim(t2m)[3])
df_downsc$t <- as.Date(as.numeric(df_downsc$t))
df_downsc_t2m <- geo_matching(data = list(df_downsc, t2m),
             settings = list(
               format = c("xyt", "matrix"),
               type = c("points", "grid"),
               crs = c(4326, 4326)
             ))

WE_municipality <- geo_matching(data = list(df_downsc_t2m,com24),
                                settings = list(
                                  format = c("xyt", "shp"),
                                  type = c("points", "polygons"),
                                  crs = c(4326, 4326)
                                ))

library(dplyr)
names(WE_municipality)[4:6]<-paste0(names(WE_municipality)[4:6],"_2") 
daily_mun <- WE_municipality %>%
  group_by(time,PRO_COM) %>%
  summarise(t2m = mean(matrix_2,na.rm=T))


df <- daily_mun[daily_mun$time==daily_mun$time[1],]
a <- merge(com24,df)

library(ggplot2)
ggplot()+
  geom_sf(data = a,aes(fill=t2m))+
  scale_fill_continuous(type="viridis")

dev.off()