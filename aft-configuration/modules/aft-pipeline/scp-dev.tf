resource "aws_organizations_policy" "dev_scp" {
  name        = "DevEnvironmentSCP"
  description = "Service Control Policy for Dev Environment"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyRootAccountUsage"
        Effect = "Deny"
        Action = [
          "iam:DeleteAccountPasswordPolicy",
          "iam:DeleteAccountAlias",
          "iam:DeleteAccount",
          "iam:CreateAccountAlias",
          "iam:UpdateAccountPasswordPolicy"
        ]
        Resource = "*"
        Condition = {
          StringLike = {
            "aws:PrincipalArn" = ["arn:aws:iam::*:root"]
          }
        }
      },
      {
        Sid    = "DenyLeavingOrganization"
        Effect = "Deny"
        Action = [
          "organizations:LeaveOrganization"
        ]
        Resource = "*"
      },
      {
        Sid    = "DenyDisablingSecurityServices"
        Effect = "Deny"
        Action = [
          "guardduty:DeleteDetector",
          "guardduty:DisassociateFromMasterAccount",
          "guardduty:DisassociateFromAdministratorAccount",
          "securityhub:DisableSecurityHub",
          "config:DeleteConfigurationRecorder",
          "config:DeleteDeliveryChannel",
          "config:StopConfigurationRecorder"
        ]
        Resource = "*"
      },
      {
        Sid    = "DenyModifyingVPCFlowLogs"
        Effect = "Deny"
        Action = [
          "ec2:DeleteFlowLogs",
          "logs:DeleteLogGroup",
          "logs:DeleteLogStream"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowDevServices"
        Effect = "Allow"
        Action = [
          "ec2:*",
          "s3:*",
          "lambda:*",
          "apigateway:*",
          "dynamodb:*",
          "cloudwatch:*",
          "logs:*",
          "iam:Get*",
          "iam:List*",
          "iam:PassRole",
          "iam:CreateRole",
          "iam:PutRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:DeleteRole",
          "sts:AssumeRole"
        ]
        Resource = "*"
      },
      {
        Sid    = "DenyProdServices"
        Effect = "Deny"
        Action = [
          "route53domains:*",
          "directconnect:*",
          "workspaces:*",
          "workspaces-web:*"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_organizations_policy_attachment" "dev_scp_attachment" {
  policy_id = aws_organizations_policy.dev_scp.id
  target_id = var.dev_ou_id  # This should be the ID of your Dev OU
} 