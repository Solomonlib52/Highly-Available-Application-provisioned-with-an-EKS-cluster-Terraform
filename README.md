# High-Availability Drupal Infrastructure on AWS

This project provisions and configures a highly available Drupal environment on AWS using Terraform and Ansible. Terraform builds the cloud infrastructure, while Ansible installs and configures Drupal across multiple application servers.

The main infrastructure-as-code files are in [`terraform/`](terraform/), and the configuration management files are in [`ansible/`](ansible/).

## Architecture Overview

The deployment includes:

- A custom AWS VPC spanning at least two availability zones.
- Public subnets for the Application Load Balancer.
- Application subnets for two Drupal EC2 instances.
- Database subnets for the managed MySQL database layer.
- An AWS Application Load Balancer to distribute HTTP traffic.
- Two Ubuntu-based EC2 virtual machines for Drupal application servers.
- An Amazon RDS MySQL database for Drupal data.
- Security groups for controlled access between the load balancer, app servers, and database.
- Ansible-based Drupal provisioning, Apache/PHP setup, database configuration, and file synchronization.

## Repository Layout

```text
.
├── terraform/
│   ├── providers.tf       # Terraform and AWS provider configuration
│   ├── variables.tf       # Region, instance type, and database variables
│   ├── vpc.tf             # VPC, subnets, route tables, NAT gateway, DB subnet group
│   ├── main.tf            # EC2 instances, ALB, target group, listeners, security groups
│   ├── database.tf        # RDS MySQL instance and database security group
│   ├── eks-data.tf        # EKS data lookups used by the later Kubernetes work
│   ├── output.tf          # ALB DNS, RDS endpoint, and app server IP outputs
│   └── logging.tf         # EKS/Fargate logging work; not part of the EC2 Drupal stack
├── ansible/
│   ├── playbook.yml       # Drupal, Apache, PHP, settings.php, and rsync setup
│   ├── inventory.ini      # Generated Ansible inventory for Drupal EC2 nodes
│   ├── generate_from_terraform.sh
│   ├── group_vars/all.yml # Generated database and load balancer values
│   ├── host_vars/         # Generated peer IPs for rsync
│   └── templates/
│       └── settings.php.j2
├── keys/
│   └── drupal-ssh-key.pem # Generated SSH private key for Ansible access
└── kubernetes/            # Separate containerized Drupal/EKS manifests
```

## Terraform Infrastructure

Terraform is located in:

```text
terraform/
```

The Terraform configuration provisions the AWS infrastructure required for the Drupal stack.

### Networking

Defined mainly in [`terraform/vpc.tf`](terraform/vpc.tf):

- VPC: `10.0.0.0/16`
- Public subnet in `us-east-1a`
- Public subnet in `us-east-1b`
- Application subnet in `us-east-1a`
- Application subnet in `us-east-1b`
- Database subnet resources
- Internet Gateway
- NAT Gateway
- Route tables and route table associations
- Database subnet group

### Compute

Defined in [`terraform/main.tf`](terraform/main.tf):

- Two Ubuntu 24.04 EC2 instances.
- Instances are distributed across two availability zones.
- SSH key pair is generated with Terraform.
- Private key is written to:

```text
keys/drupal-ssh-key.pem
```

### Load Balancing

Defined in [`terraform/main.tf`](terraform/main.tf):

- AWS Application Load Balancer.
- Target group for the Drupal EC2 instances.
- HTTP listener on port `80`.
- Health check path:

```text
/core/misc/drupal.js
```

### Security Groups

Defined in [`terraform/main.tf`](terraform/main.tf) and [`terraform/database.tf`](terraform/database.tf):

- ALB security group allows public HTTP traffic on port `80`.
- Drupal app security group allows HTTP traffic from the ALB.
- Drupal app security group allows SSH for Ansible provisioning.
- Database security group allows MySQL traffic on port `3306` from the application environment.

### Managed Database

Defined in [`terraform/database.tf`](terraform/database.tf):

- Amazon RDS MySQL.
- Engine: MySQL 8.0.
- Instance class: `db.t3.micro`.
- Database name: `drupaldb`.
- Final snapshot is enabled before deletion.

## Ansible Configuration

Ansible files are located in:

```text
ansible/
```

The main playbook is:

```text
ansible/playbook.yml
```

The playbook configures each Drupal application server by:

- Creating swap space for small EC2 instances.
- Updating apt packages.
- Installing Apache.
- Installing PHP 8.3 and Drupal PHP extensions.
- Installing required tools such as `curl`, `git`, `unzip`, and `rsync`.
- Enabling Apache rewrite support.
- Configuring Apache virtual host settings.
- Downloading Drupal core.
- Extracting Drupal into `/var/www/html`.
- Creating the Drupal files directory.
- Applying Apache ownership and permissions.
- Rendering `settings.php` from [`ansible/templates/settings.php.j2`](ansible/templates/settings.php.j2).
- Configuring Drupal database connection values from Ansible variables.
- Creating a cron-based `rsync` job for cross-server file synchronization.

## Dynamic Inventory and Variables

After Terraform creates the infrastructure, this script pulls Terraform outputs and generates Ansible files:

```bash
./ansible/generate_from_terraform.sh
```

It creates or updates:

```text
ansible/inventory.ini
ansible/group_vars/all.yml
ansible/host_vars/drupal_node_1.yml
ansible/host_vars/drupal_node_2.yml
```

Terraform outputs used by Ansible include:

- Load balancer DNS name.
- RDS endpoint.
- RDS port.
- Drupal node public IPs.
- Drupal node private IPs.

The private IPs are used to configure peer-to-peer `rsync` between Drupal application servers.

## Deployment Steps

### 1. Configure AWS credentials

Make sure AWS credentials are available in your shell:

```bash
aws configure
```

Or export credentials using your preferred AWS authentication method.

### 2. Provision infrastructure

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### 3. Generate Ansible inventory from Terraform

From the project root:

```bash
./ansible/generate_from_terraform.sh
```

Review the generated files before running the playbook, especially:

```text
ansible/inventory.ini
ansible/group_vars/all.yml
ansible/host_vars/
```

### 4. Run Ansible provisioning

```bash
cd ansible
ansible-playbook -i inventory.ini playbook.yml
```

### 5. Access Drupal

Get the load balancer DNS from Terraform:

```bash
cd terraform
terraform output load_balancer_dns
```

Open the ALB DNS name in a browser and complete the Drupal installation flow.

## File Synchronization

The playbook configures file synchronization using `rsync`.

Each Drupal server receives a cron job that syncs:

```text
/var/www/html/sites/default/files/
```

to the peer Drupal server. The peer IP is generated from Terraform private IP outputs and written into each host file under:

```text
ansible/host_vars/
```

This keeps uploaded Drupal files synchronized between the two application servers.

## Teardown

To destroy the Terraform-managed infrastructure:

```bash
cd terraform
terraform destroy
```

Because the RDS configuration uses a final snapshot, database deletion may create a final snapshot before the instance is removed.

## Notes

- [`terraform/logging.tf`](terraform/logging.tf) relates to the later EKS/Fargate logging setup and is not part of the EC2-based Drupal infrastructure described above.
- [`kubernetes/`](kubernetes/) contains separate Kubernetes/EKS manifests for a containerized version of the Drupal application.
- `terraform.tfstate`, generated Ansible variables, and private keys can contain sensitive values. They should not be committed to a public repository.
- The current Ansible inventory and group variables are generated files and may contain environment-specific IP addresses, database endpoints, and credentials.
