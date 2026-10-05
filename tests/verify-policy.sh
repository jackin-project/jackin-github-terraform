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
check_pattern(r'allow_update_branch\s*=\s*true', "allow_update_branch = true")
check_pattern(r'delete_branch_on_merge\s*=\s*true', "delete_branch_on_merge = true")
check_pattern(r'allowed_merge_methods\s*=\s*\[\s*"squash"\s*\]', "allowed_merge_methods = ['squash']")
check_pattern(r'required_linear_history\s*=\s*true', "required_linear_history = true")
check_pattern(r'deletion\s*=\s*true', "deletion = true")
check_pattern(r'non_fast_forward\s*=\s*true', "non_fast_forward = true")
check_pattern(r'required_review_thread_resolution\s*=\s*true', "required_review_thread_resolution = true")
check_pattern(r'strict_required_status_checks_policy\s*=\s*false', "strict_required_status_checks_policy = false")

assert 'bypass_actors' not in mod, "No bypass_actors allowed on core protection"

print("SUCCESS: All canonical policy invariants verified in modules/repository-policy/main.tf.")
EOF

echo "=== 5. Verifying this repository's required CI contexts ==="
python3 - << 'EOF'
import re, sys

with open("variables.tf") as f:
    content = f.read()

repo = re.search(r'"jackin-github-terraform"\s*=\s*\{(?P<body>.*?)\n\s*\}', content, re.S)
if not repo:
    print("FAILED: jackin-github-terraform policy is missing from variables.tf.")
    sys.exit(1)

checks = re.search(r'required_checks\s*=\s*\[([^\]]*)\]', repo.group("body"))
context_list = re.findall(r'"([^"]+)"', checks.group(1)) if checks else []
if set(context_list) != {"Required", "DCO"} or len(context_list) != 2:
    print(f"FAILED: Expected Required and DCO as the exact required contexts; found {context_list}.")
    sys.exit(1)

print("SUCCESS: Required and DCO are the exact declared merge-gate contexts.")
EOF

echo "=== ALL VERIFICATIONS PASSED ==="
