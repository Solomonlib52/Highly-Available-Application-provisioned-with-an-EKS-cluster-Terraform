# Disabled for Terraform destroy.
# These resources depend on an EKS Fargate execution role that may already be
# removed outside this Terraform stack, which can block destroy operations.

# data "aws_caller_identity" "current" {}

# data "aws_iam_role" "fargate_pod_execution_role" {
#   name = "eksctl-drupal-app-cluster-FargatePodExecutionRole-fLHeuVF7Zt8C"
# }

# resource "aws_cloudwatch_log_group" "drupal_fargate" {
#   name              = "/aws/eks/drupal-app/fargate/drupal"
#   retention_in_days = 30

#   tags = {
#     Name = "drupal-fargate-logs"
#   }
# }

# resource "aws_iam_policy" "fargate_cloudwatch_logging" {
#   name        = "drupal-fargate-cloudwatch-logging"
#   description = "Allow EKS Fargate pods to publish application logs to CloudWatch Logs"

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Action = [
#           "logs:CreateLogStream",
#           "logs:DescribeLogStreams",
#           "logs:PutLogEvents"
#         ]
#         Resource = "${aws_cloudwatch_log_group.drupal_fargate.arn}:*"
#       },
#       {
#         Effect = "Allow"
#         Action = [
#           "logs:DescribeLogGroups"
#         ]
#         Resource = "*"
#       }
#     ]
#   })
# }

# resource "aws_iam_role_policy_attachment" "fargate_cloudwatch_logging" {
#   role       = data.aws_iam_role.fargate_pod_execution_role.name
#   policy_arn = aws_iam_policy.fargate_cloudwatch_logging.arn
# }
