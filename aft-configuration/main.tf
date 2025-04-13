terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# AFT Management Account Configuration
module "aft_management" {
  source = "github.com/aws-ia/terraform-aws-control_tower_account_factory?ref=1.10.0"

  # AFT Configuration
  ct_management_account_id    = var.ct_management_account_id
  log_archive_account_id      = var.log_archive_account_id
  audit_account_id           = var.audit_account_id
  aft_management_account_id  = var.aft_management_account_id
  ct_home_region             = var.ct_home_region

  # VPC Configuration
  vpc_id                     = var.vpc_id
  private_subnet_ids         = var.private_subnet_ids
  aft_vpc_endpoints          = true

  # Customization Configuration
  aft_feature_cloudtrail_data_events = true
  aft_feature_delete_default_vpc     = true
  aft_feature_enterprise_support     = true

  # Customization Options
  customizations = {
    account_request = {
      source = "git::https://github.com/your-org/aft-account-request.git"
    }
    global_customizations = {
      source = "git::https://github.com/your-org/aft-global-customizations.git"
    }
    account_customizations = {
      source = "git::https://github.com/your-org/aft-account-customizations.git"
    }
  }
}

# AFT Pipeline Configuration
module "aft_pipeline" {
  source = "./modules/aft-pipeline"

  # Pipeline Configuration
  pipeline_name = "aft-account-provisioning"
  pipeline_role = aws_iam_role.aft_pipeline.arn

  # CodeBuild Configuration
  codebuild_project_name = "aft-account-provisioning"
  codebuild_role        = aws_iam_role.aft_codebuild.arn

  # CodePipeline Configuration
  codepipeline_role = aws_iam_role.aft_codepipeline.arn
}

# IAM Roles for AFT
resource "aws_iam_role" "aft_pipeline" {
  name = "aft-pipeline-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role" "aft_codebuild" {
  name = "aft-codebuild-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role" "aft_codepipeline" {
  name = "aft-codepipeline-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
      }
    ]
  })
}

# Variables
variable "ct_management_account_id" {
  description = "AWS Control Tower Management Account ID"
  type        = string
}

variable "log_archive_account_id" {
  description = "AWS Control Tower Log Archive Account ID"
  type        = string
}

variable "audit_account_id" {
  description = "AWS Control Tower Audit Account ID"
  type        = string
}

variable "aft_management_account_id" {
  description = "AFT Management Account ID"
  type        = string
}

variable "ct_home_region" {
  description = "AWS Control Tower Home Region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_id" {
  description = "VPC ID for AFT"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for AFT"
  type        = list(string)
} 