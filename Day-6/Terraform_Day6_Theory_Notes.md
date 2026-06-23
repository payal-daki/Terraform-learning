# Terraform Learning - Day 6

---

## What We Built

Complete production-like infrastructure:

- VPC with public + 2 private subnets
- EC2 web server in public subnet
- RDS PostgreSQL in private subnets
- S3 bucket for file storage
- Security Groups
- Remote State on S3
- Everything using Modules

---

## Architecture

```
Internet
    |
    v
Internet Gateway
    |
    v
PUBLIC SUBNET (10.1.2.0/24) - ap-south-1a
    └── EC2 Web Server
              |
              | internal traffic only
              v
PRIVATE SUBNET 1 (10.1.3.0/24) - ap-south-1a
PRIVATE SUBNET 2 (10.0.3.0/24) - ap-south-1b
    └── RDS PostgreSQL (needs 2 subnets in different AZs)
```

---

## Why Two Private Subnets for RDS?

RDS requires a DB subnet group with subnets in
at least 2 different Availability Zones for high availability.

```
private_subnet_1 -> ap-south-1a
private_subnet_2 -> ap-south-1b
Both passed to RDS subnet group
```

---

## Folder Structure

```
Day-6/
├── provider.tf
├── variables.tf
├── main.tf
├── outputs.tf
└── modules/
      ├── vpc/
      │     ├── variables.tf
      │     ├── main.tf
      │     └── outputs.tf
      ├── ec2/
      │     ├── variables.tf
      │     ├── main.tf
      │     └── outputs.tf
      ├── rds/
      │     ├── variables.tf
      │     ├── main.tf
      │     └── outputs.tf
      └── s3/
            ├── variables.tf
            ├── main.tf
            └── outputs.tf
```

---

## vpc/variables.tf

```hcl
variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "public_subnet_cidr" {
  description = "Public subnet CIDR"
  type        = string
}

variable "private_subnet_1_cidr" {
  type = string
}

variable "private_subnet_2_cidr" {
  type = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}
```

---

## vpc/main.tf

```hcl
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.environment}-vpc"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.environment}-public-subnet"
    Environment = var.environment
  }
}

# Private Subnet 1
resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_1_cidr
  availability_zone = "ap-south-1a"

  tags = {
    Name        = "${var.environment}-private-subnet-1"
    Environment = var.environment
  }
}

# Private Subnet 2
resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_2_cidr
  availability_zone = "ap-south-1b"

  tags = {
    Name        = "${var.environment}-private-subnet-2"
    Environment = var.environment
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.environment}-igw"
    Environment = var.environment
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "${var.environment}-public-rt"
    Environment = var.environment
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}
```

---

## vpc/outputs.tf

```hcl
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "Public Subnet ID"
  value       = aws_subnet.public.id
}

output "private_subnet_1_id" {
  value = aws_subnet.private_1.id
}

output "private_subnet_2_id" {
  value = aws_subnet.private_2.id
}
```

---

## rds/main.tf

```hcl
# Subnet group for RDS - needs 2 subnets in different AZs
resource "aws_db_subnet_group" "main" {
  name       = "${var.environment}-db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name        = "${var.environment}-db-subnet-group"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# RDS PostgreSQL instance
resource "aws_db_instance" "main" {
  identifier        = "${var.environment}-postgres"
  engine            = "postgres"
  engine_version    = "15"
  instance_class    = var.db_instance_class
  allocated_storage = 20

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.security_group_id]

  skip_final_snapshot = true   # for learning only!
  publicly_accessible = false  # private subnet only

  tags = {
    Name        = "${var.environment}-postgres"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
```

---

## Root main.tf

```hcl
# Security Group for Web Server
resource "aws_security_group" "web" {
  name        = "${var.environment}-web-sg"
  description = "Web server security group"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-web-sg"
    Environment = var.environment
  }
}

# Security Group for RDS
resource "aws_security_group" "rds" {
  name        = "${var.environment}-rds-sg"
  description = "RDS security group"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-rds-sg"
    Environment = var.environment
  }
}

# VPC Module
module "vpc" {
  source = "./vpc"

  vpc_cidr              = var.vpc_cidr
  public_subnet_cidr    = var.public_subnet_cidr
  private_subnet_1_cidr = var.private_subnet_1_cidr
  private_subnet_2_cidr = var.private_subnet_2_cidr
  environment           = var.environment
}

# EC2 Module
module "ec2" {
  source = "./ec2"

  ami_id             = var.ami_id
  instance_type      = var.instance_type
  subnet_id          = module.vpc.public_subnet_id
  security_group_ids = [aws_security_group.web.id]
  environment        = var.environment
  instance_name      = "${var.environment}-web-server"
}

# RDS Module - passes both private subnets
module "rds" {
  source = "./rds"

  db_name     = var.db_name
  db_username = var.db_username
  db_password = var.db_password
  subnet_ids = [
    module.vpc.private_subnet_1_id,
    module.vpc.private_subnet_2_id
  ]
  security_group_id = aws_security_group.rds.id
  environment       = var.environment
}

# S3 Module
module "s3" {
  source = "./s3"

  bucket_name = var.bucket_name
  environment = var.environment
}
```

---

## Root variables.tf

```hcl
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
  default = "10.1.0.0/16"
}

variable "public_subnet_cidr" {
  type    = string
  default = "10.1.2.0/24"
}

variable "private_subnet_1_cidr" {
  type    = string
  default = "10.1.3.0/24"
}

variable "private_subnet_2_cidr" {
  type    = string
  default = "10.1.4.0/24"
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
  default = "testdb"
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
  default = "test-app-storage-2026"
}
```

---

## dev.tfvars - Never Push to GitHub!

```hcl
db_password = ""
```

---

## Run Commands

```bash
terraform init
terraform plan -var-file="dev.tfvars"
terraform apply -var-file="dev.tfvars"
terraform destroy -var-file="dev.tfvars"
```

---

## Resource Creation Time

```
EC2  -> 30 seconds
S3   -> 5 seconds
RDS  -> 5-10 minutes (be patient!)
```

---

## Security Setup

```
Web SG  -> allows 22, 80, 443 from internet
RDS SG  -> allows 5432 from web SG only
S3      -> public access blocked
RDS     -> publicly_accessible = false
```

---

## Key Change From Previous Version

```
Before:
- 1 private subnet
- RDS in single subnet

After (your version):
- 2 private subnets (ap-south-1a + ap-south-1b)
- RDS uses both subnets
- More realistic production setup
- RDS requires 2 AZs for subnet group
```

---

## Push to GitHub

```bash
cat > .gitignore << 'EOF'
.terraform/
*.tfstate
*.tfstate.backup
.terraform.lock.hcl
*.tfvars
EOF

git add .
git commit -m "day6: full project EC2 + VPC + RDS + S3 with 2 private subnets"
git push
```

---

## Day 6 Summary

- VPC with 1 public + 2 private subnets
- EC2 web server in public subnet
- RDS PostgreSQL using both private subnets
- S3 bucket with versioning + public access blocked
- Security Groups for web + rds
- Remote state on S3
- All infrastructure using modules
- Password via tfvars not hardcoded
- Pushed to GitHub

---

*Day 6 complete - Full Project EC2 + VPC + RDS + S3 using Modules*
