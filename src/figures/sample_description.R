library(dplyr)
library(ggplot2)
library(ggthemr)
library(patchwork)

source('./src/helpers/helpers.R')
source('./src/figures/fig_settings.R')

ggthemr('fresh')
theme_set(theme_minimal())


df <- read_analysis_data()
# df <- read_s3parquet('s3://3di-project-eval/eval_0.parquet')

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


reorder_size <- function(x) {
  factor(x, levels = names(sort(table(x))))
}

region <- df %>%
  group_by(user_id) %>% 
  summarise(region = first(region_name)) %>% 
  mutate(region = tools::toTitleCase(region)) %>% 
  ggplot() +
  geom_bar(aes(y = reorder_size(region), x = (..count..) / sum(..count..))) +
  scale_x_continuous(labels = scales::percent) +
  labs(x = 'Percent', y = 'Region')


year_income + age + gender + region
ggsave(file.path(FIGDIR, 'sample_description.png'))
