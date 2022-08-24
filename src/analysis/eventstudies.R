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

# Customise Callaway & Sant'Anna event study plot theme
cstheme <- theme(
  plot.title = element_text(size = 22, color = "black", hjust = 0.5),
  plot.title.position = "plot",
  panel.grid.major.y = element_line(colour = "snow2"),
  panel.grid.minor.y = element_line(colour = "snow2"),
  axis.title=element_text(size = 20, colour = "black", face = "plain"),
  axis.text = element_text(size = 20),
  legend.text = element_text(size = 20),
  legend.position = "none"
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
ggdid(
  dspend_uncond_es,
  title = "Unconditional parallel trends",
  ylab = 'Discretionary spend',
  xlab = "Months since app signup",
  ylim = c(-210, 100)
  ) + cstheme

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
ggdid(
  netflows_uncond_es,
  title = " ",
  ylab = 'Net-inflows into savings accounts',
  xlab = "Months since app signup",
  ylim = c(-450, 300)
  ) + cstheme
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

ggdid(
  dspend_cond_es,
  title = "Conditional parallel trends",
  ylab = 'Discretionary spend',
  xlab = "Months since app signup",
  ylim = c(-210, 100)
  ) + cstheme
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

ggdid(
  netflows_cond_es,
  title = " ",
  ylab = 'Net-inflows into savings accounts',
  xlab = "Months since app signup",
  ylim = c(-450, 300)
  ) + cstheme
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

ggdid(
  dspend_extens_es,
  title = "Extensive margin",
  ylab = 'Discretionary spend (# of txns)',
  xlab = "Months since app signup"
  ) + cstheme
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

ggdid(
  dspend_intens_es,
  title = "Intensive margin",
  ylab = 'Discretionary spend (mean txn value)',
  xlab = "Months since app signup"
  ) + cstheme
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

ggdid(
  netflows_extens_es,
  title = " ",
  ylab = 'P(net-inflows > 0)',
  xlab = "Months since app signup"
  ) + cstheme
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

ggdid(
  netflows_intens_es,
  title = " ",
  ylab = 'Net-inflows if net-inflows > 0',
  xlab = "Months since app signup"
  ) + cstheme
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

ggdid(
  inflows_cond_es,
  title = " ",
  ylab = 'Inflows into savings accounts',
  xlab = "Months since app signup",
  ylim = c(-450, 300)
  ) + cstheme
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

ggdid(
  outflows_cond_es,
  title = " ",
  ylab = 'Outflows from savings accounts',
  xlab = "Months since app signup",
  ylim = c(-450, 300)
  ) + cstheme
ggsave(glue("{FIGDIR}/outflows_cond_es.png"))



# Anticipation effects ------------------------------------------------------------

antic_periods <- 3
yvars <- c("dspend", "netflows")
yvars <- c("netflows")


for (i in 0:antic_periods) {
  for (y in yvars) {

    print(glue("Computing antic {i} for {y}..."))
    
    # Calculate group-time treatment effects
    antic_gt <- att_gt(
      yname = y,
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
    
    # Export plot
    ylabs <- list(
      "dspend" = "Discretionary spend",
      "netflows" = "Net-inflows into savings account"
    )
    ylims <- list(
      "dspend" = c(-200, 100),
      "netflows" = c(-400, 400)
    )
    titles <- list(
      "dspend" = glue("Anticipation periods: {i}"),
      "netflows" = " "
    )
    ggdid(
      antic_es,
      title = titles[[y]],
      ylab = ylabs[[y]],
      xlab = "Months since app signup",
      ylim = ylims[[y]]
    ) + cstheme
    ggsave(glue("{FIGDIR}/{y}_antic{i}_es.png"))
  }
}
  

for (y in yvars) {
  ylims <- list(
    "dspend" = c(-200, 100),
    "netflows" = c(-400, 300)
  )
  titles <- list(
    "dspend" = glue("Anticipation periods: {i}"),
    "netflows" = " "
  )
  print(y)
  print(ylims[y])
  print(titles[[y]])
}


## Netflows ##

antic_netflows <- vector("list", antic_periods)

for (i in 1:antic_periods) {
  
  print(glue("Computing antic {i}..."))
  
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
  ggdid(
    antic_es,
    title = glue("Anticipation periods: {i}"),
    ylab = 'Net-inflows into savings accounts',
    xlab = "Months since app signup",
    ylim = c(-450, 300)
    ) + cstheme
  ggsave(glue("{FIGDIR}/netflows_antic{i}_es.png"))
}



# Unbalanced aggregation ----------------------------------------------------------

## Discretionary spend ##

# Aggregation without balance_e parameter.
dspend_cond_unbal_es <- aggte(
  dspend_cond_gt,
  type = "dynamic",
  na.rm = T,
  min_e = -6,
  max_e = 5,
)

ggdid(
  dspend_cond_unbal_es,
  title = "Unbalanced",
  ylab = "Discretionary spend",
  xlab = "Months since app signup",
  ylim = c(-210, 100)
  ) + cstheme
ggsave(glue("{FIGDIR}/dspend_cond_unbal_es.png"))

# Reprint balanced result with different title for easy comparison
ggdid(
  dspend_cond_es,
  title = "Balanced",
  ylab = 'Discretionary spend',
  xlab = "Months since app signup",
  ylim = c(-210, 100)
  ) + cstheme
ggsave(glue("{FIGDIR}/dspend_cond_bal_es.png"))


## Netflows ##

# Aggregation without balance_e parameter.
netflows_cond_unbal_es <- aggte(
  netflows_cond_gt,
  type = "dynamic",
  na.rm = T,
  min_e = -6,
  max_e = 5,
)

ggdid(
  netflows_cond_unbal_es,
  title = " ",
  ylab = "Net-inflows into savings accounts",
  xlab = "Months since app signup",
  ylim = c(-450, 300)
) + cstheme
ggsave(glue("{FIGDIR}/netflows_cond_unbal_es.png"))

# Reprint balanced result with different title for easy comparison
ggdid(
  dspend_cond_es,
  title = " ",
  ylab = "Net-inflows into savings accounts",
  xlab = "Months since app signup",
  ylim = c(-450, 300)
) + cstheme
ggsave(glue("{FIGDIR}/netflows_cond_bal_es.png"))


# Group specific effects ----------------------------------------------------------

## Discretionary spend ##
## Netflows ##
# gs <- aggte(bl_gt, type = "group", na.rm = TRUE)
# ggdid(gs)



# Calendar-time effects -----------------------------------------------------------

## Discretionary spend ##
## Netflows ##
# ct <- aggte(bl_gt, type = "calendar", na.rm = TRUE)
# ggdid(ct)


# Drop first and last periods -----------------------------------------------------

# Longer lags horizon (up to 12 periods) ------------------------------------------

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
