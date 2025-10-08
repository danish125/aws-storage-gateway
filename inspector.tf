variable "region" {
  description = "Region to configure (repeat for each region you need)"
  type        = string
  default     = "eu-west-1"
}

variable "delegated_admin_account_id" {
  description = "AWS Account ID you want to designate as Amazon Inspector delegated admin"
  type        = string
}

# Optional: existing member accounts to enable now (new ones will be auto-enabled)
variable "member_account_ids" {
  description = "List of existing member account IDs to enable Inspector in this region"
  type        = list(string)
  default     = []
}


# Management (root) account provider (assume a role there, or use env creds)
provider "aws" {
  alias  = "mgmt"
  region = var.region
  # assume_role { role_arn = "arn:aws:iam::<MANAGEMENT_ACCOUNT_ID>:role/<ROLE_NAME>" }
}

# Delegated admin account provider
provider "aws" {
  alias  = "delegated"
  region = var.region
  # assume_role { role_arn = "arn:aws:iam::${var.delegated_admin_account_id}:role/<ROLE_NAME_IN_DELEGATED_ADMIN>" }
}


# Must be applied from the ORGANIZATION MANAGEMENT account context
resource "aws_inspector2_delegated_admin_account" "this" {
  provider   = aws.mgmt
  account_id = var.delegated_admin_account_id
}


# Enable org-wide auto-enrollment for NEW accounts (per region)
resource "aws_inspector2_organization_configuration" "this" {
  provider = aws.delegated

  auto_enable {
    ec2    = true
    ecr    = true
    lambda = true
  }

  depends_on = [aws_inspector2_delegated_admin_account.this]
}
