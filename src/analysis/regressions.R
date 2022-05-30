library(dplyr)
library(fixest)
library(gridExtra)
library(lubridate)

source('./helpers/helpers.R')
source('./helpers/fixest_settings.R')

df <- read_analysis_data() %>%
  filter(between(tt, -6, 12)) %>%
  mutate(treat = 1, month=month(ym(ymn), label = T))


setFixest_fml(
  ..controls = ~month_income + month_spend + disc_spend + is_female + i(generation, "Boomers"),
  ..fe = ~user_id + month
)

fcoefplot <- function(model, ...) {
  coefplot(
    model,
    lab.fit = "tilted",
    ylab = 'Change in __depvar__',
    main = "",
    col = c(1, 2, 4, 3, 5, 6, 7, 8),
    pt.pch = c(20, 15, 17, 21, 24, 22),
    ...
  )
}

fiplot <- function(model, ...) {
  iplot(
    model,
    ylab = 'Change in __depvar__',
    main = "",
    col = c(1, 2, 4, 3, 5, 6, 7, 8),
    pt.pch = c(20, 15, 17, 21, 24, 22),
    ...
  )
  
}


# Naive pre-post comparison
figname <- 'reg_naive_pre_post.png'
m_stat_nv <- feols(netflows ~ t, df)
m_dynam_nv <- feols(netflows ~ i(tt, 0), df)
etable(m_stat_nv, m_dynam_nv)
figure(figname)
par(mfrow=c(1, 2))
fiplot(m_dynam_nv)
fcoefplot(m_stat_nv)
dev.off()

# Adding controls
figname <- 'reg_controls.png'
m_stat_ctrl <- feols(netflows ~ t + ..controls, df)
m_dynam_ctrl <- feols(netflows ~ i(tt, 0) + ..controls, df)
etable(m_stat_ctrl, m_dynam_ctrl)
figure(figname)
par(mfrow=c(1, 2))
fiplot(m_dynam_ctrl)
fcoefplot(m_stat_ctrl)
dev.off()

# Adding FEs
figname <- 'reg_twfe.png'
m_stat_twfe <- feols(netflows ~ t + ..controls | ..fe, df)
m_dynam_twfe <- feols(netflows ~ i(tt, 0) + ..controls | ..fe, df)
etable(m_stat_twfe, m_dynam_twfe)
figure(figname)
par(mfrow=c(1, 2))
fiplot(m_dynam_twfe)
fcoefplot(m_stat_twfe)
dev.off()

# Comparison plots
figname <- "reg_comparison.png"
figure(figname, height=2000, width=2000)
par(mfrow=c(2, 1))
fiplot(list(m_dynam_nv, m_dynam_ctrl, m_dynam_twfe))
legend("topleft", col = c(1, 2, 4), pch = c(20, 15, 17), 
       legend = c("Naive", "Controls", "TWFE"))
fcoefplot(list(m_stat_nv, m_stat_ctrl, m_stat_twfe))
legend("topleft", col = c(1, 2, 4), pch = c(20, 15, 17), 
       legend = c("Naive", "Controls", "TWFE"))

dev.off()

