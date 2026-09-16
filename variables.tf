# SPDX-FileCopyrightText: 2026 Alexey Zhokhov
# SPDX-License-Identifier: Apache-2.0

variable "protected_repositories" {
  description = "List of repositories to apply branch protection rules to"
  type        = list(string)
  default = [
    "homebrew-tap",
    "jackin",
    "jackin-agent-smith",
    "jackin-dev",
    "jackin-github-terraform",
    "jackin-marketplace",
    "jackin-role-action",
    "jackin-sentinel",
    "jackin-the-architect",
  ]
}

# Per-repository list of status check contexts that must pass before a PR
# can merge into the default branch. Context names are "<workflow name> /
# <job name>" for GitHub Actions checks. Repos absent from this map have no
# required status checks.
variable "repo_required_status_checks" {
  description = "Map of repository name to list of required status check contexts that must pass before merging into the default branch."
  type        = map(list(string))
  default = {
    # GitHub's required-status-check matcher uses the bare check-run name
    # field, not the `<workflow> / <job>` display string shown in PR UIs.
    #
    # `ci-required` (`ci-pr.yml`) rolls up the path-aware-gated unit jobs,
    # so adding or removing a gated job under it does not require a
    # terraform change.
    #
    # `Policy` (`ci-policy.yml`) is the velnor-workflow validator: it
    # requires the live ruleset to equal the generator-declared union, and
    # requires itself to be live-required so the gate is never advisory.
    #
    # `DCO` is enforced by the cncf/dco2 GitHub App, not by an Actions
    # workflow, but it appears as a status check on every PR and is the
    # gate for the project's contribution model.
    #
    # The `construct-required`, `docs-required`, `docs-link-check`, and
    # `validate` aggregators were dropped with their workflows in
    # jackin-project/jackin#992; requiring them blocks every merge.
    jackin = [
      "ci-required",
      "DCO",
      "Policy",
    ]
    "homebrew-tap"         = ["ci-required", "DCO"]
    "jackin-agent-smith"   = ["ci-required", "DCO"]
    "jackin-dev"           = ["ci-required", "DCO"]
    "jackin-role-action"   = ["ci-required", "DCO"]
    "jackin-sentinel"      = ["ci-required", "DCO"]
    "jackin-the-architect" = ["ci-required", "DCO"]
  }
}
