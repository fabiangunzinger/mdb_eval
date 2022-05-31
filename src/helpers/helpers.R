library(aws.s3)
library(glue)

read_analysis_data <- function(sample=NULL) {
  fp <- 's3://3di-project-eval/eval.parquet'
  df <- data.frame(aws.s3::s3read_using(arrow::read_parquet, object=fp))
  num_users <- length(unique(df$user_id))
  num_user_months <- nrow(df)
  print(glue('Users: {num_users}; User-months: {num_user_months}'))
  return(df)
}

read_s3parquet <- function(filepath) {
  # Wrapper to conveniently read parquet files from S3.
  data.frame(aws.s3::s3read_using(arrow::read_parquet, object=filepath))
}

figure <- function(filepath, width=2000, height=1000, ...) {
  # wrapper around png with custom settings
  png(
    file.path(FIGDIR, filepath),
    width = width,
    height = height,
    units = "px",
    pointsize = 30,
    ...
  )
}

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
    ylab = 'Change in __depvar__',
    main = "",
    col = c(1, 2, 4, 3, 5, 6, 7, 8),
    pt.pch = c(20, 15, 17, 21, 24, 22),
    ...
  )
}
