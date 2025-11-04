#!/bin/bash
# --------------------------
# Prometheus EC2 Setup
# --------------------------

yum update -y
amazon-linux-extras install docker -y
systemctl enable docker
systemctl start docker

# Add ec2-user to docker
usermod -aG docker ec2-user

# Define Flutter app target (replace with your LB DNS)
APP_LB_DNS="flutter-lb-1619934268.us-east-1.elb.amazonaws.com"

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

# Run Prometheus container
docker run -d \
  -p 9090:9090 \
  -v /home/ec2-user/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml \
  --name prometheus prom/prometheus
