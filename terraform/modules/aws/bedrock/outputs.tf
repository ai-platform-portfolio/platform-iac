output "profiles" {
  description = "Alias-to-profile mapping for subsequent gateway policies."
  value = { for alias, profile in aws_bedrock_inference_profile.this : alias => {
    id  = profile.id
    arn = profile.arn
  } }
}

output "inference_resource_arns" {
  description = "Approved application/system profile and target foundation-model resources for runtime IAM."
  value       = local.inference_resources
}

output "endpoints" {
  value = { for key, endpoint in aws_vpc_endpoint.this : key => {
    id          = endpoint.id
    dns_entries = endpoint.dns_entry
  } }
}
