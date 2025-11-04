#!/bin/bash
# --------------------------
# User Data for Flutter Web App EC2 Instance
# --------------------------

# Update packages and install Docker
yum update -y
amazon-linux-extras install docker -y

# Start Docker service
systemctl enable docker
systemctl start docker

# Add ec2-user to docker group (optional)
usermod -a -G docker ec2-user

# Pull the Flutter app image from Docker Hub
docker pull ${var.docker_image}

# Stop any existing containers on port 80 (if any)
docker ps -q --filter "publish=80" | grep -q . && docker stop $(docker ps -q --filter "publish=80")

# Run the Flutter web app container
docker run -d -p 80:80 --name flutter-web-app ${var.docker_image}