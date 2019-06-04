library(dplyr)
library(foreign)
library(here)
library(phylin)
library(rgdal)
library(raster)
library(sf)
library(ggplot2)
library(gridExtra)
library(splitstackshape)


options(stringsAsFactors = FALSE)
setwd("~/Data/markets")

prices <- read.csv('WFP_prices_CPI_imputednorm.csv') %>%
  rename(mktx='lon',mkty='lat')

prices[prices$market=='Mwetshi',"mktx"] <- 22.63732

prices[prices$country=='Democratic Republic of the Congo','country'] <- 'Democratic Republic of Congo'

data <- read.dta('Artemis_21_May20.dta')
shape <- readOGR(dsn='.', layer = "Artemis_21")
shape.crs <- crs(shape)
shape.sf <- read_sf(dsn='.', layer = "Artemis_21")
shape.data <- shape@data %>%
  rename(country='adm0_name') %>%
  filter(country %in% countries)

# long = x, lat = y

# Join admin codes
prices.sp <- SpatialPointsDataFrame(prices[c('mktx','mkty')],
                                    prices,
                                    proj4string = shape.crs)
shape.over <- over(prices.sp, shape) %>%
  dplyr::select(admin_code, adm0_name, centx, centy)

prices.joined <- cbind(prices, shape.over)
View(prices.joined[c("country","adm0_name")])

prices.districts <- prices.joined %>%
  # dplyr::select(country, admin_code, timeid, centx, centy,
  #          index, index_SA, cpi_used) %>%
  group_by(country, admin_code, time_id) %>%
  summarise(
    year=first(year),
    month=first(month),
    centx=first(centx),
    centy=first(centy),
    index=mean(index, na.rm=TRUE),
    index_SA=mean(index, na.rm=TRUE),
    cpi_used=mean(cpi_used, na.rm=TRUE)
  ) %>%
  ungroup()

# prices.districts[prices.districts$country=='Democratic Republic of the Congo','country'] <- 'Democratic Republic of Congo'


#V2----

variables <- c('index','index_SA','cpi_used')
countries <- unique(data$Country)
countries <- countries %>% subset(countries!="Guatemala")
sort(countries)
sort(unique(prices.districts$country)) %in% sort(unique(data$Country))
countries %in% sort(unique(prices.districts$country))
variables <- c('index','index_SA','cpi_used')

for (coun in countries){

  print(paste("running", coun))
  prices.country <- prices.districts %>%
    filter(country==coun)

  admin.country <- shape.data %>%
    filter(country==coun)

  idw.country <- admin.country

  for (time in unique(prices.country$time_id)){

    # print(paste("for time step",time))
    prices.subset <- prices.country %>% filter(time_id==time)
    time2 <- sym(as.character(time))

    for (var in variables){

      # print(paste("interpolating", var))
      var2 <- sym(as.character(var))
      label <- paste(var2,time2,sep=".")

      idw.subset <- idw(values=prices.subset[[var]],
                        coords=prices.subset[c("centx","centy")],
                        grid=admin.country[c("centx","centy")]) %>%
        rename(!!label:="Z")

      idw.country <- cbind(idw.country, idw.subset)

      rm(idw.subset)

    }


  }

  if(!exists('master.idw')){
    master.idw <- idw.country
  }
  else{
    master.idw <- rbind(master.idw, idw.country)
  }

}

rm(master.idw)
rm(prices.subset)
rm(idw.country)
rm(idw.subset)

master.idw.v2 <- master.idw



prices.districts$spatial_interpolation <- 0
names(master.idw.v2)

time.ids <- prices[c('time_id','year','month')] %>%
  distinct()

idw.re <- merged.stack(data=master.idw.v2, var.stubs=c('index','index_SA','cpi_used'), sep='.') %>%
  rename(time_id=".time_1") %>%
  mutate(time_id=as.integer(time_id)) %>%
  dplyr::select(country, admin_code, time_id, centx, centy, index, index_SA, cpi_used) %>%
  left_join(time.ids, by='time_id') %>%
  mutate(spatial_interpolation=1) %>%
  filter(!admin_code %in% unique(prices.districts$admin_code))

# prices.districts[which(prices.districts$admin_code==202 & prices.districts$time_id==101),]
# idw.re[which(idw.re$admin_code==202 & idw.re$time_id==101),]

prices.bind <- rbind(prices.districts, idw.re)

prices.bind2 <- prices.bind %>%
  left_join(shape.data[c('admin_code','admin_name')], by='admin_code') %>%
  dplyr::select(country, admin_code, admin_name, everything()) %>%
  arrange(country, admin_code, time_id)

write.csv(prices.bind2, "Prices_IDW_v2.csv", na="", row.names=FALSE)
write.dta(prices.bind2, "Prices_IDW.dta")


one <- ggplot(shape.sf[shape.sf$adm0_name=='Afghanistan',]) +
  geom_sf(fill='white') +
  theme_void() +
  theme(panel.grid.major = element_line(colour = 'transparent')) +
  geom_point(data=prices.districts[which(prices.districts$country=='Afghanistan' & prices.districts$time_id==101),]
             ,aes(x=centx,y=centy,colour=index), size=4) +
  scale_colour_distiller(type='seq', palette='RdYlGn') +
  labs(title = "Markets at the District level")

two <- ggplot(shape.sf[shape.sf$adm0_name=='Afghanistan',]) +
  geom_sf(fill='white') +
  theme_void() +
  theme(panel.grid.major = element_line(colour = 'transparent')) +
  geom_point(data=master.idw[which(master.idw$country=='Afghanistan'),]
             ,aes(x=centx,y=centy,colour=index.101), size=4) +
  scale_colour_distiller(type='seq', palette='RdYlGn') +
  labs(title='IDW Interpolation')

# grid.arrange(one, two, ncol=2)

jpeg("Afghanistan Districts and IDW .jpeg", units="in",width=8,height=6,res=200,quality=100)
grid.arrange(one, two, ncol=2)
dev.off()

#V1----

# Drop Madagascar, Rwanda, Tanzania, Djibouti?
sort(unique(data$Country))
sort(unique(prices$country))
sort(unique(prices$country)) %in% sort(unique(data$Country))

variables <- c('index','index_SA','cpi_used')
# master.idw <- shape.data

View(prices[prices$country=='Guatemala',])

countries <- unique(data$Country)
countries <- countries %>% subset(countries!="Guatemala")

for (coun in countries){

  print(paste("running", coun))
  prices.country <- prices %>%
    filter(country==coun)

  admin.country <- shape.data %>%
    filter(country==coun)

  idw.country <- admin.country

  for (time in unique(prices.country$time_id)){

    # print(paste("for time step",time))
    prices.subset <- prices.country %>% filter(time_id==time)
    time2 <- sym(as.character(time))

    for (var in variables){

      # print(paste("interpolating", var))
      var2 <- sym(as.character(var))
      label <- paste(var2,time2,sep=".")

      idw.subset <- idw(values=prices.subset[[var]],
                        coords=prices.subset[c("centx","centy")],
                        grid=admin.country[c("centx","centy")]) %>%
        rename(!!label:="Z")

      idw.country <- cbind(idw.country, idw.subset)

      rm(idw.subset)

    }


  }

  if(!exists('master.idw')){
    master.idw <- idw.country
  }
  else{
    master.idw <- rbind(master.idw, idw.country)
  }

}

# Save first version
master.idw.v1 <- master.idw

nrow(master.idw)
nrow(shape.data)

one <- ggplot(shape.sf[shape.sf$adm0_name=='Afghanistan',]) +
  geom_sf(fill='white') +
  theme_void() +
  theme(panel.grid.major = element_line(colour = 'transparent')) +
  geom_point(data=prices[which(prices$country=='Afghanistan' & prices$time_id==101),]
             ,aes(x=centx,y=centy,colour=index), size=4) +
  scale_colour_distiller(type='seq', palette='RdYlGn') +
  labs(title = "Markets")

two <- ggplot(shape.sf[shape.sf$adm0_name=='Afghanistan',]) +
  geom_sf(fill='white') +
  theme_void() +
  theme(panel.grid.major = element_line(colour = 'transparent')) +
  geom_point(data=master.idw[which(master.idw$country=='Afghanistan'),]
             ,aes(x=centx,y=centy,colour=index.101), size=4) +
  scale_colour_distiller(type='seq', palette='RdYlGn') +
  labs(title='IDW Interpolation')

grid.arrange(one, two, ncol=2)

jpeg("Afghanistan Markets and IDW.jpeg", units="in",width=8,height=6,res=200,quality=100)
grid.arrange(one, two, ncol=2)
dev.off()



#Testing-----
