library(ncdf4)
path <- '/Volumes/Extreme SSD/Lavoro/GRINS/GitHub/WE-C3S/v.1.0.0/data/VHR_REA_IT/upscaled'
fl <- list.files('/Volumes/Extreme SSD/Lavoro/GRINS/GitHub/WE-C3S/v.1.0.0/data/VHR_REA_IT/upscaled')
fl <- fl[grep("rotated",fl)]

nc <- nc_open(paste0(path,'/',fl))

cl_vhr_rea_2019 <- data.frame(
tp = c(ncvar_get(nc,"TOT_PREC_mean")),
t2m = c(ncvar_get(nc,"T_2M_mean")),
ws = c(ncvar_get(nc,"wind_speed_10m_mean")),
rh = c(ncvar_get(nc,"RH_mean")),
ssr = c(ncvar_get(nc,"ASOB_S_mean"))
)

time <- unique(c(ncvar_get(nc,"time")))
time <- as.Date(time,origin = as.Date("2019-01-13"))
summary(time)

lon <- unique(c(ncvar_get(nc,"lon")))
lat <- unique(c(ncvar_get(nc,"lat")))

coord_df <- expand.grid(
  lon = lon,
  lat = lat,
  time = time
)

df <- cbind(coord_df,cl_vhr_rea_2019)
df <- df[order(df$time,df$lat,df$lon),]
# saveRDS(df,file = "WE-C3S/v.1.0.0/data/VHR_REA_2019.rds")
sub <- df[df$time==df$time[1],]

library(ggplot2)
ggplot(sub)+
  geom_tile(aes(lon,lat,fill=t2m))+
  scale_fill_continuous(type="viridis")
# FUNZIONA!!!!!

summary(df$t2m)

library(sp)
library(spacetime)
centre <- unique(df[,1:2])
coordinates(centre) <- c("lon", "lat")
gridded(centre) <- TRUE
colnames(centre@coords) <- c("coords.x1", "coords.x2")
WE_VHR_REA_v100_ST <- STFDF(sp = centre,
                         time = unique(df$time),
                         data = df)

save(WE_VHR_REA_v100_ST,file = "AQ-FRK/v.3.0.0/A_input/data/input/WE_VHR_REA_v100_ST.rda")

