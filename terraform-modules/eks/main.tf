terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

variable "environment" {
  description = "Environment name (e.g., dev, qa, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the EKS cluster will be created"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for EKS"
  type        = list(string)
}

variable "cluster_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.24"
}

locals {
  name = "aft-${var.environment}"
  
  tags = {
    Environment = var.environment
    Terraform   = "true"
    Project     = "AFT"
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 18.0"

  cluster_name    = local.name
  cluster_version = var.cluster_version

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids

  enable_irsa = true

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  # Add-ons
  cluster_addons = {
    coredns = {
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy = {}
    vpc-cni = {
      resolve_conflicts = "OVERWRITE"
    }
  }

  # Node groups
  eks_managed_node_groups = {
    default = {
      min_size     = var.environment == "prod" ? 3 : 2
      max_size     = var.environment == "prod" ? 6 : 4
      desired_size = var.environment == "prod" ? 3 : 2

      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"

      update_config = {
        max_unavailable_percentage = 33
      }

      labels = {
        Environment = var.environment
      }

      tags = local.tags
    }
  }

  # Security groups
  cluster_security_group_additional_rules = {
    egress_nodes_ephemeral_ports_tcp = {
      description                = "To node 1025-65535"
      protocol                  = "tcp"
      from_port                 = 1025
      to_port                   = 65535
      type                      = "egress"
      source_node_security_group = true
    }
  }

  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
  }

  tags = local.tags
}

# CloudWatch Container Insights
resource "aws_cloudwatch_log_group" "eks_container_insights" {
  name              = "/aws/containerinsights/${local.name}/performance"
  retention_in_days = 30
  tags              = local.tags
}

output "cluster_id" {
  description = "EKS cluster ID"
  value       = module.eks.cluster_id
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

output "cluster_iam_role_name" {
  description = "IAM role name associated with EKS cluster"
  value       = module.eks.cluster_iam_role_name
} 