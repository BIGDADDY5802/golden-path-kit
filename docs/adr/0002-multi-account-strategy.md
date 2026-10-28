# ADR 0002: Multi-Account Strategy

**Status:** Accepted

## Context

The project needed blast-radius and billing isolation across at least two AWS accounts under one AWS Organization, with Terraform provisioning cleanly into each — without using the Organization's own `OrganizationAccountAccessRole` (admin-equivalent in the member account) for routine, day-to-day operations.

## Decision

- **Two member accounts** under the existing Organization: `shared-network` (`400484420291`) for networking building blocks, and `workload-dev` (`556166822095`) for application-layer building blocks (IAM role template, S3 bucket, its own small VPC/SG).
- **Isolated state per account:** separate S3 bucket (`golden-path-tf-state-<account-id>`) and DynamoDB lock table per account — never one shared state file across accounts. Mirrors the actual blast-radius boundary: a bad `apply` in one account can't corrupt the other's state.
- **A narrow, purpose-built deploy role per account** (`golden-path-ci-deploy`), trusted by both the GitHub OIDC CI entry role and the local human admin identity, so CI and local Terraform runs use the *identical* identity and permission set. Permissions are scoped to exactly what that account's modules create (EC2 networking actions; in workload-dev, also IAM role and S3 bucket actions restricted by ARN pattern to `workload-dev-*` / `golden-path-workload-dev-*`). `OrganizationAccountAccessRole` was used only once, to bootstrap these narrower roles into existence — it is not referenced anywhere in the ongoing `environments/` or CI configuration.
- **Cross-account reference without network peering:** workload-dev's security group needs to allow traffic from shared-network's VPC CIDR. Rather than VPC peering or RAM VPC sharing (unneeded complexity for a CIDR-level reference with no live cross-VPC traffic in this demo), workload-dev reads the value directly out of shared-network's state via a `terraform_remote_state` data source, authenticated by explicitly assuming shared-network's own `golden-path-ci-deploy` role — never the broad org access role — scoped to read-only `s3:GetObject`/`s3:ListBucket` on that one state bucket.
- **Explicit apply ordering:** because workload-dev's plan depends on shared-network's state existing and being current, `apply.yml` defines `apply-shared-network` and `apply-workload-dev` as two sequential jobs (`needs:`), not a parallel matrix — the dependency is made structural, not accidental.

## Consequences

- Positive: verified blast-radius separation — each account's deploy role can only touch resources matching that account's own naming convention; a compromised `workload-dev` credential has no path to `shared-network` resources, and vice versa.
- Positive: no standing use of an admin-equivalent role for routine work, which was a specific, demonstrable improvement made mid-project (see the OIDC bootstrap history) rather than the starting design.
- Negative: operational overhead scales roughly linearly with account count under this pattern — every new account needs its own backend bootstrap, its own `ci-deploy` role, and its own entry in `environments/`. At 2 accounts this is manageable by hand; it would not be at 10+ without turning the bootstrap step itself into a reusable module (an "account factory" pattern).

## Alternatives considered

- **Single account, multiple VPCs for isolation:** rejected — gives network isolation but not the IAM- and billing-level isolation that "multi-account strategy" actually means at enterprise scale, which is the real ask behind this JD requirement.
- **AWS Control Tower / Landing Zone Accelerator:** rejected for this project's scope — adds SSO, account-vending, and centralized guardrail machinery that is disproportionate to a 2-account demo, though it is genuinely what a DTCC-scale organization would run in production. Documented here as the honest answer to "what would you reach for at real scale" rather than something I built but didn't need.
