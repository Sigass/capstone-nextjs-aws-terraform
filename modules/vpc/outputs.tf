output "public_subnet_names" {
  description = "List of names (tags) for the public subnets."
  value       = aws_subnet.public[*].tags["Name"]
}
output "vpc_id" {
  description = "The ID of the main VPC."
  value       = aws_vpc.main.id
}

output "public_subnets" {
  description = "List of public subnet IDs (capstone-public-subnet-1, capstone-public-subnet-2). Utilisés pour l'ALB et les instances EC2."
  value       = aws_subnet.public[*].id
}