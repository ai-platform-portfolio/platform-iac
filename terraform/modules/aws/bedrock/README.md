# Private Bedrock foundation

Creates application inference profiles from approved system-defined geographic
profiles and private Bedrock Runtime/STS endpoints. Live model target regions are
checked against the configured processing allowlist; global profile IDs are rejected.
Endpoint security groups permit only HTTPS from explicit client CIDRs and have no
new outbound connections. Responses use stateful security-group connection tracking.

With an empty runtime role allowlist, endpoint policies explicitly deny all access.
Once federation is ready, supply exact role ARNs externally. Bedrock policies permit
only configured invocation actions and the approved profile/model resources; STS
permits only web identity exchange to those roles. The IAM role trust and identity
policy remain necessary controls and are provisioned separately.

Private DNS operates inside the AWS VPC. Azure requires separately provisioned
transport and DNS forwarding before these endpoints are usable from APIM. Creating
profiles does not accept model agreements, provision model capacity or validate
invocation entitlement. No content logging or inference requests are enabled here.
