# Platform components

Reusable Terraform modules and centralised Helm charts for `ai-platform-portfolio`. The [ci](terraform/ci/README.md) root is the
explicit exception for centrally operated infrastructure. See [modules](terraform/modules/README.md) and
[provenance](terraform/PROVENANCE.md).

## Repository layout

```text
terraform/
  modules/       Reusable infrastructure modules
  examples/      Module usage examples
  ci/            Centrally operated infrastructure
  scripts/       Terraform validation and deployment tooling
  PROVENANCE.md  Module extraction history
helm/
  charts/        Centralised Helm charts
  README.md      Chart conventions
```

Shared repository workflows, engineering policy and the Makefile remain at the
root. See [Helm](helm/README.md) for the chart layout.

## Terraform

Consumers use `git::https://github.com/ai-platform-portfolio/terraform-modules.git//terraform/modules/<name>?ref=<full-commit-sha>`.
Upgrade the pinned commit in a reviewed consumer change. Private repository
authentication must be available to the caller; no token belongs in a source URL.

Run `make check` with Terraform 1.12.2 and Python 3.11+ installed. It checks
formatting, initialises providers without a backend, and validates every module
and example. `make test` also runs the supplied mocked-provider plan tests.
Neither command applies resources or needs cloud credentials.

Module interface and resource-address changes require review of consumer impact.
Migrating existing addresses requires explicit moved blocks and a reviewed plan.
The network migration preserves existing Azure resources and address allocations.

The directory move changes module source URLs for new revisions: replace
`//modules/<name>` with `//terraform/modules/<name>` when upgrading the pinned
commit. Existing consumers pinned to older commits continue using their original
paths. The central deployment root is now `terraform/ci`; resource addresses and
backend configuration are unchanged. Run Makefile commands from the repo root.
