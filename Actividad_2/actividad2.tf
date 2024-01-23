terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}


//Bien
provider "aws" {
  region  = "us-east-1"
  #access_key = <Your credential>
  #secret_acces_key = <Your credential>
}
resource "aws_default_vpc" "default" {
}

//Bien
data "aws_subnets" "subnets" {
  filter {
    name   = "vpc-id"
    values = [aws_default_vpc.default.id]
  }
}


# Bien
resource "aws_security_group" "ec2_security_group" {
  name = "ec2_web_instance"
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  vpc_id = aws_default_vpc.default.id
}

resource "aws_security_group" "lb" {
  name = "lb_instance"
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id = aws_default_vpc.default.id
}


resource "aws_lb" "test" {
  name               = "test-lb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ec2_security_group.id]
  subnets            = data.aws_subnets.subnets.ids
  timeouts {
    create = "5m"
  }

}

resource "aws_lb_target_group" "test" {
  name     = "tf-example-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id = aws_default_vpc.default.id
}

resource "aws_lb_listener" "web" {
  load_balancer_arn = aws_lb.test.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.test.arn
  }
}

resource "aws_launch_configuration" "test" {
  name_prefix     = "instancia-"
  image_id        = "ami-0005e0cfe09cc9050"
  instance_type   = "t2.micro"
  user_data       = file("user-data.sh")
  security_groups = [aws_security_group.ec2_security_group.id]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "test" {
  min_size             = 1
  max_size             = 3
  desired_capacity     = 1
  launch_configuration = aws_launch_configuration.test.name
  vpc_zone_identifier  = data.aws_subnets.subnets.ids

  lifecycle { 
    ignore_changes = [desired_capacity, target_group_arns]
  }
}

resource "aws_autoscaling_attachment" "test" {
  autoscaling_group_name = aws_autoscaling_group.test.id
  lb_target_group_arn   = aws_lb_target_group.test.arn
}


resource "aws_autoscaling_policy" "scale_down" {
  name                   = "test_scale_down"
  autoscaling_group_name = aws_autoscaling_group.test.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = -1
  cooldown               = 120
}

resource "aws_cloudwatch_metric_alarm" "scale_down" {
  alarm_description   = "Monitors CPU utilization"
  alarm_actions       = [aws_autoscaling_policy.scale_down.arn]
  alarm_name          = "test_scale_down"
  comparison_operator = "LessThanOrEqualToThreshold"
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  threshold           = "25"
  evaluation_periods  = "5"
  period              = "30"
  statistic           = "Average"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.test.name
  }
}

resource "aws_autoscaling_policy" "scale_up" {
  name                   = "test_scale_up"
  autoscaling_group_name = aws_autoscaling_group.test.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown               = 120
}

resource "aws_cloudwatch_metric_alarm" "scale_up" {
  alarm_description   = "Monitors CPU utilization"
  alarm_actions       = [aws_autoscaling_policy.scale_up.arn]
  alarm_name          = "test_scale_up"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  threshold           = "25"
  evaluation_periods  = "5"
  period              = "30"
  statistic           = "Average"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.test.name
  }
}


output "public_ip" {
  value = aws_lb.test.dns_name
}