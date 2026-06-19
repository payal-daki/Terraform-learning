variable "aws_region" {
  description = "AWS region to deploy in"
  type        = string
  default     = "ap-south-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "ami_id" {
  description = "Ubuntu 22.04 AMI ID"
  type        = string
  default     = "ami-0f58b397bc5c1f2e8"
}

variable "instance_name" {
  description = "Name of EC2 instance"
  type        = string
  default     = "terraform-learning"
}

variable "environment" {
  description = "Environment"
  type        = string
  default     = "dev"
}

