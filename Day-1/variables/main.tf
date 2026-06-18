resource "aws_instance" "my_ec2" {
  ami           = var.ami_id           # using variable
  instance_type = var.instance_type    # using variable

  tags = {
    Name        = var.instance_name    # using variable
    Environment = var.environment      # using variable
    ManagedBy   = "terraform"
  }
}
