library(dplyr)
library(ggplot2)
library(gridExtra)
library(fixest)

source('./helpers/helpers.R')
source('./helpers/fixest_settings.R')

df <- read_s3parquet('s3://3di-project-eval/eval.parquet')
df <- df %>%
  filter(between(tt, -6, 6)) %>%
  mutate(treat=1)



setFixest_fml(
  ..endog = ~netflows_norm,
  ..exog = ~t,
  ..controls = ~month_income + month_spend + is_female + is_urban + i(generation),
  ..fe = ~user_id + ym
)

# Simple pre-post comparison

est <- feols(netflows ~ t, df)
coefplot(est)
etable(est)

est <- feols(netflows ~ i(tt, treat, 0), data=data)
est <- feols(netflows ~ i(tt), data=data)

png("~/test.png")
iplot(est)
dev.off()



etable(
  est
  # title = 'Components exploration'
  # order = c('[Ee]ntropy', 'Average', 'Cnz', 'Counts std')
  # drop = c('spend_')
  # ,
  # notes = c(note),
  # tex = T,
  # fontsize = 'tiny',
  # file=file.path(TABDIR, glue('reg_has_sa_inflows_explore.tex'))
  # label = glue('tab:reg_has_sa_inflows_explore'),
  # replace = T
)


