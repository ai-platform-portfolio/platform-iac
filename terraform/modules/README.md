# Shared Terraform modules

Reusable provider-organized infrastructure modules for the `ai-platform-portfolio` repos. These
are the **single source of truth** — consuming repos reference them via a
git-subdirectory source pinned to a full commit SHA, rather than copying modules per repo
(centralise-don't-copy).

## Consuming a module

```hcl
module "postgres" {
  source = "git::https://github.com/ai-platform-portfolio/platform-iac.git//terraform/modules/azure/postgres?ref=<full-commit-sha>"

  # v0.2.0: solution-specific values are REQUIRED inputs, not module defaults.
  database_name     = "myapp"
  server_extensions = ["VECTOR"] # opt-in; default [] leaves the server stock

  # Real private endpoint (no facade): wire to the shared network outputs.
  enable_private_endpoints   = true
  private_endpoint_subnet_id = module.shared_network.private_endpoint_subnet_id
  private_dns_zone_id        = module.shared_network.private_dns_zone_ids["postgres"]
  # ...remaining inputs
}
```

Only the **invocation** (wiring + tfvars) lives in the consuming repo; the
module definition lives here. See `../examples/` for full neutral-value
invocations of each changed module, and `../PROVENANCE.md` for the v0.2.0
breaking interface changes (required `database_name`, map-based identity
`workloads`, parameterised storage containers/roles/lifecycle, the
and real private endpoints).

## Modules

| Module | Purpose |
|--------|---------|
| `azure/network` | Shared VNet, map-driven subnets, optional NSGs and route tables, private DNS zones with VNet links |
| `azure/foundry` | Private AIServices account, shared identity RBAC and map-driven regional model deployments |
| `azure/apim` | Standard v2 gateway with outbound VNet integration, managed identity and inbound Private Link |
| `auth0/configuration` | Auth0 resource servers (APIs), clients (incl. M2M), grants, KV secret sync |
| `azure/identity` | User-assigned managed identities + OIDC federation for workloads |
| `azure/storage` | Storage account + role assignments for workload principals |
| `azure/postgres` | Postgres flexible server (+ replica) with Entra admin registration |
| `azure/aca` | Azure Container Apps + Environment — a Container **App** or a run-to-completion **Job** (`workload_kind`); VNet-integrated, internal-only, KV secrets + ACR pull via a user-assigned identity |

## Versioning

Tag releases as `tf-modules-vX.Y.Z`. Consumers pin to a full commit SHA; bump the pin
deliberately. Modules are parameterised — no identifying values are hardcoded.

## Removed modules (AI-36)

The legacy `openai` and `aks-nodepool` modules and the OpenAI example have been
removed. Existing consumers pinned to earlier commits continue to use those
versions. Before upgrading a consumer, replace calls to these removed paths
and review its state migration; deleting module source does not destroy Azure
resources. The central network and its existing OpenAI private DNS zone remain
owned by `terraform/ci`.

## Provider directories (AI-44)

Modules live under `azure/`, `aws/`, `gcp/`, or `auth0/`. AWS and GCP directories
are reserved for the upcoming AI platform modules; they contain no implementations
yet. Auth0's existing multi-resource configuration module is `auth0/configuration`.

When upgrading, change the source subdirectory and pinned commit together.
Existing consumers pinned to old commits continue using their original paths.
Module call names and resource addresses do not change, so no moved blocks or
state migration are needed for this directory reorganization.
