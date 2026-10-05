#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Alexey Zhokhov
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

fail() {
  echo "FAILED: $*" >&2
  exit 1
}

echo "=== Verifying this root cannot manage GitHub repositories or rulesets ==="
for forbidden in \
  '^\s*resource\s+"github_repository(_ruleset)?"' \
  '^\s*provider\s+"github"' \
  '^\s*module\s+"repository_policy"' \
  '^\s*import\s*\{' \
  '^\s*backend\s+"[^"]+"'
do
  if rg -n "$forbidden" --glob '*.tf' --glob '*.tofu' .; then
    fail "retired root contains active GitHub ownership or backend configuration ($forbidden)"
  fi
done

if [[ -e modules/repository-policy ]]; then
  fail "repository-policy module remains in the retired root"
fi
if [[ -e .terraform.lock.hcl ]]; then
  fail "unused GitHub provider lockfile remains"
fi

echo "=== Verifying state handoff never deletes live GitHub objects ==="
python3 - <<'PY'
import re
import sys
from pathlib import Path

migration = Path("migrations.tf").read_text()
expected = {
    "module.repository_policy",
    "github_repository.managed_settings",
    "github_repository_ruleset.protect_main",
    "github_repository_ruleset.protect_tags",
}
removed = re.findall(r"^\s*from\s*=\s*(\S+)\s*$", migration, re.M)
destroy_false = re.findall(r"^\s*destroy\s*=\s*false\s*$", migration, re.M)
if set(removed) != expected or len(removed) != len(expected):
    print(f"FAILED: expected removed addresses {sorted(expected)}, found {removed}")
    sys.exit(1)
if len(destroy_false) != len(expected):
    print(f"FAILED: expected destroy=false on {len(expected)} removed blocks, found {len(destroy_false)}")
    sys.exit(1)

readme = Path("README.md").read_text()
if "https://github.com/ChainArgos/github-terraform" not in readme:
    print("FAILED: deprecation pointer to the control plane is missing.")
    sys.exit(1)
for repo in (
    "homebrew-tap",
    "jackin",
    "jackin-agent-smith",
    "jackin-dev",
    "jackin-github-terraform",
    "jackin-marketplace",
    "jackin-role-action",
    "jackin-sentinel",
    "jackin-the-architect",
):
    if f"`{repo}`" not in readme:
        print(f"FAILED: handoff inventory is missing {repo}.")
        sys.exit(1)

print("SUCCESS: Legacy state addresses are forgotten with destroy=false and all nine repos point to the control plane.")
PY

echo "=== Checking OpenTofu formatting, initialization, and validation ==="
tofu fmt -check -recursive
tofu init -backend=false -input=false -lockfile=readonly -no-color
tofu validate -no-color

echo "=== Verifying a backend=false plan has no GitHub mutations ==="
plan_file="$(mktemp "${TMPDIR:-/tmp}/jackin-policy-retirement.XXXXXX")"
trap 'rm -f "$plan_file"' EXIT
tofu plan -refresh=false -input=false -no-color -out="$plan_file"
tofu show -json "$plan_file" | python3 -c '
import json
import sys

plan = json.load(sys.stdin)
changes = plan.get("resource_changes", [])
unsafe = []
for item in changes:
    actions = item.get("change", {}).get("actions", [])
    if actions not in (["no-op"], ["forget"]):
        unsafe.append((item.get("address"), actions))
if unsafe:
    print(f"FAILED: plan contains resource mutations: {unsafe}")
    sys.exit(1)
if changes:
    print(f"Plan contains state-only forget/no-op entries: {len(changes)}; no GitHub mutations.")
else:
    print("SUCCESS: plan is empty; no GitHub resources are managed or changed.")
'
