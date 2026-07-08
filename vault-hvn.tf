##############################################
# Variables - replace with your actual values
##############################################

variable "hcp_vault_public_url" {
  description = "HCP Vault Dedicated public cluster URL, e.g. https://my-cluster.vault.abc123.aws.hashicorp.cloud:8200"
  type        = string
}

variable "aws_account_id" {
  type = string
}

variable "vault_wif_audience" {
  description = "Arbitrary but unique audience string - must match on both AWS OIDC provider and Vault config"
  type        = string
  default     = "vault.example/v1/identity/oidc/plugins"
}

##############################################
# 1. Discover the TLS thumbprint of the Vault
#    identity token issuer (needed for the AWS
#    OIDC provider registration)
##############################################

data "tls_certificate" "vault_identity" {
  url = var.hcp_vault_public_url
}

##############################################
# 2. AWS: IAM OIDC identity provider trusting
#    Vault's plugin identity token issuer
##############################################

resource "aws_iam_openid_connect_provider" "vault" {
  url             = "${var.hcp_vault_public_url}/v1/identity/oidc/plugins"
  client_id_list  = [var.vault_wif_audience]
  thumbprint_list = [data.tls_certificate.vault_identity.certificates[0].sha1_fingerprint]
}

##############################################
# 3. AWS: IAM role Vault will assume via
#    AssumeRoleWithWebIdentity
##############################################

data "aws_iam_policy_document" "vault_wif_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.vault.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.vault.url, "https://", "")}:aud"
      values   = [var.vault_wif_audience]
    }
  }
}

resource "aws_iam_role" "vault_aws_auth_wif" {
  name               = "vault-aws-auth-wif-role"
  assume_role_policy = data.aws_iam_policy_document.vault_wif_trust.json
}

##############################################
# 4. AWS: minimum permissions Vault's AWS auth
#    engine needs to validate logins
#    (iam auth_type + optional ec2 auth_type)
##############################################

resource "aws_iam_role_policy" "vault_aws_auth_permissions" {
  name = "vault-aws-auth-permissions"
  role = aws_iam_role.vault_aws_auth_wif.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["iam:GetRole", "iam:GetUser", "iam:GetInstanceProfile"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["ec2:DescribeInstances"]
        Resource = "*"
      }
    ]
  })
}

##############################################
# 5. Vault: enable the AWS auth backend
##############################################

resource "vault_auth_backend" "aws" {
  type = "aws"
  path = "aws"
}

##############################################
# 6. Vault: configure the client using WIF
#    (no access_key / secret_key needed)
##############################################

resource "vault_aws_auth_backend_client" "this" {
  backend = vault_auth_backend.aws.path

  identity_token_audience = var.vault_wif_audience
  identity_token_ttl      = 3600
  role_arn                = aws_iam_role.vault_aws_auth_wif.arn
}

##############################################
# 7. Vault: example role for a workload to
#    authenticate against (iam auth_type)
##############################################

resource "vault_aws_auth_backend_role" "example" {
  backend   = vault_auth_backend.aws.path
  role      = "my-app-role"
  auth_type = "iam"

  bound_iam_principal_arns = [
    "arn:aws:iam::${var.aws_account_id}:role/my-app-role"
  ]

  token_ttl      = 3600
  token_max_ttl  = 14400
  token_policies = ["default"]
}
