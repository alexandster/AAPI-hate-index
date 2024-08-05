# -*- coding: utf-8 -*-

import pandas as pd
import re

# read hate keywords
keys_100 = pd.read_csv(r'..\data\hate_terms_committeeof100.csv', header = None)
keys_covid19 = pd.read_csv(r'..\data\hate_terms_covid19.csv', header = None)
keys_hatebase = pd.read_csv(r'..\data\hate_terms_hatebase.csv', header = None, usecols = [0])

#combine
keys = pd.concat([keys_100, keys_covid19, keys_hatebase], axis = 0, ignore_index = True)

#convert to lower case
keys = [x.lower() for x in keys[0]]

#detect hateful language in tweets
def hate(tweet):
    # split the string into list of words
    tweet = tweet.split(" ")
    # retain letters only
    tweet = [re.sub(r'^[^A-Za-z]+|[^A-Za-z]+$', '', j) for j in tweet]
    #convert to lowercase
    tweet = list(map(str.lower,tweet))

    # parse tweet body, raise flag if hateful language detected
    term="none"
    for i in tweet:
        for j in keys:
            if i==j:
                term=str(j)
                break
    return term



#read tweet file
cols = ['tweetid','userid','postdate','message','longitude','latitude','source']    #column names
df = pd.read_csv(r"..\data\twitter\covid_tweets.csv", sep = '\t', index_col=False, names = cols) # file loading
print("file read")

# classify tweets into hateful/not-hateful
df['hate'] = list(map(hate, df['message']))

# count hate terms
df['hate'].value_counts()

# chinavirus                  4895
# wuhanvirus                  3274
# chinesevirus                1787
# ccpvirus                     896
# chinaliedpeopledied          882
