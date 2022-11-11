# 
# Code to produce summary statistics table
# 


library(stargazer)

source('./src/config.R')
source('./src/helpers/helpers.R')


df = read_analysis_data()


vars <- c(
  "^txns_count$",
  "^month_income$",
  "^inflows$",
  "^outflows$",
  "^netflows$",
  "^month_spend$", 
  "^age$",
  "^is_female$", 
  "^is_urban$",
  "^dspend$",
  "accounts_active"
  )

varlabs <- c(
  "Txn count",
  "Month income (\\pounds)",
  "Savings account inflows (\\pounds)",
  "Savings account outflows (\\pounds)",
  "Savings account netflows (\\pounds)",
  "Month spend (\\pounds)", 
  "Age",
  "Female dummy", 
  "Urban dummy",
  "Active accounts",
  "Discretionary spend (\\pounds)"
)

# Workaround to handle pounds sign. See link below.
# https://github.com/markwestcott34/stargazer-booktabs/issues/3
tab <- stargazer(
  df,
  summary.stat = c('mean', 'sd', 'min', 'p25', 'median', 'p75', 'max'),
  digits = 2,
  keep = vars,
  covariate.labels = varlabs,
  float = FALSE
)
tabname <- 'sumstats.tex'
cat(tab, sep = '\n', file = file.path(TABDIR, tabname))





