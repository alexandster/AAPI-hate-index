#libraries
#-------------------------
library(dplyr)
library(sf)


#workspace
#-------------------------
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

#read tweets
tweets <- read.csv("../data/twitter/tweets_zl_GEOID.csv")


#county-level variables
#-----------------------------------------------------------------
#tweet volume
tweet_volume <- tweets %>% count(geoid)

#number of hateful tweets
hate_counts <- tweets %>%
  group_by(geoid) %>%
  summarise(hateful_tweets = sum(hate))

#user volume
user_volume <- tweets %>%
  group_by(geoid) %>%
  summarise(users = length(unique(userid)))

#number of hateful users
hate_users <- tweets %>%
  subset(., hate == 1) %>%
  group_by(geoid) %>%
  summarise(hateful_users = length(unique(userid)))

#sentiment
sent_neg <- tweets %>%
  group_by(geoid) %>%
  summarise(sent_neg = mean(neg))

sent_neu <- tweets %>%
  group_by(geoid) %>%
  summarise(sent_neu = mean(neu))

sent_pos <- tweets %>%
  group_by(geoid) %>%
  summarise(sent_pos = mean(pos))

sent_compound <- tweets %>%
  group_by(geoid) %>%
  summarise(sent_compound = mean(compound))

#sentiment volume
sent_pos_sum <- tweets %>%
  group_by(geoid) %>%
  summarize(sent_pos_sum = sum(pos))

sent_neg_sum <- tweets %>%
  group_by(geoid) %>%
  summarize(sent_neg_sum = sum(neg))

sent_neu_sum <- tweets %>%
  group_by(geoid) %>%
  summarize(sent_neu_sum = sum(neu))

#temporal variation
tweets$postdate <- as.Date(tweets$postdate)

#tweets$postdate <- as.Date(tweets$YMD)
tweets$month <- format(tweets$postdate, "%m")
tweets$week <- format(tweets$postdate, "%W")

#monthly
variation_montly <- tweets %>%
  count(geoid, month) %>%
  group_by(geoid) %>%
  summarize(var = ((max(n) - min(n))/max(n)))

#weekly
variation_weekly <- tweets %>%
  count(geoid, week) %>%
  group_by(geoid) %>%
  summarize(var = ((max(n) - min(n))/max(n)))



#join together
#-----------------------------------------------------------------

#read geometries
df <- st_read("../data/gis/tl_2020_us_county.shp") %>%
  subset(., select = c("GEOID"))  
st_geometry(df) <- NULL
df$GEOID <- as.integer(df$GEOID)

df <- left_join(df, tweet_volume, by = c("GEOID" = "geoid")) %>%
  left_join(., hate_counts, by = c("GEOID" = "geoid")) %>%
  left_join(., user_volume, by = c("GEOID" = "geoid")) %>%
  left_join(., hate_users, by = c("GEOID" = "geoid")) %>%
  left_join(., sent_neg, by = c("GEOID" = "geoid")) %>%
  left_join(., sent_neu, by = c("GEOID" = "geoid")) %>%
  left_join(., sent_pos, by = c("GEOID" = "geoid")) %>%
  left_join(., sent_neg_sum, by = c("GEOID" = "geoid")) %>%
  left_join(., sent_neu_sum, by = c("GEOID" = "geoid")) %>%
  left_join(., sent_pos_sum, by = c("GEOID" = "geoid")) %>%
  left_join(., sent_compound, by = c("GEOID" = "geoid")) %>%
  left_join(., variation_montly, by = c("GEOID" = "geoid")) %>%
  left_join(., variation_weekly, by = c("GEOID" = "geoid"))

df[is.na(df)] <- 0  

#save df
save(df,file="../outputs/tweets.Rda")





