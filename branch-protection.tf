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
      required_approving_review_count = 1
      dismiss_stale_reviews_on_push   = true
    }

    non_fast_forward = true
    deletion         = true
  }
}

resource "github_repository" "managed_settings" {
  for_each = toset(var.protected_repositories)

  name = each.value

  allow_merge_commit  = false
  allow_squash_merge  = true
  allow_rebase_merge  = true
  allow_update_branch = true
}
