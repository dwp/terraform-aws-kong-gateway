output "ids" {
  value       = [aws_security_group.security_group.id]
  description = "Array of Security Group IDs"
}

output "id" {
  value       = aws_security_group.security_group.id
  description = "Security Group ID"
}
