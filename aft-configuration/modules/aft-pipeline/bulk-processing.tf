resource "aws_codebuild_project" "bulk_account_processor" {
  name          = "aft-bulk-account-processor"
  description   = "Processes bulk account creation requests"
  service_role  = var.codebuild_role

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_MEDIUM"
    image           = "aws/codebuild/standard:5.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true

    environment_variable {
      name  = "BULK_REQUEST_FILE"
      value = "bulk-account-requests.json"
    }
  }

  source {
    type            = "S3"
    location        = "${aws_s3_bucket.artifacts.bucket}/bulk-account-requests/${var.bulk_request_file}"
    buildspec       = <<-EOF
      version: 0.2
      phases:
        install:
          runtime-versions:
            python: 3.9
          commands:
            - pip install boto3
        build:
          commands:
            - aws s3 cp s3://${aws_s3_bucket.artifacts.bucket}/bulk-account-requests/${var.bulk_request_file} .
            - python3 ${path.module}/scripts/process_bulk_requests.py
      EOF
  }
}

resource "aws_codepipeline" "bulk_account_pipeline" {
  name     = "aft-bulk-account-pipeline"
  role_arn = var.pipeline_role

  artifact_store {
    location = aws_s3_bucket.artifacts.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "S3"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        S3Bucket    = aws_s3_bucket.artifacts.bucket
        S3ObjectKey = "bulk-account-requests/${var.bulk_request_file}"
      }
    }
  }

  stage {
    name = "Validate"

    action {
      name             = "Validate"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.bulk_account_processor.name
      }
    }
  }

  stage {
    name = "Process"

    action {
      name             = "Process"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.bulk_account_processor.name
      }
    }
  }
}

resource "aws_cloudwatch_event_rule" "bulk_pipeline_events" {
  name        = "aft-bulk-pipeline-events"
  description = "Capture state changes in bulk account pipeline"

  event_pattern = jsonencode({
    source      = ["aws.codepipeline"]
    detail-type = ["CodePipeline Pipeline Execution State Change"]
    detail = {
      pipeline = [aws_codepipeline.bulk_account_pipeline.name]
    }
  })
}

resource "aws_cloudwatch_event_target" "bulk_pipeline_notifications" {
  rule      = aws_cloudwatch_event_rule.bulk_pipeline_events.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.pipeline_notifications.arn
}

resource "aws_cloudwatch_metric_alarm" "bulk_pipeline_failures" {
  alarm_name          = "aft-bulk-pipeline-failures"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "FailedExecutions"
  namespace           = "AWS/CodePipeline"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "Monitor bulk account pipeline failures"
  alarm_actions       = [aws_sns_topic.pipeline_notifications.arn]

  dimensions = {
    PipelineName = aws_codepipeline.bulk_account_pipeline.name
  }
} 