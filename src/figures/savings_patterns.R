library(cowplot)
library(tidyverse)
library(lubridate)

source('./src/config.R')
source('./src/helpers/helpers.R')

theme_set(theme_minimal())


df <- read_analysis_data()


flows <- "^(in|out|net)flows$"

flows_month <- df %>%
  select(month, matches(flows)) %>% 
  pivot_longer(matches(flows)) %>% 
  ggplot(aes(factor(month), value, colour = name, shape = name)) +
  geom_point(stat = "summary", fun = "mean") +
  scale_colour_brewer(palette = palette) +
  labs(x = "Month", y = "Amount (£)", colour = NULL, shape = NULL) +
  theme(
    legend.position = "bottom",
    legend.text = element_text(size = 12)
  )

flows_tt <- df %>% 
  select(tt, matches(flows)) %>% 
  filter(between(tt, -6, 5)) %>%
  pivot_longer(matches(flows)) %>%
  ggplot(aes(tt, value, colour = name, shape = name)) +
  geom_point(stat = "summary", fun = "mean") +
  scale_colour_brewer(palette = palette) +
  labs(x = "Time to/since beginning of app use", y = "Amount (£)")


# flows_day <- df %>%
#   select(matches("^(in|out)_..?$")) %>% 
#   pivot_longer(everything()) %>% 
#   separate(name, c("flow", "dow"), "_", convert = T) %>% 
#   ggplot() +
#   geom_point(
#     aes(dow, value, colour = flow, shape = flow),
#     stat = "summary", fun = "mean"
#   ) +
#   coord_cartesian(ylim = c(0, 70)) +
#   scale_colour_brewer(palette = palette) +
#   labs(x = "Day of month", y = "Amount (£)")


# inflow_amounts <- df %>% 
#   select(matches(flows)) %>% 
#   pivot_longer(everything()) %>% 
#   filter(name == "inflows", between(value, 1, 10000)) %>%
#   group_by(name, value) %>% 
#   ggplot() +
#   geom_bar(aes(value, color = name), group = "dodge") +
#   scale_colour_brewer(palette = palette) +
#   scale_x_continuous(breaks = seq(0, 1000, 100)) +
#   labs(x = "Amount (£)", y = "Number of transactions") +
#   coord_cartesian(xlim = c(0, 1000))


# Combine plots and add legend

p <- plot_grid(
  flows_month + theme(legend.position = "none"),
  # flows_day + theme(legend.position = "none"),
  flows_tt + theme(legend.position = "none"),
  # inflow_amounts + theme(legend.position = "none"),
  labels = "AUTO",
  label_x = 0,
  label_y = 0,
  hjust = -0.5, vjust = -1
)

legend <- get_legend(flows_month)
plot_grid(p, legend, ncol = 1, rel_heights = c(1, .1))


figname <- 'savings_patterns.png'
ggsave(
  file.path(FIGDIR, figname),
  height = 1000,
  width = 2000,
  units = "px"
)
