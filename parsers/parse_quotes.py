#!/usr/bin/env python
# coding: utf-8

# In[19]:


import urllib
import base64
import json
import datetime
import numpy as np
import pandas as pd
import time
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
engine = create_engine('sqlite:///C:\\investor\\db.sqlite3')


# In[32]:


now = datetime.datetime.now()
now_hour = int(time.strftime('%H', now.timetuple()))
now_day = int(time.strftime('%w', now.timetuple()))
if now_hour in [12,13,14,15,16,17,18,19,20,21] and now_day in [0,1,2,3,4]:
    prices = []
    url = 'https://iss.moex.com/iss/engines/stock/markets/shares/boards/TQBR/securities.html?securities.columns=SECID&marketdata.columns=SECID,BOARDID,LAST&iss.meta=off'
    df = pd.read_html(url,encoding='utf-8')
    quotes = df[1]
    quotes = quotes.fillna(0)
    quotes.columns = ['tiker','boardid','price']
    quotes = quotes[quotes.price != 0].drop('boardid',axis=1)
    quotes['dt_load']=now
    quotes.to_sql('quotes', con=engine, if_exists='append',index=False)
else:
    print ('Сейчас сессия не идет')
    print ('День:',time.strftime('%A', now.timetuple()),',',now)


# In[2]:





# In[3]:





# In[4]:





# In[5]:





# In[6]:





# In[7]:




