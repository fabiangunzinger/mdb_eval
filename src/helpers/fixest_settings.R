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
