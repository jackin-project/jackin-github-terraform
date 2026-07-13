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
    # The aggregator names (`ci-required`, `construct-required`,
    # `docs-required`) come from jackin-project/jackin#256 and roll up the
    # path-aware-gated jobs in each workflow — branch protection lists the
    # aggregators rather than the underlying jobs so adding or removing a
    # gated job under them does not require a terraform change.
    #
    # `validate` is the Renovate-config-validator workflow's only job
    # (`renovate-validate.yml`). It catches silent drift in the deb /
    # github-releases datasources behind `customManagers` — the failure
    # mode that #256 was specifically built to prevent.
    #
    # `docs-link-check` continues to be required directly because the
    # path-aware split in #256 keeps `docs-required` aggregating
    # `[changes, repo-link-check, docs-link-check, deploy]`, but the
    # docs deploy is push-only, so on a `pull_request` event
    # `docs-link-check` is the actual proof the docs build still
    # succeeds against the PR diff.
    #
    # `DCO` is enforced by the cncf/dco2 GitHub App, not by an Actions
    # workflow, but it appears as a status check on every PR and is the
    # gate for the project's contribution model.
    jackin = [
      "ci-required",
      "construct-required",
      "docs-required",
      "docs-link-check",
      "validate",
      "DCO",
    ]
  }
}
