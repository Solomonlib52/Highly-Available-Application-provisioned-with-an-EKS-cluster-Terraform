# 1. Fetch the latest official Ubuntu 24.04 LTS AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

# 2. Generate a secure cryptographic Private Key
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# 3. Register the key pair with AWS
resource "aws_key_pair" "drupal_key" {
  key_name   = "bincom-drupal-key"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

# 4. Save the Private Key locally for Ansible to access
resource "local_sensitive_file" "private_key_pem" {
  content  = tls_private_key.ssh_key.private_key_pem
  filename = "${path.module}/../keys/drupal-ssh-key.pem"
}

# =========================================================================
# SECURITY GROUPS
# =========================================================================

# 5. Security Group for the Load Balancer (Publicly accessible)
resource "aws_security_group" "alb_sg" {
  name        = "drupal-alb-sg"
  description = "Allow public HTTP traffic to the load balancer"
  vpc_id      = aws_vpc.drupal_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "drupal-alb-sg" }
}

# 6. Security Group for Drupal Application Servers (Private)
resource "aws_security_group" "app_sg" {
  name        = "drupal-app-sg"
  description = "Allow traffic from ALB and SSH for provisioning"
  vpc_id      = aws_vpc.drupal_vpc.id

  # Inbound HTTP strictly from the Application Load Balancer
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  # SSH Access for Ansible (In real production, this would go through a bastion or VPN)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "drupal-app-sg" }
}

# =========================================================================
# APPLICATION LOAD BALANCER
# =========================================================================

# 7. Create the ALB
resource "aws_lb" "drupal_alb" {
  name               = "bincom-drupal-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]

  tags = { Name = "bincom-drupal-alb" }
}

# 8. Create Target Group (Where the ALB sends traffic)
resource "aws_lb_target_group" "drupal_tg" {
  name     = "drupal-app-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.drupal_vpc.id

  health_check {
    path                = "/core/misc/drupal.js"
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
}

# 9. Create ALB Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.drupal_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.drupal_tg.arn
  }
}

# =========================================================================
# EC2 VIRTUAL MACHINES (DYNAMIC DEPLOYMENT)
# =========================================================================

# 10. Provision 2 Drupal instances spread across your private subnets
resource "aws_instance" "drupal_server" {
  count                  = 2
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.drupal_key.key_name
  vpc_security_group_ids = [aws_security_group.app_sg.id]

  # This pattern dynamically maps server 0 to subnet 1, and server 1 to subnet 2
  subnet_id = count.index == 0 ? aws_subnet.private_app_1.id : aws_subnet.private_app_2.id

  tags = {
    Name = "bincom-drupal-node-${count.index + 1}"
  }
}

# 11. Attach the instances to the ALB target group
resource "aws_lb_target_group_attachment" "drupal_attachment" {
  count            = 2
  target_group_arn = aws_lb_target_group.drupal_tg.arn
  target_id        = aws_instance.drupal_server[count.index].id
  port             = 80
}
