terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}

provider "github" {
  owner = var.github_org

  # Use a PAT
  token = var.github_token
}

variable "github_org" {
  type = string
}

variable "github_token" {
  type      = string
  sensitive = true
}

# The GitHub App installation ID in *your org* (not the App ID).
# You can find it from the org installation URL, e.g. .../settings/installations/<ID>
variable "app_installation_id" {
  type = number
}

variable "repo_name" {
  type = string
}

data "github_repository" "target" {
  name = var.repo_name
}


resource "github_app_installation_repositories" "some_app_repos" {
  # The installation id of the app (in the organization).
  installation_id        = var.app_installation_id
  selected_repositories  = [data.github_repository.target.name]
}
