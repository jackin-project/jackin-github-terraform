variable "protected_repositories" {
  description = "List of repositories to apply branch protection rules to"
  type        = list(string)
  default = [
    "jackin",
    "jackin-the-architect",
    "jackin-agent-smith",
    "jackin-dev",
    "jackin-marketplace",
  ]
}
