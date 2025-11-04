#######################################################
# DATA SOURCES
#######################################################

data "aws_availability_zones" "available" {}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

#######################################################
# NETWORKING - VPC, SUBNETS, INTERNET ACCESS
#######################################################

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "flutter-vpc"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "flutter-gateway"
  }
}

resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "flutter-public-subnet-${count.index + 1}"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "flutter-public-rt"
  }
}

resource "aws_route_table_association" "a" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

#######################################################
# SECURITY GROUP
#######################################################

resource "aws_security_group" "web_sg" {
  vpc_id = aws_vpc.main.id
  name   = "flutter-web-sg"
  description = "Security group for Flutter, Grafana, and Prometheus"

  # HTTP (Load Balancer / App)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH (for EC2 access)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Grafana web UI
  ingress {
    description = "Allow Grafana web access"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Prometheus web UI
  ingress {
    description = "Allow Prometheus web access"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "flutter-web-sg"
  }
}

#######################################################
# EC2 LAUNCH TEMPLATE + USERDATA (Docker run)
#######################################################

resource "aws_launch_template" "flutter" {
  name_prefix   = "flutter-app-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"

  user_data = base64encode(file("${path.module}/userdata.sh"))

  vpc_security_group_ids = [aws_security_group.web_sg.id]

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "flutter-instance"
    }
  }
}

#######################################################
# LOAD BALANCER + TARGET GROUP + LISTENER
#######################################################

resource "aws_lb" "flutter_lb" {
  name               = "flutter-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web_sg.id]
  subnets            = aws_subnet.public[*].id

  tags = {
    Name = "flutter-lb"
  }
}

resource "aws_lb_target_group" "flutter_tg" {
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  tags = {
    Name = "flutter-tg"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.flutter_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.flutter_tg.arn
  }
}

#######################################################
# AUTO SCALING GROUP + POLICIES
#######################################################

resource "aws_autoscaling_group" "flutter_asg" {
  desired_capacity     = 1
  max_size             = 3
  min_size             = 1

  launch_template {
    id      = aws_launch_template.flutter.id
    version = "$Latest"
  }

  vpc_zone_identifier = aws_subnet.public[*].id
  target_group_arns   = [aws_lb_target_group.flutter_tg.arn]
  health_check_type   = "EC2"

  tag {
    key                 = "Name"
    value               = "flutter-asg"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "scale_out" {
  name                   = "scale-out"
  autoscaling_group_name = aws_autoscaling_group.flutter_asg.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown               = 300
}

resource "aws_autoscaling_policy" "scale_in" {
  name                   = "scale-in"
  autoscaling_group_name = aws_autoscaling_group.flutter_asg.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = -1
  cooldown               = 300
}

#######################################################
# CLOUDWATCH ALARMS
#######################################################

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "cpu_high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 60
  alarm_description   = "Scale up when CPU > 60%"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.flutter_asg.name
  }
  alarm_actions = [aws_autoscaling_policy.scale_out.arn]
}

resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "cpu_low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 20
  alarm_description   = "Scale down when CPU < 20%"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.flutter_asg.name
  }
  alarm_actions = [aws_autoscaling_policy.scale_in.arn]
}
