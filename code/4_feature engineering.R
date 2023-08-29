#libraries
#-------------------------
library(dplyr)
library(sf)


#workspace
#-------------------------
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

#read tweets
tweets <- read.csv("../outputs/tweets_GEOID.csv")

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

#number of truncated tweets
truncated_tweet_volume <- tweets %>%
  group_by(geoid) %>%
  summarise(truncated_tweets = sum(truncated))

#number of quote tweets
quote_tweet_volume <- tweets %>%
  group_by(geoid) %>%
  summarise(quote_tweets = sum(is_quote_status))

#temporal variation
tweets$YMD <- as.Date(tweets$YMD)
tweets$month <- format(tweets$YMD, "%m")
tweets$week <- format(tweets$YMD, "%W")

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
df <- st_read("../data/gis/CONUS_counties.shp") %>%
  subset(., select = c("GEOID"))  
st_geometry(df) <- NULL
df$GEOID <- as.integer(df$GEOID)

df <- left_join(df, tweet_volume, by = c("GEOID" = "geoid")) %>%
  left_join(., hate_counts, by = c("GEOID" = "geoid")) %>%
  left_join(., user_volume, by = c("GEOID" = "geoid")) %>%
  left_join(., hate_users, by = c("GEOID" = "geoid")) %>%
  left_join(., truncated_tweet_volume, by = c("GEOID" = "geoid")) %>%
  left_join(., quote_tweet_volume, by = c("GEOID" = "geoid")) %>%
  left_join(., variation_montly, by = c("GEOID" = "geoid")) %>%
  left_join(., variation_weekly, by = c("GEOID" = "geoid"))

df[is.na(df)] <- 0  

#save df
save(df,file="../outputs/tweets.Rda")







