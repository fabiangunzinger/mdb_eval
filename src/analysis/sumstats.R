library(stargazer)

source('./src/config.R')
source('./src/helpers/helpers.R')


df = read_analysis_data()


tabname <- 'sumstats.tex'
stargazer(
  df,
  summary.stat = c('mean', 'sd', 'min', 'p25', 'median', 'p75', 'max'),
  digits = 1,
  title = 'Summary statistics',
  label = 'tab:sumstats',
  font.size = 'footnotesize',
  table.placement = "H",
out = file.path(TABDIR, tabname)
)

