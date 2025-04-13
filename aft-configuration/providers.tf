provider "aws" {
  region  = var.ct_home_region
  profile = "aft-management"

  # Assume role in the management account
  assume_role {
    role_arn = "arn:aws:iam::${var.aft_management_account_id}:role/AFTManagementRole"
  }

  default_tags {
    tags = {
      Environment = "AFT"
      Project     = "AccountFactory"
      ManagedBy   = "Terraform"
    }
  }
}

# Provider for Control Tower management account
provider "aws" {
  alias   = "ct_management"
  region  = var.ct_home_region
  profile = "ct-management"

  # Assume role in the Control Tower management account
  assume_role {
    role_arn = "arn:aws:iam::${var.ct_management_account_id}:role/AWSControlTowerExecution"
  }
}

# Provider for log archive account
provider "aws" {
  alias   = "log_archive"
  region  = var.ct_home_region
  profile = "log-archive"

  # Assume role in the log archive account
  assume_role {
    role_arn = "arn:aws:iam::${var.log_archive_account_id}:role/AWSControlTowerExecution"
  }
}

# Provider for audit account
provider "aws" {
  alias   = "audit"
  region  = var.ct_home_region
  profile = "audit"

  # Assume role in the audit account
  assume_role {
    role_arn = "arn:aws:iam::${var.audit_account_id}:role/AWSControlTowerExecution"
  }
} 