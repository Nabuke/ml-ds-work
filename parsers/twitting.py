from twitter import *
import tweepy
import re
def twit(message):
    CONSUMER_KEY = 'ТВОЙ ТОКЕН'
    CONSUMER_SECRET = 'ТВОЙ ТОКЕН'
    OAUTH_TOKEN = 'ТВОЙ ТОКЕН'
    OAUTH_TOKEN_SECRET = 'ТВОЙ ТОКЕН'
    auth = OAuth(OAUTH_TOKEN, OAUTH_TOKEN_SECRET,
                               CONSUMER_KEY, CONSUMER_SECRET)
    twitter_api = Twitter(auth=auth)
    
    twitter_api.statuses.update(status=message)

def get_tweets(key_word):
    CONSUMER_KEY = 'ТВОЙ ТОКЕН'
    CONSUMER_SECRET = 'ТВОЙ ТОКЕН'
    OAUTH_TOKEN = 'ТВОЙ ТОКЕН'
    OAUTH_TOKEN_SECRET = 'ТВОЙ ТОКЕН'
    auth = tweepy.OAuthHandler(CONSUMER_KEY, CONSUMER_SECRET)
    auth.set_access_token(OAUTH_TOKEN, OAUTH_TOKEN_SECRET)
    
    twitter_api = tweepy.API(auth)
    
    max_tweets = 1000
    tweets = [status for status in tweepy.Cursor(twitter_api.search, q=key_word).items(max_tweets)]
    
    return tweets
    
def preprocessing(tweets):
    tweets=[tweet.text.lower() for tweet in tweets]
    tweets=[tweet for tweet in tweets if  ('восход' not in tweet) & ( 'rt' not in tweet) & ('@' not in tweet) & ('http' not in tweet)]
    tweets=[' '.join(re.sub(r'[^А-Яа-я\.\,]', ' ', tweet).split()) for tweet in tweets]
    
    open('weather_tweets.txt', 'w').write('\n'.join(tweets))