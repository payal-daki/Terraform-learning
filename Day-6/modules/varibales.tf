variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  type    = string
  default = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  type    = string
  default = "10.0.2.0/24"
}

variable "ami_id" {
  type    = string
  default = "ami-0f58b397bc5c1f2e8"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "db_name" {
  type    = string
  default = "jumpickdb"
}

variable "db_username" {
  type    = string
  default = "dbadmin"
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "bucket_name" {
  type    = string
  default = "jumpick-app-storage-2026"
}
