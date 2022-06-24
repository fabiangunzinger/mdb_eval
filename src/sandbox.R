library(cowplot)
library(tidyverse)
library(lubridate)

source('./src/config.R')
source('./src/helpers/helpers.R')

# Settings and global variables
theme_set(theme_minimal())
flows <- "^(in|out|net)flows$"
levels <- c("Inflows", "Outflows", "Netflows")


df <- read_analysis_data()


# Two strange patterns
# Break at -12, peak at 0
df %>% 
  select(tt, matches(flows)) %>% 
  filter(between(tt, -24, 12)) %>%
  pivot_longer(matches(flows)) %>%
  mutate(name = factor(str_to_title(name), levels = levels)) %>% 
  group_by(tt, name) %>%
  summarise(
    value_mean = mean(value),
    value_sd = sd(value),
    value_count = n(),
  ) %>% 
  ggplot(aes(tt, value_mean, colour = name, size=value_count)) +
  geom_point() +
  scale_colour_brewer(palette = palette) +
  labs(x = "Time to/since beginning of app use", y = "Amount (£)")


# Break at -12

## Are users with longer histories different? No, pattern persists.
df %>% 
  group_by(user_id) %>% 
  filter(min(tt) <= -20) %>% 
  select(tt, matches(flows)) %>% 
  filter(between(tt, -24, 12)) %>%
  pivot_longer(matches(flows)) %>%
  mutate(name = factor(str_to_title(name), levels = levels)) %>% 
  group_by(tt, name) %>%
  summarise(
    value_mean = mean(value),
    value_sd = sd(value),
    value_count = n(),
  ) %>% 
  ggplot(aes(tt, value_mean, colour = name, size=value_count)) +
  geom_point() +
  scale_colour_brewer(palette = palette) +
  labs(x = "Time to/since beginning of app use", y = "Amount (£)")

names(df)

## Does the number of active accounts change?
## Yes, it does! I suspect it's because history that can be pulled in varies by bank, so that not all savings accounts have same amount of historical data. Given that in our analysis, we only look at past 6 months, this is not a problem, and I don't pursue this further.

df %>% 
  select(tt, accounts_active, matches(flows)) %>% 
  pivot_longer(matches(flows)) %>%
  mutate(name = factor(str_to_title(name), levels = levels)) %>% 
  group_by(tt, name) %>%
  summarise(
    value_mean = mean(value),
    value_sd = sd(value),
    value_count = n(),
    accounts_mean = mean(accounts_active)
  ) %>% 
  ggplot(aes(tt, value_mean, colour = name, size=accounts_mean)) +
  geom_point() +
  scale_colour_brewer(palette = palette) +
  labs(x = "Time to/since beginning of app use", y = "Amount (£)")


# Peak at 0

df %>% 
  select(tt, accounts_active, matches(flows)) %>% 
  filter(between(tt, -12, 12)) %>%
  pivot_longer(matches(flows)) %>%
  mutate(name = factor(str_to_title(name), levels = levels)) %>% 
  group_by(tt, name) %>%
  summarise(
    value_mean = mean(value),
    value_sd = sd(value),
    value_count = n(),
    accounts_mean = mean(accounts_active)
  ) %>% 
  ggplot(aes(tt, value_mean, colour = name, shape = name)) +
  geom_point() +
  scale_colour_brewer(palette = palette) +
  labs(x = "Time to/since beginning of app use", y = "Amount (£)")




  
  %>% 
  mutate(name = factor(str_to_title(name), levels = levels)) %>% 
  group_by(name) %>% 
  summarise(count = n()) %>% 
  ggplot() +
  geom_point(aes(name, count, colour = name), stat = "identity")
  


%>%
  ggplot() +
  geom_bar(aes(value, colour = ))
