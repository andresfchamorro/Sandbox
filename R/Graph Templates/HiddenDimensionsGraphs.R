library(tidyr)
library(ggplot2)
library(dplyr)
library(RColorBrewer)
library(wbstats)
library(grid)
library(gridExtra)
library(extrafont)
library(scales)
library(stringr)

setwd("C:/Users/WB514197/WBG/Jia Jun Lee - HD_Report_Master/working_ACH")

hd <- read.csv("hd_may18.csv") %>% filter(!region_name=="Unknown")


ggplot(data=hd, aes(y=POVcc_G1_rate190,x=FOR_G1_cover_pct)) + geom_point() +
geom_rect(aes(xmin=quantile(FOR_G1_cover_pct,0.67), xmax=100, ymin=quantile(POVcc_G1_rate190,0.67), ymax=100),fill=greens[3],alpha=2/3) +
theme_minimal() + theme(legend.position="none") +
ylab("Poverty Rate, $1.90") + xlab("Forest Cover (%)") +
geom_smooth(aes(group=1),method="loess",se=FALSE,linetype=2,size=1,colour="black")

ggplot(data=hd, aes(y=POVcc_G1_rate190,x=FOR_G1_cover_pct)) + geom_point() +
geom_rect(aes(xmin=quantile(FOR_G1_cover_pct,0.67,na.rm=TRUE), xmax=100, ymin=quantile(POVcc_G1_rate190,0.67,na.rm=TRUE), ymax=100),fill=greens[3],alpha=2/3) +
theme_minimal() + theme(legend.position="none") +
ylab("Poverty Rate, $1.90") + xlab("Forest Cover (%)") + scale_y_continuous(trans = "log") + scale_x_continuous(trans = "log") +
geom_smooth(aes(group=1),method="loess",se=FALSE,linetype=2,size=1,colour="black")

ggplot(data=hd, aes(y=POVcc_G1_rate190,x=FOR_G1_cover_pct)) + geom_point(alpha=2/3,aes(size=FOR_G1_loss_area)) + 
theme_minimal() + labs(size="Area of forest loss (hectares)") +
ylab("Poverty Rate, $1.90") + xlab("Forest Cover (%)") +
geom_smooth(aes(group=1),method="loess",se=FALSE,linetype=2,size=1,colour="black") + facet_wrap(~region_name)


#####-------------------------------------------	Figure 1.2

edu <- read.csv("edu_unesco.csv")
school <- read.csv("years_of_school.csv")
mort <- read.csv("life_exp_mort.csv")
edu %>% reshape(varying= names(filt[c(-1,-2,-198)]),sep="_",direction="long",times="year")

new_cache <- wbcache()
wbsearch("Infant Mortality Rate")
wbsearch("Life Expectancy")
wbsearch("Educational Attainment")
wbsearch("Years of schooling")

[1] "Mortality rate, infant (per 1,000 live births)"               
[2] "Life expectancy at birth, total (years)"                      
[3] "UIS: Mean years of schooling of the population age 25+. Total"


# With aggregates
res <- wb(country="aggregates",indicator=c("SP.DYN.IMRT.IN", "SP.DYN.LE00.IN","UIS.EA.MEAN.1T6.AG25T99"))
countries_agg <- unique(res$country)
sel <- countries_agg[c(12,22,23,45)]
res <- res %>% filter(country %in% sel)
res_sp <- res %>% select(-indicator) %>% spread(indicatorID,value) %>% 
dplyr::rename(mortality=SP.DYN.IMRT.IN, life_exp=SP.DYN.LE00.IN)
mort <- ggplot(data=res_sp, aes(x=as.integer(date),y=mortality, colour=country)) + geom_line()

# Try with countries
all <- new_cache$countries %>% filter(!income=="Aggregates")
inc_codes <- all %>% select(iso3c, income)

res <- wb(country="countries_only",indicator=c("SP.DYN.IMRT.IN", "SP.DYN.LE00.IN","UIS.EA.MEAN.1T6.AG25T99"))
res_j <- left_join(res, inc_codes, by="iso3c")
res_sp <- res_j %>% select(-indicator) %>% spread(indicatorID,value) %>% 
dplyr::rename(mortality=SP.DYN.IMRT.IN, life_exp=SP.DYN.LE00.IN, education=UIS.EA.MEAN.1T6.AG25T99)

res_sp$income <- factor(res_sp$income, levels=c("High income", "Upper middle income", "Lower middle income", "Low income"), labels=c("High income", "Upper middle income", "Lower middle income", "Low income"))


ggplot(data=res_sp, aes(x=as.integer(date),y=mortality,colour=income,group=country)) + geom_line()
ggplot(data=res_sp, aes(x=as.integer(date),y=life_exp,colour=income,group=country)) + geom_line()
ggplot(data=res_sp, aes(x=as.integer(date),y=education,colour=income,group=country)) + geom_line()

theme_set(theme_minimal())
font_import()
loadfonts(device = "win")

custom <- theme(axis.title.x = element_blank(), legend.title = element_blank(), text=element_text(
size=14, family="Franklin Gothic Book"))
qual <- scale_colour_brewer(type="qual",palette="RdYlGn",direction=-1)

mort <- ggplot(data=res_sp, aes(x=as.integer(date),y=mortality,colour=income)) + 
geom_smooth(method="loess",se=FALSE,linetype=1,size=1) +
custom + qual +
labs(
  title = "Infant Mortality Rate Over Time",
  y = "Inf. mortality rate (per 1,000 births)"
)

life <- ggplot(data=res_sp, aes(x=as.integer(date),y=life_exp,colour=income)) + 
geom_smooth(method="loess",se=FALSE,linetype=1,size=1) +
custom + theme(legend.position="none") + qual +
labs(
  title = "Life Expectancy Over Time",
  y = "Life expectancy at birth (years)"
)

edu <- ggplot(data=res_sp, aes(x=as.integer(date),y=education)) + 
geom_smooth(method="loess",linetype=1,size=1,color="black") +
custom +
labs(
  title = "Educational Attainment Over Time",
  y = "Years of schooling (pop. age 25+)"
)

grid.newpage()
grid.arrange(life, mort, edu, ncol=2)

jpeg("Fig1.2.jpeg", units="in",width=10,height=8,res=200,quality=100)
grid.arrange(life, mort, edu, ncol=2)
dev.off()

# try stat bin
stat_sum_df <- function(fun, geom="crossbar", ...) {
  stat_summary(fun.data = fun, colour = "red", geom = geom, width = 0.2, ...)
}

ggplot(data=res_sp, aes(x=as.integer(date),y=education)) + geom_point()

ggplot(data=res_sp, aes(x=as.integer(date),y=education)) + geom_point() +
geom_boxplot(aes(group = cut_width(date, 50)))

ggplot(data=res_sp, aes(x=as.integer(date),y=education)) + geom_point() +
geom_boxplot(aes(group = cut_interval(as.integer(date), 2)))


#####------------------------------------------- 	Figure 2.1


fig <- read.csv("figure2.csv") %>% rename(share=Shareofpoorinruralareas)

qual <- scale_fill_brewer(type="qual",palette=8)

custom <- theme(axis.title.y = element_blank(), legend.title = element_blank(), text=element_text(
size=14, family="Franklin Gothic Book"))

rural <- ggplot(data=fig, aes(x=Region,y=share,fill=Region)) + geom_bar(stat = "identity", width=0.6,color="gray") + 
custom + theme(legend.position="none") +
scale_y_continuous(limits=c(40,90),oob = rescale_none) +
labs(
  y = "% of poor population"
) + 
coord_flip() + qual 
#+ geom_text(aes(label=share))
rural

jpeg("Fig2.1.jpeg", units="in",width=6,height=4,res=200,quality=100)
grid.draw(rural)
dev.off()


#####-------------------------------------------	Figure 2.2


names(hd)
filt <- hd %>% dplyr::select(POVcc_G1_rate190,POVcc_G1_hc190_GPW,share_urban_g1_2010,region_name,region) %>%
filter(!is.na(POVcc_G1_rate190)) %>%
mutate(share_urban_nonzero=share_urban_g1_2010)

filt$share_urban_nonzero[filt$share_urban_nonzero==0] <- NA
non_zero <- filt %>% filter(!share_urban_g1_2010==0)

p = (1:4 - 1)/(4 - 1)

#non zero
filt_q <- filt %>% mutate(urban_quint=cut(share_urban_g1_2010, breaks=quantile(non_zero$share_urban_g1_2010, probs=p, na.rm=TRUE),include.lowest=TRUE),
urban_q=cut(share_urban_g1_2010, breaks=quantile(non_zero$share_urban_g1_2010, probs=p, na.rm=TRUE),labels=FALSE,include.lowest=TRUE))

filt_q$urban_q[is.na(filt_q$urban_q)] <- 0

quantile(filt$share_urban_g1_2010, probs=p, na.rm=TRUE)
quantile(filt[filt_q$share_urban_g1_2010!=0,]$share_urban_g1_2010, probs=p, na.rm=TRUE)
quantile(non_zero$share_urban_g1_2010, probs=p, na.rm=TRUE)
quantile(filt$share_urban_nonzero, probs=p, na.rm=TRUE)

# do it again but urban q is regional
filt_q <- filt %>% group_by(region_name) %>% 
mutate(urban_q=.bincode(share_urban_g1_2010, breaks=quantile(share_urban_nonzero, probs=p, na.rm=TRUE),include.lowest=TRUE))
filt_q$urban_q[is.na(filt_q$urban_q)] <- 0
filt_q$urban_q <- factor(filt_q$urban_q, levels=c(0,1,2,3), labels=c("Rural","Low Urban","Medium Urban","Urban"))

a <- filt_q %>% count(urban_q,region_name)
View(a)
ggplot(data=filt, aes(x=share_urban_g1_2010)) + geom_histogram() 

pov_urb_reg <- filt_q %>% group_by(region_name, urban_q) %>% summarise(pov_rate=mean(POVcc_G1_rate190),pov_headcount=mean(POVcc_G1_hc190_GPW))
pov_urb_reg_med <- filt_q %>% group_by(region_name, urban_q) %>% summarise(pov_rate=median(POVcc_G1_rate190),pov_headcount=median(POVcc_G1_hc190_GPW))

custom <- theme(axis.title.x = element_blank(), legend.title = element_blank(), text=element_text(
size=14, family="Franklin Gothic Book"))

povr_urb <- ggplot(data=pov_urb_reg, aes(x=urban_q, y=pov_rate, fill=as.factor(urban_q))) + 
geom_bar(stat = "identity",width=0.7,color="gray") + 
facet_wrap(~region_name) +
custom + theme(legend.position="none") + 
scale_fill_brewer(type="seq",palette="YlGnBu",direction=-1) +
scale_x_discrete(labels = function(x) str_wrap(x, width = 7)) +
scale_y_continuous(labels = scales::percent) +
labs(
	y = "Poverty Rate, $1.90"
	)
povr_urb

povh_urb_mean <- ggplot(data=pov_urb_reg, aes(x=urban_q, y=pov_headcount, fill=as.factor(urban_q))) + 
geom_bar(stat = "identity",width=0.7,color="gray") + 
facet_wrap(~region_name) +
custom + theme(legend.position="none") + 
scale_fill_brewer(type="seq",palette="YlGnBu",direction=-1) +
scale_x_discrete(labels = function(x) str_wrap(x, width = 7)) +
scale_y_continuous(labels = scales::comma) +
labs(
	y = "Poverty Headcount, $1.90"
	)

povh_urb_med <- ggplot(data=pov_urb_reg_med, aes(x=urban_q, y=pov_headcount, fill=as.factor(urban_q))) + 
geom_bar(stat = "identity",width=0.7,color="gray") + 
facet_wrap(~region_name) +
custom + theme(legend.position="none") + 
scale_fill_brewer(type="seq",palette="YlGnBu",direction=-1) +
scale_x_discrete(labels = function(x) str_wrap(x, width = 7)) +
scale_y_continuous(labels = scales::comma) +
labs(
	y = "Poverty Headcount, $1.90"
	)

grid.arrange(povh_urb_mean,povh_urb_med,ncol=2)

jpeg("Fig2.2.jpeg", units="in",width=7,height=4,res=200,quality=100)
grid.draw(povr_urb)
dev.off()

jpeg("Fig2.2_headcount.jpeg", units="in",width=7,height=4,res=200,quality=100)
grid.draw(povh_urb_med)
dev.off()


#####-------------------------------------------	Figure 2.3


filt2 <- hd %>% dplyr::select(POVcc_G1_rate190,POVcc_G1_hc190_GPW,AP_PM2BRA_G1_mean,AP_PM2BRA_G1_90p,region_name,region,dummyUrban_G1,GPW_G1_2015) %>%
filter(!is.na(POVcc_G1_rate190),dummyUrban_G1==1)

tot_pop <- sum(filt2$GPW_G1_2015)
tot_poor <- sum(filt2$POVcc_G1_hc190_GPW)
tot_nonpoor <- tot_pop-tot_poor

filt2_breaks <- filt2 %>% mutate(pollution_group=cut(AP_PM2BRA_G1_mean, breaks=c(0,10,15,25,35,1000),
	labels=c("Lower than 10", "10 - 15", "15 - 25", "25 - 35", "Higher than 35"), include.lowest=TRUE))


poor_pollution <- filt2_breaks %>% group_by(pollution_group) %>% summarise(sum_poor=sum(POVcc_G1_hc190_GPW),sum_nonpoor=sum(GPW_G1_2015)-sum(POVcc_G1_hc190_GPW)) %>%
mutate(share_poor=sum_poor/tot_poor,share_nonpoor=sum_nonpoor/tot_nonpoor)

poor_pollution
sel <- poor_pollution %>% select(1,4,5) %>% gather(poor_group,share,-pollution_group)

custom <- theme(axis.title.y = element_blank(), text=element_text(
size=14, family="Franklin Gothic Book"))

pov_pol <- ggplot(data=sel, aes(x=poor_group,y=share,fill=pollution_group)) + 
geom_bar(stat="identity",width=0.5,color="gray",position = position_stack(reverse = TRUE)) + 
scale_fill_brewer("Mean PM 2.5 (ug/m3)",palette="RdYlGn",direction=-1) +
scale_y_continuous(labels = scales::percent) +
scale_x_discrete(labels=c("Non-Poor","Poor")) +
labs(
	y = "Share of population living under WHO pollution guidelines"
	) + 
custom +
coord_flip()

jpeg("Fig2.3.jpeg", units="in",width=7,height=3.5,res=200,quality=100)
grid.draw(pov_pol)
dev.off()

#####-------------------------------------------	Figure 2.4


filt3 <- hd %>% dplyr::select(POVcc_G1_rate190,DHS_G1_hh_cooking_fuel,region_name) %>%
filter(!is.na(POVcc_G1_rate190),!is.na(DHS_G1_hh_cooking_fuel))

b = (1:6 - 1)/(6 - 1)

filt3_quint <- filt3 %>% group_by(region_name) %>% 
mutate(pov_q=.bincode(POVcc_G1_rate190, breaks=quantile(POVcc_G1_rate190, probs=b, na.rm=TRUE),include.lowest=TRUE))

filt3_quint$pov_q <- factor(filt3_quint$pov_q, levels=c(1,2,3,4,5), labels=c("Richest 20%","4th Quintile","3rd Quintile","2nd Quintile","Poorest 20%"))

fuel <- filt3_quint %>% group_by(region_name, pov_q) %>% summarise(cooking_mean=mean(DHS_G1_hh_cooking_fuel),cooking_median=median(DHS_G1_hh_cooking_fuel))

custom <- theme(axis.title.x = element_blank(), legend.title = element_blank(), text=element_text(
size=13, family="Franklin Gothic Book"))

povr_fuel <- ggplot(data=fuel, aes(x=pov_q, y=cooking_mean, fill=as.factor(pov_q))) + 
geom_bar(stat = "identity",width=0.7,color="gray") + 
facet_wrap(~region_name) +
custom + theme(legend.position="none",) + 
scale_fill_brewer(type="div",palette="RdBu",direction=-1) +
scale_x_discrete(labels = function(x) str_wrap(x, width = 7)) +
labs(
	y = "% of households using solid fuel for cooking"
	)
povr_fuel

jpeg("Fig2.4.jpeg", units="in",width=8.5,height=4,res=200,quality=100)
grid.draw(povr_fuel)
dev.off()

#####-------------------------------------------	Figure 2.5


filt4 <- hd %>% dplyr::select(POVcc_G1_rate190,FOR_G1_cover_pct,FOR_G1_loss_pct,region_name) %>%
filter(!is.na(POVcc_G1_rate190),!is.na(FOR_G1_loss_pct))

filt4_breaks <- filt4 %>% mutate(pov_q=cut(POVcc_G1_rate190, breaks=quantile(POVcc_G1_rate190, probs=b, na.rm=TRUE),
	labels=c("Richest 20%","4th Quintile","3rd Quintile","2nd Quintile","Poorest 20%"), include.lowest=TRUE))

forest <- filt4_breaks %>% group_by(pov_q) %>% summarise(cover=mean(FOR_G1_cover_pct),loss=mean(FOR_G1_loss_pct))

povr_loss <- ggplot(data=forest, aes(x=pov_q, y=loss, fill=as.factor(pov_q))) + 
geom_bar(stat = "identity",width=0.7,color="gray") + 
custom + theme(legend.position="none",) + 
scale_fill_brewer(type="div",palette="RdBu",direction=-1) +
scale_x_discrete(labels = function(x) str_wrap(x, width = 7)) +
labs(
	y = "Forest Cover Loss (2001-2012), %"
	)
povr_loss

#Now with p2
hd_p2 <- read.csv("hd_p2.csv") 
filt8 <- hd_p2 %>% filter(!is.na(WBG_P2_pov_hcr),!is.na(FOR_P2_loss_pct))

filt8_breaks <- filt8 %>% mutate(pov_q=cut(WBG_P2_pov_hcr, breaks=quantile(WBG_P2_pov_hcr, probs=b, na.rm=TRUE),
	labels=c("Richest 20%","4th Quintile","3rd Quintile","2nd Quintile","Poorest 20%"), include.lowest=TRUE))

forest_dis <- filt8_breaks %>% group_by(pov_q) %>% summarise(cover=mean(FOR_P2_cover_pct),loss=mean(FOR_P2_loss_pct))

povr_loss_dis <- ggplot(data=forest_dis, aes(x=pov_q, y=loss, fill=as.factor(pov_q))) + 
geom_bar(stat = "identity",width=0.7,color="gray") + 
custom + theme(legend.position="none",) + 
scale_fill_brewer(type="div",palette="RdBu",direction=-1) +
scale_x_discrete(labels = function(x) str_wrap(x, width = 7)) +
labs(
	y = "Forest Cover Loss (2001-2012), %"
	)
povr_loss_dis

jpeg("Fig2.5.jpeg", units="in",width=7.5,height=3,res=200,quality=100)
grid.arrange(povr_loss,povr_loss_dis,ncol=2)
dev.off()



#####-------------------------------------------	Figure 2.6

filt5 <- hd %>% dplyr::select(POVcc_G1_rate190,NPP_G1_trend_1) %>%
filter(!is.na(POVcc_G1_rate190),!is.na(NPP_G1_trend_1))

npp_pov <- ggplot(data=filt5, aes(x=POVcc_G1_rate190,y=NPP_G1_trend_1)) +
stat_summary_bin(fun.y='median', bins=10, color="black", size=2, geom='point')
npp_pov


#####-------------------------------------------	Figure 2.7


filt6 <- hd %>% dplyr::select(POVcc_G1_rate190,SOILmean_G1,region_name) %>%
filter(!is.na(POVcc_G1_rate190),!is.na(SOILmean_G1))

b = (1:6 - 1)/(6 - 1)

filt6_quint <- filt6 %>% group_by(region_name) %>% 
mutate(pov_q=.bincode(POVcc_G1_rate190, breaks=quantile(POVcc_G1_rate190, probs=b, na.rm=TRUE),include.lowest=TRUE))

filt6_quint$pov_q <- factor(filt6_quint$pov_q, levels=c(1,2,3,4,5), labels=c("Richest 20%","4th Quintile","3rd Quintile","2nd Quintile","Poorest 20%"))

soil <- filt6_quint %>% group_by(region_name, pov_q) %>% summarise(erosion_rate=mean(SOILmean_G1))

custom <- theme(axis.title.x = element_blank(), legend.title = element_blank(), text=element_text(
size=14, family="Calibri"))

povr_soil <- ggplot(data=soil, aes(x=pov_q, y=erosion_rate, fill=as.factor(pov_q))) + 
geom_bar(stat = "identity",width=0.7,color="gray") + 
facet_wrap(~region_name) +
custom + theme(legend.position="none",) + 
scale_fill_brewer(type="div",palette="RdBu",direction=-1) +
scale_x_discrete(labels = function(x) str_wrap(x, width = 7)) +
labs(
	y = "Soil Erosion Rate"
	)
povr_soil

#only the two richest and poorest
soil2 <- soil %>% filter(pov_q!="4th Quintile",pov_q!="3rd Quintile",pov_q!="2nd Quintile")
cols<-brewer.pal(n=5,name="RdBu")
two <- cols[c(5,1)]

povr_soil <- ggplot(data=soil2, aes(x=pov_q, y=erosion_rate, fill=as.factor(pov_q))) + 
geom_bar(stat = "identity",width=0.7,color="gray") + 
facet_wrap(~region_name) +
custom + theme(legend.position="none",) + 
scale_fill_manual(values=two) +
scale_x_discrete(labels = function(x) str_wrap(x, width = 7)) +
labs(
	y = "Soil erosion rate (ton/hectare/year)"
	)
povr_soil

jpeg("Fig2.7v2.jpeg", units="in",width=6,height=3.5,res=200,quality=100)
grid.draw(povr_soil)
dev.off()

#####-------------------------------------------	Figure 2.8

filt7 <- hd %>% dplyr::select(POVcc_G1_rate190,COAST_cc_ACID_G1_mean,dummyUrban_G1) %>%
filter(!is.na(POVcc_G1_rate190),!is.na(COAST_cc_ACID_G1_mean))

ocean <- filt7 %>% group_by(dummyUrban_G1) %>% summarise(acid=mean(COAST_cc_ACID_G1_mean),pov_rate=mean(POVcc_G1_rate190))
ocean$dummyUrban_G1 <- factor(ocean$dummyUrban_G1, levels=c(0,1),labels=c("Rural","Urban"))

custom <- theme(axis.title.x = element_blank(), legend.title = element_blank(), text=element_text(
size=13, family="Calibri"))

acidification <- ggplot(data=ocean, aes(x=dummyUrban_G1, y=acid, fill=as.factor(dummyUrban_G1))) + 
geom_bar(stat = "identity",width=0.7,color="gray") + 
custom + theme(legend.position="none",) + 
scale_fill_brewer(type="seq",palette="YlGnBu",direction=-1) +
scale_y_continuous(labels = scales::percent) +
labs(
	y = "Ocean Acidification (change in ASS)"
	)
acidification

poverty <- ggplot(data=ocean, aes(x=dummyUrban_G1, y=pov_rate, fill=as.factor(dummyUrban_G1))) + 
geom_bar(stat = "identity",width=0.7,color="gray") + 
custom + theme(legend.position="none",) + 
scale_fill_brewer(type="seq",palette="YlGnBu",direction=-1) +
scale_y_continuous(labels = scales::percent) +
labs(
	y = "Poverty Rate, $1.90"
	)
poverty

jpeg("Fig2.8v2.jpeg", units="in",width=6,height=3,res=200,quality=100)
grid.arrange(poverty, acidification, ncol=2)
dev.off()





#####-------------------------------------------	Figure 2.9


filt7_breaks <- filt7 %>% mutate(pov_q=cut(POVcc_G1_rate190, breaks=quantile(POVcc_G1_rate190, probs=b, na.rm=TRUE),
	labels=c("Richest 20%","4th Quintile","3rd Quintile","2nd Quintile","Poorest 20%"), include.lowest=TRUE))

ocean_byquint <- filt7_breaks %>% group_by(pov_q) %>% summarise(acid=mean(COAST_cc_ACID_G1_mean))

povr_ocean <- ggplot(data=ocean_byquint, aes(x=pov_q, y=acid, fill=as.factor(pov_q))) + 
geom_bar(stat = "identity",width=0.7,color="gray") + 
custom + theme(legend.position="none",) + 
scale_fill_brewer(type="div",palette="RdBu",direction=-1) +
scale_x_discrete(labels = function(x) str_wrap(x, width = 7)) +
scale_y_continuous(labels = scales::percent) +
labs(
	y = "Ocean Acidification (change in ASS)"
	)
povr_ocean


jpeg("Fig2.9.jpeg", units="in",width=4,height=3,res=200,quality=100)
grid.draw(povr_ocean)
dev.off()