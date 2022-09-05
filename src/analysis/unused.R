# 
# Code I played around with but ultimately didn't use for the final paper. Collected
# here for easy future access.
# 



# Subgroups -----------------------------------------------------------------------

groupvars <- c("generation", "is_female")
yvars <- c("dspend")

for (v in groupvars) {
  groups <- as.character(unique(df[[v]]))
  for (g in groups) {
    for (y in yvars) {
      
      print(glue("Computing results for {v}, {g}, {y}..."))  
      
      # Use only observations for desired group
      data <- df %>% filter(.data[[v]] == g)
      print(nrow(data))
      
      # Calculate group-time treatment effects
      gt <- att_gt(
        yname = y,
        gname = "user_reg_ym",
        idname = "user_id",
        tname = "ym",
        xformla = xformla,
        data = data,
        est_method = "reg",
        control_group = "notyettreated",
        allow_unbalanced_panel = T,
        cores = 4
      )
      
      # Aggregate to event-study parameters
      es <- aggte(
        gt,
        type = "dynamic",
        na.rm = T,
        min_e = -6,
        max_e = 5,
        balance_e = 5
      )
      
      # Export plot
      titles <- list(
        "generation" = list(
          "Boomers" = "Boomers",
          "Gen X" = "Gen X",
          "Millennials" = "Millennials",
          "Gen Z" = "Gen Z"
        ),
        "is_female" = list(
          "0" = "Men",
          "1" = "Women"
        )
      )
      title <- titles[[v]][[g]]
      
      ylabs <- list(
        "dspend" = "Discretionary spend",
        "netflows" = "Net-inflows into savings account"
      )
      ylab <- ylabs[[y]]
      
      ggdid(
        es,
        title = title,
        ylab = ylab,
        xlab = "Months since app signup"
      ) + cstheme
      
      proper_title <- tolower(gsub(" ", "", title))
      fn <- glue("{FIGDIR}/{v}_{proper_title}_{y}_es.png")
      ggsave(fn)
      
    }
  }
}


# Anticipation effects ------------------------------------------------------------

antic_periods <- 3
yvars <- c("dspend", "netflows")


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


# Matching ------------------------------------------------------------------------

library(dplyr)
library(ggplot2)
library(gridExtra)
library(PanelMatch)

source('./src/config.R')
source('./src/helpers/helpers.R')


df <- read_analysis_data()

# Specify covariates as vector and fml
covs <- c("month_income", "month_spend", "is_female",
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
    matched.set = matched_set,
    show.set.only = T,
  ) + labs(title = "") + theme(legend.position = "none") 
}
a <- disptreat(pm_ps_nn$att[100])
b <- disptreat(pm_ps_nn$att[200])
g <- arrangeGrob(a, b, ncol = 2)
ggsave(file = file.path(FIGDIR, 'matchset_examples_new.png'), g)


# Fixest settings -----------------------------------------------------------------

library(fixest)


# conveniently set fontsize of latex table produced by etable
set_font = function(x, fontsize){
  if(missing(fontsize)) return(x)
  dreamerr::check_arg_plus(
    fontsize, 
    "match(tiny, scriptsize, footnotesize, small, normalsize, large, Large)"
  )
  x[x == "%start:tab\n"] = paste0("\\begin{", fontsize, "}")
  x[x == "%end:tab\n"] = paste0("\\end{", fontsize, "}")
  return(x)
}

setFixest_etable(
  postprocess.tex = set_font,
  se.below = T,
  digits = 'r2',
  coefstat = 'confint',
  style.tex = style.tex(
    main = "base",
    tpt = TRUE,
    notes.tpt.intro = '\\footnotesize'
  )
)

setFixest_coefplot(
  # pt.col = "steelblue4",
  # ci.col = "steelblue4",
  pt.join = TRUE
)

setFixest_dict(c(
  has_sa_inflows = "Has savings",
  inflows = "Inflows",
  outflows = "Outflows",
  netflows = "Net-inflows",
  inflows_norm = "Inflows / Income",
  outflows_norm = "Outflows / Income",
  netflows_norm = "Net-inflows / Income",
  has_pos_netflows = "Has positive net-inflows",
  pos_netflows = "Positive net-inflows",
  t = "App use",
  tt = "Months relative to app use",
  
  month_income = "Month income",
  month_spend = 'Month spend',
  dspend = "Discretionary spend",
  dspend_count = "Discretionary spend txns",
  dspend_mean = "Mean discretionary spend txn",
  is_female = 'Female',
  age = 'Age',
  is_urban = 'Urban',
  generation = "Generation",
  region_code = "Region",
  accounts_active = "Active accounts",
  
  user_id = "User ID",
  ym = "Year-month",
  
  '(Intercept)' = 'Intercept'
))


fcoefplot <- function(model, ...) {
  # wrapper around coefplot with custom settings
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
  # wrapper around iplot with custom settings
  iplot(
    model,
    ylab = '__depvar__',
    main = "",
    col = c(1, 2, 4, 3, 5, 6, 7, 8),
    pt.pch = c(20, 15, 17, 21, 24, 22),
    ...
  )
}



# Savings patterns ----------------------------------------------------------------


library(cowplot)
library(tidyverse)
library(lubridate)

source('./src/config.R')
source('./src/helpers/helpers.R')

theme_set(theme_minimal())


df <- read_analysis_data()


flows <- "^(in|out|net)flows$"

inflow_amounts <- df %>%
  select(matches(flows)) %>%
  pivot_longer(everything()) %>%
  filter(name == "inflows") %>% 
  count(value) %>%
  mutate(prop = n / sum(n)) %>% 
  filter(between(value, 1, 1000)) %>% 
  ggplot() +
  geom_bar(aes(value, prop), stat = "identity", colour = palette[1]) +
  scale_x_continuous(breaks = seq(0, 1000, 100)) +
  scale_y_continuous(labels = scales::percent) +
  labs(x = "Amount (£)", y = "Percent of inflow transactions") +
  coord_cartesian(xlim = c(0, 1000))


flows_tt <- df %>%
  select(tt, matches(flows)) %>% 
  filter(between(tt, -6, 5)) %>%
  pivot_longer(matches(flows)) %>%
  mutate(name = factor(
    name, 
    levels = c("inflows", "outflows", "netflows"), 
    labels = c("Inflows", "Outflows", "Netflows")
  )) %>% 
  ggplot(aes(tt, value, colour = name, shape = name)) +
  geom_point(stat = "summary", fun = "mean") +
  labs(x = "Time to app use", y = "Amount (£)", colour = NULL, shape = NULL) +
  theme(
    legend.position = "bottom",
    legend.text = element_text(size = 12)
  )



# Combine plots and add legend

p <- plot_grid(
  inflow_amounts + theme(legend.position = "none"),
  flows_tt + theme(legend.position = "none"),
  labels = "AUTO",
  label_x = 0,
  label_y = 0,
  hjust = -0.5, vjust = -1
)

legend <- get_legend(flows_tt)
plot_grid(p, legend, ncol = 1, rel_heights = c(1, .1))


figname <- 'savings_patterns.png'
ggsave(
  file.path(FIGDIR, figname),
  height = 1000,
  width = 2000,
  units = "px"
)
