variable "aws_region" {
  type        = string
  description = "Target AWS region for deployment"
  default     = "us-east-1"
}

variable "instance_type" {
  type        = string
  description = "Size of the EC2 instances for the Drupal nodes"
  default     = "t3.micro" # Recommended to prevent out-of-memory bottlenecks during Drupal setups
}

variable "db_username" {
  type        = string
  description = "Master username for the managed MySQL database"
  default     = "drupal_admin"
}

variable "db_password" {
  type        = string
  description = "Master password for the managed MySQL database"
  sensitive   = true
  default     = "change to your preffered"
}