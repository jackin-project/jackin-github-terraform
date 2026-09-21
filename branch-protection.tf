# SPDX-FileCopyrightText: 2026 Alexey Zhokhov
# SPDX-License-Identifier: Apache-2.0

# Canonical GitHub repository settings and branch/tag protection policies
# Managed via the shared repository-policy module
module "repository_policy" {
  source = "./modules/repository-policy"

  repository_policies = var.repository_policies
}
