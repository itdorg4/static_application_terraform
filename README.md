# static_application_terraform

Same static site as `static_application_ga`, but the EC2 provisioning is done
with **Terraform** instead of the AWS-CLI composite GitHub Action.

## Flow

1. **provision** — `terraform apply` creates a security group (22/80/443) and an
   Ubuntu 22.04 EC2 instance, then outputs its public IP/DNS. Remote S3 state
   keeps it idempotent across runs (re-applies update in place, no duplicates).
2. **deploy** — `deploy.py` SSHes in, installs nginx, uploads
   `it-defined.com.conf` + `index.html`, and reloads nginx.

## Required GitHub secrets

| Secret                  | Purpose                                  |
| ----------------------- | ---------------------------------------- |
| `AWS_ACCESS_KEY_ID`     | AWS creds for Terraform                   |
| `AWS_SECRET_ACCESS_KEY` | AWS creds for Terraform                   |
| `TF_STATE_BUCKET`       | Existing S3 bucket holding Terraform state |
| `SSH_KEY`               | Private key (`june2026.pem`) for the EC2 instance |

## Run locally

```bash
cd terraform
terraform init -backend-config="bucket=<your-bucket>" \
               -backend-config="key=static-site/terraform.tfstate" \
               -backend-config="region=ap-south-1"
terraform apply
```
