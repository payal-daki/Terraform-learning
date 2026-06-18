# Terraform Day 1 -- Theory Notes

# Goal of Day 1

The objective of Day 1 is to understand how Terraform creates
infrastructure on AWS and what each file in a Terraform project is used
for.

------------------------------------------------------------------------

# What is Terraform?

Terraform is an **Infrastructure as Code (IaC)** tool.

Instead of creating AWS resources manually from the AWS Console, you
write code in `.tf` files.

Terraform then: 1. Reads your code. 2. Creates an execution plan. 3.
Creates or updates AWS resources. 4. Saves the current infrastructure
state.

------------------------------------------------------------------------

# Typical Day 1 Folder Structure

``` text
Day-1/
├── provider.tf
├── main.tf
├── variables.tf      (optional)
├── outputs.tf        (optional)
├── terraform.tfvars  (optional)
└── terraform.tfstate (created automatically)
```

------------------------------------------------------------------------

# provider.tf

## Purpose

Tells Terraform **which cloud provider** it should talk to.

Example:

``` hcl
provider "aws" {
  region = "ap-south-1"
}
```

Without a provider, Terraform does not know whether it should create
resources in AWS, Azure, or GCP.

Think of it as choosing the cloud platform.

------------------------------------------------------------------------

# main.tf

## Purpose

Contains the actual infrastructure.

Example:

``` hcl
resource "aws_instance" "web" {
  ami           = "ami-xxxxxxxx"
  instance_type = "t2.micro"
}
```

This tells Terraform to create an EC2 instance.

Usually, most resources are placed inside `main.tf`.

------------------------------------------------------------------------

# variables.tf

## Purpose

Stores input variables.

Instead of hardcoding values, we create variables.

Instead of:

``` hcl
instance_type = "t2.micro"
```

we write

``` hcl
instance_type = var.instance_type
```

Advantages:

-   Reusable
-   Easy to change
-   Better for different environments

------------------------------------------------------------------------

# terraform.tfvars

## Purpose

Stores actual values for variables.

Example:

``` hcl
instance_type = "t3.micro"
region = "ap-south-1"
```

The code stays the same while only values change.

------------------------------------------------------------------------

# outputs.tf

## Purpose

Displays useful information after Terraform finishes.

Example:

``` hcl
output "public_ip" {
  value = aws_instance.web.public_ip
}
```

Useful for:

-   EC2 Public IP
-   Instance ID
-   DNS Name

------------------------------------------------------------------------

# terraform.tfstate

## Purpose

The most important Terraform file.

Terraform uses it as its memory.

It stores:

-   Resources created
-   Resource IDs
-   Current infrastructure
-   Attribute values

Without the state file, Terraform cannot know what already exists.

Never edit this file manually.

------------------------------------------------------------------------

# .terraform Folder

Created automatically after:

``` bash
terraform init
```

Contains:

-   Provider plugins
-   Terraform modules
-   Internal files

Normally committed? **No**.

------------------------------------------------------------------------

# .terraform.lock.hcl

Locks provider versions.

Ensures every developer uses the same provider version.

Usually committed to Git.

------------------------------------------------------------------------

# README.md

Explains:

-   Project purpose
-   Commands
-   Prerequisites
-   Folder structure

Useful for documentation.

------------------------------------------------------------------------

# Terraform Workflow

``` text
Write Terraform Code
        │
        ▼
terraform init
        │
Downloads provider plugins
        ▼
terraform plan
        │
Shows what will change
        ▼
terraform apply
        │
Creates infrastructure
        ▼
terraform.tfstate updated
```

------------------------------------------------------------------------

# Summary

  File                  Why we use it
  --------------------- -------------------------------------
  provider.tf           Connect Terraform to AWS
  main.tf               Define infrastructure
  variables.tf          Declare reusable inputs
  terraform.tfvars      Store variable values
  outputs.tf            Display useful outputs
  terraform.tfstate     Store current infrastructure state
  .terraform            Provider plugins and internal files
  .terraform.lock.hcl   Lock provider versions
  README.md             Project documentation

------------------------------------------------------------------------

# Key Takeaways

-   **provider.tf** → Which cloud to use.
-   **main.tf** → What infrastructure to create.
-   **variables.tf** → Make code reusable.
-   **terraform.tfvars** → Store environment-specific values.
-   **outputs.tf** → Display important information.
-   **terraform.tfstate** → Terraform's memory.
-   **.terraform** → Downloaded provider plugins.
-   **README.md** → Documentation for the project.

Day 1 builds the foundation for everything else in Terraform.

