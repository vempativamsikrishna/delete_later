
resource "aws_launch_configuration" "example" {
  name = "example-lc"
  image_id = "ami-0747068e69eacf5c4"
  instance_type = "t2.micro"
  key_name = "BHIM"
  iam_instance_profile = "admin"

  security_groups = [ aws_security_group.allow_all.id ]
  associate_public_ip_address = true

  lifecycle {
    create_before_destroy = true
  }

  user_data = <<-EOF
    #!/bin/bash
    sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-config-wizard -a fetch-config -m ec2 -c ssm:${var.ssm_parameter_name} -s
  EOF
}

resource "aws_autoscaling_group" "example" {
  desired_capacity     = 2
  max_size             = 4
  min_size             = 1
  vpc_zone_identifier = [
    aws_subnet.subnet1-public.id,
    aws_subnet.subnet2-public.id
  ]

  launch_configuration = aws_launch_configuration.example.id

  health_check_type          = "EC2"
  health_check_grace_period  = 300
  force_delete                = true

  tag {
    key                 = "Name"
    value               = "example-asg"
    propagate_at_launch = true
  }
}

resource "aws_cloudwatch_metric_alarm" "example" {
  alarm_name          = "example-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "LoadAverage"
  namespace           = "CWAgent"
  period              = 300
  statistic           = "Average"
  threshold           = 1.0

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.example.name
  }

  alarm_actions = [
    aws_autoscaling_policy.example.arn,
  ]
}

resource "aws_autoscaling_policy" "example" {
  name                   = "example-policy"
  scaling_adjustment    = 1
  adjustment_type       = "ChangeInCapacity"
  cooldown              = 300
#   cooldown_action       = "Set to minimum"
#   estimated_instance_warmup = 600
  policy_type           = "SimpleScaling"
#   min_adjustment_magnitude = 1

  autoscaling_group_name = aws_autoscaling_group.example.name
}


resource "aws_ssm_parameter" "example" {
  name  = "/example/cloudwatch-agent-config"
  type  = "SecureString"
  value = <<EOF
  {
    "agent": {
      "metrics_collection_interval": 10
    },
    "metrics": {
      "append_dimensions": {
        "AutoScalingGroupName": "${aws_autoscaling_group.example.name}"
      },
      "metrics_collected": {
        "load": {
          "measurement": [
            "1-minute"
          ]
        }
      }
    }
  }
  EOF
}


