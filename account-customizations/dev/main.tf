terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# VPC Module
module "vpc" {
  source = "../../terraform-modules/vpc"

  environment = "dev"
  vpc_cidr    = "10.0.0.0/16"
}

# EKS Module
module "eks" {
  source = "../../terraform-modules/eks"

  environment        = "dev"
  vpc_id            = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnets
  cluster_version    = "1.24"
}

# IAM Module
module "iam" {
  source = "../../terraform-modules/iam"

  environment = "dev"
}

# Monitoring Module
module "monitoring" {
  source = "../../terraform-modules/monitoring"

  environment = "dev"
}

# Security Module
module "security" {
  source = "../../terraform-modules/security"

  environment = "dev"
  vpc_id      = module.vpc.vpc_id
}

# Development-specific Parameter Store parameters
resource "aws_ssm_parameter" "environment" {
  name  = "/aft/dev/environment"
  type  = "String"
  value = "dev"
  tags  = {
    Environment = "dev"
    Terraform   = "true"
    Project     = "AFT"
  }
}

resource "aws_ssm_parameter" "vpc_id" {
  name  = "/aft/dev/vpc_id"
  type  = "String"
  value = module.vpc.vpc_id
  tags  = {
    Environment = "dev"
    Terraform   = "true"
    Project     = "AFT"
  }
}

resource "aws_ssm_parameter" "eks_cluster_name" {
  name  = "/aft/dev/eks_cluster_name"
  type  = "String"
  value = module.eks.cluster_id
  tags  = {
    Environment = "dev"
    Terraform   = "true"
    Project     = "AFT"
  }
}

# Development-specific S3 bucket for application artifacts
resource "aws_s3_bucket" "artifacts" {
  bucket = "aft-dev-artifacts-${data.aws_caller_identity.current.account_id}"
  
  tags = {
    Environment = "dev"
    Terraform   = "true"
    Project     = "AFT"
  }
}

resource "aws_s3_bucket_versioning" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Development-specific CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "application" {
  name              = "/aft/dev/application"
  retention_in_days = 30
  tags = {
    Environment = "dev"
    Terraform   = "true"
    Project     = "AFT"
  }
}

resource "aws_cloudwatch_log_group" "eks" {
  name              = "/aft/dev/eks"
  retention_in_days = 30
  tags = {
    Environment = "dev"
    Terraform   = "true"
    Project     = "AFT"
  }
}

# Data Sources
data "aws_caller_identity" "current" {} 