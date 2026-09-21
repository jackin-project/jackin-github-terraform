output "managed_settings_repositories" {
  description = "Set of repository names with managed repository-level merge settings"
  value       = local.managed_settings_repositories
}

output "full_ruleset_repositories" {
  description = "Set of repository names with active branch and tag rulesets"
  value       = local.full_ruleset_repositories
}

output "repository_settings" {
  description = "Map of repository merge and lifecycle settings"
  value = {
    for k, v in github_repository.managed_settings : k => {
      allow_squash_merge          = v.allow_squash_merge
      allow_merge_commit          = v.allow_merge_commit
      allow_rebase_merge          = v.allow_rebase_merge
      squash_merge_commit_title   = v.squash_merge_commit_title
      squash_merge_commit_message = v.squash_merge_commit_message
      allow_update_branch         = v.allow_update_branch
      delete_branch_on_merge      = v.delete_branch_on_merge
    }
  }
}
