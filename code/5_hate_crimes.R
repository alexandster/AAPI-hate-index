library(dplyr)
library(cdlTools)
library(stringr)
library(sf)

#workspace
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

load("../data/ucr/37872-0002-Data.rda")

df2 <- as.data.frame(da37872.0002)

colnames(df2)

#subset df. STADECOD: state code, BIASMO: bias motivation, NUMVTM: number of victims, CFIPS: county fips
df2 <- df2 %>%
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
         select=c("STATECOD", 
                  "NUMVTM1", "NUMVTM2", "NUMVTM3", "NUMVTM4", "NUMVTM5", "NUMVTM6", "NUMVTM7", "NUMVTM8", "NUMVTM9", "NUMVTM10",
                  "CFIPS1", "CFIPS2", "CFIPS3", "CFIPS4", "CFIPS5"))

#state fips
df2$STATEFIPS <- fips(df2$STATECOD) %>%
  as.character(.) %>%
  str_pad(., width = 2, side = "left", pad = "0")

#county fips
df2 <- df2[df2$CFIPS1 != "   ",]
df2$CFIPS1 <- as.character(df2$CFIPS1)
df2$CFIPS1 <- gsub(" ", "0", df2$CFIPS1)

#fips - combined
df2$FIPS5 <- paste0(df2$STATEFIPS, df2$CFIPS1)

#number of victims
df2$NUMVTM <- rowSums(df2[,c("NUMVTM1", "NUMVTM2", "NUMVTM3", "NUMVTM4", "NUMVTM5", "NUMVTM6", "NUMVTM7", "NUMVTM8", "NUMVTM9", "NUMVTM10")], na.rm = TRUE)

#select columns
df2 <- subset(df2, select = c("FIPS5", "NUMVTM"))

#county sum of victims
df2 <- df2 %>%
  group_by(FIPS5) %>%
  summarise(vics = sum(NUMVTM))

#read geometries
geom <- st_read("../data/gis/CONUS_counties.shp") %>%
  subset(., select = c("GEOID"))
st_geometry(geom) <- NULL
geom$GEOID <- as.character(geom$GEOID)

#join
hate_crimes <- left_join(geom, df2, by = c("GEOID" = "FIPS5"))

#deal with NAs
hate_crimes[is.na(hate_crimes)] <- 0 

#save df
save(hate_crimes, file = "../outputs/hate_crimes.Rda")



