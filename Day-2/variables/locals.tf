# locals.tf
locals {
  # combine two variables into one name
  full_name = "${var.environment}-${var.instance_name}"

  # define tags once for ALL resources
  common_tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
    Owner       = "piyu"
  }
}
