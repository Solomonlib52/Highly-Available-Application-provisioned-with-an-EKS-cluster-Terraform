# Disabled for Terraform destroy.
# These database resources were wired to EKS data sources. If the EKS cluster is
# gone, active references to those data sources can block destroy planning.

# # 1. Security Group for the Database (Private isolation)
# resource "aws_security_group" "db_sg" {
#   name        = "drupal-db-sg-eks"
#   description = "Allow MySQL traffic from EKS Fargate pods"
#   vpc_id      = data.aws_eks_cluster.drupal_app.vpc_config[0].vpc_id

#   ingress {
#     description     = "MySQL access from EKS Fargate pods"
#     from_port       = 3306
#     to_port         = 3306
#     protocol        = "tcp"
#     security_groups = [data.aws_eks_cluster.drupal_app.vpc_config[0].cluster_security_group_id]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   lifecycle {
#     create_before_destroy = true
#   }

#   tags = { Name = "drupal-db-sg-eks" }
# }

# # 2. Managed MySQL Database Instance
# resource "aws_db_instance" "mysql_db" {
#   allocated_storage         = 20
#   max_allocated_storage     = 50
#   engine                    = "mysql"
#   engine_version            = "8.0"
#   instance_class            = "db.t3.micro" # Free-tier eligible database tier
#   availability_zone         = "us-east-1a"
#   db_name                   = "drupaldb"
#   username                  = var.db_username
#   password                  = var.db_password
#   db_subnet_group_name      = aws_db_subnet_group.db_subnet_group.name
#   vpc_security_group_ids    = [aws_security_group.db_sg.id]
#   skip_final_snapshot       = false
#   final_snapshot_identifier = "bincom-drupal-final-snapshot-20260626"
#   tags                      = { Name = "bincom-drupal-rds" }
# }
