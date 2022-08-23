library(did)
library(tidyverse)
library(glue)
library(gridExtra)
library(lubridate)

source('./src/config.R')
source('./src/helpers/fixest_settings.R')
source('./src/helpers/helpers.R')


df <- read_analysis_data()
names(df)

cstheme <- theme(
  plot.title = element_text(size = 22, color = "black", hjust = 0.5),
  plot.title.position = "plot",
  panel.grid.major.y = element_line(colour = "snow2"),
  panel.grid.minor.y = element_line(colour = "snow2"),
  axis.title=element_text(size = 20, colour = "black", face = "plain"),
  axis.text = element_text(size = 20),
  legend.text = element_text(size = 20)
)



# Unconditional parallel trends ---------------------------------------------------

## Discretionary spend ##

# Estimate group-time average treatment effects
dspend_uncond_gt <- att_gt(
  yname = "dspend",
  gname = "user_reg_ym",
  idname = "user_id",
  tname = "ym",
  data = df,
  est_method = "reg",
  control_group = "notyettreated",
  allow_unbalanced_panel = T,
  cores = 4
)

dspend_uncond_gt

# Aggregate to event-study parameters
dspend_uncond_es <- aggte(
  dspend_uncond_gt,
  type = "dynamic",
  na.rm = T,
  min_e = -6,
  max_e = 5,
  balance_e = 5
)

# Export plot
ggdid(dspend_uncond_es, ylab = 'Discretionary spend', xlab = "Time since treatment", legend = FALSE, title = "Unconditional parallel trends", ylim = c(-210, 100)) + cstheme
ggsave(glue("{FIGDIR}/dspend_uncond_es.png"))


## Netflows ##

# Estimate group-time average treatment effects
netflows_uncond_gt <- att_gt(
  yname = "netflows",
  gname = "user_reg_ym",
  idname = "user_id",
  tname = "ym",
  data = df,
  est_method = "reg",
  control_group = "notyettreated",
  allow_unbalanced_panel = T,
  cores = 4
)

# Aggregate to event-study parameters
netflows_uncond_es <- aggte(
  netflows_uncond_gt,
  type = "dynamic",
  na.rm = T,
  min_e = -6,
  max_e = 5,
  balance_e = 5
)

# Export plot
ggdid(netflows_uncond_es, ylab = 'Net-inflows into savings accounts', xlab = "Time since treatment", legend = FALSE, title = " ", ylim = c(-450, 300)) + cstheme
ggsave(glue("{FIGDIR}/netflows_uncond_es.png"))


# Conditional parallel paths ------------------------------------------------------

xformla <- ~ month_income + month_spend + accounts_active + age

## Discretionary spend ##

dspend_cond_gt <- att_gt(
  yname = "dspend",
  gname = "user_reg_ym",
  idname = "user_id",
  tname = "ym",
  xformla = xformla,
  data = df,
  est_method = "reg",
  control_group = "notyettreated",
  allow_unbalanced_panel = T,
  cores = 4
)

dspend_cond_es <- aggte(
  dspend_cond_gt,
  type = "dynamic",
  na.rm = T,
  min_e = -6,
  max_e = 5,
  balance_e = 5
)

ggdid(dspend_cond_es, ylab = 'Discretionary spend', xlab = "Time since treatment", legend = FALSE, title = "Conditional parallel trends", ylim = c(-210, 100)) + cstheme
ggsave(glue("{FIGDIR}/dspend_cond_es.png"))


## Netflows ##

netflows_cond_gt <- att_gt(
  yname = "netflows",
  gname = "user_reg_ym",
  idname = "user_id",
  tname = "ym",
  xformla = xformla,
  data = df,
  est_method = "reg",
  control_group = "notyettreated",
  allow_unbalanced_panel = T,
  cores = 4
)

netflows_cond_es <- aggte(
  netflows_cond_gt,
  type = "dynamic",
  na.rm = T,
  min_e = -6,
  max_e = 5,
  balance_e = 5
)

ggdid(netflows_cond_es, ylab = 'Net-inflows into savings accounts', xlab = "Time since treatment", legend = FALSE, title = " ", ylim = c(-450, 300)) + cstheme
ggsave(glue("{FIGDIR}/netflows_cond_es.png"))


# Extensive and intensive margins -------------------------------------------------

## Discretionary spend ##

dspend_extens_gt <- att_gt(
  yname = "dspend_count",
  gname = "user_reg_ym",
  idname = "user_id",
  tname = "ym",
  xformla = xformla,
  data = df,
  est_method = "reg",
  control_group = "notyettreated",
  allow_unbalanced_panel = T,
  cores = 4
)

dspend_extens_es <- aggte(
  dspend_extens_gt,
  type = "dynamic",
  na.rm = T,
  min_e = -6,
  max_e = 5,
  balance_e = 5
)

ggdid(dspend_extens_es, ylab = 'Discretionary spend (# of txns)', xlab = "Time since treatment")
ggsave(glue("{FIGDIR}/dspend_extens_es.png"))


dspend_intens_gt <- att_gt(
  yname = "dspend_mean",
  gname = "user_reg_ym",
  idname = "user_id",
  tname = "ym",
  xformla = xformla,
  data = df,
  est_method = "reg",
  control_group = "notyettreated",
  allow_unbalanced_panel = T,
  cores = 4
)

dspend_intens_es <- aggte(
  dspend_intens_gt,
  type = "dynamic",
  na.rm = T,
  min_e = -6,
  max_e = 5,
  balance_e = 5
)

ggdid(dspend_intens_es, ylab = 'Discretionary spend (mean spend)', xlab = "Time since treatment")
ggsave(glue("{FIGDIR}/dspend_intens_es.png"))

## Netflows ##

netflows_extens_gt <- att_gt(
  yname = "has_pos_netflows",
  gname = "user_reg_ym",
  idname = "user_id",
  tname = "ym",
  xformla = xformla,
  data = df,
  est_method = "reg",
  control_group = "notyettreated",
  allow_unbalanced_panel = T,
  cores = 4
)

netflows_extens_es <- aggte(
  netflows_extens_gt,
  type = "dynamic",
  na.rm = T,
  min_e = -6,
  max_e = 5,
  balance_e = 5
)

ggdid(netflows_extens_es, ylab = 'P(net-inflows > 0)', xlab = "Time since treatment")
ggsave(glue("{FIGDIR}/netflows_extens_es.png"))


netflows_intens_gt <- att_gt(
  yname = "pos_netflows",
  gname = "user_reg_ym",
  idname = "user_id",
  tname = "ym",
  xformla = xformla,
  data = df,
  est_method = "reg",
  control_group = "notyettreated",
  allow_unbalanced_panel = T,
  cores = 4
)

netflows_intens_es <- aggte(
  netflows_intens_gt,
  type = "dynamic",
  na.rm = T,
  min_e = -6,
  max_e = 5,
  balance_e = 5
)

ggdid(netflows_intens_es, ylab = 'Net-inflows if net-inflows > 0', xlab = "Time since treatment")
ggsave(glue("{FIGDIR}/netflows_intens_es.png"))


# Inflows and outflows ------------------------------------------------------------

inflows_cond_gt <- att_gt(
  yname = "inflows",
  gname = "user_reg_ym",
  idname = "user_id",
  tname = "ym",
  xformla = xformla,
  data = df,
  est_method = "reg",
  control_group = "notyettreated",
  allow_unbalanced_panel = T,
  cores = 4
)

inflows_cond_es <- aggte(
  inflows_cond_gt,
  type = "dynamic",
  na.rm = T,
  min_e = -6,
  max_e = 5,
  balance_e = 5
)

ggdid(inflows_cond_es, ylab = 'Inflows', xlab = "Time since treatment")
ggsave(glue("{FIGDIR}/inflows_cond_es.png"))


outflows_cond_gt <- att_gt(
  yname = "outflows",
  gname = "user_reg_ym",
  idname = "user_id",
  tname = "ym",
  xformla = xformla,
  data = df,
  est_method = "reg",
  control_group = "notyettreated",
  allow_unbalanced_panel = T,
  cores = 4
)

outflows_cond_es <- aggte(
  outflows_cond_gt,
  type = "dynamic",
  na.rm = T,
  min_e = -6,
  max_e = 5,
  balance_e = 5
)

ggdid(outflows_cond_es, ylab = 'Outflows', xlab = "Time since treatment")
ggsave(glue("{FIGDIR}/outflows_cond_es.png"))




# Anticipation effects ------------------------------------------------------------

## Discretionary spend ##
antic_periods <- 6

antic_dspend <- vector("list", antic_periods)

for (i in 1:antic_periods) {
  
  # Calculate group-time treatment effects
  antic_gt <- att_gt(
    yname = "dspend",
    gname = "user_reg_ym",
    idname = "user_id",
    tname = "ym",
    xformla = xformla,
    anticipation = i,
    data = df,
    est_method = "reg",
    control_group = "notyettreated",
    allow_unbalanced_panel = T,
    cores = 4
  )
  
  # Aggregate to event-study parameters
  antic_es <- aggte(
    antic_gt,
    type = "dynamic",
    na.rm = T,
    min_e = -6,
    max_e = 5,
    balance_e = 5
  )
  
  # Save results for reuse
  antic_dspend[[i]] <- list(gt = antic_gt, es = antic_es)
  
  # Export plot
  ggdid(antic_es, ylim = c(-200, 100))
  fn <- glue("{FIGDIR}/dspend_antic{i}_es.png")
  ggsave(fn)
}


## Netflows ##

antic_netflows <- vector("list", antic_periods)

for (i in 1:antic_periods) {
  
  # Calculate group-time treatment effects
  antic_gt <- att_gt(
    yname = "netflows",
    gname = "user_reg_ym",
    idname = "user_id",
    tname = "ym",
    xformla = xformla,
    anticipation = i,
    data = df,
    est_method = "reg",
    control_group = "notyettreated",
    allow_unbalanced_panel = T,
    cores = 4
  )
  
  # Aggregate to event-study parameters
  antic_es <- aggte(
    antic_gt,
    type = "dynamic",
    na.rm = T,
    min_e = -6,
    max_e = 5,
    balance_e = 5
  )
  
  # Save results for reuse
  antic_netflows[[i]] <- list(gt = antic_gt, es = antic_es)
  
  # Export plot
  ggdid(antic_es, ylim = c(-200, 100))
  fn <- glue("{FIGDIR}/netflows_antic{i}_es.png")
  ggsave(fn)
}




# Unbalanced aggregation ----------------------------------------------------------

## Discretionary spend ##
## Netflows ##

# Similar to baseline aggregation, but without balance_e parameter.
ub_es <- aggte(
  bl_gt,
  type = "dynamic",
  na.rm = T,
  min_e = -6,
  max_e = 5,
)


ggdid(bl_es, ylim = c(-220, 50))
fn <- glue("{FIGDIR}/bl_es_comp.png")
ggsave(fn)

ggdid(ub_es, ylim = c(-220, 50))
fn <- glue("{FIGDIR}/ub_es.png")
ggsave(fn)




# Group specific effects ----------------------------------------------------------

## Discretionary spend ##
## Netflows ##
gs <- aggte(bl_gt, type = "group", na.rm = TRUE)
ggdid(gs)



# Calendar-time effects -----------------------------------------------------------

## Discretionary spend ##
## Netflows ##
ct <- aggte(bl_gt, type = "calendar", na.rm = TRUE)
ggdid(ct)




# Rambachan and Roth (2021) sensitivity analysis ----------------------------------

## Discretionary spend ##
## Netflows ##
# Based on https://github.com/pedrohcgs/CS_RR


# Install some packages
library(devtools)
install_github("bcallaway11/BMisc", dependencies = TRUE)
install_github("bcallaway11/did", dependencies = TRUE)
install_github("asheshrambachan/HonestDiD", dependencies = TRUE)
#--------------------------------------------------------------------------
# Load packages
#--------------------------------------------------------------------------
# Libraries
# Load libraries
library(ggplot2)
library(here)
library(foreign)
library(tidyverse)
library(dplyr)
library(did)
library(HonestDiD)

#' @title honest_did
#'
#' @description a function to compute a sensitivity analysis
#'  using the approach of Rambachan and Roth (2021)
#' @param es an event study
honest_did <- function(es, ...) {
  UseMethod("honest_did", es)
}


#' @title honest_did.AGGTEobj
#'
#' @description a function to compute a sensitivity analysis
#'  using the approach of Rambachan and Roth (2021) when
#'  the event study is estimating using the `did` package
#'
#' @param e event time to compute the sensitivity analysis for.
#'  The default value is `e=0` corresponding to the "on impact"
#'  effect of participating in the treatment.
#' @param type Options are "smoothness" (which conducts a
#'  sensitivity analysis allowing for violations of linear trends
#'  in pre-treatment periods) or "relative_magnitude" (which
#'  conducts a sensitivity analysis based on the relative magnitudes
#'  of deviations from parallel trends in pre-treatment periods).
#' @inheritParams HonestDiD::createSensitivityResults
#' @inheritParams HonestDid::createSensitivityResults_relativeMagnitudes
honest_did.AGGTEobj <- function(es,
                                e=0,
                                type=c("smoothness", "relative_magnitude"),
                                method=NULL,
                                bound="deviation from parallel trends",
                                Mvec=NULL,
                                Mbarvec=NULL,
                                monotonicityDirection=NULL,
                                biasDirection=NULL,
                                alpha=0.05,
                                parallel=FALSE,
                                gridPoints=10^3,
                                grid.ub=NA,
                                grid.lb=NA,
                                ...) {
  
  
  type <- type[1]
  
  # make sure that user is passing in an event study
  if (es$type != "dynamic") {
    stop("need to pass in an event study")
  }
  
  # check if used universal base period and warn otherwise
  if (es$DIDparams$base_period != "universal") {
    warning("it is recommended to use a universal base period for honest_did")
  }
  
  # recover influence function for event study estimates
  es_inf_func <- es$inf.function$dynamic.inf.func.e
  
  # recover variance-covariance matrix
  n <- nrow(es_inf_func)
  V <- t(es_inf_func) %*% es_inf_func / (n*n) 
  
  
  nperiods <- nrow(V)
  npre <- sum(1*(es$egt < 0))
  npost <- nperiods - npre
  
  baseVec1 <- basisVector(index=(e+1),size=npost)
  
  orig_ci <- constructOriginalCS(betahat = es$att.egt,
                                 sigma = V, numPrePeriods = npre,
                                 numPostPeriods = npost,
                                 l_vec = baseVec1)
  
  if (type=="relative_magnitude") {
    if (is.null(method)) method <- "C-LF"
    robust_ci <- createSensitivityResults_relativeMagnitudes(betahat = es$att.egt, sigma = V, 
                                                             numPrePeriods = npre, 
                                                             numPostPeriods = npost,
                                                             bound=bound,
                                                             method=method,
                                                             l_vec = baseVec1,
                                                             Mbarvec = Mbarvec,
                                                             monotonicityDirection=monotonicityDirection,
                                                             biasDirection=biasDirection,
                                                             alpha=alpha,
                                                             gridPoints=100,
                                                             grid.lb=-1,
                                                             grid.ub=1,
                                                             parallel=parallel)
    
  } else if (type=="smoothness") {
    robust_ci <- createSensitivityResults(betahat = es$att.egt,
                                          sigma = V, 
                                          numPrePeriods = npre, 
                                          numPostPeriods = npost,
                                          method=method,
                                          l_vec = baseVec1,
                                          monotonicityDirection=monotonicityDirection,
                                          biasDirection=biasDirection,
                                          alpha=alpha,
                                          parallel=parallel)
  }
  
  list(robust_ci=robust_ci, orig_ci=orig_ci, type=type)
}




# code for running honest_did
hd_cs_smooth_never <- honest_did(cond_es, type="smoothness")
hd_cs_rm_never <- honest_did(cond_es, type="relative_magnitude")
# Drop 0 as that is not really allowed.
hd_cs_rm_never$robust_ci <- hd_cs_rm_never$robust_ci[-1,]

# make sensitivity analysis plots
cs_HDiD_smooth <- createSensitivityPlot(hd_cs_smooth_never$robust_ci,
                                        hd_cs_smooth_never$orig_ci)
cs_HDiD_smooth
fn <- glue("{FIGDIR}/cs_hdid_smooth.png")
ggsave(fn)


cs_HDiD_relmag <- createSensitivityPlot_relativeMagnitudes(hd_cs_rm_never$robust_ci,
                                                           hd_cs_rm_never$orig_ci)
cs_HDiD_relmag
fn <- glue("{FIGDIR}/cs_hdid_relmag.png")
ggsave(fn)



# Further results -----------------------------------------------------------------

## Discretionary spend ##
## Netflows ##

# Drop first and last periods

# Longer lags horizon (up to 12 periods)







