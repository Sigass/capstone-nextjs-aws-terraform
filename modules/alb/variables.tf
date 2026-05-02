variable "vpc_id" {
	description = "ID of the VPC for the ALB."
}
variable "public_subnets" {
	description = "List of public subnet IDs for the ALB."
}
variable "alb_sg" {
	description = "ID of the security group for the ALB."
}