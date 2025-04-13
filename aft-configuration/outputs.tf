output "pipeline_arn" {
  description = "ARN of the AFT CodePipeline"
  value       = module.aft_pipeline.pipeline_arn
}

output "codebuild_project_arn" {
  description = "ARN of the AFT CodeBuild project"
  value       = module.aft_pipeline.codebuild_project_arn
}

output "artifacts_bucket_name" {
  description = "Name of the S3 bucket for pipeline artifacts"
  value       = module.aft_pipeline.artifacts_bucket_name
}

output "artifacts_bucket_arn" {
  description = "ARN of the S3 bucket for pipeline artifacts"
  value       = module.aft_pipeline.artifacts_bucket_arn
}

output "pipeline_role_arn" {
  description = "ARN of the IAM role for CodePipeline"
  value       = aws_iam_role.aft_pipeline.arn
}

output "codebuild_role_arn" {
  description = "ARN of the IAM role for CodeBuild"
  value       = aws_iam_role.aft_codebuild.arn
}

output "codepipeline_role_arn" {
  description = "ARN of the IAM role for CodePipeline"
  value       = aws_iam_role.aft_codepipeline.arn
}

output "aft_management_account_id" {
  description = "ID of the AFT management account"
  value       = var.aft_management_account_id
}

output "ct_management_account_id" {
  description = "ID of the Control Tower management account"
  value       = var.ct_management_account_id
}

output "log_archive_account_id" {
  description = "ID of the Log Archive account"
  value       = var.log_archive_account_id
}

output "audit_account_id" {
  description = "ID of the Audit account"
  value       = var.audit_account_id
} 