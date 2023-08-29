# -*- coding: utf-8 -*-

import pandas as pd
from pytrends.request import TrendReq

def chunker(seq, size):
    return (seq[pos:pos + size] for pos in range(0, len(seq), size))

# Only need to run this once, the rest of requests will use the same session.
pytrend = TrendReq()

#hate keywords
hate = pd.read_csv('../data/keywords_v2.csv')
hate = pd.DataFrame(hate['word'].unique())
hate.columns = ['word']

#US states
states = [ 'AL', 'AR', 'AZ', 'CA', 'CO', 'CT', 'DC', 'DE', 'FL', 'GA',
           'IA', 'ID', 'IL', 'IN', 'KS', 'KY', 'LA', 'MA', 'MD', 'ME',
           'MI', 'MN', 'MO', 'MS', 'MT', 'NC', 'ND', 'NE', 'NH', 'NJ', 'NM',
           'NV', 'NY', 'OH', 'OK', 'OR', 'PA', 'RI', 'SC', 'SD', 'TN', 'TX',
           'UT', 'VA', 'VT', 'WA', 'WI', 'WV', 'WY']

#crosswalk: file by Jacob Schneider (https://sites.google.com/view/jacob-schneider, https://drive.google.com/open?id=1Gzu6MfQItuM60fm6TMF9IX6KAEJN7SO8)
cross = pd.read_csv('..data/google/trends_metro_counties_crosswalk.csv')[['GEOID', 'trends_geocode']]
cross['trends_geocode'] = cross['trends_geocode'].astype(str)
cross = cross.set_index('trends_geocode')

#initiate df1
df1 = pd.DataFrame()

for group in chunker(hate, 5):

    print(list(group['word']))

    # Create payload and capture API tokens. 
    pytrend.build_payload(kw_list=list(group['word']), geo = 'US')

    #get the data
    df2 = pytrend.interest_by_region(resolution='DMA', inc_low_vol=True, inc_geo_code=True)
    
    #set index
    df2 = df2.set_index('geoCode')

    #append columns to df1    
    df1[list(group['word'])] = df2[list(group['word'])]

#average columns
df1['hate_interest'] = df1.mean(axis=1)

#drop columns
df1 = pd.DataFrame(df1['hate_interest'])

#df_final = cross.join(df1)
df_final = df1.join(cross)

#write to csv
df_final.to_csv('../outputs/googletrends.csv', index = False)

