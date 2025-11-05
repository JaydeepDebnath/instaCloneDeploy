output "load_balancer_dns" {
  value = aws_lb.flutter_lb.dns_name
}

output "prometheus_public_ip" {
  value = aws_instance.prometheus.public_ip
}

output "prometheus_public_dns" {
  value = aws_instance.prometheus.public_dns
}

output "grafana_public_ip" {
  value = aws_instance.grafana.public_ip
}

output "grafana_public_dns" {
  value = aws_instance.grafana.public_dns
}

