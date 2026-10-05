# SPDX-FileCopyrightText: 2026 Alexey Zhokhov
# SPDX-License-Identifier: Apache-2.0

variable "repository_policies" {
  description = "Authoritative map of managed repository names to their protection policy configuration"
  type = map(object({
    visibility      = string # "public" | "private"
    required_checks = list(string)
  }))
  default = {
    # The current Velnor CI aggregator is Required; DCO is an independent app check.
    "homebrew-tap" = {
      visibility      = "public"
      required_checks = ["Required", "DCO"]
    }
    "jackin" = {
      visibility      = "public"
      required_checks = ["Required", "DCO"]
    }
    "jackin-agent-smith" = {
      visibility      = "public"
      required_checks = ["Required", "DCO"]
    }
    "jackin-dev" = {
      visibility      = "public"
      required_checks = ["Required", "DCO"]
    }
    "jackin-github-terraform" = {
      visibility      = "public"
      required_checks = ["Required", "DCO"]
    }
    "jackin-marketplace" = {
      visibility      = "public"
      required_checks = ["Policy"]
    }
    "jackin-role-action" = {
      visibility      = "public"
      required_checks = ["Required", "DCO"]
    }
    "jackin-sentinel" = {
      visibility      = "public"
      required_checks = ["Required", "DCO"]
    }
    "jackin-the-architect" = {
      visibility      = "public"
      required_checks = ["Required", "DCO"]
    }
  }

  # There are no no-CI exceptions: every inventory entry must have a verified required context.
  validation {
    condition = alltrue([
      for policy in values(var.repository_policies) :
      length(policy.required_checks) > 0 && alltrue([
        for context in policy.required_checks : trimspace(context) != ""
      ])
    ])
    error_message = "Every managed repository must declare at least one nonblank, verified required CI context."
  }
}
