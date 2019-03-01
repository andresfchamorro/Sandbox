library(dplyr)
library(tidyr)
library(ggplot2)
library(reshape2)
library(stats)
library(zoo)
library(scales)
library(RColorBrewer)
library(grid)
library(gridExtra)
library(scales)

data <- read.csv("ss_pop_crisis_ts.csv")

data_re <- merged.stack(data=data, var.stubs=c("maArtemisCrisis_pct", "population_analyzed", "maArtemisCrisis_pop"), sep=".") %>% 
mutate(ymt=as.Date(as.yearmon(.time_1,format="%Y_%m")))

data_re_sum <- data_re %>% group_by(adm2_code) %>% summarise(sum_CrisisPop=sum(maArtemisCrisis_pop))
data_re2 <- left_join(data_re,data_re_sum,"adm2_code")

graph <- ggplot(data=data_re2, aes(x=ymt)) + 
geom_line(aes(y=maArtemisCrisis_pop, group=adm2_name, colour=log(sum_CrisisPop)),size=0.5,alpha=0.75) +
scale_y_continuous(name="Number of people", labels=scales::comma) +
labs(title= "Food-insecure population over time - South Sudan") +
theme_minimal() + theme(axis.title.x = element_blank(), text=element_text(size=14), legend.position="none") +
scale_colour_distiller(type="seq",palette="YlOrRd",direction=1) +
scale_x_date(labels=date_format("%m-%Y"), breaks = pretty(data_re2$ymt, n=10))
graph