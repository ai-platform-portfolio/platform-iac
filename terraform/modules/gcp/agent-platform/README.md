# Private Gemini Enterprise Agent Platform inference

Creates a custom-mode VPC without default internet routes, an endpoint subnet,
internal address, regional Private Service Connect endpoint targeting the chosen
jurisdictional Agent Platform API, private DNS and an inbound DNS policy for future
hybrid access. The backend hostname and API path use the same processing location.
Managed Gemini inference needs no model endpoint deployment or GPU resources.

Google renamed Vertex AI to Gemini Enterprise Agent Platform. API identifiers,
IAM permission names and provider resources retain `aiplatform` where required.

Use the administrator bootstrap to enable Compute, DNS, Network Connectivity and
Agent Platform APIs before the normal Plan/Apply workflow. API enablement and IAM
are separately managed so workload Apply cannot modify its own permissions.

The EU `.rep.googleapis.com` endpoint requires regional PSC; Private Google Access
and the generic global Google API bundle are not substitutes. This module creates
only private DNS records. Cross-cloud circuits, route advertisements and Azure DNS
forwarding must be connected separately before APIM can reach the endpoint. PSC
does not disable Google's public service endpoint: use IAM and, where required,
VPC Service Controls to enforce access from approved paths. No claim of complete
network isolation is made by provisioning PSC alone.

Model approvals are explicit inputs backed by a live model/residency review, not
automatic discovery. Global processing is rejected. For OpenAI compatibility,
the gateway sends `google/<model-id>` with a short-lived OAuth token. APIM policy
fragments and Foundry BYOM connections are separate gateway configuration.

References checked 2026-10-11:
- [Current product names](https://docs.cloud.google.com/gemini-enterprise-agent-platform/release-notes)
- [Model processing residency](https://docs.cloud.google.com/gemini-enterprise-agent-platform/resources/data-residency)
- [Jurisdictional endpoints and private connectivity](https://docs.cloud.google.com/gemini-enterprise-agent-platform/resources/locations)
- [Regional PSC and hybrid DNS](https://docs.cloud.google.com/vpc/docs/access-regional-google-apis-endpoints)
- [OpenAI-compatible API](https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/migrate/openai/overview)
