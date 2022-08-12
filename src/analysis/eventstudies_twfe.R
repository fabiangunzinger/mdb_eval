library(dplyr)
library(fixest)
library(glue)
library(gridExtra)
library(lubridate)

source('./src/config.R')
source('./src/helpers/fixest_settings.R')
source('./src/helpers/helpers.R')

df <- read_analysis_data()
names(df)

# Duplicate time to treatment variable as x for fixest indicator binning
df$x <- df$tt

# Define fixest variable macros
setFixest_fml(
  ..ds = ~i(tt, ref = -1, bin = .("-6" = ~x <= -6, "5" = ~x >= 5)),
  ..controls = ~month_income + month_spend + accounts_active,
  ..fe = ~user_id + ym,
  ..mvfe = ~mvsw(user_id, ym)
)



# Dev -----------------------------------------------------------------------------

# Anomaly: length of pre window changes estimates for post window
m1 <- feols(dspend ~ i(tt, ref = -1, bin = .("-6" = ~x <= -6, "11" = ~x >= 11)) + ..controls | user_id + ym, df)
m2 <- feols(dspend ~ i(tt, ref = -1, bin = .("-12" = ~x <= -12, "11" = ~x >= 11)) + ..controls | user_id + ym, df)
iplot(list(m2, m1))
etable(m1, m2)


# Hypothesis: sample issue

## Check that each user has required leads and lags
num_users <- n_distinct(df$user_id)
tt_counts <- df %>% 
  filter(between(tt, -6, 5)) %>% 
  group_by(tt) %>% 
  count() 
min_count <- min(tt_counts$n)
stopifnot(min_count == num_users)

## Run models with available leads and lags
m1 <- feols(dspend ~ i(tt, ref = -1, bin = .("-6" = ~x <= -6, "5" = ~x >= 5)) + ..controls | user_id + ym, df)
m2 <- feols(dspend ~ i(tt, ref = -1, bin = .("-3" = ~x <= -3, "5" = ~x >= 5)) + ..controls | user_id + ym, df)
iplot(list(m1, m2))
etable(m1, m2)

## Explore data used for estimation
m1_obs <- obs(m1)
data <- df %>% slice(m1_obs)
data %>%
  filter(between(tt, -6, 5)) %>% 
  group_by(tt) %>% 
  count()


## Estimates without binning
m1 <- feols(dspend ~ i(tt) + ..controls, df)
m2 <- feols(dspend ~ i(tt) + ..controls, df)
iplot(list(m1, m2))
etable(m1, m2)


## Estimates without FEs
m1 <- feols(dspend ~ i(tt, ref = -1, bin = .("-6" = ~x <= -6, "5" = ~x >= 5)) + ..controls, df)
m2 <- feols(dspend ~ i(tt, ref = -1, bin = .("-3" = ~x <= -3, "5" = ~x >= 5)) + ..controls, df)
iplot(list(m1, m2))
etable(m1, m2)




# Main results --------------------------------------------------------------------

m <- feols(dspend ~ ..ds + ..controls | ..fe, df)
png(file.path(FIGDIR, 'dspend_main.png'), width = 2000, height = 1500, pointsize=60)
fiplot(m)
dev.off()

m <- feols(netflows ~ ..ds + ..controls | ..fe, df)
png(file.path(FIGDIR, 'netflows_main.png'), width = 2000, height = 1500, pointsize=60)
fiplot(m)
dev.off()


# Decomposing intensive and extensive margin --------------------------------------

has_pos_netflows <- feols(has_pos_netflows ~ ..ds + ..controls | ..fe, df)
png(file.path(FIGDIR, 'has_pos_netflows.png'), width = 2000, height = 1500, pointsize=60)
fiplot(has_pos_netflows)
dev.off()

pos_netflows <- feols(pos_netflows ~ ..ds + ..controls | ..fe, df)
png(file.path(FIGDIR, 'pos_netflows.png'), width = 2000, height = 1500, pointsize=60)
fiplot(pos_netflows)
dev.off()

dspend_count <- feols(dspend_count ~ ..ds + ..controls | ..fe, df)
png(file.path(FIGDIR, 'dspend_count.png'), width = 2000, height = 1500, pointsize=60)
fiplot(dspend_count)
dev.off()

dspend_mean <- feols(dspend_mean ~ ..ds + ..controls | ..fe, df)
png(file.path(FIGDIR, 'dspend_mean.png'), width = 2000, height = 1500, pointsize=60)
fiplot(dspend_mean)
dev.off()

label <- 'intext'
etable(has_pos_netflows, pos_netflows, dspend_count, dspend_mean,
       title = "Intensive and extensive margins",
       order = c("App use", "!Intercept"),
       tex = T,
       fontsize = 'tiny',
       file=file.path(TABDIR, glue('{label}.tex')),
       label = glue('tab:{label}'),
       replace = T
)


# Decomposing inflows and outflows ------------------------------------------------

netflows <- feols(netflows ~ ..ds + ..controls | ..fe, df)
png(file.path(FIGDIR, 'netflows.png'), width = 2000, height = 1500, pointsize=60)
fiplot(netflows)
dev.off()

inflows <- feols(inflows ~ ..ds + ..controls | ..fe, df)
png(file.path(FIGDIR, 'inflows.png'), width = 2000, height = 1500, pointsize=60)
fiplot(inflows)
dev.off()

outflows <- feols(outflows ~ ..ds + ..controls | ..fe, df)
png(file.path(FIGDIR, 'outflows.png'), width = 2000, height = 1500, pointsize=60)
fiplot(outflows)
dev.off()

title <- 'Decomposing inflows and outflows'
label <- "inout"
etable(netflows, inflows, outflows,
       title = title,
       order = c("App use", "!Intercept"),
       tex = T,
       fontsize = 'tiny',
       file=file.path(TABDIR, glue('{label}.tex')),
       label = glue('tab:{label}'),
       replace = T
)

# Alternative FE specifications ----------------------------------------------------

m <- feols(dspend ~ ..ds + ..controls | ..mvfe, df)
etable(m,
       title = "Alternative model specifications",
       order = c("App use", "!Intercept"),
       tex = T,
       fontsize = 'tiny',
       file=file.path(TABDIR, 'dspend_alt.tex'),
       label = glue('tab:dspend_alt'),
       replace = T
)
png(file.path(FIGDIR, 'dspend_alt.png'), width = 2000, height = 1500, pointsize=60)
fiplot(m)
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


m <- feols(netflows ~ ..ds + ..controls | ..mvfe, df)
etable(m,
       title = "Alternative model specifications",
       order = c("App use", "!Intercept"),
       tex = T,
       fontsize = 'tiny',
       file=file.path(TABDIR, 'netflows_alt.tex'),
       label = glue('tab:netflows_alt'),
       replace = T
)
png(file.path(FIGDIR, 'netflows_alt.png'), width = 2000, height = 1500, pointsize=60)
fiplot(m)
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




# Static models -------------------------------------------------------------------

title <- 'Static results'
label <- "static"
m_static <- feols(c(netflows, dspend) ~ t + ..controls | ..mvfe, df)
etable(m_static,
       title = title,
       order = c("App use", "!Intercept"),
       tex = T,
       fontsize = 'tiny',
       file=file.path(TABDIR, glue('{label}.tex')),
       label = glue('tab:{label}'),
       replace = T
)



# Subgroups -----------------------------------------------------------------------

# is_female
# generation
# month_income quartile (pre signup)
# netflows quartile (pre signup)
# dspend quartile (pre_signup)



