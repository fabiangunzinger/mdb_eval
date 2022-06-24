library(cowplot)
library(dplyr)
library(ggplot2)
library(lubridate)
library(patchwork)

source('./src/config.R')
source('./src/helpers/helpers.R')

theme_set(theme_minimal())

df <- read_analysis_data()
names(df)

app_lcfs_data <- df %>% 
  filter(ymn == 201904) %>% 
  transmute(
    yr_income = month_income * 12,
    yr_spend = month_spend * 12,
    source = 'APP'
  ) %>% 
  bind_rows(read_lcfs())


year_income <- app_lcfs_data %>% 
  ggplot() +
  geom_density(aes(yr_income, color = source), alpha = 0.2) +
  scale_x_continuous(labels = scales::comma) +
  labs(x = 'Disposable income (£) in 2019', y = 'Density', color = "") +
  scale_colour_brewer(palette = palette) +
  theme(legend.position = c(0.9, 0.9))


year_spend <- app_lcfs_data %>% 
  ggplot() +
  geom_density(aes(yr_spend, color = source), alpha = 0.2) +
  scale_x_continuous(labels = scales::comma) +
  labs(x = 'Total spend (£) in 2019', y = 'Density', color = "") +
  scale_colour_brewer(palette = palette) +
  coord_cartesian(xlim = c(0, 125000)) +
  theme(legend.position = c(0.9, 0.9))


gender <- df %>% 
  group_by(user_id) %>%
  summarise(gender = first(is_female)) %>%
  mutate(gender = factor(gender, labels = c("Male", "Female"))) %>% 
  ggplot() +
  geom_bar(aes(x = gender, y = (..count..) / sum(..count..)), fill = single_col) +
  scale_y_continuous(labels = scales::percent) +
  labs(x = "", y = "Percent")


age <- df %>% 
  group_by(user_id) %>% 
  summarise(age = first(age)) %>%
  group_by(age) %>% 
  summarise(n = n()) %>% 
  ggplot() +
  geom_point(aes(age, n / sum(n)), colour = single_col) +
  scale_y_continuous(labels = scales::percent) +
  labs(x = "Age", y = "Percent")


region <- df %>%
  group_by(user_id) %>% 
  summarise(region = first(region)) %>% 
  count(region) %>%
  mutate(region = tools::toTitleCase(region), prop = n / sum(n)) %>% 
  ggplot() +
  geom_bar(aes(y = reorder(region, prop), x = prop), stat = "identity", fill = single_col) +
  scale_x_continuous(labels = scales::percent) +
  labs(x = 'Percent', y = 'Region')


active_accounts <- df %>% 
  group_by(user_id) %>% 
  summarise(accounts_active = first(accounts_active)) %>% 
  ggplot() +
  scale_colour_brewer(palette = palette) +
  geom_bar(aes(factor(accounts_active)), fill = single_col) +
  labs(x = "Number of active accounts (by month)", y = "Count")


plot_grid(
  year_income, year_spend, age, gender, region, active_accounts,
  labels = "AUTO",
  ncol = 2
)

figname <- 'sample_description.png'
ggsave(
  file.path(FIGDIR, figname),
  height = 2000,
  width = 3000,
  units = "px"
)



