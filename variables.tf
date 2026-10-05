# SPDX-FileCopyrightText: 2026 Alexey Zhokhov
# SPDX-License-Identifier: Apache-2.0

variable "repository_policies" {
  description = "Authoritative map of managed repository names to their protection policy configuration"
  type = map(object({
    disposition     = string # "FullRuleset" | "RepoSettingsOnly"
    visibility      = string # "public" | "private"
    required_checks = list(string)
  }))
  default = {
    # The current Velnor CI aggregator is Required; DCO is an independent app check.
    "homebrew-tap" = {
      disposition     = "FullRuleset"
      visibility      = "public"
      required_checks = ["Required", "DCO"]
    }
    "jackin" = {
      disposition     = "FullRuleset"
      visibility      = "public"
      required_checks = ["Required", "DCO"]
    }
    "jackin-agent-smith" = {
      disposition     = "FullRuleset"
      visibility      = "public"
      required_checks = ["Required", "DCO"]
    }
    "jackin-dev" = {
      disposition     = "FullRuleset"
      visibility      = "public"
      required_checks = ["Required", "DCO"]
    }
    "jackin-github-terraform" = {
      disposition     = "FullRuleset"
      visibility      = "public"
      required_checks = ["Required", "DCO"]
    }
    "jackin-marketplace" = {
      disposition     = "FullRuleset"
      visibility      = "public"
      required_checks = ["Policy"]
    }
    "jackin-role-action" = {
      disposition     = "FullRuleset"
      visibility      = "public"
      required_checks = ["Required", "DCO"]
    }
    "jackin-sentinel" = {
      disposition     = "FullRuleset"
      visibility      = "public"
      required_checks = ["Required", "DCO"]
    }
    "jackin-the-architect" = {
      disposition     = "FullRuleset"
      visibility      = "public"
      required_checks = ["Required", "DCO"]
    }
  }
}
