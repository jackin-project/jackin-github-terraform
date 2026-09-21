terraform {
  required_version = ">= 1.5"

  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}

locals {
  managed_settings_repositories = toset([
    for repo, policy in var.repository_policies : repo
    if contains(["FullRuleset", "RepoSettingsOnly"], policy.disposition)
  ])

  full_ruleset_repositories = toset([
    for repo, policy in var.repository_policies : repo
    if policy.disposition == "FullRuleset"
  ])
}

# Repository-level merge settings (Tier 1 enforcement across all repos)
resource "github_repository" "managed_settings" {
  for_each = local.managed_settings_repositories

  name = each.value

  # Strict squash-only merge policy
  allow_squash_merge = true
  allow_merge_commit = false
  allow_rebase_merge = false

  # Standard commit title and body format
  squash_merge_commit_title   = "PR_TITLE"
  squash_merge_commit_message = "PR_BODY"

  # Branch lifecycle management
  allow_update_branch    = true
  delete_branch_on_merge = true

  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      description,
      homepage_url,
      has_issues,
      has_projects,
      has_wiki,
      has_discussions,
      visibility,
      archived,
      topics,
      vulnerability_alerts,
      allow_auto_merge,
      web_commit_signoff_required,
      pages,
      security_and_analysis,
    ]
  }
}

# Branch ruleset on main / default branch (Tier 2 ref protection)
resource "github_repository_ruleset" "protect_main" {
  for_each = local.full_ruleset_repositories

  name        = "protect-main"
  target      = "branch"
  enforcement = "active"
  repository  = each.value

  conditions {
    ref_name {
      include = ["~DEFAULT_BRANCH"]
      exclude = []
    }
  }

  # MANDATORY INVARIANT: Zero standing bypasses on core protections.
  # Direct pushes, non-squash integration, force pushes, and deletion are blocked for all actors.

  rules {
    deletion                = true
    non_fast_forward        = true
    required_linear_history = true

    pull_request {
      allowed_merge_methods             = ["squash"]
      required_approving_review_count   = 0
      dismiss_stale_reviews_on_push     = true
      require_last_push_approval        = false
      require_code_owner_review         = false
      required_review_thread_resolution = true
    }

    dynamic "required_status_checks" {
      for_each = length(var.repository_policies[each.value].required_checks) > 0 ? [1] : []
      content {
        strict_required_status_checks_policy = false
        do_not_enforce_on_create             = false

        dynamic "required_check" {
          for_each = var.repository_policies[each.value].required_checks
          content {
            context = required_check.value
          }
        }
      }
    }
  }
}

# Tag ruleset protecting all tags
resource "github_repository_ruleset" "protect_tags" {
  for_each = local.full_ruleset_repositories

  name        = "protect-tags"
  target      = "tag"
  enforcement = "active"
  repository  = each.value

  conditions {
    ref_name {
      include = ["~ALL"]
      exclude = []
    }
  }

  rules {
    deletion         = true
    non_fast_forward = true
  }
}
