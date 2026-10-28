# ADR 0003: Multi-Region Resilience

**Status:** Proposed — design only, not deployed

## Context

Multi-region resilience was explicitly out of scope for live deployment in this project, given the stated time budget (~15–24 hours across 3 weeks) and cost ceiling (under $10). This ADR exists to show the design reasoning honestly, as a decision record rather than a working system — it should never be read or cited as evidence that a second region was actually built.

## Decision (proposed, not implemented)

- **Posture: active/passive, not active/active.** The resources this project manages (VPC, security groups, an IAM role, an S3 bucket) carry no live application traffic. Active/active buys nothing here — there is nothing to load-balance — and would simply double the ongoing resource count and cost for no corresponding benefit.
- **What would replicate with no module changes:** none of the four modules hardcode a region; region comes entirely from the calling provider block. Standing up `environments/shared-network-dr/` and `environments/workload-dev-dr/` pointed at a second region (via a second provider alias) would reuse the exact same module code as the primary region — this is a direct benefit of the composition pattern in [ADR 0001](0001-module-versioning.md).
- **What would NOT "just work" from re-running the same modules twice:**
  - S3 bucket contents are regional by nature; actual data resilience would need `aws_s3_bucket_replication_configuration` (Cross-Region Replication), not just re-provisioning an empty bucket in a second region.
  - The cross-account `terraform_remote_state` CIDR-reference pattern from [ADR 0002](0002-multi-account-strategy.md) assumes one state bucket per account. A DR region's `workload-dev` stack would need to read the DR region's `shared-network` state, not the primary region's — the backend bucket/key naming convention would need a region suffix (e.g. `golden-path-tf-state-<account-id>-<region>`), which is a real design change, not a copy-paste.
  - The OIDC/`ci-deploy` bootstrap in `bootstrap/oidc/` is account-scoped, not region-scoped — IAM is a global service, so no changes are needed there, but this is worth stating explicitly rather than assuming.
- **RTO/RPO:** not defined, on purpose. These are business decisions about acceptable downtime and data loss, not technical ones, and this project has no real workload owner to set them. Inventing numbers here would be worse than stating plainly that this is the open question a real DR conversation would need to answer first.
- **Failover mechanism, if built:** Route 53 health-check-based failover routing, pointed at whichever region's endpoint is currently healthy. Not implemented here, since there is no running compute/endpoint in this project for a health check to actually probe.

## Why this was not built live

- **Cost:** cross-region data transfer, a second region's worth of resources, and a second OIDC/IAM bootstrap would plausibly exceed the project's $10 ceiling once S3 replication and any redundant lock-table usage are added.
- **Time:** per the project's own prioritization (Section 1 of the role-requirements analysis this project was built against), multi-account strategy, remote state isolation, CI/CD governance, and drift detection were assessed as higher-priority, more strongly-signaled JD requirements than live multi-region deployment. Finishing those first was the better use of a fixed time budget.

## Consequences

This ADR is deliberately a tradeoff-reasoning artifact, not a deployed capability. The intended interview use is direct: "here's what I'd build live given more time and budget, here's exactly what would and wouldn't reuse the existing modules, and here's why I didn't build it for this project" — an honest answer beats an overclaimed one.
