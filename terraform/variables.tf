variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "pwndoc-ng"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.small"
}

variable "ssh_key_name" {
  description = "Name of an existing EC2 key pair for SSH access"
  type        = string
}

variable "ssh_allowed_cidr" {
  description = "CIDR block allowed to SSH into the instance"
  type        = string
  default     = "0.0.0.0/0"
}

variable "domain_name" {
  description = "Domain name for the application (optional, used for Route 53)"
  type        = string
  default     = ""
}

variable "route53_zone_id" {
  description = "Route 53 hosted zone ID (required if domain_name is set)"
  type        = string
  default     = ""
}

variable "ebs_volume_size" {
  description = "Size of the EBS volume for MongoDB data (GB)"
  type        = number
  default     = 20
}

variable "mongo_root_password" {
  description = "MongoDB root password"
  type        = string
  sensitive   = true
}

variable "mongo_app_password" {
  description = "MongoDB application user password"
  type        = string
  sensitive   = true
}

variable "jwt_secret" {
  description = "JWT secret for token signing"
  type        = string
  sensitive   = true
}

variable "jwt_refresh_secret" {
  description = "JWT refresh secret for refresh token signing"
  type        = string
  sensitive   = true
}

variable "git_repo_url" {
  description = "Git repository URL to clone"
  type        = string
  default     = "https://github.com/pwndoc-ng/pwndoc-ng.git"
}

variable "git_branch" {
  description = "Git branch to deploy"
  type        = string
  default     = "main"
}

variable "environment" {
  description = "Deployment environment (e.g. prod, staging, dev)"
  type        = string
  default     = "prod"
}
