# Terraform Day 2 — Theory Notes 📝

---

## What We Covered Today

```
Concept 1 → Variable Validation
Concept 2 → Sensitive Variables
Concept 3 → Locals
```

---

## Concept 1 — Variable Validation

### What is it?
Stops wrong values **before** they reach AWS.
Error appears immediately on your terminal — no API call wasted.

### Syntax

```hcl
variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}
```

### How to test

```bash
terraform plan -var="environment=production"
# Error: Environment must be dev, staging, or prod. ✅
```

### Key Points
- `condition` → the rule that must be true
- `error_message` → what you see when rule fails
- Validation runs before anything touches AWS
- Think of it like form validation in a web app — catch error early

### Interview Answer
> *"How do you prevent wrong variable values in Terraform?"*
> Add a `validation` block inside the variable with a `condition` and `error_message`.

---

## Concept 2 — Sensitive Variables

### What is it?
Hides secret values from terminal output so passwords never appear in logs.

### Syntax

```hcl
variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}
```

### What you see in terminal

```
Without sensitive = true:
+ db_password = "MySecret123"      ← dangerous ❌

With sensitive = true:
+ db_password = (sensitive value)  ← safe ✅
```

### Right way to pass sensitive values

```bash
# Never put secrets in tfvars — that file goes to GitHub ❌

# Use environment variable instead ✅
export TF_VAR_db_password="MySecret123"
terraform plan
```

### Key Points
- Add `sensitive = true` to any variable holding a secret
- Never store secrets in `terraform.tfvars`
- Pass via `TF_VAR_` environment variables
- In real projects use AWS Secrets Manager

### Interview Answer
> *"How do you handle secrets in Terraform?"*
> Mark variable as `sensitive = true`. Never store in tfvars files.
> Pass via `TF_VAR_` environment variables or AWS Secrets Manager.

---

## Concept 3 — Locals

### What is it?
Values you **calculate inside** your code — not inputs from outside.

### Variable vs Local — Simple Difference

```
Variable → value comes FROM OUTSIDE (you pass it or tfvars file)
Local    → value you CREATE INSIDE your code itself
```

### Real Life Analogy

```
First name = "Piyu"       ← variable (given from outside)
Last name  = "Patel"      ← variable (given from outside)
Full name  = "Piyu Patel" ← local (you combined two things)
```

### Syntax

```hcl
# locals.tf
locals {
  # combine two variables into one value
  full_name = "${var.environment}-${var.instance_name}"
  # if environment = "dev" and instance_name = "server"
  # full_name = "dev-server" ✅

  # common tags for ALL resources
  common_tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
    Owner       = "piyu"
  }
}
```

### How to use in main.tf

```hcl
resource "aws_instance" "my_ec2" {
  ami           = var.ami_id
  instance_type = var.instance_type

  tags = merge(local.common_tags, {
    Name = local.full_name
  })
}
```

### What merge() does

```
local.common_tags = { Environment, ManagedBy, Owner }
{ Name = local.full_name } = { Name }

merge() combines both →
{ Environment, ManagedBy, Owner, Name }  ✅
```

### Why common_tags?

```
Without locals → write tags in every resource → change in 5 places ❌
With locals    → write once → change in 1 place → updates everywhere ✅
```

### Key Points
- Use `local.` prefix to access (not `var.`)
- Perfect for computed values and shared tags
- Define in `locals.tf` (separate file, cleaner)
- `merge()` combines two tag maps into one

### Interview Answer
> *"What is the difference between a variable and a local in Terraform?"*
> Variable is an input from outside your code (passed by user or tfvars).
> Local is a value computed inside your code, like combining two variables.
> Locals are great for shared tags across all resources.

---

## File Structure After Day 2

```
Day-2/
├── provider.tf     ← same as Day 1
├── variables.tf    ← added validation + sensitive variable
├── locals.tf       ← NEW — full_name and common_tags
├── main.tf         ← updated to use locals
├── outputs.tf      ← same as Day 1
└── terraform.tfvars
```

---

## Quick Reference

| Concept | Keyword | Use for |
|---|---|---|
| Validation | `validation {}` | Reject wrong variable values |
| Sensitive | `sensitive = true` | Hide secrets from output |
| Locals | `locals {}` | Compute values inside code |
| Use locals | `local.name` | Reference a local value |
| Merge tags | `merge()` | Combine two tag maps |

---

## Commands Used Today

```bash
terraform init                              # setup providers
terraform plan                             # preview
terraform plan -var="environment=production"  # test validation
terraform plan -var="db_password=MySecret123" # test sensitive
terraform apply                            # create
terraform destroy                          # delete after practice
```

---

## Day 2 Checklist ✅

```
✅ Variable validation — reject wrong inputs
✅ Sensitive variables — hide secrets from output
✅ Locals — computed values and common tags
✅ merge() — combine tag maps
✅ Pushed to GitHub
```

---

*Day 2 complete — Validation, Sensitive Variables, Locals* 🚀
