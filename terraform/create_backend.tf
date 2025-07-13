# This configuration should be run once manually to create the
# S3 bucket and DynamoDB table for the remote backend.

# Choose a unique name for your S3 bucket.
# Replace "your-unique-project-name-tfstate" with something unique to you.
variable "bucket_name" {
  description = "A unique name for the S3 bucket to store Terraform state."
  type        = string
  default     = "ansible2-project-tfstate-2025"
}

# Choose a unique name for your DynamoDB table.
variable "table_name" {
  description = "A unique name for the DynamoDB table for state locking."
  type        = string
  default     = "terraform-state-lock-prod"
}

# Create the S3 bucket to store the terraform.tfstate file
resource "aws_s3_bucket" "terraform_state" {
  bucket = var.bucket_name

  # Prevent accidental deletion of the state file
 # lifecycle {
#    prevent_destroy = true
#  }

  # Enable versioning to keep a history of your state files
  versioning {
    enabled = true
  }

  # Encrypt the state file at rest
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

# Create the DynamoDB table for state locking
resource "aws_dynamodb_table" "terraform_locks" {
  name         = var.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
