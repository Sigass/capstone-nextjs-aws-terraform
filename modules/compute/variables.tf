variable "vpc_id" {
	description = "ID of the VPC for EC2 instances."
}
variable "public_subnets" {
	description = "List of public subnet IDs for EC2 instances."
}
variable "instance_sg" {
	description = "ID of the security group for EC2 instances."
}
variable "target_group_arn" {
	description = "ARN of the target group for the ALB."
}
variable "key_name" {
	description = "Name of the EC2 Key Pair for SSH access."
}
variable "instance_type" {
	description = "EC2 instance type for the Next.js app."
}
variable "min_size" {
	description = "Minimum number of EC2 instances in the ASG."
}
variable "max_size" {
	description = "Maximum number of EC2 instances in the ASG."
}
variable "desired_capacity" {
	description = "Desired number of EC2 instances in the ASG."
}