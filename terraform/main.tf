#######################################################
# DATA SOURCES
#######################################################

data "aws_availability_zones" "available" {}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-2.0.20250902.3-x86_64-gp2"]
  }
}

#######################################################
# NETWORKING - VPC, SUBNETS, INTERNET ACCESS
#######################################################

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet-${count.index + 1}"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "${var.project_name}-rt"
  }
}

resource "aws_route_table_association" "public_assoc" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

#######################################################
# SECURITY GROUPS
#######################################################

# ALB Security Group
resource "aws_security_group" "flutter_sg" {
  vpc_id      = aws_vpc.main.id
  name        = "${var.project_name}-lb-sg"
  description = "Security group for ALB"
  
  ingress {
    description = "Allow HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["45.123.162.128/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-lb-sg"
  }
}

# EC2 Security Group
resource "aws_security_group" "flutter_ec2_sg" {
  vpc_id      = aws_vpc.main.id
  name        = "${var.project_name}-ec2-sg"
  description = "Security group for Flutter EC2 instances"

  ingress {
    description     = "Allow HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.flutter_sg.id]
  }

  ingress {
    description = "Allow Node Exporter"
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    description = "Allow SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["45.123.162.128/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-ec2-sg"
  }
}

#######################################################
# LOAD BALANCER + TARGET GROUP + LISTENER
#######################################################

resource "aws_lb" "flutter_lb" {
  name               = "${var.project_name}-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.flutter_sg.id]
  subnets            = aws_subnet.public[*].id

  tags = {
    Name = "${var.project_name}-lb"
  }
}

resource "aws_lb_target_group" "flutter_tg" {
  port     = var.instance_port
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/index.html"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 5
    matcher             = "200-399"
  }

  tags = {
    Name = "${var.project_name}-tg"
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
# KEY PAIR FOR SSH
#######################################################
resource "aws_key_pair" "deployer" {
  key_name   = "${var.project_name}-key"
  public_key = file("/Users/jaydeep/.ssh/sample-project-one.pub")
}

#######################################################
# LAUNCH TEMPLATE (FLUTTER APP)
#######################################################
resource "aws_launch_template" "flutter" {
  name_prefix   = "${var.project_name}-lt-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  key_name      = aws_key_pair.deployer.key_name
  user_data     = base64encode(file("${path.module}/userdata.sh"))
  vpc_security_group_ids = [aws_security_group.flutter_ec2_sg.id]

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-instance"
    }
  }
}

#######################################################
# AUTO SCALING GROUP (FLUTTER APP)
#######################################################
resource "aws_autoscaling_group" "flutter_asg" {
  desired_capacity           = var.desired_capacity
  max_size                   = var.max_size
  min_size                   = var.min_size

  launch_template {
    id      = aws_launch_template.flutter.id
    version = "$Latest"
  }

  vpc_zone_identifier       = aws_subnet.public[*].id
  target_group_arns         = [aws_lb_target_group.flutter_tg.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 300

  tag {
    key                 = "Name"
    value               = "${var.project_name}-asg"
    propagate_at_launch = true
  }
}
