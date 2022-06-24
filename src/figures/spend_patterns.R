library(cowplot)
library(tidyverse)
library(lubridate)

source('./src/config.R')
source('./src/helpers/helpers.R')

theme_set(theme_minimal())


df <- read_analysis_data()


df %>% 
  select(tt, discret_spend) %>% 
  # filter(between(tt, -24, 24)) %>%
  # pivot_longer(matches(flows)) %>%
  ggplot(aes(tt, discret_spend)) +
  geom_point(stat = "summary", fun = "mean") +
  scale_colour_brewer(palette = palette) +
  labs(x = "Time to/since beginning of app use", y = "Amount (£)")
