# Azure managed identity to Google inference

Creates an OIDC pool/provider and inference-only Google service account. Trust
requires the exact Entra issuer, dedicated audience, tenant ID, managed identity
object ID and application role. The single approved identity may impersonate only
this account; the custom role grants prediction and API usage, without model,
network or IAM administration. No keys or passwords are created.

The application/audience and role assignment belong to the administrator
bootstrap. APIM must obtain an Entra token, exchange it using Google STS and use
IAM Credentials to obtain a short-lived OAuth token. Outputs provide the exact
exchange metadata for that policy implementation. The federation trust alone
does not implement APIM token renewal, network reachability or model restrictions.

The prediction permission is project-scoped; enforce the reviewed model and
processing endpoint allowlist in APIM and validate it at runtime. Project IAM
alone is not a per-model or jurisdictional routing restriction.

[Google Azure federation](https://docs.cloud.google.com/iam/docs/workload-identity-federation-with-other-clouds),
[Agent Platform permissions](https://docs.cloud.google.com/gemini-enterprise-agent-platform/machine-learning/general/access-control).
