#######################################################
# PROMETHEUS EC2 INSTANCE
#######################################################

resource "aws_security_group" "prometheus_sg" {
  vpc_id      = aws_vpc.main.id
  name        = "prometheus-sg"
  description = "Security group for Prometheus"

  ingress {
    description = "Allow Prometheus Web UI"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow scraping Flutter EC2 instances
  ingress {
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "prometheus-sg"
  }
}

resource "aws_instance" "prometheus" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.prometheus_sg.id]
  associate_public_ip_address = true

  user_data = base64encode(templatefile("${path.module}/prometheus_userdata.sh", {
    APP_LB_DNS = aws_lb.flutter_lb.dns_name
  }))

  tags = {
    Name = "prometheus-server"
  }
}
