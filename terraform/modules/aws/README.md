# aws Terraform modules

`github-identity` creates environment-specific GitHub OIDC roles and a Bedrock
runtime permissions boundary. Bootstrap it using an existing administrator session
before enabling AWS authentication in the workload workflow.

The Plan role reads infrastructure metadata. Apply manages tagged workload resources
and runtime roles under the workload IAM path. It cannot edit its own deployment
roles or remove the runtime permissions boundary. Exact OIDC subjects and account
metadata are supplied externally, never committed in tfvars.
