library(ggplot2)
library(PanelMatch)

source('./src/helpers/helpers.R')
source('./src/figures/fig_settings.R')


df <- read_s3parquet('s3://3di-project-eval/eval_XX1.parquet')
df$generation <- as.numeric(df$generation)


# Treatment assignment plot

sample_size <- 200
dfs <- df %>% filter(user_id %in% sample(unique(user_id), sample_size))
xticks <- c(201201, 201301, 201401, 201501, 201601, 201701, 201801, 201901, 202001)
DisplayTreatment(data = dfs,
                 unit.id = "user_id",
                 time.id = "ymn",
                 treatment = "t",
                 legend.position = "bottom",
                 xlab = "Year-months",
                 ylab = "User",
                 legend.labels = c("Not using app (control)", "Using app (treatment)"),
                 title = "") +
  theme(axis.text.y = element_blank(), axis.ticks.y = element_blank(),
        axis.text.x = element_text(angle=0, size=6.5, vjust=0.5)) +
  scale_y_discrete(breaks = xticks) +
  guides(fill=guide_legend(title=""))

ggsave(file.path(FIGDIR, 'treatplot_sample_raw.png'))


# From here, following imai2021matching code

# Perform matching
pm <- PanelMatch(
  data = df,
  time.id = "ym",
  unit.id = "user_id",
  treatment = "t",
  outcome.var = "netflows_norm",
  lag = 6,
  lead = 0:5,  
  qoi = "att",
  forbid.treatment.reversal = T,
  refinement.method = "ps.match",
  covs.formula = ~ generation + is_female + is_urban + month_income,
  size.match = 1
  )

# Inspect distribution of match set size
# plot(pm$att)

# Inspect covariate balance
# Comparison of equal weights (pre-refinement) and post-refinement weights
# shows impact of refinement / matching stage.
covs <- c("generation", "month_income", "is_female", "is_urban")

get_covariate_balance(pm$att, data = df, use.equal.weights = T, covariates = covs, plot = T, ylim = c(-1, 1))


get_covariate_balance(pm$att, data = df, use.equal.weights = F, covariates = covs, plot = T, ylim = c(-1, 1))

# Check for parallel pre-treatment trend assumption


# Estimates
pe <- PanelEstimate(sets = pm, data = df)
summary(pe)
plot(pe)




# Visualise treatment history matching
mset <- pm$att[3]

DisplayTreatment(
  data = df,
  unit.id = "user_id",
  time.id = "ym",
  treatment = "t",
  legend.position = "right",
  xlab = "Year-months",
  ylab = "User",
  matched.set = mset,
  show.set.only = T
)
