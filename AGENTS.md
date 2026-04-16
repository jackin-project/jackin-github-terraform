# AGENTS.md — jackin-github-terraform

This repository manages GitHub org settings (branch protection rulesets, repo merge policy) via OpenTofu. **It is public.** Assume anything committed here is world-readable and indexed by GitHub, Google, and archival mirrors — there is no "undo" for a leaked secret.

Treat every change as if it will be screenshotted and posted on Hacker News.

## Threat model

The assets this repo can leak:

1. **GitHub PAT / App credentials** used to run `tofu apply`. These have write access to org settings — a leak lets an attacker weaken branch protection, disable required checks, or push malicious code to default branches.
2. **`terraform.tfstate`** — contains the GitHub token used at last apply in plaintext (OpenTofu stores provider config including sensitive env values in the state file, which still uses the `terraform.tfstate` default filename for compatibility).
3. **Plan files (`*.tfplan`)** — same risk as state.
4. **Future secrets added to `.tf` files** — if anyone ever hardcodes a token "temporarily for testing," it lands in git history forever, even if deleted in a later commit.

## Hard rules (do not break these)

1. **Never commit files matching `.gitignore`.** The ignore list is curated for this threat model; do not narrow it without a security review. If you need to track something that matches (e.g., an `.env.example`), use `!` negation for that specific file, not a broad rule change.
2. **Never hardcode credentials in `.tf` files.** The GitHub provider authenticates via environment variables (`GITHUB_TOKEN`, `GITHUB_APP_*`). If a `.tf` file needs a secret, it is wrong — refactor to use an env var or data source.
3. **Never commit `.tfvars`.** Even "non-sensitive" vars can leak private repo names or internal structure. If a variable genuinely needs committing, inline it in `variables.tf` with a `default`.
4. **Never force-push to `main`** after this repo is included in the protected ruleset (self-referentially protected). Use PRs.
5. **Never disable or weaken the protection on this repo** in `variables.tf` without a documented rationale and a rollback plan.

## Required pre-commit checks

Run both of these before every `git commit`. If either returns anything, **stop and investigate.**

```bash
# 1. What's about to be committed? Make sure nothing surprising is staged.
git status --porcelain

# 2. Secret-pattern scan across staged content only.
#    (A broader audit over all tracked files is a separate manual step; see
#     the "Periodic full-history audit" section below.)
git diff --cached --name-only -z | xargs -0 -r \
  grep -l -iE "ghp_|gho_|ghs_|ghr_|github_pat_|BEGIN [A-Z ]*PRIVATE KEY|aws_access_key_id|aws_secret_access_key|bearer [a-z0-9-]{20,}" 2>/dev/null
```

If check 2 prints a filename: do not commit. Rotate the leaked credential immediately (GitHub tokens: delete and regenerate; SSH keys: revoke), then remove the content.

## Periodic full-history audit

The pre-commit scan only inspects staged content. Before a high-risk event (making this repo public, onboarding a new collaborator, rotating a major credential), also run the broader scan against every tracked file and every commit in history:

```bash
# Tracked content
git ls-files -z | xargs -0 -r \
  grep -l -iE "ghp_|gho_|ghs_|ghr_|github_pat_|BEGIN [A-Z ]*PRIVATE KEY|aws_access_key_id|aws_secret_access_key|bearer [a-z0-9-]{20,}" 2>/dev/null

# Git history (every blob ever committed)
git log -p --all -G "ghp_|gho_|ghs_|ghr_|github_pat_|BEGIN [A-Z ]*PRIVATE KEY|aws_access_key_id|aws_secret_access_key" | head -200
```

If either prints anything that isn't a documentation reference to the patterns themselves, rotate and document the incident.

## Required post-apply verification

After running `tofu apply`, before your next commit:

```bash
# Must output NOTHING. If anything shows up, the .gitignore failed — add the pattern first.
git status --porcelain | grep -iE "tfstate|tfplan|\.env|\.pem|\.key"
```

## Working with credentials

The provider takes credentials from the environment. Set them in your shell session, never in a file tracked by git:

```bash
# Option 1: Personal Access Token (fine-grained, org-scoped)
export GITHUB_TOKEN="<paste-token-here>"

# Option 2: GitHub App (preferred for production)
export GITHUB_APP_ID="..."
export GITHUB_APP_INSTALLATION_ID="..."
export GITHUB_APP_PEM_FILE="$(cat ~/.secrets/jackin-terraform-app.pem)"
```

Store the values in a password manager or a file **outside** this repo (`~/.secrets/`, `~/.config/`, etc.). Consider [`direnv`](https://direnv.net/) with an `.envrc` that lives outside this directory tree, or [`1password-cli`](https://developer.1password.com/docs/cli/) for just-in-time secret injection.

## State file handling

- `terraform.tfstate` is local-only. It stays on your machine.
- Back it up to an encrypted location if you need recovery (not S3/GCS public buckets, not a git submodule).
- If the state is ever lost, you can recover by re-importing every resource — painful but possible. See `tofu import` docs.
- Never email, Slack, or paste state contents.

## If a secret is leaked

Assume the credential is compromised the instant it hits a public commit.

1. **Rotate immediately.** GitHub token: delete it in Settings → revoke all associated grants → generate a new one. GitHub App: regenerate the private key.
2. **Force-push is not enough.** GitHub caches and indexes commits; the leaked value may already be scraped. Rotation is the only real remediation.
3. **Audit logs.** Check `gh api /orgs/jackin-project/audit-log` (requires Enterprise) or `gh api /user/events` for the user whose token leaked to spot any malicious API use.
4. **Document the incident** — add a note to this file if the threat model shifts.

## Rotating the OpenTofu runner token

When the PAT approaches expiration (or on a quarterly schedule):

```bash
# 1. Create new token in GitHub UI with the required scopes
# 2. Update your shell/secret manager
export GITHUB_TOKEN="<paste-new-token-here>"

# 3. Verify tofu still works
tofu plan

# 4. Delete the old token in GitHub Settings → Personal access tokens
```

Rotation is cheap. Do it on a schedule, not only after incidents.

## Manually-managed org settings

Not every GitHub org setting is reachable via Terraform/OpenTofu. Some are only exposed in the GitHub Web UI — the `integrations/terraform-provider-github` provider doesn't wrap them, and in some cases the GitHub REST API itself treats them as read-only. Changes to these settings live outside IaC and must be verified periodically for drift.

### Current manually-managed settings

| Setting | Desired | Verified | Source of truth |
|---|---|---|---|
| `members_can_delete_repositories` | `false` | 2026-04-16 | GitHub UI: **Settings → Member privileges → Repository deletion and transfer** |

### Drift check

Run monthly, or after any org-owner change:

```bash
gh api orgs/jackin-project --jq '{
  members_can_delete_repositories,
  members_can_change_repo_visibility,
  members_can_invite_outside_collaborators,
  members_can_delete_issues
}'
```

Expected baseline (as of 2026-04-16):

```json
{
  "members_can_delete_repositories": false,
  "members_can_change_repo_visibility": true,
  "members_can_invite_outside_collaborators": true,
  "members_can_delete_issues": false
}
```

If any value diverges from the "Desired" column above, restore via the GitHub UI path noted in the table. Document any intentional change by updating both this table and the baseline block.

### Why these aren't in Terraform

- `members_can_delete_repositories`: the GitHub REST `PATCH /orgs/{org}` endpoint does not accept this field as a writable parameter (verified against [GitHub REST docs](https://docs.github.com/en/rest/orgs/orgs?apiVersion=2022-11-28#update-an-organization) on 2026-04-16); GitHub silently accepts and echoes it in responses but does not persist the change. The Terraform provider also has no attribute for it. Only the GitHub UI actually writes this setting. A GraphQL mutation path may exist and is worth investigating if automation becomes critical.

### What this does NOT protect against

- **Org owners can always delete repositories** regardless of member-privilege settings. Minimize the owner set and rely on [GitHub's 90-day repo restore](https://docs.github.com/en/repositories/creating-and-managing-repositories/restoring-a-deleted-repository) as a recovery mechanism.
- Repo admins can still delete their own repos if the member-privilege doesn't reach them (e.g., outside collaborators with admin role).
- Terraform's `lifecycle { prevent_destroy = true }` on `github_repository.managed_settings` stops IaC-initiated deletion but does nothing for UI-initiated deletion. Both guards are needed.

## Conventions

- Branch naming: `chore/*`, `feat/*`, `fix/*` — never include a token, PAT suffix, or credential in the branch name.
- Commit messages follow Conventional Commits.
- Use `main` as the primary branch.
- All changes go through a PR (required by the self-referential ruleset).
