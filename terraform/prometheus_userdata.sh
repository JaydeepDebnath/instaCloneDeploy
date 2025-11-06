#!/bin/bash
######################################
# Prometheus EC2 Setup
######################################

yum update -y
amazon-linux-extras install docker -y
systemctl enable docker
systemctl start docker
usermod -aG docker ec2-user

# Terraform injects this value
APP_LB_DNS="${APP_LB_DNS}"

mkdir -p /home/ec2-user/prometheus
cat <<EOF > /home/ec2-user/prometheus/prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'flutter_app'
    static_configs:
      - targets: ['${APP_LB_DNS}:80']

  - job_name: 'node_exporters'
    static_configs:
      - targets: ['${APP_LB_DNS}:9100']
EOF

docker run -d \
  -p 9090:9090 \
  -v /home/ec2-user/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml \
  --name prometheus prom/prometheus:latest

docker update --restart unless-stopped prometheus

echo "✅ Prometheus running on port 9090, scraping from $APP_LB_DNS"
