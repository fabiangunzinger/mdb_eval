library(cowplot)
library(tidyverse)
library(lubridate)
library(glue)


source('./src/config.R')
source('./src/helpers/helpers.R')

theme_set(theme_minimal())


df <- read_analysis_data()
names(df)



# Raw dspend by tt ----------------------------------------------------------------

df %>% 
  group_by(tt) %>% 
  summarise_all(mean) %>% 
  filter(between(tt, -6, 5)) %>% 
  ggplot(aes(tt, dspend)) +
  geom_line() +
  geom_point() +
  ylim(0, 1100) %>% 
  labs(
    xlab = "Time since app signup",
    ylab = "Discretionary spend"
  )

