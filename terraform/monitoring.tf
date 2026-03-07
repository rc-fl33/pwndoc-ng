# CloudWatch alarms for basic instance monitoring
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.project_name}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "CPU utilization exceeds 80% for 15 minutes"

  dimensions = {
    InstanceId = aws_instance.app.id
  }

  tags = {
    Name = "${var.project_name}-cpu-high"
  }
}

resource "aws_cloudwatch_metric_alarm" "status_check" {
  alarm_name          = "${var.project_name}-status-check"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Maximum"
  threshold           = 0
  alarm_description   = "Instance status check failed"

  dimensions = {
    InstanceId = aws_instance.app.id
  }

  tags = {
    Name = "${var.project_name}-status-check"
  }
}
