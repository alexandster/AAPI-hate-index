# -*- coding: utf-8 -*-

import pandas as pd
from tqdm import tqdm
import os
import re
import glob
import multiprocessing as mp

# read hate keywords
keys = pd.read_csv('../data/keywords_v2.csv')
keys = [x.lower() for x in keys['word']]

#read list of human tweet sources (Li et al 2021, Scientific Reports, https://doi.org/10.1038/s41598-021-94300-7)
source_list = list(pd.read_csv('../data/source_list.txt',
                          header = None,
                          sep = ', ').stack())

#drop tweets
def preprocess(in_element):
  try:
    ele = detect(in_element)
    if ele == 'en':
      return detect(in_element)
    else:
      return '-9999'
  except:
    return '-9999'
    
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


def Extracting(tweet_file):
    #print(tweet_file)
    
    tweet = pd.read_csv(tweet_file)

    tweetid = []
    userid = []
    YMD = []
    time = []
    x = []
    y = []
    truncated = []
    is_quote = []
    source = []

    try:
        for i in tqdm(range(len(tweet))):
                        
            YMD.append(tweet.created_at[i].split()[0])                          #YMD
            time.append(tweet.created_at[i].split()[1])
            tweetid.append(tweet.id[i])
            userid.append(int((tweet.user[i].split(', ')[0].split(': ')[1])))
            coord = str(eval(tweet.place[i])['bounding_box']['coordinates'])    #Raw 1, str -> dict(eval) -> str // extract coordinate string
            xy = re.findall(r"[-+]?\b(?<!\d\.)\d+\.\d+\b(?!\.\d)", coord)       #Extracting only float from string
            x.append((float(xy[0])+float(xy[2])+float(xy[4])+float(xy[6]))/4)     #Average x
            y.append((float(xy[1])+float(xy[3])+float(xy[5])+float(xy[7]))/4)     #Average y
            truncated.append(tweet.truncated[i])
            is_quote.append(tweet.is_quote_status[i])
            source.append(tweet.source[i].split(">")[1].split("<")[0])
            
    except Exception as e:
            print(f"{type:e}, and {e}")   #Result = No exception. 
                        
    tweet_out = tweet.loc[:,["timestamp_ms", "text", "place"]]
    
    tweet_out['tweetid'] = tweetid
    tweet_out['userid'] = userid
    tweet_out['YMD'] = YMD
    tweet_out['x'] = x
    tweet_out['y'] = y
    tweet_out['truncated'] = truncated
    tweet_out['is_quote_status'] = is_quote
    tweet_out['source'] = source
                 
    #credible source        
    tweet_out = tweet_out[tweet_out['source'].isin(source_list)] 
               
    # classify tweets into hateful/not-hateful
    tweet_out['hate'] = list(map(hate, tweet_out['text']))                
    
    tweet_out = tweet_out[['tweetid', 'userid', 'YMD', 'x','y', 'truncated', 'is_quote_status', 'hate']] #range columns
    tweet_out.to_excel("../outputs/twitter/tweets_" + tweet_file.split(os.sep)[-1][:-4] + ".xlsx")

path = "/data/twitter/*.csv"
file_list = glob.glob(path)       # changing number 0 to 22

p = mp.Pool(mp.cpu_count())

p.map(Extracting, file_list)

