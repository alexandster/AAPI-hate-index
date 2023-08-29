# -*- coding: utf-8 -*-

import glob
import pandas as pd

path = '../outputs/twitter/*.xlsx'
res = glob.glob(path)

df = pd.DataFrame()

i = 0
for file in res:
    data = pd.read_excel(file, index_col=0)
    df = pd.concat([df, data], axis=0)
    print(i)
    i += 1
df.to_csv('../outputs/tweets_master.csv', index=False)


