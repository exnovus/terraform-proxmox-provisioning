locals {
  backend_enabled = false

  s3_bucket      = "my-org-tfstate-dev"
  s3_region      = "us-east-1"
  dynamodb_table = "my-org-tfstate-locks-dev"

  # S3-compatible endpoint (for example MinIO). Leave empty for AWS S3.
  s3_endpoint = ""
}
