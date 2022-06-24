library(dplyr)
library(ggplot2)
library(gridExtra)
library(PanelMatch)

source('./src/config.R')
source('./src/helpers/helpers.R')


df <- read_analysis_data()

# Specify covariates as vector and fml
covs <- c("month_income", "month_spend", "discret_spend", "is_female",
          "generation_code", "is_urban", "accounts_active")
fml <- reformulate(covs)

# Perform matching
pm_ps_nn <- PanelMatch(
  data = df,
  time.id = "ym",
  unit.id = "user_id",
  treatment = "t",
  outcome.var = "netflows",
  lag = 5,
  lead = 0:5,  
  qoi = "att",
  forbid.treatment.reversal = T,
  refinement.method = "ps.match",
  covs.formula = fml,
  size.match = 1
  )


# Frequency distribution of matched sets
set_sizes <- summary(pm_ps_nn$att)$overview$matched.set.size
png(
  file.path(FIGDIR, "hist_matchset_size.png"),
  width     = 10,
  height    = 6,
  units     = "cm",
  res       = 1200,
  pointsize = 6
)
plot(pm_ps_nn$att, main = NULL)
dev.off()


# Inspect covariate balance 1
ylim <- c(-1, 1)
png(
  file.path(FIGDIR, "covar_balance.png"),
  width     = 12,
  height    = 6,
  units     = "cm",
  res       = 1200,
  pointsize = 6
)
par(mfrow=c(1,2))
get_covariate_balance(
  pm_ps_nn$att,
  data = df,
  use.equal.weights = T,
  covariates = covs,
  plot = T,
  ylim = ylim
)
get_covariate_balance(
  pm_ps_nn$att,
  data = df,
  use.equal.weights = F,
  covariates = covs,
  plot = T,
  ylim = ylim
)
dev.off()


# Check for parallel pre-treatment trend assumption
# tbd


# Estimates
pe <- PanelEstimate(sets = pm_ps_nn, data = df)
summary(pe)
png(
  file.path(FIGDIR, "match_estimates.png"),
  width     = 12,
  height    = 6,
  units     = "cm",
  res       = 1200,
  pointsize = 6
)
plot(pe, main = NULL)
dev.off()


# Visualise matchset examples

disptreat <- function(matched_set) {
  DisplayTreatment(
    data = df,
    unit.id = "user_id",
    time.id = "ym",
    treatment = "t",
    legend.position = "right",
    xlab = "Year-months",
    ylab = "User",
    hide.x.axis.label = T,
    hide.y.axis.label = T,
    matched.set = mset,
    show.set.only = T,
  ) + labs(title = "") + theme(legend.position = "none") 
}
a <- disptreat(pm_ps_nn$att[100])
b <- disptreat(pm_ps_nn$att[200])
g <- arrangeGrob(a, b, ncol = 2)
ggsave(file = file.path(FIGDIR, 'matchset_examples_new.png'), g)
