library(did)
library(ggplot2)
library(glue)
library(gridExtra)
library(lubridate)

source('./src/config.R')
# source('./src/helpers/fixest_settings.R')
source('./src/helpers/helpers.R')


df <- read_analysis_data()
names(df)


# Customise event study plot theme
size <- 24
cstheme <- theme(
  plot.title = element_text(size = size, color = "black", hjust = 0.5),
  plot.title.position = "plot",
  panel.grid.major.y = element_line(colour = "snow2"),
  panel.grid.minor.y = element_line(colour = "snow2"),
  axis.title=element_text(size = size, colour = "black", face = "plain"),
  axis.text = element_text(size = size),
  legend.text = element_text(size = size),
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
  ylab = 'Savings',
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
  allow_unbalanced_panel = T
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
  ylab = 'Savings',
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
  ylab = 'Number of spending txns',
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
  ylab = 'Mean spend txn value (£)',
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
  ylab = 'P(Savings > 0)',
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
  ylab = 'Savings | savings > 0',
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
  ylab = 'Savings account inflows',
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
  ylab = 'Savings account outflows',
  xlab = "Months since app signup",
  ylim = c(-450, 300)
  ) + cstheme
ggsave(glue("{FIGDIR}/outflows_cond_es.png"))


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
  ylab = "Net savings",
  xlab = "Months since app signup",
  ylim = c(-450, 300)
) + cstheme
ggsave(glue("{FIGDIR}/netflows_cond_unbal_es.png"))

# Reprint balanced result with different title for easy comparison
ggdid(
  netflows_cond_es,
  title = " ",
  ylab = "Net savings",
  xlab = "Months since app signup",
  ylim = c(-450, 300)
) + cstheme
ggsave(glue("{FIGDIR}/netflows_cond_bal_es.png"))


# Where did money go? -------------------------------------------------------------

yvars <- c(
  "investments",
  "up_savings",
  "ca_transfers",
  "loan_rpmts"
  # "cc_payments",
  # "loan_funds",
)

for (y in yvars) {
  
  print(glue("Computing results for {y}..."))
  
  # Calculate group-time treatment effects
  gt <- att_gt(
    yname = y,
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
  ylabs <- list(
    "investments" = "Investments",
    "up_savings" = "Unliked savings",
    "ca_transfers" = "Current account tfrs",
    "cc_payments" = "Credit card payments",
    "loan_funds" = "Loan funds",
    "loan_rpmts" = "Loan repayment"
  )
  ggdid(
    es,
    title = " ",
    ylab = ylabs[[y]],
    xlab = "Months since app signup"
  ) + cstheme
  ggsave(glue("{FIGDIR}/{y}_cond_es.png"))
}


# Disaggregated dspend ------------------------------------------------------------

yvars <- c(
  "dspend",   # recalculate for consistent plot output
  "dspend_groceries",
  "dspend_entertainment",
  "dspend_food",
  "dspend_clothes",
  "dspend_other",
  "dspend_dd"
)

for (y in yvars) {
  
  print(glue("Computing results for {y}..."))

  gt <- att_gt(
    yname = y,
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
  
  es <- aggte(
    gt,
    type = "dynamic",
    na.rm = T,
    min_e = -6,
    max_e = 5,
    balance_e = 5
  )
  
  ylabs <- c(
    "dspend" = "Total",
    "dspend_groceries" = "Groceries",
    "dspend_entertainment" = "Entertainment",
    "dspend_food" = "Food",
    "dspend_clothes" = "Clothes",
    "dspend_other" = "Other",
    "dspend_dd" = "Debit-direct"
  )
  
  ggdid(
    es,
    title = " ",
    ylab = ylabs[[y]],
    xlab = "Months since app signup",
    ylim = c(-210, 100)
  ) + cstheme
  
  ggsave(glue("{FIGDIR}/disag_{y}_cond_es.png"))
}



