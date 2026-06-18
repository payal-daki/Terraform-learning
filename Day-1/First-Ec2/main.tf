resource "aws_instance" "my_first_ec2" {
  ami           = "ami-0f58b397bc5c1f2e8"
  instance_type = "t3.micro"          # changed from t2.micro

  tags = {
    Name        = "terraform-learning"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}
