output "load_balancer_dns" {
  value       = aws_lb.drupal_alb.dns_name
  description = "The public URL of the Application Load Balancer to access Drupal"
}

 output "rds_endpoint" {
   value       = aws_db_instance.mysql_db.address
   description = "The hostname for the MySQL database. The port is configured separately in Ansible."
 }

 output "rds_port" {
   value       = aws_db_instance.mysql_db.port
   description = "The MySQL database port"
 }

# Since the servers are in private subnets,output their IDs or IPs
output "drupal_node_ips" {
  value       = aws_instance.drupal_server[*].private_ip
  description = "The private IP addresses of the Drupal app nodes"
}

output "drupal_node_public_ips" {
  value       = aws_instance.drupal_server[*].public_ip
  description = "Public IPs for Ansible configuration access"
}
