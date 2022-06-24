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

# setFixest_coefplot(
#   pt.col = "steelblue4",
#   pt.cex = 1.5,
#   pt.pch = 15,
#   ci.col = "darkolivegreen4",
#   ci.width = 0,
#   ci.lwd = 2
# )

setFixest_dict(c(
  has_sa_inflows = "Has savings",
  inflows = "Inflows",
  outflows = "Outflows",
  netflows = "Net-inflows",
  inflows_norm = "Inflows / Income",
  outflows_norm = "Outflows / Income",
  netflows_norm = "Net-inflows / Income",
  has_pos_netflows = "Has positive net-inflows",
  t = "App use",
  tt = "Months to/since app use",
  
  month_income = "Month income",
  month_spend = 'Month spend',
  discret_spend = "Discretionary spend",
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

