# backend.tf
terraform {
  backend "s3" {
    bucket         = "terraform-state-piyu-2026"  # your S3 bucket
    key            = "dev/terraform.tfstate"          # path inside bucket
    region         = "ap-south-1"
    dynamodb_table = "terraform-state-lock"           # locking table
    encrypt        = true                             # encrypt state file
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

resource "aws_instance" "my_ec2" {
  ami           = "ami-0f58b397bc5c1f2e8"
  instance_type = "t3.micro"

  tags = {
    Name      = "remote-state-demo"
    ManagedBy = "terraform"
  }
}
