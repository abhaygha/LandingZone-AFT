terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

variable "environment" {
  description = "Environment name (e.g., dev, qa, prod)"
  type        = string
}

locals {
  name = "aft-${var.environment}"
  
  tags = {
    Environment = var.environment
    Terraform   = "true"
    Project     = "AFT"
  }
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc/${local.name}/flow-logs"
  retention_in_days = 30
  tags              = local.tags
}

resource "aws_cloudwatch_log_group" "application_logs" {
  name              = "/aws/applications/${local.name}"
  retention_in_days = 30
  tags              = local.tags
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${local.name}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period             = "300"
  statistic          = "Average"
  threshold          = "80"
  alarm_description  = "This metric monitors EC2 CPU utilization"
  alarm_actions      = []  # Add SNS topic ARN here

  dimensions = {
    AutoScalingGroupName = "placeholder"  # Replace with actual ASG name
  }

  tags = local.tags
}

# AWS Config
resource "aws_config_configuration_recorder" "config" {
  name     = "${local.name}-config-recorder"
  role_arn = aws_iam_role.config_role.arn

  recording_group {
    all_supported = true
    include_global_resources = true
  }
}

resource "aws_config_configuration_recorder_status" "config" {
  name       = aws_config_configuration_recorder.config.name
  is_enabled = true
}

# GuardDuty
resource "aws_guardduty_detector" "main" {
  enable = true

  datasources {
    s3_logs {
      enable = true
    }
    kubernetes {
      audit_logs {
        enable = true
      }
    }
  }

  tags = local.tags
}

# IAM Role for Config
resource "aws_iam_role" "config_role" {
  name = "${local.name}-config-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
      }
    ]
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "config_policy" {
  role       = aws_iam_role.config_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
}

# Outputs
output "config_role_arn" {
  description = "ARN of AWS Config IAM role"
  value       = aws_iam_role.config_role.arn
}

output "guardduty_detector_id" {
  description = "ID of GuardDuty detector"
  value       = aws_guardduty_detector.main.id
}

output "vpc_flow_logs_group" {
  description = "Name of VPC Flow Logs CloudWatch Log Group"
  value       = aws_cloudwatch_log_group.vpc_flow_logs.name
}

output "application_logs_group" {
  description = "Name of Application CloudWatch Log Group"
  value       = aws_cloudwatch_log_group.application_logs.name
} 