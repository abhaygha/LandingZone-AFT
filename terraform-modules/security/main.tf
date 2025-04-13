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

variable "vpc_id" {
  description = "VPC ID for security group creation"
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

# Service Control Policies
resource "aws_organizations_policy" "restrict_regions" {
  name = "${local.name}-restrict-regions"
  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "RestrictRegions"
        Effect    = "Deny"
        Action    = "*"
        Resource  = "*"
        Condition = {
          StringNotEquals = {
            "aws:RequestedRegion": [
              "us-east-1",
              "us-west-2"
            ]
          }
        }
      }
    ]
  })

  tags = local.tags
}

resource "aws_organizations_policy" "require_tags" {
  name = "${local.name}-require-tags"
  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "RequireTags"
        Effect    = "Deny"
        Action    = [
          "ec2:RunInstances",
          "ec2:CreateVolume",
          "rds:CreateDBInstance"
        ]
        Resource  = "*"
        Condition = {
          "Null": {
            "aws:RequestTag/Environment": "true",
            "aws:RequestTag/Project": "true"
          }
        }
      }
    ]
  })

  tags = local.tags
}

# Security Groups
resource "aws_security_group" "bastion" {
  name        = "${local.name}-bastion"
  description = "Security group for bastion hosts"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Should be restricted to company IP range
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, {
    Name = "${local.name}-bastion"
  })
}

resource "aws_security_group" "internal" {
  name        = "${local.name}-internal"
  description = "Security group for internal resources"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.bastion.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, {
    Name = "${local.name}-internal"
  })
}

# AWS WAF Web ACL
resource "aws_wafv2_web_acl" "main" {
  name        = "${local.name}-web-acl"
  description = "Web ACL for protecting applications"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name               = "AWSManagedRulesCommonRuleSetMetric"
      sampled_requests_enabled  = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name               = "${local.name}-web-acl-metric"
    sampled_requests_enabled  = true
  }

  tags = local.tags
}

# Outputs
output "bastion_security_group_id" {
  description = "ID of bastion security group"
  value       = aws_security_group.bastion.id
}

output "internal_security_group_id" {
  description = "ID of internal security group"
  value       = aws_security_group.internal.id
}

output "web_acl_arn" {
  description = "ARN of WAF Web ACL"
  value       = aws_wafv2_web_acl.main.arn
}

output "restrict_regions_policy_id" {
  description = "ID of restrict regions SCP"
  value       = aws_organizations_policy.restrict_regions.id
}

output "require_tags_policy_id" {
  description = "ID of require tags SCP"
  value       = aws_organizations_policy.require_tags.id
} 