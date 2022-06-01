library(dplyr)
library(ggplot2)
library(PanelMatch)

source('./src/config.R')
source('./src/helpers/helpers.R')


df <- read_analysis_data()


sample_size <- 200
dfs <- filter(df, user_id %in% sample(unique(user_id), sample_size))
xticks <- c(201206, 201306, 201406, 201506, 201606, 201706, 201806, 201906, 202006)
xlabs <- c("2012", "2013", "2014", "2015", "2016", "2017", "2018", "2019", "2020")

DisplayTreatment(
  data = dfs,
  unit.id = "user_id",
  time.id = "ymn",
  treatment = "t",
  legend.position = "bottom",
  xlab = "Year-months",
  ylab = "User",
  legend.labels = c("Not using app (control)", "Using app (treatment)"),
  title = ""
  ) +
  theme(
    axis.text.y = element_blank(),
    axis.ticks.y = element_blank(),
    axis.text.x = element_text(angle=0, size=10)
    ) +
  scale_y_discrete(breaks = xticks, labels = xlabs) +
  guides(fill=guide_legend(title=""))

ggsave(file.path(FIGDIR, 'treatplot_sample_raw.png'))
