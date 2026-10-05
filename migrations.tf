# SPDX-FileCopyrightText: 2026 Alexey Zhokhov
# SPDX-License-Identifier: Apache-2.0

# Forget this root's former ownership without deleting the GitHub objects.
removed {
  from = module.repository_policy

  lifecycle {
    destroy = false
  }
}

removed {
  from = github_repository.managed_settings

  lifecycle {
    destroy = false
  }
}

removed {
  from = github_repository_ruleset.protect_main

  lifecycle {
    destroy = false
  }
}

removed {
  from = github_repository_ruleset.protect_tags

  lifecycle {
    destroy = false
  }
}
