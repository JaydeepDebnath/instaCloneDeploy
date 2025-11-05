#######################################################
# GRAFANA EC2 INSTANCE
#######################################################

resource "aws_security_group" "grafana_sg" {
  vpc_id      = aws_vpc.main.id
  name        = "grafana-sg"
  description = "Security group for Grafana"

  ingress {
    description = "Allow Grafana Web UI"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "grafana-sg"
  }
}

resource "aws_instance" "grafana" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public[1].id
  vpc_security_group_ids = [aws_security_group.grafana_sg.id]
  associate_public_ip_address = true

  user_data = base64encode(file("${path.module}/grafana-userdata.sh"))

  tags = {
    Name = "grafana-server"
  }
}
