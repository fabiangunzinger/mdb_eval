library(dplyr)
library(fixest)
library(gridExtra)
library(lubridate)

source('./helpers/helpers.R')
source('./helpers/fixest_settings.R')

df <- read_analysis_data() %>%
  filter(between(tt, -6, 12))


setFixest_fml(
  ..controls = ~month_income + month_spend + discret_spend + is_female + i(generation, "Boomers") + region_code + num_accounts,
  ..fe = ~user_id + month,
  ..mvfe = ~mvsw(user_id, month)
)

# Simple pre-post comparison
figname <- 'reg_pre_post.png'
m_stat_pp <- feols(netflows ~ t, df)
m_dynam_pp <- feols(netflows ~ i(tt, 0), df)
etable(m_stat_pp, m_dynam_pp)
figure(figname)
par(mfrow=c(1, 2))
fiplot(m_dynam_pp)
fcoefplot(m_stat_pp)
dev.off()

# Adding FEs
figname <- 'reg_twfe.png'
m_stat_twfe <- feols(netflows ~ t + ..controls | ..mvfe, df)
m_dynam_twfe <- feols(netflows ~ i(tt, 0) + ..controls | ..mvfe, df)
etable(m_stat_twfe)
etable(m_dynam_twfe)
figure(figname)
par(mfrow=c(1, 2))
fiplot(m_dynam_twfe)
fcoefplot(m_stat_twfe)
dev.off()

# Comparison plots
figname <- "reg_comparison.png"
figure(figname, height=2000, width=2000)
par(mfrow=c(2, 1))
fiplot(list(m_dynam_pp, m_dynam_twfe))
# legend("topleft", col = c(1, 2, 4), pch = c(20, 15, 17), 
       # legend = c("Pre-post", "TWFE"))
fcoefplot(list(m_stat_pp, m_stat_twfe), keep="App use")
# legend("topleft", col = c(1, 2, 4), pch = c(20, 15, 17), 
       # legend = c("Pre-post", "TWFE"))
dev.off()

# Decompose net-inflows
m_dynam_twfe_net <- feols(netflows ~ i(tt, 0) + ..controls | ..fe, df)
m_dynam_twfe_in <- feols(inflows ~ i(tt, 0) + ..controls | ..fe, df)
m_dynam_twfe_out <- feols(outflows ~ i(tt, 0) + ..controls | ..fe, df)
fiplot(list(m_dynam_twfe_net, m_dynam_twfe_in, m_dynam_twfe_out))

# Decompose internal vs external margin
m_dynam_twfe_int <- feols(pos_netflows ~ i(tt, 0) + ..controls | ..fe, df)
m_dynam_twfe_ext <- feols(has_pos_netflows ~ i(tt, 0) + ..controls | ..fe, df)
fiplot(m_dynam_twfe_int)
fiplot(m_dynam_twfe_ext)


# Tables
tabname <- "reg_compare.tex"
etable(m_stat_pp, m_stat_twfe,
  title = 'Regression results',
  order = c("App use", "!Intercept"),
  tex = T,
  fontsize = 'tiny',
  file=file.path(TABDIR, tabname),
  label = glue('tab:reg_compare'),
  replace = T
)

etable(m_stat_pp, m_stat_twfe,
       title = 'Regression results',
       order = c("App use", "!Intercept")
)
