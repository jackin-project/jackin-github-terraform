# SPDX-FileCopyrightText: 2026 Alexey Zhokhov
# SPDX-License-Identifier: Apache-2.0

# Module refactoring: migrate root-level resources into module.repository_policy
moved {
  from = github_repository.managed_settings
  to   = module.repository_policy.github_repository.managed_settings
}

moved {
  from = github_repository_ruleset.protect_main
  to   = module.repository_policy.github_repository_ruleset.protect_main
}

moved {
  from = github_repository_ruleset.protect_tags
  to   = module.repository_policy.github_repository_ruleset.protect_tags
}
