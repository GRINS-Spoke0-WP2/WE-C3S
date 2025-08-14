i_t <- which(dimnames(daily_rh_005x005_2018)[[3]]==as.numeric(as.Date("2018-12-31")))
y <- daily_rh_005x005_2018
try(y <- y[,,i_t])

lat <- dimnames(y)[[1]]
lon <- dimnames(y)[[2]]
lat <- as.numeric(lat)
lon <- as.numeric(lon)

y0 <- seq(min(lon)+.1,max(lon)-.1,0.01)
x0 <- seq(min(lat)+.1,max(lat)-.1,0.01)

# lat <- rep(lat,length(lon))
# lon <- rep(lon,each=length(dimnames(y)[[1]]))
y <- y[dim(y)[1]:1,]
library(akima)
a <- bilinear(x=as.numeric(dimnames(y)[[1]]),
         y=as.numeric(dimnames(y)[[2]]),
         z=y,
         x0=rep(x0,length(y0)),
         y0=rep(y0,each=length(x0))
)

library(ggplot2)
b <- as.data.frame(a)
ggplot(b)+
  geom_tile(aes(y,x,col=z))+
  scale_color_continuous(type = "viridis")

data(akima760)
# interpolate at the diagonal of the grid [0,8]x[0,10]
akima.bil <- bilinear(akima760$x,akima760$y,akima760$z,
                      seq(0,8,length=50), seq(0,10,length=50))
plot(sqrt(akima.bil$x^2+akima.bil$y^2), akima.bil$z, type="l")

