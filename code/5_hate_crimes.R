library(dplyr)
library(cdlTools)
library(stringr)
library(sf)

#workspace
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

load("C:/Users/u6025895/Box/research/AAPI_hate_clustering/data/fbi/ICPSR_38790/DS0002/38790-0002-Data.rda") #2020
load("C:/Users/u6025895/Box/research/AAPI_hate_clustering/data/fbi/ICPSR_38798/DS0002/38798-0002-Data.rda") #2021



#df1 <- as.data.frame(da37872.0002)
df2020 <- as.data.frame(da38790.0002) %>%
  subset(., BIASMO1 == "(14) Anti-Asian" |
           BIASMO2 == "(14) Anti-Asian" |
           BIASMO3 == "(14) Anti-Asian" |
           BIASMO4 == "(14) Anti-Asian" |
           BIASMO5 == "(14) Anti-Asian" |
           BIASMO6 == "(14) Anti-Asian" |
           BIASMO7 == "(14) Anti-Asian" |
           BIASMO8 == "(14) Anti-Asian" |
           BIASMO9 == "(14) Anti-Asian" |
           BIASMO10 == "(14) Anti-Asian",
         select=c("STATECOD", "TNUMVTMS", "TNUMOFF", 
                  "NUMVTM1", "NUMVTM2", "NUMVTM3", "NUMVTM4", "NUMVTM5", "NUMVTM6", "NUMVTM7", "NUMVTM8", "NUMVTM9", "NUMVTM10",
                  "CFIPS1", "CFIPS2", "CFIPS3", "CFIPS4", "CFIPS5"))

df2021 <- as.data.frame(da38798.0002) %>%
  subset(., BIASMO1 == "(14) Anti-Asian" |
           BIASMO2 == "(14) Anti-Asian" |
           BIASMO3 == "(14) Anti-Asian" |
           BIASMO4 == "(14) Anti-Asian" |
           BIASMO5 == "(14) Anti-Asian" |
           BIASMO6 == "(14) Anti-Asian" |
           BIASMO7 == "(14) Anti-Asian" |
           BIASMO8 == "(14) Anti-Asian" |
           BIASMO9 == "(14) Anti-Asian" |
           BIASMO10 == "(14) Anti-Asian",
         select=c("STATECOD", "TNUMVTMS", "TNUMOFF",
                  "NUMVTM1", "NUMVTM2", "NUMVTM3", "NUMVTM4", "NUMVTM5", "NUMVTM6", "NUMVTM7", "NUMVTM8", "NUMVTM9", "NUMVTM10",
                  "CFIPS1", "CFIPS2", "CFIPS3", "CFIPS4", "CFIPS5"))

colnames(df2020)
colnames(df2021)

#tack on top of each other
df <- bind_rows(df2020, df2021)

#state fips
df$STATEFIPS <- fips(df$STATECOD) %>%
  as.character(.) %>%
  str_pad(., width = 2, side = "left", pad = "0")

#county fips
df <- df[df$CFIPS1 != "   ",]
df$CFIPS1 <- as.character(df$CFIPS1)
df$CFIPS1 <- gsub(" ", "0", df$CFIPS1)

#fips - combined
df$FIPS5 <- paste0(df$STATEFIPS, df$CFIPS1)

#number of victims
df$NUMVTM <- rowSums(df[,c("NUMVTM1", "NUMVTM2", "NUMVTM3", "NUMVTM4", "NUMVTM5", "NUMVTM6", "NUMVTM7", "NUMVTM8", "NUMVTM9", "NUMVTM10")], na.rm = TRUE)

#select columns
df <- subset(df, select = c("FIPS5", "TNUMOFF","NUMVTM"))

#county sum of victims and offenders
df <- df %>%
  group_by(FIPS5) %>%
  summarise(vics = sum(NUMVTM), off = sum(TNUMOFF))

#read geometries
geom <- st_read("../data/gis/tl_2020_us_county.shp") %>%
  subset(., select = c("GEOID"))
st_geometry(geom) <- NULL
geom$GEOID <- as.character(geom$GEOID)

#join
hate_crimes <- left_join(geom, df, by = c("GEOID" = "FIPS5"))

#deal with NAs
hate_crimes[is.na(hate_crimes)] <- 0 

#save df
save(hate_crimes, file = "../outputs/hate_crimes.Rda")



