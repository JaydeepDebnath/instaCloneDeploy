#!/bin/bash
# --------------------------
# User Data for Flutter Web App EC2 Instance
# --------------------------

set -e
LOG_FILE="/var/log/user-data.log"
exec > >(tee -a $LOG_FILE) 2>&1

echo "✅ Starting Flutter Web User Data Script at $(date)"

# Update system and install Docker
yum update -y
amazon-linux-extras install docker -y
systemctl enable docker
systemctl start docker
usermod -aG docker ec2-user

# Pull and run Flutter web container
IMAGE_NAME="jay0604/flutter-web:1.0.0-1"
CONTAINER_NAME="flutter-web"

echo "🔹 Pulling Docker image..."
docker pull --platform linux/amd64 $IMAGE_NAME

# Stop any existing container
EXISTING_CONTAINER=$(docker ps -q --filter "name=$CONTAINER_NAME")
if [ -n "$EXISTING_CONTAINER" ]; then
    echo "🔹 Stopping existing container..."
    docker stop $EXISTING_CONTAINER
    docker rm $EXISTING_CONTAINER
fi

# Run container on port 80
echo "🔹 Starting Flutter web container..."
docker run -d --platform linux/amd64 -p 80:80 --name $CONTAINER_NAME $IMAGE_NAME

# Wait until app responds
echo "🔹 Waiting for Flutter app to start..."
until curl -s http://localhost:80/index.html; do
    echo "Waiting 5s..."
    sleep 5
done

echo "✅ Flutter app is running and ready at $(date)"
