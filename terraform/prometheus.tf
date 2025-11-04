###########################################
####### PROMETHEUS EC2 INSTANCE ###########
###########################################

resource "aws_instance" "prometheus" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public[0].id
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true
  key_name                    = "sample-project-one"

  user_data = base64encode(file("${path.module}/prometheus_userdata.sh"))

  tags = {
    Name = "prometheus-server"
  }
}

###########################################
############ OUTPUTS ######################
###########################################

output "prometheus_public_ip" {
  value = aws_instance.prometheus.public_ip
}

output "prometheus_public_dns" {
  value = aws_instance.prometheus.public_dns
}
