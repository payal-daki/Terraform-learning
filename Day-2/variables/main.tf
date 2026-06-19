resource "aws_instance" "my_ec2" {
  ami           = var.ami_id
  instance_type = var.instance_type

  tags = merge(local.common_tags, {
    Name = local.full_name
  })
}
