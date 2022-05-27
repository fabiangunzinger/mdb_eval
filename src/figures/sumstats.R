library(stargazer)
library(glue)
library(stringr)

source('./helpers/helpers.R')

df = read_analysis_data()


stargazer(
  df,
  summary.stat = c('mean', 'sd', 'min', 'p25', 'median', 'p75', 'max'),
  title = 'Summary statistics',
  label = 'tab:sumstats',
  font.size = 'tiny',
  out = file.path(TABDIR, 'sumstats.tex')
)
