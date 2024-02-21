provider "aws" {
  region = "us-east-1" # Replace with your desired AWS region
}

resource "aws_vpc" "default" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  tags = {
    Name        = "${var.vpc_name}"
    Owner       = "Vamsi Krishna"
    environment = "${var.environment}"
  }
}

resource "aws_internet_gateway" "default" {
  vpc_id = aws_vpc.default.id
  tags = {
    Name = "${var.IGW_name}"
  }
}


resource "aws_subnet" "subnet1-public" {
  vpc_id            = aws_vpc.default.id
  cidr_block        = var.public_subnet1_cidr
  availability_zone = "us-east-1a"

  tags = {
    Name = "${var.public_subnet1_name}"
  }
}

resource "aws_subnet" "subnet2-public" {
  vpc_id            = aws_vpc.default.id
  cidr_block        = var.public_subnet2_cidr
  availability_zone = "us-east-1b"

  tags = {
    Name = "${var.public_subnet2_name}"
  }
}

resource "aws_subnet" "subnet3-public" {
  vpc_id            = aws_vpc.default.id
  cidr_block        = var.public_subnet3_cidr
  availability_zone = "us-east-1c"

  tags = {
    Name = "${var.public_subnet3_name}"
  }

}

resource "aws_route_table" "terraform-public" {
  vpc_id = aws_vpc.default.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.default.id
  }

  tags = {
    Name = "Public_Routing_Table"
  }
}

# resource "aws_route_table" "terraform-private" {
#   vpc_id = aws_vpc.default.id

#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_internet_gateway.default.id
#     # gateway_id = aws_nat_gateway.nat_gateway.id
#   }

#   tags = {
#     Name = "Private_Routing_Table"
#   }
# }

resource "aws_route_table_association" "terraform-public" {
  # count = "${length(aws_subnet.public-subnet)}"
  count = 3
  subnet_id      = aws_subnet.subnet1-public.id
  route_table_id = aws_route_table.terraform-public.id
}

# resource "aws_route_table_association" "terraform-private" {
#   count = "${length(aws_subnet.private-subnet)}"
#   subnet_id      = "${element(aws_subnet.private-subnet.*.id, count.index)}"
#   route_table_id = aws_route_table.terraform-private.id
# }

resource "aws_security_group" "allow_all" {
  name        = "allow_all"
  description = "Allow all inbound traffic"
  vpc_id      = aws_vpc.default.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# =============================================================================================

# resource "aws_launch_configuration" "example" {
#   name = "example-launch-config"

#   image_id = "${lookup(var.amis, var.aws_region, "us-east-1")}"  # Replace with your desired AMI ID
#   instance_type = "t2.micro" # Replace with your desired instance type

#   lifecycle {
#     create_before_destroy = true
#   }
# }

# resource "aws_autoscaling_group" "example" {
# #   count = "${length(aws_subnet.public-subnet)}"
#   desired_capacity     = 2
#   max_size             = 5
#   min_size             = 2
#   vpc_zone_identifier = ["${aws_subnet.subnet1-public.id}"]  # Replace with your subnet ID
#   launch_configuration = aws_launch_configuration.example.id

#   health_check_type          = "EC2"
#   health_check_grace_period  = 300

#   tag {
#     key                 = "Name"
#     value               = "example-instance"
#     propagate_at_launch = true
#   }
# }

# resource "aws_cloudwatch_metric_alarm" "scale_up_alarm" {
#   alarm_name          = "scale-up-alarm"
#   comparison_operator = "GreaterThanOrEqualToThreshold"
#   evaluation_periods  = 1
#   metric_name         = "LoadAverage"
#   namespace           = "System/Linux"
#   period              = 300 # 5 minutes
#   statistic           = "Average"
#   threshold           = 75
#   alarm_description   = "Scale up when the 5-minute load average is greater than or equal to 75%."

#   dimensions = {
#     AutoScalingGroupName = aws_autoscaling_group.example.name
#   }

#   alarm_actions = [aws_autoscaling_policy.scale_up_policy.arn]
# #   alarm_actions = [aws_autoscaling_policy.scale_up_policy.arn, aws_sns_topic.scale_alerts.arn]
# }

# resource "aws_autoscaling_policy" "scale_up_policy" {
#   name                   = "scale-up-policy"
#   scaling_adjustment    = 1
#   cooldown              = 300 # 5 minutes cooldown
#   adjustment_type       = "ChangeInCapacity"
# #   cooldown_action       = "Default"
#   estimated_instance_warmup = 300 # 5 minutes warm-up time

#   autoscaling_group_name = aws_autoscaling_group.example.name
# }

# resource "aws_cloudwatch_metric_alarm" "scale_down_alarm" {
#   alarm_name          = "scale-down-alarm"
#   comparison_operator = "LessThanOrEqualToThreshold"
#   evaluation_periods  = 1
#   metric_name         = "LoadAverage"
#   namespace           = "System/Linux"
#   period              = 300 # 5 minutes
#   statistic           = "Average"
#   threshold           = 50
#   alarm_description   = "Scale down when the 5-minute load average is less than or equal to 50%."

#   dimensions = {
#     AutoScalingGroupName = aws_autoscaling_group.example.name
#   }

# #   alarm_actions = [aws_autoscaling_policy.scale_down_policy.arn, aws_sns_topic.scale_alerts.arn]
#   alarm_actions = [aws_autoscaling_policy.scale_down_policy.arn]
# }

# resource "aws_autoscaling_policy" "scale_down_policy" {
#   name                   = "scale-down-policy"
#   scaling_adjustment    = -1
#   cooldown              = 300 # 5 minutes cooldown
#   adjustment_type       = "ChangeInCapacity"
# #   cooldown_action       = "Default"
#   estimated_instance_warmup = 300 # 5 minutes warm-up time

#   autoscaling_group_name = aws_autoscaling_group.example.name
# }

# ===============================================================================================

# resource "aws_sns_topic" "scale_alerts" {
#   name = "scale-alerts"
# }

# resource "aws_lambda_function" "instance_refresh" {
#   function_name    = "instance-refresh"
#   runtime          = "python3.8"
#   handler          = "handler.lambda_handler"
#   timeout          = 60
#   memory_size      = 128
#   source_code_hash = filebase64("${path.module}/lambda_function.zip")

#   role = aws_iam_role.lambda_execution_role.arn

# #   environment = {
# #     AUTOSCALING_GROUP_NAME = aws_autoscaling_group.example.name
# #   }

#   depends_on = [aws_autoscaling_group.example]
# }

# resource "aws_iam_role" "lambda_execution_role" {
#   name = "lambda_execution_role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Action = "sts:AssumeRole",
#         Effect = "Allow",
#         Principal = {
#           Service = "lambda.amazonaws.com",
#         },
#       },
#     ],
#   })
# }

# resource "aws_iam_role_policy_attachment" "lambda_execution_role_policy_attachment" {
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
#   role       = aws_iam_role.lambda_execution_role.name
# }

# resource "aws_iam_role_policy" "lambda_execution_role_policy" {
#   name = "lambda_execution_role_policy"
#   role = aws_iam_role.lambda_execution_role.name

#   policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Action = "autoscaling:SetDesiredCapacity",
#         Effect = "Allow",
#         Resource = "*",
#       },
#       {
#         Action = "autoscaling:DescribeAutoScalingGroups",
#         Effect = "Allow",
#         Resource = "*",
#       },
#     ],
#   })
# }
