variable "repository_policies" {
  description = "Map of repository names to their protection policy configurations"
  type = map(object({
    visibility      = string # "public" | "private"
    required_checks = list(string)
  }))

  validation {
    condition = alltrue([
      for name, config in var.repository_policies :
      contains(["public", "private"], config.visibility)
    ])
    error_message = "visibility must be either 'public' or 'private'."
  }

  # There are no no-CI exceptions: every inventory entry must have a verified required context.
  validation {
    condition = alltrue([
      for name, config in var.repository_policies :
      length(config.required_checks) > 0 && alltrue([
        for context in config.required_checks : trimspace(context) != ""
      ])
    ])
    error_message = "Every managed repository must declare at least one nonblank, verified required CI context."
  }
}
