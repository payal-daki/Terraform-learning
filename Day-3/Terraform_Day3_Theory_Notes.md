# Terraform Learning — Day 3 🚀

---

## Remote State

---

### Why Remote State?

Local state problems:
```
❌ EC2 gets deleted → state file gone → disaster
❌ Team member can't access your state
❌ Two people run terraform apply same time → conflict
❌ No backup
```

Solution — store tfstate on S3:
```
✅ Safe forever
✅ Whole team can access
✅ Locking prevents conflicts
✅ S3 versioning = automatic backup
```

---

### Two Resources Needed

```
S3 Bucket   →  stores tfstate file
DynamoDB    →  locking (old way — now deprecated)
use_lockfile →  locking (new way ✅)
```

---

### Backend-setup/main.tf — Creates S3 + DynamoDB

```hcl
provider "aws" {
  region = "ap-south-1"
}

# S3 bucket to store state
resource "aws_s3_bucket" "terraform_state" {
  bucket = "terraform-state-piyu-2026"
  tags = {
    Name      = "terraform-state"
    ManagedBy = "terraform"
  }
}

# Enable versioning — every state change saved
resource "aws_s3_bucket_versioning" "state_versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Block all public access
resource "aws_s3_bucket_public_access_block" "state_public_access" {
  bucket                  = aws_s3_bucket.terraform_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# DynamoDB for locking (old way — kept for reference)
resource "aws_dynamodb_table" "terraform_lock" {
  name         = "terraform-state-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
  tags = {
    Name      = "terraform-lock"
    ManagedBy = "terraform"
  }
}
```

---

### Remote-state/main.tf — Uses S3 as Backend

```hcl
terraform {
  backend "s3" {
    bucket       = "terraform-state-piyu-2026"
    key          = "dev/terraform.tfstate"
    region       = "ap-south-1"
    use_lockfile = true      # new way — S3 handles locking
    encrypt      = true      # encrypt sensitive data in state
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}
```

---

### What Each Setting Does

| Setting | Purpose |
|---|---|
| `bucket` | Which S3 bucket stores tfstate |
| `key` | Path inside bucket |
| `use_lockfile` | Prevents two people running at same time |
| `encrypt` | Protects passwords inside state file |

---

### use_lockfile vs dynamodb_table

```
Old way (deprecated):
dynamodb_table = "terraform-state-lock"
→ DynamoDB handles locking

New way:
use_lockfile = true
→ S3 itself handles locking with .tflock file
→ Same result, simpler setup ✅
```

---

### State File Location in S3

```
S3 Bucket: terraform-state-piyu-2026
└── dev/terraform.tfstate     ← dev state
└── prod/terraform.tfstate    ← prod state
```

---

### Locking Flow

```
terraform apply starts
      │
      ▼
Creates .tflock file in S3 🔒
      │
      ▼
Creates/updates infrastructure
      │
      ▼
Saves new state to S3
      │
      ▼
Removes .tflock file 🔓
      │
      ▼
Done ✅
```

---

### Verify State in S3

```bash
# See state file in S3
aws s3 ls s3://terraform-state-piyu-2026/dev/

# Download and read state
aws s3 cp s3://terraform-state-piyu-2026/dev/terraform.tfstate .
cat terraform.tfstate
```

---

### Verify Locking

Terminal 1:
```bash
terraform apply   # run this
```

Terminal 2 (while apply is running):
```bash
aws dynamodb scan \
  --table-name terraform-state-lock \
  --region ap-south-1

# Count: 1 = locked 🔒
# Count: 0 = unlocked 🔓
```

---

### terraform init -reconfigure

Use this when you change backend config:

```bash
terraform init -reconfigure
```

---

## State Commands

---

### terraform state list
> See all resources Terraform is tracking

```bash
terraform state list
```

Output:
```
aws_instance.my_ec2
aws_s3_bucket.terraform_state
aws_dynamodb_table.terraform_lock
```

---

### terraform state show
> Full details of one resource

```bash
terraform state show aws_s3_bucket.terraform_state
```

---

### terraform show
> Full state in readable format

```bash
terraform show
```

---

### terraform state rm
> Remove resource from state WITHOUT deleting from AWS

```bash
terraform state rm aws_instance.my_ec2
```

Resource still exists on AWS — Terraform just stops tracking it.

When to use:
```
→ Want to manage resource manually
→ Moving to different state file
→ Resource imported wrongly
```

---

### terraform state mv
> Rename resource in state without touching AWS

```bash
terraform state mv \
  aws_instance.my_ec2 \
  aws_instance.web_server
```

Without mv:
```
→ Terraform deletes old EC2 ❌
→ Terraform creates new EC2 ❌
→ Downtime! 😵
```

With mv:
```
→ Just renames in state ✅
→ Same EC2, new name
→ Zero downtime 🎯
```

---

### terraform import
> Import existing AWS resource into Terraform

```bash
terraform import aws_instance.my_ec2 i-0abc123def456
```

When to use:
```
→ Infrastructure created before Terraform
→ Want Terraform to manage it
→ Import instead of recreate ✅
```

---

### terraform refresh
> Sync state file with actual AWS resources

```bash
terraform refresh
```

---

### State Drift

```
Terraform state says → t3.micro
Someone changed on AWS console → t3.large

terraform refresh → state updated ✅
terraform plan    → shows drift detected!
terraform apply   → brings back to t3.micro ✅
```

> State drift = reality doesn't match your code. 🎯

---

## Folder Structure

```
Day-3/
├── Backend-setup/
│     ├── main.tf       ← creates S3 + DynamoDB (run once)
│     └── .gitignore
└── Remote-state/
      ├── main.tf       ← uses S3 as backend
      └── .gitignore
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

## Quick Reference — All State Commands

```bash
terraform state list           # list all resources
terraform state show <name>    # details of one resource
terraform show                 # full state readable
terraform state rm <name>      # remove from state
terraform state mv <old> <new> # rename in state
terraform import <name> <id>   # import existing resource
terraform refresh               # sync state with AWS
terraform init -reconfigure    # reinitialize with new backend
```

---

## Day 3 Summary ✅

```
✅ Why remote state needed
✅ S3 bucket + versioning + public access block
✅ DynamoDB (old) vs use_lockfile (new)
✅ Backend config with encrypt + use_lockfile
✅ Verified locking in action
✅ Verified tfstate stored in S3
✅ State commands — list, show, rm, mv, import, refresh
✅ State drift concept
✅ Pushed to GitHub
```

---

*Day 3 complete — Remote State, S3 Backend, State Commands* 🚀
