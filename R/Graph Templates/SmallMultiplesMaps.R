library(raster)
library(ggplot2)
library(dplyr)
library(rgdal)
library(rgeos)
library(maptools)
library(mapproj)
library(sp)
library(sf)

shape_path <- "C:/Users/WB514197/OneDrive - WBG/FCV_Famine/GIS"
artemis_sf <- read_sf(dsn = path.expand(shape_path), layer = "Artemis_countries") 

#		South Sudan
ss_ipc <- full %>% filter(Country=="South Sudan") %>%
mutate(ymt=as.Date(as.yearmon(Year_Month,format="%Y_%m")),ymt2=format(ymt, format="%Y, %m")) %>%
filter(!is.na(IPC_Phase)) %>%
select(Country,admin_code,ymt,ymt2,population_analyzed,starts_with("IPC"))

ss_sf <- artemis_sf %>% filter(adm0_name=="South Sudan")
ss <- left_join(ss_ipc,ss_sf,c("admin_code"="code"))
ss[ss$IPC_Phase==0,"IPC_Phase"] <- NA

plot_ss <- ggplot(ss_sf) + 
geom_sf(fill="light grey") + 
geom_sf(data=ss,aes(fill=as.factor(IPC_Phase))) + 
coord_sf(datum=NA) +
facet_wrap(~ymt2) + 
scale_fill_manual(values=pal) + 
theme_void() +
labs(title="IPC Time Series - South Sudan", fill="IPC Phase") +
theme(plot.title = element_text(hjust = 0.5))

setwd("C:/Users/WB514197/OneDrive - WBG/FCV_Famine/Graphs")
jpeg("South Sudan FEWS IPC Time Series.jpeg", units="in",width=10,height=10,res=200,quality=100)
grid.draw(plot_ss)
dev.off()