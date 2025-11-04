#!/bin/bash
# --------------------------
# User Data for Flutter Web App EC2 Instance
# --------------------------

# Update system packages and install Docker
yum update -y
amazon-linux-extras install docker -y

# Start and enable Docker service
systemctl enable docker
systemctl start docker

# Add ec2-user to docker group (optional)
usermod -aG docker ec2-user

# Define image name (without hardcoding version)
IMAGE_NAME="jay0604/flutter-web:latest"

# Always pull the latest version of your image
docker pull $IMAGE_NAME

# Stop and remove any existing container on port 80
EXISTING_CONTAINER=$(docker ps -q --filter "publish=80")
if [ -n "$EXISTING_CONTAINER" ]; then
    docker stop $EXISTING_CONTAINER
    docker rm $EXISTING_CONTAINER
fi

# Run the latest Flutter web app container
docker run -d -p 80:80 --name flutter-web $IMAGE_NAME

# (Optional) Install Node Exporter for Prometheus monitoring
cd /opt
curl -LO https://github.com/prometheus/node_exporter/releases/latest/download/node_exporter-1.8.1.linux-amd64.tar.gz
tar xvf node_exporter-1.8.1.linux-amd64.tar.gz
cd node_exporter-1.8.1.linux-amd64
nohup ./node_exporter > /dev/null 2>&1 &
echo "Node Exporter running on port 9100"

# --------------------------
# Prometheus Setup
# --------------------------

mkdir -p /home/ec2-user/prometheus
cat <<EOF > /home/ec2-user/prometheus/prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'flutter_app'
    static_configs:
      - targets: ['localhost:80']

  - job_name: 'node_exporter'
    static_configs:
      - targets: ['localhost:9100']
EOF

# Run Prometheus container
docker run -d \
  -p 9090:9090 \
  -v /home/ec2-user/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml \
  --name prometheus prom/prometheus


# --------------------------
# Grafana Setup
# --------------------------

docker run -d \
  -p 3000:3000 \
  --name grafana grafana/grafana

echo "✅ Flutter app running on port 80"
echo "✅ Prometheus running on port 9090"
echo "✅ Grafana running on port 3000"
echo "✅ Node Exporter running on port 9100"
