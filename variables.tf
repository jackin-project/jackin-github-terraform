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
