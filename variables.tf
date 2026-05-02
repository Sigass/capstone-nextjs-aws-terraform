variable "key_name" {
  description = "EC2 Key Pair"
  type        = string
  default     = "vockey"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "min_size" {
  default = 2
}

variable "max_size" {
  default = 3
}

variable "desired_capacity" {
  default = 2
}