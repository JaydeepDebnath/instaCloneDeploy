#######################################################
# VARIABLES FOR FLUTTER AWS AUTO SCALING DEPLOYMENT
#######################################################

variable "aws_region" {
  description = "AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name prefix for all AWS resources"
  type        = string
  default     = "flutter-app"
}

variable "instance_type" {
  description = "EC2 instance type for Flutter app"
  type        = string
  default     = "t2.micro"
}

variable "desired_capacity" {
  description = "Number of instances to start with"
  type        = number
  default     = 1
}

variable "min_size" {
  description = "Minimum number of instances in Auto Scaling Group"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of instances in Auto Scaling Group"
  type        = number
  default     = 3
}

variable "docker_image" {
  description = "Docker image for the Flutter web app"
  type        = string
  default     = "jay0604/flutter-web-app:latest"
}

variable "instance_port" {
  description = "Port where Flutter web app container listens"
  type        = number
  default     = 80
}
