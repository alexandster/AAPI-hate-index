#libraries
library(dplyr)

#workspace
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

#read dfs
load("../outputs/tweets.Rda")
load("../outputs/hate_crimes.Rda")

#load Google Search Trends (GST) data
google_1 <- read.csv("../data/googlesearch/terms interest/china virus.csv", skip = 2)
google_2 <- read.csv("../data/googlesearch/terms interest/wuhan virus.csv", skip = 2)
google_3 <- read.csv("../data/googlesearch/terms interest/chinese virus.csv", skip = 2)
google_4 <- read.csv("../data/googlesearch/terms interest/ccp virus.csv", skip = 2)
google_5 <- read.csv("../data/googlesearch/terms interest/china lied people died.csv", skip = 2)
google_5$china.lied.people.died...1.1.20...12.31.21. <- as.numeric(google_5$china.lied.people.died...1.1.20...12.31.21.)

#GST: merge together
gst <- dplyr::bind_rows(google_1, google_2, google_3, google_4, google_5)
gst$sum <- rowSums(gst %>% select(-DMA), na.rm = TRUE)
gst <- aggregate(gst$sum, by=list(Category=gst$DMA), FUN=sum)

#GST: scale
gst$x <- (gst$x-min(gst$x))/(max(gst$x)-min(gst$x))

#GST: load crosswalk
crosswalk <- read.csv("../data/googlesearch/trends_metro_counties_crosswalk.csv") %>%
  subset(., select = c("GEOID", "trends_geocode", "trends_geoname"))  

#GST: apply to counties  
gst <- left_join(crosswalk, gst, by = c("trends_geoname" = "Category"))
gst <- subset(gst, select = c(-trends_geocode, -trends_geoname))
gst <- gst %>%
  rename("GST interest" = "x")

#Hate crimes: convert GEOID column to integer
hate_crimes$GEOID <- as.integer(hate_crimes$GEOID)

#Tweets: column names
df <- df %>% 
  rename( "monthly_variation" = "var.x",
          "weekly_variation" = "var.y")

#join together
df_final <- left_join(hate_crimes, gst, by = "GEOID") %>%
  left_join(., df, by = "GEOID")

#replace NAs
df_final[is.na(df_final)] <- 0

#write to file
write.csv(df_final, "../outputs/df_final.csv", row.names = FALSE)
