library(aws.s3)
library(glue)


read_analysis_data <- function(sample) {
  fn <- if (!missing(sample)) glue('eval_{sample}.parquet') else 'eval.parquet'
  fp <- file.path('s3://3di-project-eval', fn)
  df <- data.frame(aws.s3::s3read_using(arrow::read_parquet, object=fp))
  num_users <- length(unique(df$user_id))
  num_user_months <- nrow(df)
  print(fn)
  print(glue('Users: {num_users}; User-months: {num_user_months}'))
  return(df)
}


read_s3parquet <- function(filepath) {
  # Wrapper to conveniently read parquet files from S3.
  data.frame(aws.s3::s3read_using(arrow::read_parquet, object=filepath))
}


read_lcfs <- function() {
  # Read ONS Living Cost and Food Survey 2018/19 wave and
  # calculate yearly household income and spending
  # Variable definitions:
  # P389p: Normal weekly disposable household income - anonymised
  # P600: COICOP: Total consumption expenditure
  fp <- 's3://3di-data-ons/lcfs/tab/2018_dvhh_ukanon.tab'
  df <- s3read_using(read.table, object = fp, sep = '\t', header = TRUE) %>% 
    select(wk_income = P389p, wk_spend = P600) %>% 
    transmute(
      yr_income = wk_income * 52,
      yr_spend = wk_spend * 52,
      source = 'LCFS'
    )
}


figure <- function(filepath, width=2000, height=1000, pointsize=30, ...) {
  # wrapper around png with custom settings
  png(
    file.path(FIGDIR, filepath),
    width = width,
    height = height,
    units = "px",
    pointsize = pointsize,
    ...
  )
}