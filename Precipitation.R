library(sf)
library(raster)
library(dplyr)
library(ggplot2)

options(scipen=10)

#Load Shapefiles from Chilean regions
regiones <- read_sf("C:/Richard/R and Python/Environmental Data Science/Regiones/Regional.shp")

#Load Rasters
prec <- brick("C:/Richard/R and Python/Environmental Data Science/GIS/ChileClimate/Data_raw/precip.2019.nc")
prec <- rotate(prec)

#For Valparaiso remove Easter Island and Isla Juan Fernandez, then buffer to make it larger
valpo <- read_sf("C:/Richard/R and Python/Environmental Data Science/Comunas/comunas.shp") %>% 
  filter(!Comuna %in% c("Isla de Pascua","Juan Fernández"),Region=="Región de Valparaíso") %>% 
  st_simplify(dTolerance=500) %>% 
  st_buffer(5000) %>% 
  st_union()
  

#Plot Valparaiso Region without Easter Island
valpo %>% 
ggplot()+
  geom_sf()+
  theme(legend.position = "none")

#Intersect Valparaiso with the new Valpo without Easter Island
test <- regiones %>% filter(Region=="Región de Valparaíso") %>% 
  st_buffer(dist=0) %>% 
  st_intersection(valpo)

#Remove old Valparaiso region from regions and add new Valpo
regiones <- regiones %>% 
  filter(!Region%in%c("Región de Valparaíso","Zona sin demarcar")) %>%
  rbind(test)

#Simplified version for faster visualization
reg_simp <- regiones %>% 
  st_simplify(dTolerance=8000)

reg_simp %>% 
  ggplot()+
  geom_sf()+
  theme(legend.position = "none")

regiones <- regiones %>% st_transform(crs(prec)@projargs)
reg_simp <- reg_simp %>% st_transform(crs(prec)@projargs)

#Get the raster data

#Change extent and CRS 
#extent(prec) <- extent(-9000000,9000000,-18000000,18000000)
crs(prec) <- crs(regiones)


rt <- data.frame(rasterToPoints(mask(prec[[161]],reg_simp)))

names(rt) <- c("x","y","value")



ggplot()+
  geom_tile(data=rt,aes(x=x,y=y,fill=value))+
  geom_sf(data=reg_simp,col="red",fill=NA)


