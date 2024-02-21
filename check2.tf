

resource "aws_launch_configuration" "example" {
  name = "example_config"
  
  image_id = "ami-0c7217cdde317cfec"  # Specify the desired Ubuntu AMI ID
  instance_type = "t2.micro"          # Specify the desired instance type
  key_name = "BHIM"
  iam_instance_profile = "admin"

  security_groups = [ aws_security_group.allow_all.id ]
  associate_public_ip_address = true

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "example" {
  name = "testing"
  desired_capacity     = 2
  max_size             = 5
  min_size             = 2
  health_check_type    = "EC2"
  force_delete         = true
  vpc_zone_identifier  = [aws_subnet.subnet1-public.id]  # Specify your subnet ID

  launch_configuration = aws_launch_configuration.example.id

  tag {
    key                 = "Name"
    value               = "example-instance"
    propagate_at_launch = true
  }

#   scaling_policy {
#     name                   = "scale_up"
#     scaling_adjustment    = 1
#     adjustment_type       = "ChangeInCapacity"
#     cooldown              = 300  # 5 minutes cooldown
#     estimated_instance_warmup = 300
#   }

#   scaling_policy {
#     name                   = "scale_down"
#     scaling_adjustment    = -1
#     adjustment_type       = "ChangeInCapacity"
#     cooldown              = 300  # 5 minutes cooldown
#     estimated_instance_warmup = 300
#   }
}

resource "aws_autoscaling_policy" "web_policy_up" {
  name                   = "scale_up"
  scaling_adjustment    = 1
  adjustment_type       = "ChangeInCapacity"
  cooldown              = 300  # 5 minutes cooldown
#   estimated_instance_warmup = 300
  autoscaling_group_name = aws_autoscaling_group.example.name
}

resource "aws_autoscaling_policy" "web_policy_down" {
    name                   = "scale_down"
    scaling_adjustment    = -1
    adjustment_type       = "ChangeInCapacity"
    cooldown              = 300  # 5 minutes cooldown
    # estimated_instance_warmup = 300
  autoscaling_group_name = aws_autoscaling_group.example.name
}

resource "aws_cloudwatch_metric_alarm" "scale_up_alarm" {
  alarm_name          = "scale_up_alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "Load5"
  namespace           = "AWS/EC2"
  period              = 300  # 5 minutes
  statistic           = "Average"
  threshold           = 75
  alarm_description   = "Scale up when 5 mins load average >= 75%"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.example.name
  }

#   alarm_actions = [aws_autoscaling_policy.web_policy_up.id, aws_sns_topic.example.arn]
}

resource "aws_cloudwatch_metric_alarm" "scale_down_alarm" {
  alarm_name          = "scale_down_alarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "Load5"
  namespace           = "AWS/EC2"
  period              = 300  # 5 minutes
  statistic           = "Average"
  threshold           = 50
  alarm_description   = "Scale down when 5 mins load average <= 50%"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.example.name
  }

#   alarm_actions = [aws_autoscaling_policy.web_policy_down.id, aws_sns_topic.example.arn]
}

# resource "aws_autoscaling_schedule" "daily_refresh" {
#   scheduled_action_name  = "daily_refresh"
#   min_size               = 0
#   max_size               = 0
#   desired_capacity       = 0
#   recurrence             = "0 0 * * ? *"  # Everyday at 12am UTC

#   autoscaling_group_name = aws_autoscaling_group.example.name
# }

resource "aws_sns_topic" "example" {
  name = "example_topic"
}

resource "aws_sns_topic_subscription" "example" {
  topic_arn = aws_sns_topic.example.arn
  protocol  = "email"
  endpoint  = "your-email@example.com"
}
