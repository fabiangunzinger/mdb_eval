library(aws.s3)
library(glue)

read_analysis_data <- function(sample=NULL) {
  filepath <- 's3://3di-project-eval/eval.parquet'
  df <- data.frame(aws.s3::s3read_using(arrow::read_parquet, object=filepath))
  print(glue('Users: {length(unique(df$user_id))}; User-months: {nrow(df)}'))
  df
}

read_s3parquet <- function(filepath) {
  # Wrapper to conveniently read parquet files from S3.
  data.frame(aws.s3::s3read_using(arrow::read_parquet, object=filepath))
}