# ADR 0001: Module Composition and Versioning Strategy

**Status:** Accepted

## Context

The project needed four reusable building blocks (`vpc`, `security-group`, `iam-role`, `s3-bucket`) consumed by two root compositions (`environments/shared-network`, `environments/workload-dev`). Two decisions were needed: how modules are composed into environments, and how module changes get versioned so a change doesn't silently break every consumer at once (the exact "DTCC base module" failure mode this role exists to prevent).

## Decision

**Composition:** root-module pattern. Each environment under `environments/` is a thin composition — it calls the shared modules with environment-specific inputs (CIDR blocks, names, tags) and contains no resource logic of its own. All reusable logic lives in `modules/`.

**Sourcing, for now:** relative local paths (`source = "../../modules/vpc"`), not Git-tag-pinned refs. This repo has exactly one maintainer and two consumers (the two environments), both of which go through the same PR-gated `plan.yml` pipeline before merge — so a breaking module change gets caught in the *same* PR, against *both* consumers, before it ever reaches `main`. Pinning to a Git ref (`source = "git::https://github.com/BIGDADDY5802/golden-path-kit.git//modules/vpc?ref=v1.2.0"`) is the documented upgrade path the moment a second repository or team consumes these modules independently — at that point, an unpinned change in this repo could break a consumer with no PR in this repo to catch it, which is the scenario version pinning actually defends against.

**Governance baked into the interface, not just caught externally:** every module's `tags` variable has a `validation` block requiring `Owner` and `Environment` keys; `security-group` has a `lifecycle precondition` that blocks any `0.0.0.0/0` ingress rule unless `allow_public_ingress = true` is explicitly set; `s3-bucket` hardcodes the public-access block with no variable to disable it. These are enforced at `terraform plan` time, independent of whether `tfsec` or any other external scanner is even configured — defense in depth, not a replacement for CI-level scanning.

## Consequences

- Positive: both environments are guaranteed to be using the exact same module code at any given commit — there is no drift between "which version of the VPC module shared-network uses" vs. workload-dev.
- Negative: there is currently no way to upgrade one environment's module version independently of the other, since both read from the same uncommitted-path source. Acceptable at this scale; would not be acceptable with a third team consuming these modules from a separate repo.
- Follow-up trigger: the moment a second repository needs to consume these modules, switch that consumer (not necessarily this repo's own environments) to a Git-ref-pinned source, and start tagging releases (`v1.0.0`, etc.) on this repository.

## Alternatives considered

- **Private Terraform module registry (Terraform Cloud or an internal registry):** rejected for now — real version-resolution and publishing workflow benefits, but operational overhead disproportionate to two in-repo consumers. This is what I'd reach for if a third team needed these modules.
- **Git-ref pinning from day one:** rejected as premature. Pinning before there is a second independent consumer just adds a manual "bump the ref" step with no corresponding safety benefit yet.
