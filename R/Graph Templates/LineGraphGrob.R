library(splitstackshape)
library(dplyr)
library(tidyr)
library(ggplot2)
library(reshape2)
library(stats)
library(zoo)
library(grid)
library(scales)

ts_long <- ts_long %>% 
mutate(
	ymt=as.Date(as.yearmon(Year_Month,format="%Y_%m")),
	IPC_SUM = IPC1_pct+IPC2_pct+IPC3_pct+IPC4_pct+IPC5_pct,
	IPC1_pct_re=IPC1_pct*(1/IPC_SUM),
	IPC2_pct_re=IPC2_pct*(1/IPC_SUM),
	IPC3_pct_re=IPC3_pct*(1/IPC_SUM),
	IPC4_pct_re=IPC4_pct*(1/IPC_SUM),
	IPC5_pct_re=IPC5_pct*(1/IPC_SUM),
	IPC_SUM_re=IPC1_pct_re+IPC2_pct_re+IPC3_pct_re+IPC4_pct_re+IPC5_pct_re
	)

som <- ts_long %>% filter(Country=="Somalia", !is.na(year)) %>%
filter(year>2008) %>%
left_join(prices_som, c("Country","admin_code","Year_Month")) %>%
left_join(context[c("admin_code","admin_name")],"admin_code")

# som <- ts_long %>% filter(Country=="Somalia", !is.na(year)) %>%
# left_join(context[c("admin_code","admin_name")],"admin_code")

som_sum <- som %>% mutate(IPC_PctCrisis=IPC3_pct+IPC4_pct+IPC5_pct) %>% 
group_by(admin_code) %>% summarise(sumPctCrisis=median(IPC_PctCrisis,na.rm=TRUE))
som_sum <- som_sum[order(-som_sum$sumPctCrisis),]
crisis_list <- as.list(som_sum[1:20,1])[[1]]
som_sel <- som %>% filter(admin_code %in% crisis_list[2])

som_sel_gather <- gather(som_sel, key='IPC', value="PERCENT", ends_with("_pct_re"), convert=FALSE)
som_sel_gather$IPC_FACT <- factor(som_sel_gather$IPC, levels=c("IPC5_pct_re","IPC4_pct_re","IPC3_pct_re","IPC2_pct_re","IPC1_pct_re"), labels=c("5: Famine","4: Emergency","3: Crisis","2: Stresed","1: Minimal"))
pal <- c("#640000","#C80000","#E67800","#FAE61E","#DCF0DC")



som_sel_gather$NdviAllAnom_scaled <- scale(som_sel_gather$NdviAllAnom)
som_sel_gather$RainAllAnom_scaled <- scale(som_sel_gather$RainAllAnom)
som_sel_gather$ESI_mean_anom_scaled <- scale(som_sel_gather$ESI_mean_anom)
som_sel_gather$SoilMois_dif_scaled <- scale(som_sel_gather$SoilMois_dif)
som_sel_gather$precip_anom_scaled <- scale(som_sel_gather$precip_anom)
som_sel_gather$tavg_anom_scaled <- scale(som_sel_gather$tavg_anom)

ipc_plot <- ggplot(data=som_sel_gather, aes(x=ymt)) + 
geom_area(aes(y=PERCENT,fill=IPC_FACT),alpha=0.7,size=1,position = "stack") +
geom_point(aes(y=PERCENT), shape = 21, position="stack", colour="black", alpha=0.5, fill="white", size=2, stroke=1) +
theme_minimal() + 
theme(plot.title = element_text(hjust = 0.25),axis.title.x = element_blank()) +
scale_x_date(labels=date_format("%Y"), date_breaks="1 year", limits=as.Date(c('2010-01-01','2018-06-01'))) +
scale_fill_manual(values=pal, name="IPC Distribution") +
scale_y_continuous(labels = scales::percent) +
labs(y="% of pop.",title=paste("Data Profile for",som_sel_gather$admin_name,som_sel_gather$Country)) +
theme(axis.title.y = element_text(margin = margin(t = 0, r = 20, b = 0, l = 0)))

ndvi_plot <- ggplot(data=som_sel_gather, aes(x=ymt)) + 
geom_line(aes(y=NdviAllAnom, colour = "NDVI"),size=1) +
#geom_line(aes(y=RainAllAnom, colour = "Rainfall, CHIRPS"),size=1) +
geom_line(aes(y=100),size=.5) +
theme_minimal() +
theme(plot.title = element_text(hjust = 0.25),axis.title.x = element_blank()) +
scale_x_date(labels=date_format("%Y"), date_breaks="1 year", limits=as.Date(c('2010-01-01','2018-06-01'))) +
scale_colour_manual(values=c("dark green"),name="Modis (NASA)") +
labs(y="Anomalies") +
theme(axis.title.y = element_text(margin = margin(t = 0, r = 20, b = 0, l = 0)))


rain_plot <- ggplot(data=som_sel_gather, aes(x=ymt)) + 
geom_line(aes(y=RainAllAnom, colour = "Rainfall"),size=1) +
#geom_line(aes(y=RainAllAnom, colour = "Rainfall, CHIRPS"),size=1) +
geom_line(aes(y=0),size=.5) +
theme_minimal() +
theme(plot.title = element_text(hjust = 0.25),axis.title.x = element_blank()) +
scale_x_date(labels=date_format("%Y"), date_breaks="1 year", limits=as.Date(c('2010-01-01','2018-06-01'))) +
scale_colour_manual(values=c("navy"),name="CHIRPS") +
labs(y="Anomalies") +
theme(axis.title.y = element_text(margin = margin(t = 0, r = 20, b = 0, l = 0)))


esi_plot <- ggplot(data=som_sel_gather, aes(x=ymt)) + 
geom_line(aes(y=ESI_mean_anom, colour = "Evaporative Stress Index"),size=1) +
#geom_line(aes(y=RainAllAnom, colour = "Rainfall, CHIRPS"),size=1) +
geom_line(aes(y=0),size=.5) +
theme_minimal() +
theme(plot.title = element_text(hjust = 0.25),axis.title.x = element_blank()) +
scale_x_date(labels=date_format("%Y"), date_breaks="1 year", limits=as.Date(c('2010-01-01','2018-06-01'))) +
scale_colour_manual(values=c("green"),name="USDA and NASA") +
labs(y="Anomalies")

precip_plot <- ggplot(data=som_sel_gather, aes(x=ymt)) + 
geom_line(aes(y=precip_anom, colour = "Rainfall"),size=1) +
#geom_line(aes(y=RainAllAnom, colour = "Rainfall, CHIRPS"),size=1) +
geom_line(aes(y=0),size=.5) +
theme_minimal() +
theme(plot.title = element_text(hjust = 0.25),axis.title.x = element_blank()) +
scale_x_date(labels=date_format("%Y"), date_breaks="1 year", limits=as.Date(c('2010-01-01','2018-06-01'))) +
scale_colour_manual(values=c("blue"),name="Descartes Lab") +
labs(y="Anomalies")

tavg_plot <- ggplot(data=som_sel_gather, aes(x=ymt)) + 
geom_line(aes(y=tavg_anom, colour = "Temp. (Avg)"),size=1) +
#geom_line(aes(y=RainAllAnom, colour = "Rainfall, CHIRPS"),size=1) +
geom_line(aes(y=0),size=.5) +
theme_minimal() +
theme(plot.title = element_text(hjust = 0.25),axis.title.x = element_blank()) +
scale_x_date(labels=date_format("%Y"), date_breaks="1 year", limits=as.Date(c('2010-01-01','2018-06-01'))) +
scale_colour_manual(values=c("red", "blue"),name="Descartes Lab") +
labs(y="Anomalies")

mois_plot <- ggplot(data=som_sel_gather, aes(x=ymt)) + 
geom_line(aes(y=SoilMois_anom, colour = "Soil Moisture"),size=1) +
geom_line(aes(y=0),size=.5) +
theme_minimal() +
theme(plot.title = element_text(hjust = 0.25),axis.title.x = element_blank()) +
scale_x_date(labels=date_format("%Y"), date_breaks="1 year", limits=as.Date(c('2010-01-01','2018-06-01'))) +
scale_colour_manual(values=c("blue", "red"),name="VanderSat") +
labs(y="Anomalies")

prices_plot <- ggplot(data=som_sel_gather, aes(x=ymt)) + 
geom_line(aes(y=basket_food, colour = "Food Basket"),size=1) +
theme_minimal() +
theme(plot.title = element_text(hjust = 0.25),axis.title.x = element_blank()) +
scale_x_date(labels=date_format("%Y"), date_breaks="1 year", limits=as.Date(c('2010-01-01','2018-06-01'))) +
scale_colour_manual(values=c("red"),name="FSNAU") +
labs(y="Price")

acled_plot <- ggplot(data=som_sel_gather, aes(x=ymt,y=acled_count)) + 
geom_bar(stat="identity",size=1.5,aes(fill = "Count")) +
theme_minimal() + 
theme(plot.title = element_text(hjust = 0.25),axis.title.x = element_blank()) +
scale_x_date(labels=date_format("%Y"), date_breaks="1 year", limits=as.Date(c('2010-01-01','2018-06-01'))) +
scale_fill_manual(values=c("red"),name="ACLED") +
labs(y="Count of violent events")

grid.draw(rbind(
	ggplotGrob(ipc_plot),
	ggplotGrob(ndvi_plot),
	ggplotGrob(rain_plot),
	ggplotGrob(precip_plot),
	ggplotGrob(tavg_plot),
	ggplotGrob(mois_plot),
	size = "last"))

grid.draw(rbind(
	ggplotGrob(ipc_plot),
	ggplotGrob(ndvi_plot),
	ggplotGrob(rain_plot),
	ggplotGrob(prices_plot),
	ggplotGrob(acled_plot),
	size = "last"))


setwd("C:/Users/WB514197/OneDrive - WBG/FCV_Famine/Graphs")
jpeg("Cadale.jpeg", units="in",width=8,height=6,res=200,quality=100)
grid.newpage()
grid.draw(rbind(
	ggplotGrob(ipc_plot),
	ggplotGrob(ndvi_plot),
	ggplotGrob(rain_plot),
	size = "last"))
dev.off()