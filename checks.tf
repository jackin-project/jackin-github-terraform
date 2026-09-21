# SPDX-FileCopyrightText: 2026 Alexey Zhokhov
# SPDX-License-Identifier: Apache-2.0

# Deterministic invariant assertions to prevent policy weakening and inventory omissions

check "mandatory_target_repositories_present" {
  assert {
    condition = length(setsubtract([
      "homebrew-tap",
      "jackin",
      "jackin-agent-smith",
      "jackin-dev",
      "jackin-github-terraform",
      "jackin-role-action",
      "jackin-sentinel",
      "jackin-the-architect",
    ], keys(var.repository_policies))) == 0
    error_message = "One or more mandatory jackin-project target repositories are missing from repository_policies."
  }
}

check "self_protection_enforced" {
  assert {
    condition     = lookup(var.repository_policies, "jackin-github-terraform", null) != null && var.repository_policies["jackin-github-terraform"].disposition == "FullRuleset"
    error_message = "jackin-github-terraform must protect itself with FullRuleset disposition."
  }
}

check "delete_branch_on_merge_mandate" {
  assert {
    condition = alltrue([
      for name, repo in module.repository_policy.repository_settings :
      repo.delete_branch_on_merge == true
    ])
    error_message = "All managed repositories must enforce delete_branch_on_merge = true."
  }
}

check "squash_only_merge_mandate" {
  assert {
    condition = alltrue([
      for name, repo in module.repository_policy.repository_settings :
      repo.allow_squash_merge == true &&
      repo.allow_merge_commit == false &&
      repo.allow_rebase_merge == false &&
      repo.squash_merge_commit_title == "PR_TITLE" &&
      repo.squash_merge_commit_message == "PR_BODY"
    ])
    error_message = "All managed repositories must enforce squash-only merge policy with PR_TITLE/PR_BODY."
  }
}
