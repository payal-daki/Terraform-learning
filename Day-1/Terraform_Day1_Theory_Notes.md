# Terraform Learning — Day 1 & Day 2 🚀

---

## Day 1 — Terraform Basics & First EC2

---

### Why Does Terraform Exist?

Right now to create infrastructure on AWS you:

```
Login to AWS Console
→ Click EC2
→ Click Launch Instance
→ Choose Ubuntu
→ Choose t2.micro
→ Configure Security Group
→ Click Launch
```

**Works fine for 1 server. But what about 30 servers?**

- Dev environment → 10 servers
- Staging → 10 servers
- Production → 10 servers

Someone deletes something by accident? You click everything again. 😵

---

### Solution — Infrastructure as Code ✅

Instead of clicking — you **write code:**

```hcl
resource "aws_instance" "my_server" {
  ami           = "ami-0f58b397bc5c1f2e8"
  instance_type = "t3.micro"
}
```

Run one command:
```bash
terraform apply
```

**EC2 created. No clicking.** ✅

---

### What is Terraform?

> Terraform is a tool that lets you **create, update, and delete** any cloud infrastructure using code.

Works with AWS, GCP, Azure, and 100+ providers.

**Real Life Analogy 🏠**

```
Without Terraform:
→ Builder builds manually
→ Something wrong → rebuild manually
→ Build same house again → start from scratch

With Terraform:
→ Write blueprint (code)
→ Terraform builds automatically
→ Something wrong → fix code → reapply
→ Build same house again → run same code ✅
```

---

### 3 Things Terraform Does

```
1. CREATE   → build infrastructure from code
2. UPDATE   → change infrastructure by changing code
3. DESTROY  → delete everything with one command
```

---

### How Terraform Works — 4 Commands

```
Step 1 → Write code (.tf files)
Step 2 → terraform init    (setup)
Step 3 → terraform plan    (preview)
Step 4 → terraform apply   (create)
```

| Command | What it does |
|---|---|
| `terraform init` | Downloads AWS provider — like `npm install` |
| `terraform plan` | Preview what will be created — nothing happens yet |
| `terraform apply` | Actually creates infrastructure on AWS |
| `terraform destroy` | Deletes everything — always run after practice! |

---

### Key Terms

| Term | Meaning |
|---|---|
| Provider | Which cloud (AWS, GCP, Azure) |
| Resource | What to create (EC2, S3, VPC) |
| .tf file | Your code file |
| State file | Terraform's memory |
| Plan | Preview of changes |
| Apply | Actually create |
| Destroy | Delete everything |

---

### Terraform vs AWS Console

| | AWS Console | Terraform |
|---|---|---|
| Create infra | Manual clicks | One command |
| Recreate same infra | Click again | Run same code |
| Track changes | ❌ | ✅ Git history |
| Team sharing | ❌ | ✅ Push to GitHub |
| Dev + Prod same setup | Manual twice | Same code, different vars |
| Accident recovery | Click everything again | `terraform apply` |

---

### File Structure

```
day1-first-ec2/
├── provider.tf    ← tells Terraform to use AWS
└── main.tf        ← your infrastructure code
```

---

### provider.tf

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"    # Mumbai region
}
```

---

### main.tf

```hcl
resource "aws_instance" "my_first_ec2" {
  ami           = "ami-0f58b397bc5c1f2e8"   # Ubuntu 22.04 Mumbai
  instance_type = "t3.micro"

  tags = {
    Name        = "terraform-learning"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}
```

---

### Understanding the Code

```hcl
resource "aws_instance" "my_first_ec2" {
   │         │                │
   │         │                └── your name for this resource
   │         └── type of resource (EC2 instance)
   └── keyword — always "resource"
```

---

### Run It — Step by Step

```bash
# Step 1 — Initialize
terraform init

# Step 2 — Preview
terraform plan

# Step 3 — Create
terraform apply

# Step 4 — Delete after practice (save cost!)
terraform destroy
```

---

### Push to GitHub

```bash
git add .
git commit -m "day1: first EC2 with Terraform"
git push
```

---

### Day 1 Summary

```
✅ Understood what Terraform is
✅ Wrote first provider.tf
✅ Wrote first main.tf
✅ Ran all 4 commands
✅ Created real EC2 on AWS
✅ Pushed to GitHub
```

---

---

## Day 2 — Variables & Outputs

---

### Problem With Day 1 Code

Everything was **hardcoded:**

```hcl
ami           = "ami-0f58b397bc5c1f2e8"
instance_type = "t3.micro"
```

What if:
- Dev → t3.micro
- Prod → t3.large

You'd have to manually change code every time. ❌

---

### Solution — Variables ✅

> Variables in Terraform = same as `.env` file in your apps.

```
INSTANCE_TYPE=t3.micro
AMI_ID=ami-0f58b397bc5c1f2e8
```

Instead of hardcoding → use variables. 🎯

---

### File Structure

```
day2-variables/
├── provider.tf     ← same as day 1
├── variables.tf    ← defines all variables
├── main.tf         ← uses variables
└── outputs.tf      ← prints useful info after apply
```

---

### variables.tf

```hcl
variable "aws_region" {
  description = "AWS region to deploy in"
  type        = string
  default     = "ap-south-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "ami_id" {
  description = "Ubuntu 22.04 AMI ID"
  type        = string
  default     = "ami-0f58b397bc5c1f2e8"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "instance_name" {
  description = "Name of EC2 instance"
  type        = string
  default     = "terraform-learning"
}
```

---

### main.tf — Using Variables

```hcl
resource "aws_instance" "my_ec2" {
  ami           = var.ami_id           # using variable
  instance_type = var.instance_type    # using variable

  tags = {
    Name        = var.instance_name    # using variable
    Environment = var.environment      # using variable
    ManagedBy   = "terraform"
  }
}
```

---

### outputs.tf

```hcl
output "instance_id" {
  description = "EC2 Instance ID"
  value       = aws_instance.my_ec2.id
}

output "public_ip" {
  description = "Public IP of EC2"
  value       = aws_instance.my_ec2.public_ip
}

output "instance_type" {
  description = "Instance type used"
  value       = aws_instance.my_ec2.instance_type
}
```

After `terraform apply` you'll see:
```
Outputs:

instance_id   = "i-0abc123def456"
instance_type = "t3.micro"
public_ip     = "13.x.x.x"
```

---

### Override Variables From Command Line

```bash
# Create prod size instance
terraform apply -var="instance_type=t3.large" -var="environment=prod"

# Different region
terraform apply -var="aws_region=us-east-1"
```

Same code → different result. ✅

---

### terraform.tfvars — Cleaner Way

```hcl
# terraform.tfvars
instance_type = "t3.micro"
environment   = "dev"
instance_name = "my-dev-server"
aws_region    = "ap-south-1"
```

Terraform automatically reads this file:
```bash
terraform apply    # reads tfvars automatically ✅
```

---

### Dev vs Prod with tfvars 🎯

```hcl
# dev.tfvars
instance_type = "t3.micro"
environment   = "dev"
instance_name = "dev-server"
```

```hcl
# prod.tfvars
instance_type = "t3.large"
environment   = "prod"
instance_name = "prod-server"
```

```bash
# Deploy dev
terraform apply -var-file="dev.tfvars"

# Deploy prod
terraform apply -var-file="prod.tfvars"
```

**Same code — different environments!** 🎯

---

### tfstate vs tfstate.backup

| File | What it is |
|---|---|
| `terraform.tfstate` | Current state — what exists RIGHT NOW on AWS |
| `terraform.tfstate.backup` | Previous state — what existed BEFORE last apply |

```
Day 1 → apply → creates EC2
        tfstate        = {ec2: t3.micro}
        tfstate.backup = {}

Day 2 → change to t3.large → apply
        tfstate        = {ec2: t3.large}   ← current
        tfstate.backup = {ec2: t3.micro}   ← previous
```

> If tfstate gets corrupted → restore from tfstate.backup 🎯

---

### .gitignore — Important! 🔒

```
# Never push these to GitHub!
*.tfvars              # may contain secrets
.terraform/
*.tfstate             # contains AWS account details
*.tfstate.backup
.terraform.lock.hcl
```

---

### Push to GitHub

```bash
terraform destroy    # clean up first!
git add .
git commit -m "day2: variables and outputs"
git push
```

---

### Day 2 Summary

| | Day 1 | Day 2 |
|---|---|---|
| Values | Hardcoded | Variables |
| Dev vs Prod | Change code manually | Change tfvars file |
| After apply | Nothing printed | IP + ID printed |
| Reusability | ❌ | ✅ |

```
variables.tf  →  define variables (like .env file)
var.name      →  use variable in code
outputs.tf    →  print useful info after apply
tfvars file   →  set values per environment
```

---

## Quick Reference — All Commands

```bash
terraform init              # setup
terraform plan              # preview
terraform apply             # create
terraform destroy           # delete
terraform apply -var="key=value"           # override one variable
terraform apply -var-file="dev.tfvars"     # use tfvars file
```

---

*Generated during Terraform learning session — Day 1 & Day 2* 🚀
