library(cowplot)
library(tidyverse)
library(lubridate)

source('./src/config.R')
source('./src/helpers/helpers.R')

theme_set(theme_minimal())

fp = 's3://3di-data-mdb/clean/mdb_X11.parquet'
df <- read_s3parquet(fp)
head(df)

dfs <- sample_n(df, size = 1)


df %>% 
  group_by(account_id, ym) %>% 
  select(account_provider, account_created, account_type) %>% 
  summarise_all(first) %>% 
  mutate(
    account_created = 
  )