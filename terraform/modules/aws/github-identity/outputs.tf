output "roles" {
  description = "Environment-specific CI role ARNs; configure them externally in GitHub environments."
  sensitive   = true
  value       = { for phase, role in aws_iam_role.deployment : phase => role.arn }
}

output "runtime_permissions_boundary_arn" {
  description = "Boundary required when Apply creates Bedrock runtime roles."
  sensitive   = true
  value       = aws_iam_policy.runtime_boundary.arn
}
