library(dplyr)
library(ggplot2)
library(gridExtra)
library(PanelMatch)

source('./src/helpers/helpers.R')
source('./src/figures/fig_settings.R')


df <- read_s3parquet('s3://3di-project-eval/eval_XX1.parquet')
df$generation <- as.numeric(df$generation)


# Treatment assignment plot

sample_size <- 200
dfs <- df %>% filter(user_id %in% sample(unique(user_id), sample_size))
xticks <- c(201206, 201306, 201406, 201506, 201606, 201706, 201806, 201906, 202006)
xlabs <- c("2012", "2013", "2014", "2015", "2016", "2017", "2018", "2019", "2020")

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
        axis.text.x = element_text(angle=0, size=10)) +
  scale_y_discrete(breaks = xticks, labels = xlabs) +
  guides(fill=guide_legend(title=""))

ggsave(file.path(FIGDIR, 'treatplot_sample_raw.png'))


# Perform matching

fml <-  ~ generation + is_female + is_urban + month_income
pm <- PanelMatch(
  data = df,
  time.id = "ym",
  unit.id = "user_id",
  treatment = "t",
  outcome.var = "netflows_norm",
  lag = 5,
  lead = 0:5,  
  qoi = "att",
  forbid.treatment.reversal = T,
  refinement.method = "ps.match",
  covs.formula = fml,
  size.match = 1
  )


# Frequency distribution of matched sets

set_sizes <- summary(pm$att)$overview$matched.set.size
png(
  file.path(FIGDIR, "hist_matchset_size.png"),
  width     = 10,
  height    = 6,
  units     = "cm",
  res       = 1200,
  pointsize = 6
)
plot(pm$att, main = NULL)
dev.off()


# Inspect covariate balance 1

covs <- c("generation", "month_income", "is_female", "is_urban")

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
  pm$att,
  data = df,
  use.equal.weights = T,
  covariates = covs,
  plot = T,
  ylim = c(-0.5, 0.5)
  )

get_covariate_balance(
  pm$att,
  data = df,
  use.equal.weights = F,
  covariates = covs,
  plot = T,
  ylim = c(-0.5, 0.5)
  )

dev.off()


# Check for parallel pre-treatment trend assumption

# tbd


# Estimates

pe <- PanelEstimate(sets = pm, data = df)
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
 
mset <- pm$att[100]
a <- DisplayTreatment(
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

mset <- pm$att[200]
b <- DisplayTreatment(
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


g <- arrangeGrob(a, b, ncol = 2)
ggsave(file = file.path(FIGDIR, 'matchset_examples.png'), g)
