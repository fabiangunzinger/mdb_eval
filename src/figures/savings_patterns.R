library(cowplot)
library(tidyverse)
library(lubridate)

source('./src/config.R')
source('./src/helpers/helpers.R')

theme_set(theme_minimal())


df <- read_analysis_data()


flows <- "^(in|out|net)flows$"
# 
# flows_month <- df %>%
#   select(month, matches(flows)) %>% 
#   pivot_longer(matches(flows)) %>% 
#   mutate(name = factor(
#     name, 
#     levels = c("inflows", "outflows", "netflows"), 
#     labels = c("Inflows", "Outflows", "Netflows")
#     )) %>% 
#   ggplot(aes(factor(month), value, colour = name, shape = name)) +
#   geom_point(stat = "summary", fun = "mean") +
#   labs(x = "Month", y = "Amount (£)", colour = NULL, shape = NULL) +
#   theme(
#     legend.position = "bottom",
#     legend.text = element_text(size = 12)
#   )

inflow_amounts <- df %>%
  select(matches(flows)) %>%
  pivot_longer(everything()) %>%
  filter(name == "inflows") %>% 
  count(value) %>%
  mutate(prop = n / sum(n)) %>% 
  filter(between(value, 1, 1000)) %>% 
  ggplot() +
  geom_bar(aes(value, prop), stat = "identity", colour = palette[1]) +
  scale_x_continuous(breaks = seq(0, 1000, 100)) +
  scale_y_continuous(labels = scales::percent) +
  labs(x = "Amount (£)", y = "Percent of inflow transactions") +
  coord_cartesian(xlim = c(0, 1000))


flows_tt <- df %>%
  select(tt, matches(flows)) %>% 
  filter(between(tt, -6, 5)) %>%
  pivot_longer(matches(flows)) %>%
  mutate(name = factor(
    name, 
    levels = c("inflows", "outflows", "netflows"), 
    labels = c("Inflows", "Outflows", "Netflows")
  )) %>% 
  ggplot(aes(tt, value, colour = name, shape = name)) +
  geom_point(stat = "summary", fun = "mean") +
  labs(x = "Time to app use", y = "Amount (£)", colour = NULL, shape = NULL) +
  theme(
    legend.position = "bottom",
    legend.text = element_text(size = 12)
  )



# Combine plots and add legend

p <- plot_grid(
  inflow_amounts + theme(legend.position = "none"),
  flows_tt + theme(legend.position = "none"),
  labels = "AUTO",
  label_x = 0,
  label_y = 0,
  hjust = -0.5, vjust = -1
)

legend <- get_legend(flows_tt)
plot_grid(p, legend, ncol = 1, rel_heights = c(1, .1))


figname <- 'savings_patterns.png'
ggsave(
  file.path(FIGDIR, figname),
  height = 1000,
  width = 2000,
  units = "px"
)
