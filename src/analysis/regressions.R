library(dplyr)
library(fixest)
library(glue)
library(gridExtra)
library(lubridate)

source('./src/config.R')
source('./src/helpers/fixest_settings.R')
source('./src/helpers/helpers.R')


df <- read_analysis_data()

setFixest_fml(
  ..ds = ~ i(tt, -1, bin=list("<-6" = -35:-6, ">5" = 6:25)),
  ..controls = ~month_income + month_spend + accounts_active,
  ..fe = ~ym + user_id,
  ..mvfe = ~mvsw(ym, user_id)
)

names(df)
# Static models -------------------------------------------------------------------

title <- 'Static results'
label <- "reg_static"
m_static <- feols(c(netflows, discret_spend) ~ t + ..controls | ..mvfe, df)
etable(m_static,
       title = title,
       order = c("App use", "!Intercept"),
       tex = T,
       fontsize = 'tiny',
       file=file.path(TABDIR, glue('{label}.tex')),
       label = glue('tab:{label}'),
       replace = T
)





# Dynamic models ------------------------------------------------------------------

title <- 'Dynamic results'
label <- "reg_dynamic"
m_dynamic <- feols(c(netflows, discret_spend) ~ ..ds + ..controls | ..mvfe, df)
etable(m_dynamic,
       title = title,
       order = c("App use", "!Intercept"),
       tex = T,
       fontsize = 'tiny',
       file=file.path(TABDIR, glue('{label}.tex')),
       label = glue('tab:{label}'),
       replace = T
)
figure(glue('{label}.png'), width = 2000, height = 2000, pointsize=30)
par(mfrow=c(2,1))
fiplot(m_dynamic[1:4])
legend(
  "topleft",
  col = c(1, 2, 4, 3),
  pch = c(20, 15, 17, 21),
  legend = c(
    "Controls",
    "Controls and year-month FEs",
    "Controls and user FE",
    "Controls and year-month and user FEs"
  )
)
fiplot(m_dynamic[5:8])
legend(
  "bottomright",
  col = c(1, 2, 4, 3),
  pch = c(20, 15, 17, 21),
  legend = c(
    "Controls",
    "Controls and year-month FEs",
    "Controls and user FE",
    "Controls and year-month and user FEs"
  )
)
dev.off()


# Decomposing inflows and outflows ------------------------------------------------

title <- 'Decomposing inflows and outflows'
label <- "reg_decomp_inout"
reg_decomp_inout <- feols(c(netflows, inflows, outflows) ~ ..ds + ..controls | ..fe, df)
etable(reg_decomp_inout,
       title = title,
       order = c("App use", "!Intercept"),
       tex = T,
       fontsize = 'tiny',
       file=file.path(TABDIR, glue('{label}.tex')),
       label = glue('tab:{label}'),
       replace = T
)
figure(glue('{label}.png'), width = 2000, height = 3000, pointsize=70)
par(mfrow=c(3,1))
fiplot(reg_decomp_inout[1])
fiplot(reg_decomp_inout[2])
fiplot(reg_decomp_inout[3])
dev.off()


# Decomposing intensive and extensive margin --------------------------------------

title <- 'Decomposing intensive and extensive margin'
label <- "reg_decomp_intext"
reg_decomp_intext <- feols(c(pos_netflows, has_pos_netflows) ~ ..ds + ..controls | ..fe, df)
etable(reg_decomp_intext,
       title = title,
       order = c("App use", "!Intercept"),
       tex = T,
       fontsize = 'tiny',
       file=file.path(TABDIR, glue('{label}.tex')),
       label = glue('tab:{label}'),
       replace = T
)

figure(glue('{label}.png'), width = 2000, height = 2000, pointsize=50)
par(mfrow=c(2,1))
fiplot(reg_decomp_intext[1])
fiplot(reg_decomp_intext[2])
dev.off()


# Sun & Abraham estimator ---------------------------------------------------------

#tbd