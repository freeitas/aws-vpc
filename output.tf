output "ssm_vpc_id" {
  description = "VPC ID, stored in Parameter Store."
  value       = aws_ssm_parameter.vpc.id
  sensitive   = true
}

output "ssm_subnet_private_1a" {
  description = "Private subnet ID in AZ 1a, stored in Parameter Store."
  value       = aws_ssm_parameter.private_1a
  sensitive   = true
}

output "ssm_subnet_private_1b" {
  description = "Private subnet ID in AZ 1b, stored in Parameter Store."
  value       = aws_ssm_parameter.private_1b
  sensitive   = true
}

output "ssm_subnet_private_1c" {
  description = "Private subnet ID in AZ 1c, stored in Parameter Store."
  value       = aws_ssm_parameter.private_1c
  sensitive   = true
}

output "ssm_subnet_public_1a" {
  description = "Public subnet ID in AZ 1a, stored in Parameter Store."
  value       = aws_ssm_parameter.public_1a
  sensitive   = true
}

output "ssm_subnet_public_1b" {
  description = "Public subnet ID in AZ 1b, stored in Parameter Store."
  value       = aws_ssm_parameter.public_1b
  sensitive   = true
}

output "ssm_subnet_public_1c" {
  description = "Public subnet ID in AZ 1c, stored in Parameter Store."
  value       = aws_ssm_parameter.public_1c
  sensitive   = true
}

output "ssm_subnet_databases_1a" {
  description = "Database subnet ID in AZ 1a, stored in Parameter Store."
  value       = aws_ssm_parameter.databases_1a
  sensitive   = true
}

output "ssm_subnet_databases_1b" {
  description = "Database subnet ID in AZ 1b, stored in Parameter Store."
  value       = aws_ssm_parameter.databases_1b
  sensitive   = true
}

output "ssm_subnet_databases_1c" {
  description = "Database subnet ID in AZ 1c, stored in Parameter Store."
  value       = aws_ssm_parameter.databases_1c
  sensitive   = true
}
