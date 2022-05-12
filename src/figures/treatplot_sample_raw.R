Sys.setenv(AWS_PROFILE='3di', AWS_DEFAULT_REGION='eu-west-2')
source('./src/figures/fig_settings.R')

library(aws.s3)
library(arrow)
library(dplyr)
library(ggplot2)
library(PanelMatch)

fp <- 's3://3di-project-eval/eval_111.parquet'
df <- data.frame(aws.s3::s3read_using(arrow::read_parquet, object=fp))


sample_size <- 83
dfs <- df %>% filter(user_id %in% sample(unique(user_id), sample_size))

DisplayTreatment(
  data = dfs,
  unit.id = "user_id",
  time.id = "ym",
  treatment = "t",
  legend.position = "right",
  xlab = "Year-months",
  ylab = "User",
  # color.of.treated = treat_col,
  # color.of.untreated = untreat_col,
  x.size = 5
)

ggsave(file.path(FIGDIR, 'treatplot_sample_raw'))