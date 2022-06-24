library(RColorBrewer)

# Environment variable
Sys.setenv(AWS_PROFILE='3di', AWS_DEFAULT_REGION='eu-west-2')

# Global variables
ROOT <- '/Users/fgu/dev/projects/mdb_eval'
FIGDIR <- file.path(ROOT, 'output/figures')
TABDIR <- file.path(ROOT, 'output/tables')

setwd(ROOT)


# Figure settings
palette <- "Set1"
single_col <- brewer.pal(3, name=palette)[2]

# colours from wesanderson palette Zissou1
# https://github.com/karthik/wesanderson/blob/master/R/colors.R
# treat_col <- '#78B7C5'
# untreat_col <- '#E1AF00'

