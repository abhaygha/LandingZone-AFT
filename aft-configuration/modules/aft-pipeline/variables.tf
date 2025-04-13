variable "codebuild_role" {
  description = "ARN of the IAM role for CodeBuild"
  type        = string
}

variable "pipeline_role" {
  description = "ARN of the IAM role for CodePipeline"
  type        = string
}

variable "bulk_request_file" {
  description = "Name of the bulk account request file in S3"
  type        = string
  default     = "bulk-account-requests.json"
}

variable "artifacts_bucket" {
  description = "Name of the S3 bucket for pipeline artifacts"
  type        = string
} 