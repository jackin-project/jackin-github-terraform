# Deprecated repository-policy root

This repository is being retired as an owner of Jackin GitHub repository settings and rulesets. The planned source of truth is the [ChainArgos GitHub Terraform control plane](https://github.com/ChainArgos/github-terraform), which centralizes policies across organizations.

Do not merge this retirement until the central control-plane change is on its default branch and its reviewed plan confirms it adopts the existing nine Jackin repositories and their rulesets. The control plane should be the only root that declares or imports these policies.

The handoff inventory is:

- `homebrew-tap`
- `jackin`
- `jackin-agent-smith`
- `jackin-dev`
- `jackin-github-terraform`
- `jackin-marketplace`
- `jackin-role-action`
- `jackin-sentinel`
- `jackin-the-architect`

This root intentionally contains no GitHub provider, repository inventory, repository or ruleset resources, or import blocks. The `removed` blocks in `migrations.tf` forget any legacy local-state ownership with `destroy = false`; they do not delete GitHub repositories or rulesets. CI initializes with `-backend=false`, and this root does not configure a remote backend.
