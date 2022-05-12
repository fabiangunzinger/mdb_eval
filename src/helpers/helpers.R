Sys.setenv(AWS_PROFILE='3di', AWS_DEFAULT_REGION='eu-west-2')
library(aws.s3)

read_s3parquet <- function(filepath) {
  # Wrapper to conveniently read parquet files from S3.
  data.frame(aws.s3::s3read_using(arrow::read_parquet, object=filepath))
}