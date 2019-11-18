library(dplyr)
library(ggplot2)
library(tidyr)

temps <- read.csv("C:/Richard/R and Python/Datasets/Temperatures/cr2_tasAmon_2018.txt",header=F,row.names=1,na.strings = '-9999')
temps2 <- data.frame(t(temps))
temps3 <- gather(temps2,key="date",value="temp",16:1432)
temps3 <- temps3 %>% filter(!is.na(temp)) %>%
  mutate(year=substr(date,2,5),
         month=substr(date,7,8),
         date=as.Date(paste0(year,"-",month,"-01")),
         temp=as.numeric(temp))

###
#Stations

#Good stations are those which have at least 20 years of measurements between 1970
#and 2000 (to calculate the average)
stations <- temps3 %>% group_by(nombre) %>%
  mutate(longitud=as.numeric(as.character(longitud)),
         latitud=as.numeric(as.character(latitud))) %>%
  summarise(start_date=min(date),end_date=max(date),measurements=n(),
            still_active=max(ifelse(end_date=='2018-01-01','Y','N')),
            thirty_y_period=length(temp[date>='1970-01-01' & date < '2000-01-01']),
            longitud=max(longitud),
            latitud=max(latitud)) %>%
  filter(longitud>(-80),longitud<(-65)) %>%
  filter(thirty_y_period>240,still_active=='Y')



chile <- map_data("world",region="Chile") %>% 
  filter(subregion!="Easter Island" | is.na(subregion))

g <- ggplot() + geom_polygon(data = chile, aes(x=long, y = lat, group = group)) +
  geom_point(data=stations,aes(x=longitud,y=latitud,text=nombre),col="yellow",size=2) + 
  coord_fixed(0.5)

library(plotly)

ggplotly(g,tooltip="text")

#Compare to 30 years average

avg_temps <- temps3 %>% 
  filter(year %in% 1970:2000) %>% 
  filter(nombre %in% stations$nombre) %>%
  group_by(nombre,month) %>%
  summarise(avg_temp=mean(temp,na.rm=T))

avg_temps %>% left_join(stations,by=c("nombre"="nombre")) %>%
  ggplot(aes(x=month,y=avg_temp,group=1))+geom_line(size=1)+
  facet_wrap(~reorder(nombre,-latitud))

act_temps <- temps3 %>% filter(nombre %in% stations$nombre) %>%
  filter(year %in% 2010:2017) %>%
  select(nombre,year,month,temp)

temp_diff <- act_temps %>% 
  left_join(avg_temps, by=c("nombre"="nombre","month"="month")) %>%
  left_join(stations,by=c("nombre"="nombre")) %>%
  mutate(temp_diff=temp-avg_temp)# %>%
  #filter(year=="2017")

temp_diff %>% ggplot(aes(x=month,group=1))+geom_line(aes(y=avg_temp),size=1)+
  geom_point(aes(y=temp),col="red",size=1)+facet_wrap(~reorder(nombre,-latitud))

#For ggplotly: size=2, uncomment the facet_wrap
#For gganimate: size=4, comment the facet_wrap
g <- ggplot() + geom_polygon(data = chile, aes(x=long, y = lat, group = group)) +
  geom_point(data=temp_diff,aes(x=longitud,y=latitud,col=temp_diff,text=paste0(nombre,"\n",round(temp_diff,2),"°C")),size=2) + 
  scale_color_gradient2(low="blue",high="red",mid="white",midpoint=0,limits=c(-3,3),
                        na.value="red")+
  coord_fixed(0.5) +facet_wrap(~month)

library(plotly)

ggplotly(g,tooltip="text")

library(gganimate)

g + transition_states(month,state_length=2) +
  ggtitle('Now showing {closest_state}-2017')

###
#Temperatures
nombres <- temps3 %>% group_by(nombre) %>% 
  summarise(count=n(),length()) %>% 
  filter(count>300) %>% .$nombre

temps3 %>% group_by(nombre) %>%
  summarise(count=n(),
            first_meas=min(date),
            last_meas=max(date),
            total_time=last_meas-first_meas) %>%
  arrange(desc(count))

temps3 %>% filter(nombre %in% nombres) %>%
  ggplot(aes(x=date,y=as.numeric(temp)))+geom_line()+geom_smooth(method='lm',col="red",size=2)+
  facet_wrap(~nombre,scales="free")


#Check one station

#Option 1
g <- temp_diff %>% filter(nombre=="Santo Domingo Ad.") %>%
  ggplot(aes(x=year,y=temp,fill=temp_diff))+
  geom_bar(aes(text=paste0("Temp.diff: ",round(temp_diff,2),"°C")),stat="identity")+
  geom_hline(aes(yintercept = avg_temp),col="yellow")+
  scale_fill_gradient2(low="blue",high="red",mid="white",midpoint=0,limits=c(-2,2),
                        na.value="red")+
  facet_wrap(~month)

ggplotly(g,tooltip="text")


g <- temp_diff %>% filter(nombre=="Santo Domingo Ad.") %>%
  mutate(date=as.Date(paste0(year,"-",month,"-01"))) %>%
  ggplot(aes(x=date))+
  geom_line(aes(y=temp),col="orange",size=2)+
  geom_line(aes(y=avg_temp))
  


##Temps vs fires

g <- temps3 %>% filter(nombre %in% "Santo Domingo Ad.",year %in% 1986:2017) %>% 
  group_by(year=as.numeric(year)) %>% summarise(avg_temp=mean(temp),
                                                max_temp=max(temp),
                                                temp_dic=max(temp[month%in%c("12","01","02")],na.rm=T)) %>% 
  left_join(df_fires %>% filter(region=="V",year%in% 1986:2017) %>%
              group_by(year) %>% 
              summarise(fires=sum(forest_fire_cnt)),by=c("year"="year")) %>%
  ggplot(aes(x=temp_dic,y=fires,text=year))+geom_point()+geom_smooth(method="lm")


ggplotly(g,tooltip="text")
