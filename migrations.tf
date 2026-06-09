moved {
  from = github_repository.managed_settings["validate-agent-action"]
  to   = github_repository.managed_settings["jackin-role-action"]
}

moved {
  from = github_repository_ruleset.protect_main["validate-agent-action"]
  to   = github_repository_ruleset.protect_main["jackin-role-action"]
}

import {
  to = github_repository.managed_settings["jackin-sentinel"]
  id = "jackin-sentinel"
}

import {
  to = github_repository_ruleset.protect_tags["jackin-role-action"]
  id = "jackin-role-action:16515394"
}
