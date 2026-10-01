\# Assignment — Secure CI Pipeline with GitHub OIDC



\## Objective



Extend your Terraform project with a \*\*pull request CI workflow\*\* that

validates infrastructure changes automatically — without ever storing AWS

credentials in GitHub. You'll authenticate using \*\*OIDC\*\* instead of a

long-lived Access Key / Secret Key, and provision infrastructure for a

static frontend and a containerized backend.



\---



\## Part 1 — Replace Static Credentials with OIDC



\- \[ ] Create an IAM OIDC identity provider for GitHub Actions

&#x20;     (`token.actions.githubusercontent.com`)

\- \[ ] Create an IAM role that trusts this identity provider

\- \[ ] Scope the trust policy to your specific GitHub repo (and optionally

&#x20;     branch) using the `sub` condition — don't trust `\*`

\- \[ ] Attach only the permissions the pipeline actually needs

&#x20;     (least privilege — no `AdministratorAccess`)

\- \[ ] Remove any `AWS\_ACCESS\_KEY\_ID` / `AWS\_SECRET\_ACCESS\_KEY` values from

&#x20;     GitHub Secrets

\- \[ ] Use `aws-actions/configure-aws-credentials` with `role-to-assume` and

&#x20;     `permission: id-token: write` in the workflow



> 💡 \*\*Why this matters:\*\* access keys are long-lived and leak easily (in

> logs, commits, forks). OIDC issues short-lived, per-run credentials that

> expire automatically — nothing to rotate, nothing to revoke.



\---



\## Part 2 — Pull Request Workflow



Build a GitHub Actions workflow that triggers \*\*on pull request\*\* and runs

validation only — no `apply`. This gives reviewers a safe preview of every

change before it merges.



\- \[ ] Trigger on `pull\_request` targeting your main branch

\- \[ ] `terraform fmt -check`

\- \[ ] `terraform init`

\- \[ ] `terraform validate`

\- \[ ] `terraform plan`

\- \[ ] Post the plan output as a PR comment (or upload as a workflow artifact)

\- \[ ] Ensure the job fails if `fmt`, `validate`, or `plan` fails

\- \[ ] Confirm no `terraform apply` step exists in this workflow



> ⚠️ \*\*Checkpoint:\*\* a pull request should never be able to change real

> infrastructure by itself. `apply` belongs in a separate workflow, gated

> on merge to main (and ideally, manual approval).



\---



\## Part 3 — Application Infrastructure



\### Frontend — S3 + CloudFront

\- \[ ] Create an S3 bucket to host the static frontend build

\- \[ ] Block public access on the bucket directly

\- \[ ] Create a CloudFront distribution in front of the bucket

\- \[ ] Use Origin Access Control (OAC) so CloudFront is the only way to

&#x20;     reach the bucket

\- \[ ] Configure HTTPS (default CloudFront certificate or ACM + custom domain)



\### Backend — App Runner

\- \[ ] Create an App Runner service for the backend

\- \[ ] Configure the source (ECR image or GitHub repo, per your build setup)

\- \[ ] Set environment variables / secrets via App Runner config, not

&#x20;     hardcoded in the image

\- \[ ] Configure health checks

\- \[ ] Confirm the frontend can reach the backend (CORS, API URL config, etc.)



\---



\## Additional Suggestions (Stretch Goals)



Pick a few of these to go further:



\- \[ ] \*\*Separate plan and apply workflows\*\* — `pull\_request` runs plan only;

&#x20;     `push` to `main` runs apply, ideally with a required manual approval

&#x20;     (GitHub Environments)

\- \[ ] \*\*State locking + remote state\*\* — confirm your S3 backend and

&#x20;     DynamoDB (or S3-native) locking are wired into the CI role's

&#x20;     permissions too

\- \[ ] \*\*`tflint` / `checkov` / `tfsec`\*\* — add a static analysis / security

&#x20;     scanning step to the PR workflow, alongside `validate`

\- \[ ] \*\*Least-privilege IAM policy iteration\*\* — start permissive to get

&#x20;     things working, then tighten the role down to only the actions

&#x20;     Terraform actually calls

\- \[ ] \*\*CloudFront cache invalidation step\*\* — after frontend deploys,

&#x20;     invalidate the CloudFront cache so users get the latest build

\- \[ ] \*\*App Runner auto-deploy\*\* — trigger a new App Runner deployment when

&#x20;     a new image is pushed to ECR

\- \[ ] \*\*Cost estimation in PRs\*\* — add `infracost` to comment estimated

&#x20;     cost delta on each pull request

\- \[ ] \*\*Branch protection rules\*\* — require the PR workflow to pass before

&#x20;     merge is allowed



\---



\## Deliverables



1\. Terraform code for the OIDC provider, IAM role, S3 + CloudFront

&#x20;  frontend, and App Runner backend

2\. A `.github/workflows/pr-checks.yml` workflow running `fmt`, `init`,

&#x20;  `validate`, and `plan` on every pull request

3\. A short write-up (README section is fine) explaining:

&#x20;  - How OIDC trust is scoped to your repo

&#x20;  - Why the PR workflow doesn't run `apply`

&#x20;  - Which stretch goals you implemented, and why

