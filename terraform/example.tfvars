# Example Terraform Variables File
# Rename this to terraform.tfvars and customize values as needed

aws_region      = "us-east-1"
environment     = "dev"
cluster_name    = "pmagaiwer-airflow"
cluster_version = "1.28"
vpc_cidr        = "10.0.0.0/16"

# Networking
enable_nat_gateway = true
single_nat_gateway = true

# Airflow Configuration
airflow_namespace     = "airflow"
airflow_release_name  = "airflow"
airflow_chart_version = "1.11.0"

# Replicas (development/minimal)
airflow_webserver_replicas = 1
airflow_scheduler_replicas = 1
airflow_worker_replicas    = 0

# Exposure
expose_via_loadbalancer = true

# Admin credentials (CHANGE THESE IN PRODUCTION!)
airflow_admin_user     = "admin"
airflow_admin_password = "airflow"
airflow_admin_email    = "admin@airflow.local"

# Additional tags
tags = {
  Project     = "airflow-eks"
  Environment = "dev"
  Owner       = "pmagaiwer"
}
