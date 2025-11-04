#######################################################
# OUTPUTS FOR FLUTTER DEPLOYMENT
#######################################################

output "load_balancer_dns" {
  description = "Public DNS of the Load Balancer to access your Flutter web app"
  value       = aws_lb.flutter_lb.dns_name
}

output "vpc_id" {
  description = "ID of the main VPC"
  value       = aws_vpc.main.id
}

output "security_group_id" {
  description = "ID of the security group attached to EC2 instances"
  value       = aws_security_group.web_sg.id
}

output "autoscaling_group_name" {
  description = "Name of the Auto Scaling group managing Flutter app instances"
  value       = aws_autoscaling_group.flutter_asg.name
}
