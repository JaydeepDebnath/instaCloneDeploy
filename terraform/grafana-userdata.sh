#!/bin/bash
######################################
# User Data for Grafana EC2 Instance #
######################################

# Update system and install Docker
yum update -y
amazon-linux-extras install docker -y

# Enable and start Docker service
systemctl enable docker
systemctl start docker

# Add ec2-user to docker group
usermod -aG docker ec2-user

# Pull latest Grafana image
docker pull grafana/grafana:latest

# Run Grafana container on port 3000
docker run -d \
  -p 3000:3000 \
  --name grafana \
  grafana/grafana:latest

# (Optional) Enable auto-restart on reboot
docker update --restart unless-stopped grafana

echo " Grafana running on port 3000"
