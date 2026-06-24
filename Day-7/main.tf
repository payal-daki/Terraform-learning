# Simple EC2 for Day 7 demo github action
resource "aws_instance" "web" {
  ami           = "ami-0f58b397bc5c1f2e8"
  instance_type = var.instance_type

  tags = {
    Name        = "${var.environment}-cicd-demo"
    Environment = var.environment
    ManagedBy   = "terraform"
    DeployedBy  = "github-actions"
  }
}
