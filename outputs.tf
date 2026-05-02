output "alb_dns_name" {
  description = "Public URL of the Load Balancer"
  value       = module.alb.alb_dns_name
}