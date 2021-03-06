#source: http://www.conaf.cl/incendios-forestales/incendios-forestales-en-chile/estadisticas-historicas/

library(dplyr)
library(tidyr)
library(ggplot2)
library(forcats)

#######
#Load Data and clean
#######

library(readxl)

change_colnames <- function(df) {
  colnames(df) <- c("month",colnames(df)[2:length(colnames(df))])
  return(df)
}

df <- read_xlsx("C:/Richard/R and Python/Datasets/Conaf_Waldbraende.xlsx",
                   sheet=6,range="A10:M21")
df <- change_colnames(df)
df$year <- 2016

for(i in 5:35) {
  if(i %in% 5:7) {
    fuego <- read_xlsx("C:/Richard/R and Python/Datasets/Conaf_Waldbraende.xlsx",
                       sheet=i+2,range="A10:M22")
  }
  else {
    fuego <- read_xlsx("C:/Richard/R and Python/Datasets/Conaf_Waldbraende.xlsx",
                       sheet=i+2,range="A9:M21")
  }
  
  fuego <- change_colnames(fuego)
  fuego$year <- 2020-i
  df <- rbind(df,fuego)
}


df_2019 <- read_xlsx("C:/Richard/R and Python/Datasets/Conaf_Waldbraende.xlsx",
                          sheet=3,range="A10:Q22")
df_2019 <- change_colnames(df_2019)
df_2019$year <- 2019


df_new <- read_xlsx("C:/Richard/R and Python/Datasets/Conaf_Waldbraende.xlsx",
                     sheet=4,range="A10:P22")
df_new <- change_colnames(df_new)
df_new$year <- 2018

for(i in 5:6) {
  fuego <- read_xlsx("C:/Richard/R and Python/Datasets/Conaf_Waldbraende.xlsx",
                       sheet=5,range="A10:P22")
  fuego <- change_colnames(fuego)
  fuego$year <- 2022-i
  
  df_new <- rbind(df_new,fuego)
}

df_fires <- pivot_longer(df_2019,cols=2:(length(df_2019)-1),names_to="region",values_to="forest_fire_cnt")
df_fires <- rbind(df_fires,pivot_longer(df_new,cols=2:(length(df_new)-1),names_to="region",values_to="forest_fire_cnt"))
df_fires <- rbind(df_fires,pivot_longer(df,cols=2:(length(df)-1),names_to="region",values_to="forest_fire_cnt"))


#Replace missing values by 0


df_fires <- df_fires %>% mutate(forest_fire_cnt=ifelse(is.na(forest_fire_cnt),0,forest_fire_cnt))


#Adjust the years (period is going from July to June)

df_fires <- df_fires %>% mutate(month_num = case_when(
  month=="ENERO" ~ 1,
  month=="FEBRERO" ~ 2,
  month=="MARZO" ~ 3,
  month=="ABRIL" ~ 4,
  month=="MAYO" ~ 5,
  month=="JUNIO" ~ 6,
  month=="JULIO" ~ 7,
  month=="AGOSTO" ~ 8,
  month=="SEPTIEMBRE" ~ 9,
  month=="OCTUBRE" ~ 10,
  month=="NOVIEMBRE" ~ 11,
  month=="DICIEMBRE" ~ 12
)) %>% mutate(year=ifelse(month_num>=7,year-1,year))


df_fires %>% group_by(year,month,month_num) %>% 
  summarise(fires=sum(forest_fire_cnt)) %>%
  ggplot(aes(x=year,y=fires))+geom_line()+facet_wrap(~reorder(month,month_num))

df_fires %>% 
  mutate(region=fct_relevel(region,c("XV","I","II","III","IV","V","RM","VI","VII","XVI",
                                     "VIII","IX","X","XI","XII"))) %>% 
  filter(!region%in%c("XV","I","II","XVI")) %>% 
  group_by(year,region) %>% 
  summarise(fires=sum(forest_fire_cnt)) %>%
  ggplot(aes(x=year,y=fires))+geom_line()+facet_wrap(~region)
