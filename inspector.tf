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



# Immediately enable Inspector in existing accounts (per region)
resource "aws_inspector2_enabler" "members" {
  provider       = aws.delegated
  for_each       = toset(var.member_account_ids)
  account_ids    = [each.key]
  resource_types = ["EC2", "ECR", "LAMBDA"]

  depends_on = [aws_inspector2_organization_configuration.this]
}

















data "aws_caller_identity" "delegated" {
#   provider = aws.delegated
}
resource "aws_inspector2_enabler" "self" {
#   provider       = aws.delegated
  # account_ids is optional in recent providers; if yours requires it, uncomment next line:
  # account_ids    = [data.aws_caller_identity.delegated.account_id]
  resource_types = ["EC2", "ECR", "LAMBDA"]
  account_ids    = [data.aws_caller_identity.delegated.account_id]

}
# Enable org-wide auto-enrollment for NEW accounts (per region)
resource "aws_inspector2_organization_configuration" "this" {
#   provider = aws.delegated
  lifecycle { create_before_destroy = true }

  auto_enable {
    ec2    = true
    ecr    = true
    lambda = true
  }

  depends_on = [aws_inspector2_enabler.self ]
}



# Immediately enable Inspector in existing accounts (per region)
# resource "aws_inspector2_enabler" "members" {
# #   provider       = aws.delegated
#   for_each       = toset(local.member_account_ids)
#   account_ids    = [each.key]
#   resource_types = ["EC2", "ECR", "LAMBDA"]

#   depends_on = [aws_inspector2_organization_configuration.this]
# }



# MANAGEMENT account: associate first, then enable
resource "aws_inspector2_member_association" "management" {
#   provider   = aws.delegated
  account_id = "339713106964"
  depends_on = [aws_inspector2_enabler.self]
}

resource "aws_inspector2_enabler" "management" {
#   provider       = aws.delegated
  account_ids    = ["339713106964"]
  resource_types = ["EC2", "ECR", "LAMBDA", "LAMBDA_CODE"]
  depends_on     = [aws_inspector2_member_association.management]
}
locals {
  member_account_ids = ["339713106964"]
}
