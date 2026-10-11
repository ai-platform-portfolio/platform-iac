# Dedicated federation audience

Creates a single-tenant Entra application and service principal, with a dedicated
`api://` audience and application role assigned to an existing managed identity.
Creates no managed identity, client password or certificate. Version 1 access
tokens match the Entra issuer documented by Google's OIDC federation guidance.
The external provider must also restrict tenant, object ID, audience and role.

Run as part of the administrator identity bootstrap. It requires permissions to
create applications/service principals and assign application roles; workload
deployment roles do not manage their own federation trust.

[Google Azure federation](https://docs.cloud.google.com/iam/docs/workload-identity-federation-with-other-clouds),
[Entra application role assignments](https://learn.microsoft.com/en-us/entra/identity-platform/howto-add-app-roles-in-apps).
