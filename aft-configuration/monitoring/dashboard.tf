resource "aws_cloudwatch_dashboard" "aft_bulk_dashboard" {
  dashboard_name = "AFT-Bulk-Account-Creation"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/CodePipeline", "FailedExecutions", "PipelineName", "aft-bulk-account-pipeline"]
          ]
          period = 300
          stat   = "Sum"
          region = "us-east-1"
          title  = "Pipeline Failures"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/CodePipeline", "SucceededExecutions", "PipelineName", "aft-bulk-account-pipeline"]
          ]
          period = 300
          stat   = "Sum"
          region = "us-east-1"
          title  = "Pipeline Successes"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/Organizations", "CreateAccountStatus", "Status", "SUCCEEDED"],
            ["AWS/Organizations", "CreateAccountStatus", "Status", "FAILED"]
          ]
          period = 300
          stat   = "Sum"
          region = "us-east-1"
          title  = "Account Creation Status"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/CodeBuild", "Duration", "ProjectName", "aft-bulk-account-processor"]
          ]
          period = 300
          stat   = "Average"
          region = "us-east-1"
          title  = "Processing Duration"
        }
      },
      {
        type   = "text"
        x      = 0
        y      = 12
        width  = 24
        height = 3
        properties = {
          markdown = "# AFT Bulk Account Creation Dashboard\n\nThis dashboard monitors the bulk account creation process."
        }
      }
    ]
  })
}

resource "aws_cloudwatch_log_group" "aft_bulk_logs" {
  name              = "/aws/codebuild/aft-bulk-account-processor"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_metric_filter" "account_creation_errors" {
  name           = "AccountCreationErrors"
  pattern        = "ERROR"
  log_group_name = aws_cloudwatch_log_group.aft_bulk_logs.name

  metric_transformation {
    name      = "AccountCreationErrors"
    namespace = "AFT/BulkAccountCreation"
    value     = "1"
  }
}

resource "aws_cloudwatch_alarm" "account_creation_errors" {
  alarm_name          = "aft-bulk-account-creation-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "AccountCreationErrors"
  namespace           = "AFT/BulkAccountCreation"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "Monitor errors in bulk account creation"
  alarm_actions       = [aws_sns_topic.pipeline_notifications.arn]
} 