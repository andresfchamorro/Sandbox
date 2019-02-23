library(dplyr)

#Import data

# setwd(/Users/andreschamorro/Repos/apollo/2_data/Master_data)
setwd("C:/Users/WB514197/apollo/2_data/Master_data")
prices_yem <- read.csv("Prices/Prices_Yemen.csv")

# setwd(/Users/andreschamorro/Repos/apollo/2_data/Price_interpolation)
setwd("C:/Users/WB514197/apollo/2_data/Price_interpolation")
tt_matrix <- read.csv("Pairs_Yemen.csv") %>%
  rename(
    admin_code="O_UID",
    admin_code_dest="D_UID"
    ) %>%
  select(admin_code,admin_code_dest,DIST)

# Repeat tt matrix
list_months <- sort(unique(prices_yem$Year_Month))
n <- length(list_months)
list_ids <- 1:n
ids_months <- data.frame(list_ids,list_months)

tt_matrix_rep <- do.call("rbind", replicate(n, tt_matrix, simplify = FALSE)) %>%
mutate(list_ids=((row_number()-1)%/%nrow(test))+1,Country="Yemen") %>%
left_join(ids_months,"list_ids") %>%
select(-list_ids) %>%
rename(Year_Month=list_months)

# Join
prices_tt <- tt_matrix_rep %>%
  left_join(prices_yem,c("admin_code","Year_Month","Country"))

# Get price names
prices <- names(prices_yem)
prices <- prices %>% subset(prices!="Country"&prices!="Year_Month"&prices!="admin_code")

# Run interpolation in loop for each price
# Group by time and destination matrix, do calculations and assign sum of weighted values to all dest (each origin will have different values)

prices_tt_grouped <- prices_tt %>% group_by(Year_Month,admin_code_dest)

for (each in prices){

  each <- sym(each)
  label <- paste(each,"_interp",sep="")

  prices_tt_grouped <- prices_tt_grouped %>% mutate(
    inverseTT=ifelse(!is.na(!!each)&DIST!=0,1/DIST^2,NA),
    sumInverseTT=sum(inverseTT,na.rm=TRUE),
    weight=inverseTT/sumInverseTT,
    multiplied=!!each*weight,
    !!label:=sum(multiplied,na.rm=TRUE)
  )

}

# Collapse data frame to unique admin codes

prices_tt_interp <- prices_tt_grouped %>%
  ungroup() %>%
  filter(admin_code==admin_code_dest)

# prices_tt_interp %>% count(Year_Month)

# Assign interpolation to original price column and add exist flag

for (each in prices){

  label <- paste("exist_",each,sep="")
  label_interp <- paste(each,"_interp",sep="")

  prices_tt_interp[[label]] <- ifelse(is.na(prices_tt_interp[[each]]),0,1)
  prices_tt_interp[[each]] <- ifelse(is.na(prices_tt_interp[[each]])&prices_tt_interp[[label_interp]]!=0,prices_tt_interp[[label_interp]],prices_tt_interp[[each]])

}

prices_final <- prices_tt_interp %>%
  select(Country,Year_Month,admin_code,starts_with("p"),starts_with("exist"))

#setwd("/Users/andreschamorro/Repos/apollo/2_data/Master_data/Prices")
# setwd("C:/Users/WB514197/apollo/2_data/Master_data/Prices")
# write.csv(prices_final,"Prices_Yemen_interpolated.csv",row.names=FALSE)
