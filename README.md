# AWS Landing Zone with Account Factory for Terraform (AFT)

This repository implements an AWS Landing Zone using Account Factory for Terraform (AFT) to automate secure, multi-account provisioning aligned with AWS Control Tower best practices.

## Architecture Overview

The implementation follows a GitOps-based architecture with the following components:

- Account Factory for Terraform (AFT) for automated account provisioning
- Segregated repositories for:
  - Account requests
  - Global customizations
  - Account-specific customizations
  - Reusable Terraform modules
- Environment-specific AWS accounts (Dev, QA, Prod)
- Centralized shared services account for governance

## Repository Structure

```
.
├── account-request/           # JSON metadata for account provisioning
├── terraform-modules/        # Reusable infrastructure modules
│   ├── vpc/
│   ├── eks/
│   ├── iam/
│   ├── monitoring/
│   └── security/
├── global-customizations/    # Customizations applied to all accounts
├── account-customizations/   # Environment-specific configurations
│   ├── dev/
│   ├── qa/
│   └── prod/
└── aft-configuration/       # AFT core configuration
```

## Prerequisites

1. AWS Control Tower setup with:
   - Management account
   - Audit account
   - Log archive account
2. AWS CLI configured with appropriate credentials
3. Terraform >= 1.0.0
4. Git for version control

## Implementation Components

1. **Account Factory for Terraform (AFT)**
   - Automated account provisioning
   - Integration with AWS Control Tower
   - CI/CD pipeline configuration

2. **Core Infrastructure Modules**
   - VPC with proper networking
   - EKS clusters
   - IAM roles and policies
   - CloudWatch monitoring
   - GuardDuty security
   - AWS Config Rules

3. **Governance and Security**
   - Service Control Policies (SCPs)
   - Centralized logging
   - Audit controls
   - GuardDuty integration
   - AWS Config Rules

4. **Shared Services**
   - Centralized logging
   - Security monitoring
   - Cross-account access management
   - Parameter Store integration
   - Secrets Manager configuration

## Getting Started

1. Clone this repository
2. Configure AWS credentials
3. Initialize AFT using the provided scripts
4. Submit account requests using the JSON templates
5. Monitor account provisioning through AWS CodePipeline

## Usage

### Account Provisioning

1. Create a new account request in `account-request/` directory
2. Commit and push changes to trigger the AFT pipeline
3. Monitor the account creation process in AWS CodePipeline

### Customizing Accounts

1. Add account-specific configurations in `account-customizations/`
2. Define global customizations in `global-customizations/`
3. Utilize reusable modules from `terraform-modules/`

## Security Features

- Centralized logging and monitoring
- GuardDuty enabled across all accounts
- AWS Config Rules for compliance
- Service Control Policies for governance
- Secure parameter and secret management

## Maintenance and Updates

- Regular updates to modules and customizations
- Compliance monitoring and reporting
- Security patch management
- Backup and disaster recovery procedures

## Contributing

1. Fork the repository
2. Create a feature branch
3. Submit a pull request with detailed description

## License

This project is licensed under the MIT License - see the LICENSE file for details. 