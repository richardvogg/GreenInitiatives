library(sf)
library(raster)
library(dplyr)
library(ggplot2)
#library(ncdf4)

regiones <- read_sf("C:/Richard/R and Python/Environmental Data Science/Regiones/Regional.shp")
valpo <- read_sf("C:/Richard/R and Python/Environmental Data Science/Comunas/comunas.shp") %>% 
  filter(!Comuna %in% c("Isla de Pascua","Juan Fernández"),Region=="Región de Valparaíso") %>% 
  st_simplify(dTolerance=500) %>% 
  st_buffer(400) %>% 
  st_union()

#chile <- comunas %>% st_union()

valpo %>% 
ggplot()+
  geom_sf()+
  theme(legend.position = "none")

test <- regiones %>% filter(Region=="Región de Valparaíso") %>% 
  st_intersection(valpo)

regiones <- regiones %>% filter(!Region%in%c("Región de Valparaíso","Zona sin demarcar")) %>%
  rbind(test)

reg_simp <- regiones %>% 
  st_simplify(dTolerance=8000)

reg_buff <- reg_simp %>% 
  st_buffer(20000)

reg_simp %>% 
  ggplot()+
  geom_sf()+
  theme(legend.position = "none")

#Get the raster data


ncin <- brick("C:/Richard/R and Python/Environmental Data Science/GIS/ChileClimate/Data_raw/precip.2019.nc")
ncin <- brick("C:/Richard/R and Python/Environmental Data Science/GIS/ChileClimate/Data_raw/precip.mon.mean.nc")
#ncin <- projectRaster(ncin, crs = crs("+init=epsg:3857"))
extent(ncin) <- extent(-18000000,18000000,-9000000,9000000)

crs(ncin) <- crs(regiones)
test <- raster::intersect(x=ncin[[1]],y=reg_buff)

rt <- data.frame(rasterToPoints(mask(test,reg_buff)))
names(rt) <- c("x","y","value")


ggplot()+
  geom_raster(data=rt,aes(x=x,y=y,fill=value))+
  geom_sf(data=reg_simp,col="red",fill=NA)
