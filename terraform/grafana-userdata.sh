#!/bin/bash
######################################
# User Data for Grafana EC2 Instance #
######################################

# Update and install Docker
yum update -y
amazon-linux-extras install docker -y

systemctl enable docker
systemctl start docker
usermod -aG docker ec2-user

# Pull and run Grafana container
docker pull grafana/grafana:latest

# Run Grafana on port 3000
docker run -d \
  -p 3000:3000 \
  --name grafana \
  grafana/grafana:latest

