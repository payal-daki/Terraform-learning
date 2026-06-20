provider "aws" {
  region = "ap-south-1"
}

# S3 bucket to store state
resource "aws_s3_bucket" "terraform_state" {
  bucket = "terraform-state-piyu-2026"   # must be unique globally

  tags = {
    Name      = "terraform-state"
    ManagedBy = "terraform"
  }
}

# Enable versioning on S3
# So every state change is saved
resource "aws_s3_bucket_versioning" "state_versioning" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Block all public access to state file
resource "aws_s3_bucket_public_access_block" "state_public_access" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# DynamoDB table for state locking
resource "aws_dynamodb_table" "terraform_lock" {
  name         = "terraform-state-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name      = "terraform-lock"
    ManagedBy = "terraform"
  }
}
