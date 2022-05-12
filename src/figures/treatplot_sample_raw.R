Sys.setenv(AWS_PROFILE='3di', AWS_DEFAULT_REGION='eu-west-2')
source('./src/figures/fig_settings.R')

library(aws.s3)
library(arrow)
library(dplyr)
library(ggplot2)
library(gridExtra)
library(PanelMatch)

fp <- 's3://3di-project-eval/eval_XX1.parquet'
df <- data.frame(aws.s3::s3read_using(arrow::read_parquet, object=fp))


dfs <- df %>% filter(user_id %in% sample(unique(user_id), sample_size))

DisplayTreatment(
  data = dfs,
  unit.id = "user_id",
  time.id = "ym",
  treatment = "t",
  legend.position = "right",
  xlab = "Year-months",
  ylab = "User",
  hide.x.axis.label = T,
  hide.y.axis.label = T
)





ADis <- DisplayTreatment(unit.id = "wbcode2",
                         time.id = "year", 
                         xlab = "Year", ylab = "Countries", legend.position = "bottom",
                         legend.labels = c("Autocracy (Control)", "Democracy (Treatment)"),
                         title = "Democracy as the Treatment",
                         treatment = "dem", data = d2) + 
  theme(axis.text.y = element_blank(), axis.ticks.y = element_blank(),
        axis.text.x = element_text(angle=0, size = 6.5, vjust=0.5)) + 
  scale_y_discrete(breaks = c(1960, 1970, 1980, 1990, 2000, 2010))



SDis <- DisplayTreatment(unit.id = "name", 
                         time.id = "year", legend.position = "bottom",
                         xlab = "Year", ylab = "Countries",
                         legend.labels = c("Peace (Control)", "War (Treatment)"),
                         y.size = 10,
                         title = "War as the Treatment",
                         treatment = "himobpopyear2p", data = d3) + 
  theme(axis.text.x = element_text(angle=0, size = 6.5, vjust=0.5), 
        axis.ticks.y = element_blank()) + 
  scale_y_discrete(breaks = c(1850, 1900, 1950, 2000))
g <- arrangeGrob(ADis, SDis, ncol = 2)

ggsave(file = "Figure1.pdf", height = 6, width = 10,
       g, path = OUT_DIR)

