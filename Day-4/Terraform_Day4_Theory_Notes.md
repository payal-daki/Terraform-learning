# Terraform Learning — Day 4 🚀

---

## Why VPC?

Default VPC problems:
```
❌ No proper isolation
❌ Not production ready
❌ Security risk
```

In real companies — everything runs in custom VPC. 🎯

---

## What is VPC?

> VPC = your private network on AWS

```
Home WiFi          →   VPC
Devices on WiFi    →   EC2 instances
Router             →   Internet Gateway
WiFi password      →   Security Groups
Rooms in house     →   Subnets
```

---

## VPC Components

| Component | Purpose |
|---|---|
| VPC | Your private network |
| Subnet | Section of network (public/private) |
| Internet Gateway | Door to internet |
| Route Table | Traffic direction rules |
| Security Group | Firewall for EC2 |

---

## Public vs Private Subnet

```
Public Subnet  →  has internet access
               →  Web server, Load Balancer lives here

Private Subnet →  no direct internet access
               →  Database, Backend lives here
```

> Golden rule: Database should NEVER be in public subnet. 🔒

---

## Private Subnet Access

```
FROM Internet      → Private Subnet = ❌ BLOCKED
FROM Public Subnet → Private Subnet = ✅ ALLOWED
FROM Private Subnet → Private Subnet = ✅ ALLOWED
```

Office Building Analogy:
```
Internet       = Outside world
VPC            = Office Building
Public Subnet  = Reception (anyone can enter)
Private Subnet = Server room (only staff can enter)
```

---

## What We Built

```
VPC (10.0.0.0/16)
├── Public Subnet  (10.0.1.0/24)  → EC2 Web Server
├── Private Subnet (10.0.2.0/24)  → Database
├── Internet Gateway               → internet access
└── Route Table                    → traffic rules
```

---

## File Structure

```
Day-4/
├── provider.tf     ← AWS provider + remote backend
├── variables.tf    ← all variables
├── main.tf         ← all networking resources
└── outputs.tf      ← useful info after apply
```

---

## provider.tf

```hcl
terraform {
  backend "s3" {
    bucket       = "terraform-state-piyu-2026"
    key          = "day4/terraform.tfstate"
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

## variables.tf

```hcl
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "Public subnet CIDR"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "Private subnet CIDR"
  type        = string
  default     = "10.0.2.0/24"
}
```

---

## main.tf

```hcl
# VPC
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

# Private Subnet
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = "ap-south-1b"

  tags = {
    Name        = "${var.environment}-private-subnet"
    Environment = var.environment
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.environment}-igw"
    Environment = var.environment
  }
}

# Route Table for public subnet
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

# Associate route table with public subnet
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Security Group for web server
resource "aws_security_group" "web" {
  name        = "${var.environment}-web-sg"
  description = "Security group for web server"
  vpc_id      = aws_vpc.main.id

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

# Security Group for database (private subnet)
resource "aws_security_group" "db" {
  name        = "${var.environment}-db-sg"
  description = "Security group for database"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]  # only from web server!
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-db-sg"
    Environment = var.environment
  }
}

# EC2 in public subnet
resource "aws_instance" "web" {
  ami                    = "ami-0f58b397bc5c1f2e8"
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web.id]

  tags = {
    Name        = "${var.environment}-web-server"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
```

---

## outputs.tf

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

output "web_server_public_ip" {
  description = "Web server public IP"
  value       = aws_instance.web.public_ip
}

output "security_group_id" {
  description = "Security Group ID"
  value       = aws_security_group.web.id
}
```

---

## Request Flow — Internet to Public Subnet

```
User opens http://13.x.x.x
      │
      ▼
Internet Gateway (entry point)
      │
      ▼
Route Table checks traffic direction
(0.0.0.0/0 → IGW → Public Subnet)
      │
      ▼
Security Group checks port
(port 80 allowed? YES ✅)
      │
      ▼
EC2 Web Server in Public Subnet
      │
      ▼
Response goes back same path ✅
```

---

## Request Flow — Public to Private Subnet

```
EC2 Web Server needs database data
      │
      ▼
Talks to DB using private IP (10.0.2.10)
      │
      ▼
DB Security Group checks:
"request from web server SG? YES ✅"
      │
      ▼
Database responds internally ✅
(no internet involved)
```

---

## Full Architecture

```
INTERNET
    │
    ▼
Internet Gateway
    │
    ▼
Route Table
    │
    ▼
Security Group (port 80/443)
    │
    ▼
PUBLIC SUBNET (10.0.1.0/24)
└── EC2 Web Server (10.0.1.10)
      │
      │ internal VPC traffic
      ▼
PRIVATE SUBNET (10.0.2.0/24)
└── Database (10.0.2.10) 🔒
    (internet CANNOT reach this)
```

---

## How Resources Connect

```
aws_vpc.main
    ├── aws_subnet.public → aws_instance.web
    │                            └── aws_security_group.web
    ├── aws_subnet.private
    ├── aws_internet_gateway.main
    └── aws_route_table.public
          └── aws_route_table_association.public
```

---

## .gitignore

```
.terraform/
*.tfstate
*.tfstate.backup
.terraform.lock.hcl
*.tfvars
```

---

## Day 4 Summary ✅

```
✅ Why custom VPC needed
✅ VPC components understood
✅ Public vs private subnet
✅ Internet Gateway created
✅ Route Table configured
✅ Security Groups for web + db
✅ EC2 in public subnet
✅ Request flow understood
✅ Private subnet access within VPC only
✅ Pushed to GitHub
```

---

*Day 4 complete — VPC, Subnets, IGW, Route Table, Security Groups* 🚀
