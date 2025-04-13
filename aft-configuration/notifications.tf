# SNS Topic for pipeline notifications
resource "aws_sns_topic" "pipeline_notifications" {
  name = "aft-pipeline-notifications"
  
  tags = {
    Name        = "AFT Pipeline Notifications"
    Environment = "AFT"
  }
}

# SNS Topic Policy
resource "aws_sns_topic_policy" "pipeline_notifications" {
  arn = aws_sns_topic.pipeline_notifications.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
        Action = [
          "SNS:Publish"
        ]
        Resource = aws_sns_topic.pipeline_notifications.arn
      }
    ]
  })
}

# CloudWatch Event Rule for pipeline state changes
resource "aws_cloudwatch_event_rule" "pipeline_state" {
  name        = "aft-pipeline-state-changes"
  description = "Capture AFT pipeline state changes"

  event_pattern = jsonencode({
    source = ["aws.codepipeline"]
    detail-type = ["CodePipeline Pipeline Execution State Change"]
    detail = {
      pipeline = [module.aft_pipeline.pipeline_name]
    }
  })
}

# CloudWatch Event Target
resource "aws_cloudwatch_event_target" "pipeline_notifications" {
  rule      = aws_cloudwatch_event_rule.pipeline_state.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.pipeline_notifications.arn
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "pipeline_failures" {
  alarm_name          = "aft-pipeline-failures"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "FailedExecutions"
  namespace           = "AWS/CodePipeline"
  period             = "300"
  statistic          = "Sum"
  threshold          = "0"
  alarm_description  = "This metric monitors AFT pipeline failures"
  alarm_actions      = [aws_sns_topic.pipeline_notifications.arn]

  dimensions = {
    PipelineName = module.aft_pipeline.pipeline_name
  }
}

resource "aws_cloudwatch_metric_alarm" "pipeline_duration" {
  alarm_name          = "aft-pipeline-duration"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "ExecutionTime"
  namespace           = "AWS/CodePipeline"
  period             = "300"
  statistic          = "Maximum"
  threshold          = "3600"  # 1 hour
  alarm_description  = "This metric monitors AFT pipeline execution time"
  alarm_actions      = [aws_sns_topic.pipeline_notifications.arn]

  dimensions = {
    PipelineName = module.aft_pipeline.pipeline_name
  }
} 