# -*- coding: utf-8 -*-

import pandas as pd
import re
#import multiprocessing as mp
import time
from eld import LanguageDetector
from vaderSentiment.vaderSentiment import SentimentIntensityAnalyzer

#set up language detection
detector = LanguageDetector()

#set up sentiment analysis
analyzer = SentimentIntensityAnalyzer()

# read hate keywords
keys_100 = pd.read_csv(r'..\data\hate_terms_committeeof100.csv', header = None)
keys_covid19 = pd.read_csv(r'..\data\hate_terms_covid19.csv', header = None)
keys_hatebase = pd.read_csv(r'..\data\hate_terms_hatebase.csv', header = None, usecols = [0])

#combine
keys = pd.concat([keys_100, keys_covid19, keys_hatebase], axis = 0, ignore_index = True)

#convert to lower case
keys = [x.lower() for x in keys[0]]

#read list of human tweet sources (Li et al 2021, Scientific Reports, https://doi.org/10.1038/s41598-021-94300-7)
source_list = list(pd.read_csv(r'..\data\source_list.txt',
                          header = None,
                          sep = ', ').stack())
    
#detect hateful language in tweets
def hate(tweet):
    # split the string into list of words
    tweet = tweet.split(" ")
    # retain letters only
    tweet = [re.sub(r'^[^A-Za-z]+|[^A-Za-z]+$', '', j) for j in tweet]
    #convert to lowercase
    tweet = list(map(str.lower,tweet))

    # parse tweet body, raise flag if hateful language detected
    flag=0
    for i in tweet:
        for j in keys:
            if i==j:
                flag=1
                break
    return flag

#language detection
def eld_detect(item):
    return detector.detect(item).language

#sentiment analysis
def sent(row):
    res = analyzer.polarity_scores(row['message'])
    return res['neg'], res['neu'], res['pos'], res['compound']

#read tweet file
cols = ['tweetid','userid','postdate','message','longitude','latitude','source']    #column names
df = pd.read_csv(r"..\data\twitter\covid_tweets.csv", sep = '\t', index_col=False, names = cols) # file loading
print("file read")
      
start_time = time.time()

#language detection and credible source
df['en'] = list(map(eld_detect, df['message']))
df = df[(df['source'].isin(source_list)) & (df['en'].isin(['en']))] 

print("language and credible source detected")

# classify tweets into hateful/not-hateful
df['hate'] = list(map(hate, df['message']))

print("hate classified")

# count hate terms
df['hate'].value_counts()

#sentiment analysis
df['neg'], df['neu'], df['pos'], df['compound']  = zip(*df.apply(sent, axis = 1))

print("sentiment analyzed")

end_time = time.time()
print(end_time - start_time)

df.to_csv(r'..\outputs\df_tweets.csv', columns = ['tweetid', 'userid', 'postdate', 'longitude','latitude', 'hate', 'neg', 'neu', 'pos', 'compound'], sep = '\t', index = False)
