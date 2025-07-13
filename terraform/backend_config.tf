# This file configures Terraform to use the S3 remote backend.
# It should be committed to your repository.

terraform {
  backend "s3" {
    # Replace with the unique bucket name you chose in the previous step
    bucket = "ansible2-project-tfstate-2025"
    key    = "prod/terraform.tfstate" # The path to the state file within the bucket
    region = "us-east-1"

    # Replace with the unique table name you chose
    dynamodb_table = "terraform-state-lock-prod"
    encrypt        = true
  }
}
