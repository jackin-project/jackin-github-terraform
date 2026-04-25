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
    "jackin-the-architect",
    "validate-agent-action",
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
    jackin = ["Docs / build"]
  }
}
