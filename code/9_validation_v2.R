library(dplyr)
library(tidyr)
library(psych)
library(tidycensus)
library(ggplot2)

# set workspace----
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

#read PCA results
df_pca <- read.csv("../outputs/df_pca.csv")

#read validation data
df_val <- read.csv("../data/validation/UNMC_Mental Health and Racism_20201221.csv") %>%
  subset(., Q2 == 4, select = c(WEIGHT, Q14, COUNTY_FIPS_CODE))

#omit na values
df_val <- df_val[!is.na(df_val$COUNTY_FIPS_CODE),]

# #count frequencies
df_freq <- df_val %>%
  group_by(COUNTY_FIPS_CODE, Q14) %>%
  summarise(sum = sum(WEIGHT)) %>%
  pivot_wider(id_cols = COUNTY_FIPS_CODE, names_from = Q14, values_from = sum)

#NA to 0
df_freq[is.na(df_freq)] <- 0

#join with pca df
df_freq <- left_join(df_freq, df_pca, by = c("COUNTY_FIPS_CODE" = "GEOID"))

#complete cases
df_freq <- df_freq[complete.cases(df_freq), ]

#variable engineering
df_freq$mhealth1_rate <- (df_freq$`1` / df_freq$pop2020) * 100000 #case rate

#fight zero-inflation: sample zero observations (2-3%)
cutoff <- 0
zeros <- df_freq[df_freq$`1` <= cutoff,]
z_sample <- zeros[sample(nrow(zeros), round(nrow(zeros)*0.025)), ]
df_freq2 <- rbind(df_freq[df_freq$`1` > cutoff,], z_sample)

#modelling
# pc1 plot a scatter plot
plot(df_freq2$pc1, df_freq2$mhealth1_rate,
     xlab='mhealth1_rate', ylab='pc1')
# plot a regression line
abline(lm(mhealth1_rate ~ pc1,data=df_freq2),col='red')
summary(lm(mhealth1_rate ~ pc1,data=df_freq2))

# pc2 plot a scatter plot
plot(df_freq2$pc2, df_freq2$mhealth1_rate,
     xlab='mhealth1_rate', ylab='pc2')
# plot a regression line
abline(lm(mhealth1_rate~pc2,data=df_freq2),col='red')
summary(lm(mhealth1_rate~pc2,data=df_freq2))

# pc3 plot a scatter plot
plot(df_freq2$pc3, df_freq2$mhealth1_rate,
     xlab='pc3', ylab='mhealth')
abline(lm(mhealth1_rate ~ pc3,data=df_freq2),col='red')
summary(lm(mhealth1_rate ~ pc3, data = df_freq2))

#joint model
summary(lm(mhealth1_rate ~ pc1 + pc2 + pc3, data = df_freq2))

#maps
write.csv(df_freq2, "../outputs/validation.csv", row.names = FALSE)


