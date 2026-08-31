# SPDX-FileCopyrightText: 2026 Alexey Zhokhov
# SPDX-License-Identifier: Apache-2.0

resource "github_repository_ruleset" "protect_main" {
  for_each = toset(var.protected_repositories)

  repository  = each.value
  name        = "protect-main"
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["~DEFAULT_BRANCH"]
      exclude = []
    }
  }

  rules {
    pull_request {
      # Solo-maintainer repo. Requiring an approving review would
      # block every merge — GitHub does not let the PR author approve
      # their own PR. Required status checks remain the merge safety net.
      # Revisit if/when the project has a second human reviewer.
      required_approving_review_count = 0
      dismiss_stale_reviews_on_push   = true
      require_last_push_approval      = false
    }

    dynamic "required_status_checks" {
      for_each = length(lookup(var.repo_required_status_checks, each.value, [])) > 0 ? [1] : []
      content {
        dynamic "required_check" {
          for_each = lookup(var.repo_required_status_checks, each.value, [])
          content {
            context = required_check.value
          }
        }
      }
    }

    non_fast_forward = true
    deletion         = true
  }
}

resource "github_repository_ruleset" "protect_tags" {
  for_each = toset(var.protected_repositories)

  repository  = each.value
  name        = "protect-tags"
  target      = "tag"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["~ALL"]
      exclude = []
    }
  }

  rules {
    non_fast_forward = true
    deletion         = true
  }
}

resource "github_repository" "managed_settings" {
  for_each = toset(var.protected_repositories)

  name = each.value

  allow_merge_commit          = false
  allow_squash_merge          = true
  allow_rebase_merge          = false
  squash_merge_commit_title   = "PR_TITLE"
  squash_merge_commit_message = "PR_BODY"
  allow_update_branch         = true
  delete_branch_on_merge      = true

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
