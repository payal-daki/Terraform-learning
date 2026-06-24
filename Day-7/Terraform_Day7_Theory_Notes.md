# Terraform Learning - Day 7

---

## Terraform + CI/CD

---

## Why CI/CD for Terraform?

Without CI/CD:
```
Developer manually runs:
terraform plan
terraform apply
```

Problems:
- Someone forgets to plan before apply
- No review process
- Different people run different versions
- No audit trail

With CI/CD:
- Every code push triggers pipeline automatically
- Team reviews plan before apply
- Consistent process every time
- Full audit trail in GitHub

---

## Real World Flow

```
Developer pushes code to GitHub
        |
        v
GitHub Actions triggers automatically
        |
        v
terraform fmt    -> code formatted?
terraform validate -> syntax correct?
terraform plan   -> shows what will change
        |
        v
Team reviews plan (on PR)
        |
        v
PR merged to main
        |
        v
terraform apply  -> infra updated automatically
```

---

## Why GitHub Actions Over Jenkins?

```
Jenkins        -> needs separate server to manage
GitHub Actions -> built into GitHub, free, zero setup
```

For Terraform CI/CD -> GitHub Actions is simpler and faster.

---

## File Structure

```
Terraform-learning/
├── Day-7/
│     ├── provider.tf
│     ├── variables.tf
│     ├── main.tf
│     └── outputs.tf
└── .github/
      └── workflows/
            └── terraform.yml
```

---

## .github/workflows/terraform.yml

```yaml
name: Terraform CI/CD

on:
  push:
    branches:
      - main
    paths:
      - 'Day-7/**'
  pull_request:
    branches:
      - main

jobs:
  terraform:
    name: Terraform Plan & Apply
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.7.0

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id:     ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region:            ap-south-1

      - name: Terraform Init
        run: terraform init
        working-directory: ./Day-7

      - name: Terraform Format Check
        run: terraform fmt -check
        working-directory: ./Day-7

      - name: Terraform Validate
        run: terraform validate
        working-directory: ./Day-7

      - name: Terraform Plan
        run: terraform plan -var="db_password=${{ secrets.DB_PASSWORD }}"
        working-directory: ./Day-7

      - name: Terraform Apply
        if: github.ref == 'refs/heads/main' && github.event_name == 'push'
        run: terraform apply -auto-approve -var="db_password=${{ secrets.DB_PASSWORD }}"
        working-directory: ./Day-7
```

---

## Understanding the Workflow File

```
on: push/pull_request  -> when to trigger pipeline
runs-on: ubuntu-latest -> GitHub provides free server
working-directory      -> which folder to run terraform in
secrets.AWS_ACCESS_KEY -> credentials stored safely in GitHub
if: github.ref == main -> apply only on main branch merge
```

---

## Add Secrets to GitHub

```
GitHub -> your repo
-> Settings
-> Secrets and variables
-> Actions
-> New repository secret

Add:
AWS_ACCESS_KEY_ID      -> your AWS access key
AWS_SECRET_ACCESS_KEY  -> your AWS secret key
DB_PASSWORD            -> your db password
```

Never hardcode credentials in workflow file!

---

## provider.tf

```hcl
terraform {
  backend "s3" {
    bucket       = "terraform-state-piyu-2026"
    key          = "day7/terraform.tfstate"
    region       = "ap-south-1"
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
  type    = string
  default = "ap-south-1"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "db_password" {
  type      = string
  sensitive = true
}
```

---

## main.tf

```hcl
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
```

---

## outputs.tf

```hcl
output "instance_id" {
  value = aws_instance.web.id
}

output "public_ip" {
  value = aws_instance.web.public_ip
}
```

---

## terraform fmt

```bash
terraform fmt          # formats all .tf files automatically
terraform fmt -check   # just checks, fails if not formatted
```

Like Prettier for JavaScript but for Terraform.
Pipeline fails if code is not formatted properly.

---

## terraform validate

```bash
terraform validate
```

Checks code for syntax errors before applying.

```
Valid configuration      -> pipeline continues
Error: missing argument  -> pipeline fails, fix before merge
```

---

## Pipeline Steps Explained

```
terraform fmt -check  -> is code properly formatted?
terraform validate    -> is syntax correct?
terraform plan        -> what will change?
terraform apply       -> make the changes (main branch only)
```

---

## PR vs Push Behavior

```
On Pull Request:
-> fmt check
-> validate
-> plan only (team reviews output)
-> NO apply

On Push to Main (after PR merge):
-> fmt check
-> validate
-> plan
-> apply (infra updated)
```

---

## Watch Pipeline Run

After pushing:
```
GitHub -> your repo -> Actions tab
-> See pipeline running live
-> Green = success
-> Red = something failed
```

---

## Full CI/CD Flow in Companies

```
Feature branch created
      |
      v
Developer writes Terraform code
      |
      v
Push to feature branch
      |
      v
Create Pull Request
      |
      v
Pipeline runs plan -> team sees what will change
      |
      v
Team approves PR
      |
      v
Merge to main
      |
      v
Pipeline runs apply -> infra updated automatically
```

---

## Push to GitHub

```bash
git add .
git commit -m "day7: terraform cicd with github actions"
git push
```

---

## Destroy After Practice

```bash
terraform destroy -var="db_password=Db_PASS"
```

---

## Summary

| Step | Command | Runs On |
|---|---|---|
| Format check | terraform fmt -check | Every push + PR |
| Validate | terraform validate | Every push + PR |
| Plan | terraform plan | Every push + PR |
| Apply | terraform apply | Main branch only |

```
Secrets in GitHub   -> AWS credentials safe
Auto plan on PR     -> team reviews before apply
Auto apply on merge -> infra updated automatically
No manual apply     -> ever again
```

---

## Terraform Week Complete!

```
Day 1 - Basics + First EC2
Day 2 - Variables + Locals + Validation
Day 3 - Remote State + S3 + Locking
Day 4 - VPC + Networking
Day 5 - Modules
Day 6 - Full Project EC2 + VPC + RDS + S3
Day 7 - Terraform + CI/CD with GitHub Actions
```

---

*Day 7 complete - Terraform CI/CD with GitHub Actions*
