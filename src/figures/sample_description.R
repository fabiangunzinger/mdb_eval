library(dplyr)
library(ggplot2)
library(ggthemr)
library(patchwork)

source('./src/config.R')
source('./src/helpers/helpers.R')

ggthemr('fresh')
theme_set(theme_minimal())


df <- read_analysis_data()

gender <- df %>% 
  group_by(user_id) %>%
  summarise(gender = first(is_female)) %>%
  mutate(gender = factor(gender, labels = c("Male", "Female"))) %>% 
  ggplot() +
  geom_bar(aes(x = gender, y = (..count..) / sum(..count..))) +
  scale_y_continuous(labels = scales::percent, name = 'Percent') +
  xlab('')

year_income <- df %>% 
  group_by(user_id) %>%
  summarise(year_income = first(month_income) * 12) %>% 
  ggplot() +
  geom_density(aes(year_income)) +
  scale_x_continuous(labels = scales::comma) +
  labs(x = 'Annual income (£)', y = 'Density')

age <- df %>% 
  group_by(user_id) %>% 
  summarise(age = first(age)) %>%
  filter(!is.na(age)) %>% 
  ggplot() +
  geom_density(aes(age)) +
  labs(x = "Age", y = "Density")

region <- df %>%
  group_by(user_id) %>% 
  summarise(region = first(region)) %>% 
  count(region) %>%
  mutate(region = tools::toTitleCase(region), prop = n / sum(n)) %>% 
  ggplot() +
  geom_bar(aes(y = reorder(region, prop), x = prop), stat = "identity") +
  scale_x_continuous(labels = scales::percent) +
  labs(x = 'Percent', y = 'Region')


year_income + age + gender + region

figname <- 'sample_description.png'
ggsave(
  file.path(FIGDIR, figname),
  height = 2000,
  width = 3000,
  units = "px"
)
