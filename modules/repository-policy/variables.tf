variable "repository_policies" {
  description = "Map of repository names to their protection policy configurations"
  type = map(object({
    disposition     = string # "FullRuleset" | "RepoSettingsOnly"
    visibility      = string # "public" | "private"
    required_checks = list(string)
  }))

  validation {
    condition = alltrue([
      for name, config in var.repository_policies :
      contains(["FullRuleset", "RepoSettingsOnly"], config.disposition)
    ])
    error_message = "disposition must be either 'FullRuleset' or 'RepoSettingsOnly'."
  }

  validation {
    condition = alltrue([
      for name, config in var.repository_policies :
      contains(["public", "private"], config.visibility)
    ])
    error_message = "visibility must be either 'public' or 'private'."
  }
}
