library(tidyverse)
library(ggthemr)
library(patchwork)

source('./src/config.R')
source('./src/helpers/helpers.R')

ggthemr('fresh')
theme_set(theme_minimal())


df <- read_analysis_data()
names(df)


flowpat <- "^(in|out|net)flows$"


flows_by_tt <- df %>% 
  select(tt, matches(flowpat)) %>% 
  filter(between(tt, -12, 24)) %>% 
  pivot_longer(matches(flowpat)) %>% 
  ggplot(aes(tt, value, color = str_to_title(name))) +
  stat_summary(fun.data = "mean_cl_boot") +
  labs(
    x = "Months to/since beginning of app use",
    y = "Amount (£)",
    color = ""
  )

flows_by_month <- df %>% 
  select(month, matches(flowpat)) %>% 
  pivot_longer(matches(flowpat)) %>% 
  ggplot(aes(month(month, label = T), value, color = str_to_title(name))) +
  stat_summary(fun.data = "mean_cl_boot") +
  labs(
    x = "Month",
    y = "Amount (£)",
    color = ""
  )


flows_by_tt + flows_by_month



# dev

day_order <- c('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday')







# old entropy stuff
moy <- ggplot(dt) +
  geom_bar(aes(month(date, label = T))) +
  labs(
    x = 'Month of year',
    y = txns_label
  )
moy

dom <- ggplot(dt) +
  geom_bar(aes(day(date))) +
  labs(
    x = 'Day of month',
    y = txns_label
  )
dom

d <- dt[, .N, -amount][order(-N)][1:10]
amounts <- ggplot(d) +
  geom_bar(aes(N, reorder(factor(amount), N)), stat = 'identity') +
  labs(
    x = txns_label,
    y = 'Amount'
  )
amounts


cap <- 'Notes: number of days since last transfer into savings account. Number of transactions with delay of more than 35 days are fewer than 5 percent and are not shown.'
dt <- dt[, ddate := difftime(date, shift(date), units = 'days'), user_id]
ddate <- ggplot(dt[ddate <= 35]) +
  geom_bar(aes(factor(ddate))) +
  labs(
    x = 'Days since last savings account transfer',
    y = txns_label,
    caption = cap
  )
ddate


pw <- moy + dom + amounts + ddate 
pw + plot_layout(ncol = 2)
ggsave(file.path(FIGDIR, 'savings.png'))








