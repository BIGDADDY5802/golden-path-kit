# Bootstrap

One-time setup that has to exist before anything in `modules/` or `environments/` can use a remote backend. Both steps here intentionally use **local** state — bootstrapping remote state with remote state is the classic chicken-and-egg, so these two folders are the deliberate exception.

## accounts/

Creates the two AWS Organization member accounts under the existing Organization (`o-rfffzd1pr7`, management account `778185677715`).

| Account | ID | Root email |
|---|---|---|
| shared-network | `400484420291` | firstofmyname5802+shared-network@gmail.com |
| workload-dev | `556166822095` | firstofmyname5802+workload-dev@gmail.com |

`close_on_deletion = false` on both — running `terraform destroy` here only forgets the accounts in Terraform state, it never closes the real AWS accounts (account closure has a 90-day email-reuse cooldown and isn't meant to happen by accident).

## state-backend/

Assumes the auto-created `OrganizationAccountAccessRole` in each member account and creates, per account:
- An S3 bucket (`golden-path-tf-state-<account-id>`) — versioned, SSE-AES256 encrypted, all public access blocked.
- A DynamoDB table (`terraform-locks`) — `PAY_PER_REQUEST` billing, so it costs nothing at zero/low usage.

| Account | State bucket | Lock table |
|---|---|---|
| shared-network | `golden-path-tf-state-400484420291` | `terraform-locks` |
| workload-dev | `golden-path-tf-state-556166822095` | `terraform-locks` |

`environments/<account>/backend.tf` (next milestone) will point at these.

## Cost note

Everything created here is free at this usage level (empty S3 buckets, on-demand DynamoDB tables, no NAT Gateways, no running compute). The management account's existing AWS Budgets alarms (`My Zero-Spend Budget` at $1, `My Monthly Cost Budget` at $10) already cover the whole account, including these new accounts' activity once consolidated billing reports it. As of this bootstrap, this month's account-wide spend (~$22.80) is from unrelated prior activity — primarily a one-time ~$19 Route 53 domain registration — not from anything in this project.
