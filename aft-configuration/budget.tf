# Budget for AFT Management Account
resource "aws_budgets_budget" "aft_management" {
  name              = "aft-management-budget"
  budget_type       = "COST"
  limit_amount      = "1000"
  limit_unit        = "USD"
  time_period_start = "2024-01-01_00:00"
  time_unit         = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = 80
    threshold_type            = "PERCENTAGE"
    notification_type         = "ACTUAL"
    subscriber_email_addresses = ["aft-alerts@your-domain.com"]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = 100
    threshold_type            = "PERCENTAGE"
    notification_type         = "ACTUAL"
    subscriber_email_addresses = ["aft-alerts@your-domain.com"]
  }
}

# Cost Allocation Tags
resource "aws_cost_allocation_tags" "aft" {
  tags = {
    Environment = "AFT"
    Project     = "AccountFactory"
    ManagedBy   = "Terraform"
  }
}

# Cost Explorer Report
resource "aws_ce_cost_allocation_tag" "aft" {
  tag_key = "Environment"
  status  = "Active"
}

# Budget for Account Factory
resource "aws_budgets_budget" "account_factory" {
  name              = "account-factory-budget"
  budget_type       = "COST"
  limit_amount      = "5000"
  limit_unit        = "USD"
  time_period_start = "2024-01-01_00:00"
  time_unit         = "MONTHLY"

  cost_filter {
    name   = "Service"
    values = ["AWS Control Tower", "AWS Organizations", "AWS CloudFormation"]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = 80
    threshold_type            = "PERCENTAGE"
    notification_type         = "ACTUAL"
    subscriber_email_addresses = ["aft-alerts@your-domain.com"]
  }
}

# Budget for Customizations
resource "aws_budgets_budget" "customizations" {
  name              = "customizations-budget"
  budget_type       = "COST"
  limit_amount      = "2000"
  limit_unit        = "USD"
  time_period_start = "2024-01-01_00:00"
  time_unit         = "MONTHLY"

  cost_filter {
    name   = "Service"
    values = ["AWS CodePipeline", "AWS CodeBuild", "Amazon S3"]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = 80
    threshold_type            = "PERCENTAGE"
    notification_type         = "ACTUAL"
    subscriber_email_addresses = ["aft-alerts@your-domain.com"]
  }
} 