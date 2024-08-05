
#install.packages("hash")
#install.packages("ggcorrplot")
#install.packages("psych")

library(reshape2)
library(dplyr)
library(ggplot2)
library(sf)
library(tidycensus)
library(factoextra)
library(cdlTools)
library(stringr)
library(hash)
library(ggcorrplot)
library(psych)

#avoid scientific notation
options(scipen=999)

normalize <- function(x, na.rm = TRUE) {
  return((x- min(x)) /(max(x)-min(x)))
}

# set workspace----
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

#census api
census_api_key("[GET YOUR OWN KEY]") #get census API key!

#read county shapefile
geom <- st_read("../data/gis/CONUS_counties.shp") %>%
  subset(., select = c("GEOID"))
st_geometry(geom) <- NULL
geom$GEOID <- as.integer(geom$GEOID)

#read table
df <- read.csv("../outputs/df_final.csv")

#state id
df$STATEID <- lapply(df$GEOID, as.character) %>%
  str_pad(., 5, side = "left", pad = "0") %>%
  substring(., first = 1, last = 2)

#alien land bills
alb <- read.delim("../data/alien_land_bills.txt")
alb$STATE_ID <- lapply(alb$STATE_ID, as.character) %>%
  str_pad(., 2, side = "left", pad = "0")

df <- left_join(df, alb, by = c("STATEID" = "STATE_ID")) %>%
  select(., -c(STATE, ID, STATEID))

#pop - county
pop_county <- subset(get_acs(geography = "county",
                      variables = c(var = "S0101_C01_001E"),
                      year = 2020),
                  select = -c(NAME,variable, moe))
pop_county$GEOID <- as.integer(pop_county$GEOID)
names(pop_county)[names(pop_county) == 'estimate'] <- 'pop2020'

df <- geom %>%
  left_join(., df, by = "GEOID") %>%  
  left_join(., pop_county, by = "GEOID")

#rates
df$tweets_rate <- df$n / df$pop2020                                               #tweets rate: number of tweets per pop
df$hateful_tweets_prop <- df$hateful_tweets / (df$n + 1)                          #hateful tweet proportion
df$hateful_tweets_rate <- df$hateful_tweets / df$pop2020                          #hateful tweets rate: number of hateful tweets per pop  
df$tweets_per_user <- df$n / (df$users + 1)                                       #number of tweets per user
df$user_rate <- df$users / df$pop2020                                             #user rate: number of users per pop
df$hateful_tweets_per_user <- df$hateful_tweets / (df$users + 1)                  #number of hateful tweets per user
df$hateful_tweets_per_hateful_users <- df$hateful_tweets / (df$hateful_users + 1) #number of hateful tweets per hateful users
df$vics_rate <- df$vics / df$pop2020                                              #hate crime victim rate: number of anti-Asian hate crime victims per pop 
df$off_rate <- df$off / df$pop2020                                                #hate crime offender rate: number of anti-Asian hate crime offenders per pop
df$vics_off <- df$vics / (df$off + 1)                                             #hate crime offender proportion: number of hate crime victims per offender

#write.csv(df,"../outputs/df_unscaled.csv", row.names = FALSE)

#scale variables
df_subset <- subset(df, select = c(tweets_rate, hateful_tweets_prop, hateful_tweets_rate, tweets_per_user, user_rate, hateful_tweets_per_user,
                                   hateful_tweets_per_hateful_users, sent_neg, sent_neu, sent_pos, sent_compound, sent_neg_sum, sent_neu_sum, 
                                   sent_pos_sum, vics_rate, off_rate, vics_off, monthly_variation, weekly_variation, GST.interest, ALB))
rownames(df_subset) <- df$GEOID
df_scaled <- lapply(df_subset, normalize) %>%
  as.data.frame(.)
rownames(df_scaled) <- df$GEOID

#PCA
pca <- prcomp(df_scaled, scale = FALSE, retx = TRUE)

#summary
test <- summary(pca)

#pca$rotation

#Scree plot
scree <- fviz_eig(pca, addlabels = TRUE)
df_scree <- data.frame(scree$data$dim, scree$data$eig) #create df
colnames(df_scree) <- c("Principal Components", "Explained Variance [%]")            #change column names
df_scree$Var <- round(df_scree$`Explained Variance [%]`, 2)                #round
p_scree<-ggplot(data=df_scree, aes(x = `Principal Components`, y = `Explained Variance [%]`)) +     #plot
  geom_bar(stat="identity") +
  geom_text(aes(label = Var), vjust = -0.5) +
  expand_limits(y = 45) + 
  theme_minimal() +
  theme(axis.text=element_text(size=10),
        plot.background = element_rect(colour = "white"))
p_scree
ggsave("../figures/screeplot.png", p_scree)

#Variable Representation
# Dimension 1
var1 <- fviz_cos2(pca, choice = "var", axes = 1)
df1 <- data.frame(var1$data$name, var1$data$cos2) #create df
colnames(df1) <- c("Variable", "Cos2")            #change column names
df1$Cos2 <- round(df1$Cos2, 4)                    #round
df1 <- df1 %>% arrange(desc(Cos2)) %>%             #select Cos2 > 0
      slice(1:5)
# df1 <- df1 %>% arrange(desc(Cos2)) %>%             #select Cos2 > 0
#     subset(., Cos2 > 0)
p1<-ggplot(data=df1, aes(x = reorder(Variable, -Cos2), y = Cos2)) +     #plot
  geom_bar(stat="identity") +
  geom_text(aes(label = Cos2), vjust = -0.5) +
  expand_limits(y = .1) +
  theme_minimal() +
  theme(axis.text=element_text(size=10),
        axis.title.x=element_blank(),
        axis.text.x=element_text(angle=45, hjust=0.9),
        plot.background = element_rect(colour = "white"))
p1
ggsave("../figures/var_rep_dim_1.png", p1)

# Dimension 2
var2 <- fviz_cos2(pca, choice = "var", axes = 2)
df2 <- data.frame(var2$data$name, var2$data$cos2) #create df
colnames(df2) <- c("Variable", "Cos2")            #change column names
df2$Cos2 <- round(df2$Cos2, 4)                    #round
df2 <- df2 %>% arrange(desc(Cos2)) %>%             #select Cos2 > 0
  slice(1:5)
p2<-ggplot(data=df2, aes(x = reorder(Variable, -Cos2), y = Cos2)) +     #plot
  geom_bar(stat="identity") +
  geom_text(aes(label = Cos2), vjust = -0.5) +
  expand_limits(y = .15) +
  theme_minimal() +
  theme(axis.text=element_text(size=10),
        axis.title.x=element_blank(),
        axis.text.x=element_text(angle=45, hjust=0.9),
        plot.background = element_rect(colour = "white"))
p2
ggsave("../figures/var_rep_dim_2.png", p2)

# Dimension 3
var3 <- fviz_cos2(pca, choice = "var", axes = 3)
df3 <- data.frame(var3$data$name, var3$data$cos2) #create df
colnames(df3) <- c("Variable", "Cos2")            #change column names
df3 <- df3 %>% arrange(desc(Cos2)) %>%            #select top 10 variables
  slice(1:5) 
df3$Cos2 <- round(df3$Cos2, 4)                #round
p3<-ggplot(data=df3, aes(x = reorder(Variable, -Cos2), y = Cos2)) +     #plot
  geom_bar(stat="identity") +
  geom_text(aes(label = Cos2), vjust = -0.5) +
  expand_limits(y = .008) +
  theme_minimal() +
  theme(axis.text=element_text(size=10),
        axis.title.x=element_blank(),
        axis.text.x=element_text(angle=45, hjust=0.9),
        plot.background = element_rect(colour = "white"))
p3
ggsave("../figures/var_rep_dim_3.png", p3)

#add factor loadings back to df
df$pc1 <- pca$x[,1]
df$pc2 <- pca$x[,2]
df$pc3 <- pca$x[,3]

write.csv(df,"../outputs/df_pca.csv", row.names = FALSE)
