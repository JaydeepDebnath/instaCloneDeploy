resource "aws_instance" "grafana" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public[0].id
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true
  key_name                    = "sample-project-one"

  user_data = file("${path.module}/grafana-userdata.sh")

  tags = {
    Name = "Grafana-Server"
  }
}

output "grafana_public_ip" {
  value = aws_instance.grafana.public_ip
}

output "grafana_public_dns" {
  value = aws_instance.grafana.public_dns
}
