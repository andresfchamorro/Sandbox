library(dplyr)
library(ggplot2)
library(tidyr)
library(zoo)
library(splitstackshape)
library(gridExtra)


setwd("/Users/andreschamorro/Data/Famine/FEWS")
data <- read.csv("cs_timeseries.csv")
steps <- read.csv("cs_timeseries2.csv")


steps_re <- steps %>% gather(key="year_month",value="CS",names(steps)[4:35]) %>% filter(CS>0)
steps_ts <- steps_re %>% mutate(year_month=as.Date(as.yearmon(year_month,format="%b.%y")))


data_ts <- data %>% gather(key="year_month",value="CS",names(data)[4:35]) %>% filter(CS>0)
data_ts_labs <- data_ts %>% mutate(year_month=factor(year_month, labels=c("Jul-09","Oct-09","Jan-10","Apr-10","Jul-10","Oct-10","Jan-11","Apr-11","Jul-11","Oct-11","Jan-12","Apr-12","Jul-12","Oct-12","Jan-13","Apr-13","Jul-13","Oct-13","Jan-14","Apr-14","Jul-14","Oct-14","Jan-15","Apr-15","Jul-15","Oct-15","Feb-16","Jun-16","Oct-16","Feb-17","Jun-17","Oct-17")))

data_ts_sel <- data_ts_labs %>% filter(NAME_0=="Somalia" | NAME_0=="Ethiopia" | NAME_0=="Yemen" | NAME_0=="Nigeria" | NAME_0=="South Sudan" | NAME_0=="Kenya")

steps_ts_sel <- steps_ts %>% filter(NAME_0=="Somalia" | NAME_0=="Ethiopia" | NAME_0=="Yemen" | NAME_0=="Nigeria" | NAME_0=="South Sudan" | NAME_0=="Kenya")

pal <- c("#DCF0DC","#FAE61E","#E67800","#C80000","#640000")

#All data - using factors
ggplot(data= data_ts_labs, aes(x= year_month,y= CS, colour=as.factor(CS))) + 
geom_jitter(alpha=0.3,size=1.5,width=0.3,height=0.3) + 
scale_colour_manual(values=pal) + 
theme(panel.background = element_rect(fill = "white", colour = "grey50"), legend.position="none") + 
scale_x_discrete(labels=abbreviate)

#with dates instead of factor
ggplot(data= steps_ts, aes(x= year_month,y= CS, colour=as.factor(CS))) + 
geom_jitter(alpha=0.3,size=1.5,width=0.5,height=0.3) + 
scale_colour_manual(values=pal) + 
theme(panel.background = element_rect(fill = "white", colour = "grey50"), legend.position="none")


#by country all
all <- ggplot(data= steps_ts, aes(x= year_month,y= CS, colour=as.factor(CS))) + 
geom_jitter(alpha=0.5,size=0.5,width=0.25,height=0.25) + 
scale_colour_manual(values=pal) + 
theme(panel.background = element_rect(fill = "white", colour = "grey50"), legend.position="none", axis.title.x=element_blank()) + 
facet_wrap(~NAME_0) + 
labs(title="Frequency of IPC states at the district-level",y="IPC Phase",caption="Source: FEWSNET")

#selection - by country sel
sel_graph <- ggplot(data= steps_ts_sel, aes(x= year_month,y= CS, colour=as.factor(CS))) + 
geom_jitter(alpha=0.4,size=1,width=0.25,height=0.25) + scale_colour_manual(values=pal) + 
theme(panel.background = element_rect(fill = "white", colour = "grey50"), legend.position="none", axis.title.x=element_blank()) + 
facet_wrap(~NAME_0) + 
labs(title="Frequency of IPC states at the district-level",y="IPC Phase", caption="Source: FEWSNET")

jpeg("Frequency_selection.jpeg", units="in",width=10,height=7,res=200,quality=100)
sel_graph
dev.off()