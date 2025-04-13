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
  type        = string
  description = "Environment name (e.g., dev, qa, prod)"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for VPC"
}

variable "azs" {
  type        = list(string)
  description = "Availability zones"
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

locals {
  name = "aft-${var.environment}"
  
  private_subnets = [
    for i, az in var.azs : cidrsubnet(var.vpc_cidr, 4, i)
  ]
  
  public_subnets = [
    for i, az in var.azs : cidrsubnet(var.vpc_cidr, 4, i + length(var.azs))
  ]

  tags = {
    Environment = var.environment
    Terraform   = "true"
    Project     = "AFT"
  }
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"

  name = local.name
  cidr = var.vpc_cidr

  azs             = var.azs
  private_subnets = local.private_subnets
  public_subnets  = local.public_subnets

  enable_nat_gateway     = true
  single_nat_gateway     = var.environment != "prod"
  enable_dns_hostnames   = true
  enable_dns_support     = true
  
  # VPC Flow Logs
  enable_flow_log                      = true
  create_flow_log_cloudwatch_log_group = true
  create_flow_log_cloudwatch_iam_role  = true
  flow_log_max_aggregation_interval    = 60

  # VPC Endpoints for AWS Services
  enable_s3_endpoint       = true
  enable_dynamodb_endpoint = true

  vpc_tags = merge(local.tags, {
    Name = local.name
  })

  private_subnet_tags = merge(local.tags, {
    "kubernetes.io/role/internal-elb" = "1"
    Tier = "Private"
  })

  public_subnet_tags = merge(local.tags, {
    "kubernetes.io/role/elb" = "1"
    Tier = "Public"
  })
}

output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnets
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
} 