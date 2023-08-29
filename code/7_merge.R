#libraries
library(dplyr)

#workspace
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

#read dfs
load("../outputs/tweets.Rda")
load("../outputs/hate_crimes.Rda")
google <- read.csv("../outputs/googletrends.csv") 

#convert GEIOD column to integer
hate_crimes$GEOID <- as.integer(hate_crimes$GEOID)

#join together
df_final <- left_join(df, google, by = "GEOID") %>%
  left_join(., hate_crimes, by = "GEOID")

#column names
df_final <- df_final %>% 
  rename( "monthly_variation" = "var.x",
         "weekly_variation" = "var.y")


#write to file
write.csv(df_final, "../outputs/df_final.csv", row.names = FALSE)
