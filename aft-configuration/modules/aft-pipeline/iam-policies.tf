# CodePipeline Policy
resource "aws_iam_policy" "pipeline_policy" {
  name        = "aft-pipeline-policy"
  description = "Policy for AFT CodePipeline"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketVersioning",
          "s3:PutObject"
        ]
        Resource = [
          aws_s3_bucket.aft_artifacts.arn,
          "${aws_s3_bucket.aft_artifacts.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild"
        ]
        Resource = [aws_codebuild_project.aft_build.arn]
      },
      {
        Effect = "Allow"
        Action = [
          "cloudformation:CreateStack",
          "cloudformation:DeleteStack",
          "cloudformation:DescribeStacks",
          "cloudformation:UpdateStack",
          "cloudformation:CreateChangeSet",
          "cloudformation:ExecuteChangeSet",
          "cloudformation:DescribeChangeSet"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "organizations:CreateAccount",
          "organizations:DescribeCreateAccountStatus",
          "organizations:ListAccounts",
          "organizations:ListParents",
          "organizations:ListRoots"
        ]
        Resource = "*"
      }
    ]
  })
}

# CodeBuild Policy
resource "aws_iam_policy" "codebuild_policy" {
  name        = "aft-codebuild-policy"
  description = "Policy for AFT CodeBuild"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject"
        ]
        Resource = [
          aws_s3_bucket.aft_artifacts.arn,
          "${aws_s3_bucket.aft_artifacts.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "codebuild:CreateReportGroup",
          "codebuild:CreateReport",
          "codebuild:UpdateReport",
          "codebuild:BatchPutTestCases"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "sts:AssumeRole"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach policies to roles
resource "aws_iam_role_policy_attachment" "pipeline_policy" {
  role       = var.pipeline_role
  policy_arn = aws_iam_policy.pipeline_policy.arn
}

resource "aws_iam_role_policy_attachment" "codebuild_policy" {
  role       = var.codebuild_role
  policy_arn = aws_iam_policy.codebuild_policy.arn
} 