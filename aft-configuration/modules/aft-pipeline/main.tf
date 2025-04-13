terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# CodePipeline for AFT
resource "aws_codepipeline" "aft_pipeline" {
  name     = var.pipeline_name
  role_arn = var.pipeline_role

  artifact_store {
    location = aws_s3_bucket.aft_artifacts.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        RepositoryName = "aft-account-request"
        BranchName     = "main"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = var.codebuild_project_name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CloudFormation"
      input_artifacts = ["build_output"]
      version         = "1"

      configuration = {
        ActionMode     = "CREATE_UPDATE"
        Capabilities   = "CAPABILITY_NAMED_IAM"
        StackName      = "aft-account-provisioning"
        TemplatePath   = "build_output::template.yaml"
        ParameterOverrides = jsonencode({
          AccountEmail = "#{AccountEmail}"
          AccountName  = "#{AccountName}"
          ManagedOrganizationalUnit = "#{ManagedOrganizationalUnit}"
        })
      }
    }
  }
}

# CodeBuild Project
resource "aws_codebuild_project" "aft_build" {
  name          = var.codebuild_project_name
  description   = "Build project for AFT account provisioning"
  build_timeout = "5"
  service_role  = var.codebuild_role

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = "us-east-1"
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = file("${path.module}/buildspec.yml")
  }
}

# S3 Bucket for Pipeline Artifacts
resource "aws_s3_bucket" "aft_artifacts" {
  bucket = "aft-pipeline-artifacts-${data.aws_caller_identity.current.account_id}"
  
  tags = {
    Name        = "AFT Pipeline Artifacts"
    Environment = "AFT"
  }
}

resource "aws_s3_bucket_versioning" "aft_artifacts" {
  bucket = aws_s3_bucket.aft_artifacts.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "aft_artifacts" {
  bucket = aws_s3_bucket.aft_artifacts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Variables
variable "pipeline_name" {
  description = "Name of the CodePipeline"
  type        = string
}

variable "pipeline_role" {
  description = "ARN of the IAM role for CodePipeline"
  type        = string
}

variable "codebuild_project_name" {
  description = "Name of the CodeBuild project"
  type        = string
}

variable "codebuild_role" {
  description = "ARN of the IAM role for CodeBuild"
  type        = string
}

variable "codepipeline_role" {
  description = "ARN of the IAM role for CodePipeline"
  type        = string
}

# Data Sources
data "aws_caller_identity" "current" {} 