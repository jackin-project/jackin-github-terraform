#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Alexey Zhokhov
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

echo "=== 1. Checking OpenTofu formatting ==="
tofu fmt -check -recursive

echo "=== 2. Validating OpenTofu configuration ==="
tofu validate

echo "=== 3. Verifying mandatory target inventory coverage ==="
MANDATORY_TARGETS=(
  "homebrew-tap"
  "jackin"
  "jackin-agent-smith"
  "jackin-dev"
  "jackin-github-terraform"
  "jackin-role-action"
  "jackin-sentinel"
  "jackin-the-architect"
)

python3 - << 'EOF'
import re, sys

with open("variables.tf") as f:
    content = f.read()

mandatory = [
    "homebrew-tap",
    "jackin",
    "jackin-agent-smith",
    "jackin-dev",
    "jackin-github-terraform",
    "jackin-role-action",
    "jackin-sentinel",
    "jackin-the-architect",
]

missing = []
for repo in mandatory:
    pattern = rf'"{re.escape(repo)}"\s*=\s*\{{'
    if not re.search(pattern, content):
        missing.append(repo)

if missing:
    print(f"FAILED: Missing mandatory repositories in variables.tf: {missing}")
    sys.exit(1)

print(f"SUCCESS: All {len(mandatory)} mandatory jackin-project target repositories are declared.")
EOF

echo "=== 4. Verifying canonical policy invariants in module ==="
python3 - << 'EOF'
import re, sys

with open("modules/repository-policy/main.tf") as f:
    mod = f.read()

def check_pattern(pattern, desc):
    if not re.search(pattern, mod):
        print(f"FAILED invariant: {desc}")
        sys.exit(1)

check_pattern(r'allow_squash_merge\s*=\s*true', "allow_squash_merge = true")
check_pattern(r'allow_merge_commit\s*=\s*false', "allow_merge_commit = false")
check_pattern(r'allow_rebase_merge\s*=\s*false', "allow_rebase_merge = false")
check_pattern(r'squash_merge_commit_title\s*=\s*"PR_TITLE"', "squash_merge_commit_title = PR_TITLE")
check_pattern(r'squash_merge_commit_message\s*=\s*"PR_BODY"', "squash_merge_commit_message = PR_BODY")
update_branch_values = re.findall(r'^\s*allow_update_branch\s*=\s*(true|false)\s*$', mod, re.M)
if update_branch_values != ["false"]:
    print(f"FAILED invariant: expected one allow_update_branch = false setting; found {update_branch_values}")
    sys.exit(1)
check_pattern(r'delete_branch_on_merge\s*=\s*true', "delete_branch_on_merge = true")
check_pattern(r'allowed_merge_methods\s*=\s*\[\s*"squash"\s*\]', "allowed_merge_methods = ['squash']")
check_pattern(r'required_linear_history\s*=\s*true', "required_linear_history = true")
check_pattern(r'deletion\s*=\s*true', "deletion = true")
check_pattern(r'non_fast_forward\s*=\s*true', "non_fast_forward = true")
check_pattern(r'required_review_thread_resolution\s*=\s*true', "required_review_thread_resolution = true")
strict_freshness_values = re.findall(r'^\s*strict_required_status_checks_policy\s*=\s*(true|false)\s*$', mod, re.M)
if strict_freshness_values != ["false"]:
    print(f"FAILED invariant: expected one strict_required_status_checks_policy = false setting; found {strict_freshness_values}")
    sys.exit(1)

assert 'bypass_actors' not in mod, "No bypass_actors allowed on core protection"

print("SUCCESS: All canonical policy invariants verified in modules/repository-policy/main.tf.")
EOF

echo "=== 5. Verifying configured required CI contexts ==="
python3 - << 'EOF'
import re, sys

with open("variables.tf") as f:
    content = f.read()

expected = {
    "homebrew-tap": {"Required", "DCO"},
    "jackin": {"Required", "DCO"},
    "jackin-agent-smith": {"Required", "DCO"},
    "jackin-dev": {"Required", "DCO"},
    "jackin-github-terraform": {"Required", "DCO"},
    "jackin-role-action": {"Required", "DCO"},
    "jackin-sentinel": {"Required", "DCO"},
    "jackin-the-architect": {"Required", "DCO"},
    "jackin-marketplace": {"Policy"},
}

policies = {}
for name, body in re.findall(r'"([^"]+)"\s*=\s*\{(.*?)\n\s*\}', content, re.S):
    checks = re.search(r'required_checks\s*=\s*\[([^\]]*)\]', body)
    policies[name] = re.findall(r'"([^"]+)"', checks.group(1)) if checks else []

missing = sorted(set(expected) - set(policies))
incorrect = {
    name: policies[name]
    for name, contexts in expected.items()
    if name in policies and (set(policies[name]) != contexts or len(policies[name]) != len(contexts))
}
if missing or incorrect:
    print(f"FAILED: Missing policy entries: {missing}; incorrect required contexts: {incorrect}.")
    sys.exit(1)

print("SUCCESS: All 8 target repos require Required and DCO; marketplace retains its verified Policy context.")
EOF

echo "=== 6. Verifying every protected repository has required CI contexts ==="
python3 - << 'EOF'
import re, sys

with open("variables.tf") as f:
    content = f.read()

policies = re.findall(r'"([^"]+)"\s*=\s*\{(.*?)\n\s*\}', content, re.S)
empty = []
protected_count = 0
for name, body in policies:
    disposition = re.search(r'disposition\s*=\s*"([^"]+)"', body)
    checks = re.search(r'required_checks\s*=\s*\[([^\]]*)\]', body)
    contexts = re.findall(r'"([^"]+)"', checks.group(1)) if checks else []
    if disposition and disposition.group(1) == "FullRuleset":
        protected_count += 1
        if not contexts:
            empty.append(name)

if empty:
    print(f"FAILED: Protected repositories have no required CI contexts: {empty}")
    sys.exit(1)

print(f"SUCCESS: All {protected_count} protected repositories have required CI contexts.")
EOF

echo "=== ALL VERIFICATIONS PASSED ==="
