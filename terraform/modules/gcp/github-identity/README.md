# Google GitHub deployment federation

Administrator bootstrap enables APIs without disabling them on destroy, creates
separate Plan/Apply service accounts and GitHub OIDC providers, and grants only
the network/DNS roles needed by workload deployment. Exact customized subjects
and immutable repository/owner IDs are required. Apply additionally requires
main and rejects pull request events. No service-account keys are created.

Workload deployment identities cannot administer project IAM, service accounts,
API enablement or their own federation trust. Maintain this module with the
administrator bootstrap state, separate from the workload state.

[Google deployment federation guidance](https://docs.cloud.google.com/iam/docs/workload-identity-federation-with-deployment-pipelines).
