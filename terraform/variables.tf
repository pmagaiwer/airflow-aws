variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "pmagaiwer-airflow"
}

variable "cluster_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use single NAT Gateway for all private subnets (saves cost)"
  type        = bool
  default     = true
}

variable "airflow_namespace" {
  description = "Kubernetes namespace for Airflow"
  type        = string
  default     = "airflow"
}

variable "airflow_release_name" {
  description = "Helm release name for Airflow"
  type        = string
  default     = "airflow"
}

variable "airflow_chart_version" {
  description = "Airflow Helm chart version"
  type        = string
  default     = "1.11.0"
}

variable "airflow_webserver_replicas" {
  description = "Number of Airflow webserver replicas"
  type        = number
  default     = 1
}

variable "airflow_scheduler_replicas" {
  description = "Number of Airflow scheduler replicas"
  type        = number
  default     = 1
}

variable "airflow_worker_replicas" {
  description = "Number of Airflow worker replicas (LocalExecutor: 0)"
  type        = number
  default     = 0
}

variable "enable_alb_ingress" {
  description = "Enable ALB ingress for Airflow Web UI"
  type        = bool
  default     = false
}

variable "expose_via_loadbalancer" {
  description = "Expose Airflow Web UI via LoadBalancer service"
  type        = bool
  default     = true
}

variable "airflow_admin_user" {
  description = "Airflow admin username"
  type        = string
  default     = "admin"
  sensitive   = true
}

variable "airflow_admin_password" {
  description = "Airflow admin password"
  type        = string
  default     = "airflow"
  sensitive   = true
}

variable "airflow_admin_email" {
  description = "Airflow admin email"
  type        = string
  default     = "admin@airflow.local"
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default = {
    Project = "airflow-eks"
  }
}
