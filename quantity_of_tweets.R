library(dplyr)
library(tidyr)
library(data.table)
library(zoo)
library(ggplot2)

canada_tweets_file <- file.path("data", "canadian_tweets_3week_window.csv")

canada_tweets <- fread(canada_tweets_file, header = TRUE)

canada_tweets$date <- as.Date(canada_tweets$created_at)

may_20th <- as.Date("2020-05-20")

tweets_per_day <- canada_tweets %>% 
  group_by(date) %>% 
  summarize(n_tweets = n())


tweets_window <- rollmean(tweets_per_day$n_tweets, k = 5, fill=NA)

tweets_per_day$window_avg <- tweets_window


tweets_per_day %>% 
  ggplot(aes(x = date, y =n_tweets)) +
  geom_line() + 
  geom_vline(aes(xintercept = may_20th)) +
  theme_bw() + 
  ggtitle("Number of Tweets Per day")