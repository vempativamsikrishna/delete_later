

resource "aws_launch_configuration" "example" {
  name = "example-launch-configuration"

  image_id = "ami-072108ddc216e134a"  # Replace with your AMI ID
  instance_type = "t2.micro"  # Choose an appropriate instance type
  key_name = "BHIM"
  iam_instance_profile = "admin"

  security_groups = [ aws_security_group.allow_all.id ]
  associate_public_ip_address = true

  user_data = <<USER_DATA
#!/bin/bash
apt update
sudo apt install unzip jq -y
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    sudo service nginx on
    sudo service nginx start
    USER_DATA

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "example" {
  desired_capacity     = 2
  max_size             = 5
  min_size             = 2
  vpc_zone_identifier  = [
    aws_subnet.subnet1-public.id,
    aws_subnet.subnet2-public.id
  ]  # Replace with your subnet ID

  launch_configuration = aws_launch_configuration.example.id

  health_check_type          = "EC2"
  health_check_grace_period  = 300  # 5 minutes

  tag {
    key                 = "Name"
    value               = "example-asg-instance"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "scale_up" {
  name                   = "scale-up-policy"
  scaling_adjustment    = 1
  adjustment_type       = "ChangeInCapacity"
  cooldown              = 300  # 5 minutes
#   cooldown_action       = "Default"
  autoscaling_group_name = aws_autoscaling_group.example.name

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "CustomMetrics"  # Placeholder metric, replace with the correct load average metric type
    }

    # estimated_instance_warmup = 300  # Adjust based on your application's startup time
    target_value              = 30   # Scale up when the 5-minute load average reaches 75%
  }
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "scale-down-policy"
  scaling_adjustment    = -1
  adjustment_type       = "ChangeInCapacity"
  cooldown              = 300  # 5 minutes
#   cooldown_action       = "Default"
  autoscaling_group_name = aws_autoscaling_group.example.name

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "CustomMetrics"  # Placeholder metric, replace with the correct load average metric type
    }

    # estimated_instance_warmup = 300  # Adjust based on your application's startup time
    target_value              = 10   # Scale down when the 5-minute load average reaches 50%
  }
}
