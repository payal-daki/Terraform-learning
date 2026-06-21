# Terraform Learning — Day 5 🚀

---

## Why Modules?

Without modules — repeating same code everywhere:
```
Day-1/ → VPC code
Day-4/ → same VPC code again
Project2/ → same VPC code again ❌
```

With modules — write once, use everywhere:
```hcl
module "vpc" {
  source = "./modules/vpc"
  vpc_cidr = "10.0.0.0/16"
}
```

---

## Module = Function in Programming

```python
# Python function
def create_vpc(cidr, environment):
    # creates vpc
    return vpc_id

# Terraform module
module "vpc" {
  source      = "./modules/vpc"
  vpc_cidr    = "10.0.0.0/16"
  environment = "dev"
}
```

---

## Folder Structure

```
Day-5/
├── provider.tf          ← AWS connection
├── variables.tf         ← root inputs
├── main.tf              ← calls modules
├── outputs.tf           ← root outputs
└── modules/
      ├── vpc/
      │     ├── variables.tf  ← what vpc needs
      │     ├── main.tf       ← vpc resources
      │     └── outputs.tf    ← what vpc returns
      └── ec2/
            ├── variables.tf  ← what ec2 needs
            ├── main.tf       ← ec2 resources
            └── outputs.tf    ← what ec2 returns
```

---

## One Line Per File

```
modules/vpc/variables.tf  →  what VPC needs as input
modules/vpc/main.tf       →  what VPC creates
modules/vpc/outputs.tf    →  what VPC returns

modules/ec2/variables.tf  →  what EC2 needs as input
modules/ec2/main.tf       →  what EC2 creates
modules/ec2/outputs.tf    →  what EC2 returns

root/variables.tf         →  all project inputs
root/main.tf              →  calls all modules
root/outputs.tf           →  shows final results
```

---

## modules/vpc/variables.tf

```hcl
variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "public_subnet_cidr" {
  description = "Public subnet CIDR"
  type        = string
}

variable "private_subnet_cidr" {
  description = "Private subnet CIDR"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}
```

---

## modules/vpc/main.tf

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

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = "ap-south-1b"

  tags = {
    Name        = "${var.environment}-private-subnet"
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

## modules/vpc/outputs.tf

```hcl
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "Public Subnet ID"
  value       = aws_subnet.public.id
}

output "private_subnet_id" {
  description = "Private Subnet ID"
  value       = aws_subnet.private.id
}
```

---

## modules/ec2/variables.tf

```hcl
variable "ami_id" {
  description = "AMI ID"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "subnet_id" {
  description = "Subnet ID"
  type        = string
}

variable "security_group_ids" {
  description = "Security Group IDs"
  type        = list(string)
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "instance_name" {
  description = "Name of instance"
  type        = string
}
```

---

## modules/ec2/main.tf

```hcl
resource "aws_instance" "this" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.security_group_ids

  tags = {
    Name        = var.instance_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
```

---

## modules/ec2/outputs.tf

```hcl
output "instance_id" {
  description = "EC2 Instance ID"
  value       = aws_instance.this.id
}

output "public_ip" {
  description = "Public IP"
  value       = aws_instance.this.public_ip
}
```

---

## Root provider.tf

```hcl
terraform {
  backend "s3" {
    bucket       = "terraform-state-piyu-2026"
    key          = "day5/terraform.tfstate"
    region       = "ap-south-1"
    use_lockfile = true
    encrypt      = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
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
```

---

## Root main.tf — Where Modules Are Called

```hcl
# Security Group
resource "aws_security_group" "web" {
  name        = "${var.environment}-web-sg"
  description = "Web server security group"
  vpc_id      = module.vpc.vpc_id    # using vpc module output!

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

# Call VPC Module
module "vpc" {
  source = "./modules/vpc"

  vpc_cidr            = var.vpc_cidr
  public_subnet_cidr  = var.public_subnet_cidr
  private_subnet_cidr = var.private_subnet_cidr
  environment         = var.environment
}

# Call EC2 Module
module "ec2" {
  source = "./modules/ec2"

  ami_id             = var.ami_id
  instance_type      = var.instance_type
  subnet_id          = module.vpc.public_subnet_id   # vpc output used here!
  security_group_ids = [aws_security_group.web.id]
  environment        = var.environment
  instance_name      = "${var.environment}-web-server"
}
```

---

## Root outputs.tf

```hcl
output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_id" {
  value = module.vpc.public_subnet_id
}

output "web_server_ip" {
  value = module.ec2.public_ip
}
```

---

## How Module Call Works

```hcl
module "vpc" {
  source      = "./modules/vpc"   # which module to use
  vpc_cidr    = var.vpc_cidr      # passing input
  environment = var.environment   # passing input
}
```

Using module output in another module:
```hcl
subnet_id = module.vpc.public_subnet_id
#                │         │
#                │         └── output from vpc module
#                └── module name
```

---

## Full Data Flow

```
Root variables.tf
      │ passes values
      ▼
Root main.tf
      ├── module "vpc" ──► creates VPC, subnets, IGW
      │         │          returns vpc_id, subnet_ids
      │         │
      └── module "ec2" ──► receives subnet_id from vpc
                │          creates EC2
                │          returns public_ip
                ▼
          Root outputs.tf
          shows vpc_id + public_ip
```

---

## Reuse Same Modules — Different Projects

```
modules/ → never change ✅

# test-dev.tfvars
environment   = "dev"
vpc_cidr      = "10.0.0.0/16"
instance_type = "t3.micro"

# test-prod.tfvars
environment   = "prod"
vpc_cidr      = "10.1.0.0/16"
instance_type = "t3.large"
```

```bash
# Deploy dev
terraform apply -var-file="test-dev.tfvars"

# Deploy prod
terraform apply -var-file="test-prod.tfvars"
```

Same modules — different environments! 🎯

---

## Run Commands

```bash
terraform init      # loads modules
terraform plan      # preview
terraform apply     # create
terraform destroy   # cleanup
```

---

## Without vs With Modules

| | Without Modules | With Modules |
|---|---|---|
| Code reuse | ❌ copy paste | ✅ call module |
| Consistency | ❌ different every time | ✅ same always |
| Maintenance | ❌ update everywhere | ✅ update once |
| Team sharing | ❌ | ✅ |
| New project | copy all files | just change variables |

---

## Day 5 Summary ✅

```
✅ Why modules needed
✅ Module = reusable function
✅ VPC module created
✅ EC2 module created
✅ Root main.tf calls both modules
✅ Module outputs used as inputs to other modules
✅ Same modules reused for dev + prod
✅ Pushed to GitHub
```

---

*Day 5 complete — Terraform Modules, VPC Module, EC2 Module* 🚀
