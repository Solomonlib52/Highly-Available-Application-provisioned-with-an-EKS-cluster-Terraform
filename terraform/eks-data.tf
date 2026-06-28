# Disabled for Terraform destroy.
# These data sources depend on the EKS cluster being available. If the cluster
# has already been removed, Terraform can fail before it reaches destroy.

#data "aws_eks_cluster" "drupal_app" {
#  name = "drupal-app"
#}

#data "aws_subnets" "eks_private" {
#  filter {
#    name   = "vpc-id"
#    values = [data.aws_eks_cluster.drupal_app.vpc_config[0].vpc_id]
#  }

#  tags = {
#    Name = "*Private*"
#  }
#}
