output "vpc_id" {
  value = module.vpc.vpc_id
}

output "web_server_ip" {
  value = module.ec2.public_ip
}

output "db_endpoint" {
  value = module.rds.db_endpoint
}

output "s3_bucket" {
  value = module.s3.bucket_name
}
