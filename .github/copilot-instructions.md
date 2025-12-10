# Airflow on AWS EKS - AI Copilot Instructions

## Architecture Overview

This project deploys **Apache Airflow** on **AWS EKS with Fargate** using Terraform and Helm. The architecture spans three layers:

1. **Infrastructure (Terraform)**: Provisions VPC, EKS cluster, and IAM roles
2. **Kubernetes/Helm**: Deploys Airflow components (webserver, scheduler, PostgreSQL) via the Apache Airflow Helm chart
3. **Configuration**: Values managed in `terraform/helm-values/airflow-values.yaml`

### Key Architecture Decisions

- **LocalExecutor**: Uses single-node execution (no workers) for minimal cost; scale to CeleryExecutor for distributed DAGs
- **EKS Fargate**: Serverless Kubernetes (no node management), reduces operational overhead
- **In-cluster PostgreSQL**: For PoC/dev only; use managed RDS for production
- **LoadBalancer Service**: Exposes Airflow Web UI externally; disable for internal-only setups

### Service Boundaries

| Component | Purpose | Managed By | Notes |
|-----------|---------|-----------|-------|
| VPC + Subnets | Network isolation | `terraform/main.tf` (vpc module) | Auto-discovers AZs; configurable CIDR |
| EKS Cluster | Kubernetes control plane | `terraform/main.tf` (aws_eks_cluster) | Version: 1.28 (configurable) |
| Fargate Profile | Pod compute layer | `terraform/main.tf` (aws_eks_fargate_profile) | Limited to `airflow` namespace |
| Airflow Helm Release | DAG orchestration | `terraform/main.tf` (helm_release) | Bitnami/Apache chart, v1.11.0 |
| PostgreSQL | Metadata DB | Helm chart dependency | In-cluster; credentials in `airflow-values.yaml` |

## Critical Workflows & Commands

### Terraform Operations

```bash
# Initialize Terraform (required once)
terraform init

# Plan changes (always review before apply)
terraform plan -out=tfplan

# Apply infrastructure
terraform apply tfplan

# Destroy all resources (careful!)
terraform destroy
```

### Accessing Airflow After Deployment

```bash
# Configure kubectl to access the cluster
aws eks update-kubeconfig --region us-east-1 --name pmagaiwer-airflow

# Get Airflow Web UI URL (if LoadBalancer enabled)
kubectl get svc -n airflow airflow-webserver

# Port-forward if using ClusterIP (instead of LoadBalancer)
kubectl port-forward -n airflow svc/airflow-webserver 8080:8080

# Access Airflow logs
kubectl logs -n airflow -l app=airflow-webserver
kubectl logs -n airflow -l app=airflow-scheduler
```

### Configuration Changes

- **Helm Values**: Edit `terraform/helm-values/airflow-values.yaml`, then `terraform apply`
- **Infrastructure**: Modify variables in `terraform/variables.tf` or use `.tfvars` files
- **Scaling**: Adjust `airflow_webserver_replicas`, `airflow_scheduler_replicas` in variables; set `airflow_worker_replicas > 0` to enable workers

## Project-Specific Patterns & Conventions

### Terraform Structure

- **Data Sources** (top): AWS availability zones auto-discovery
- **Modules** (vpc): Terraform AWS modules for standardization
- **Resources** (EKS, IAM, K8s, Helm): Explicit resource definitions with minimal abstractions
- **RBAC**: Service accounts and cluster roles defined for Airflow worker pod execution
- **Random Secrets**: `random_string` generates Airflow webserver secret key

### Naming Convention

- EKS Cluster: `{cluster_name}-eks` (default: `pmagaiwer-airflow`)
- VPC: `{cluster_name}-vpc`
- Fargate Profile: `{cluster_name}-airflow`
- Kubernetes Namespace: Variable `airflow_namespace` (default: `airflow`)
- Helm Release: Variable `airflow_release_name` (default: `airflow`)

### Sensitive Data Handling

- Admin credentials (`airflow_admin_user`, `airflow_admin_password`) marked as `sensitive = true`
- Webserver secret key generated via `random_string` and passed via `set_sensitive` in Helm
- **Note**: In-cluster PostgreSQL uses hardcoded credentials (`airflow:airflow`) – use SecretsManager for production

## Integration Points & Dependencies

### External Dependencies

- **Helm Repository**: `https://airflow.apache.org` (Apache Airflow official chart)
- **Terraform Providers**: AWS (~5.0), Kubernetes (~2.0), Helm (~2.0)
- **AWS Services**: EKS, VPC, EC2, IAM, Fargate

### Cross-Component Communication

1. **Terraform → Kubernetes**: Uses `kubernetes` provider authenticated via EKS cluster endpoint
2. **Terraform → Helm**: Helm provider reads kubeconfig from EKS cluster
3. **Airflow → PostgreSQL**: Via connection string in `AIRFLOW__CORE__SQL_ALCHEMY_CONN` env var (default: `postgresql://airflow:airflow@postgresql:5432/airflow`)
4. **Airflow DAGs**: Stored in `/opt/airflow/dags` (mounted volume in container)

### Output Usage

Key Terraform outputs for debugging/access:
- `eks_cluster_endpoint`: Kubernetes API endpoint
- `kubeconfig_command`: Setup kubectl access
- `airflow_webserver_loadbalancer_dns`: Public URL for Web UI
- `port_forward_command`: Alternative access if LoadBalancer disabled

## Common Modifications & Patterns

### Enable CeleryExecutor (Distributed DAGs)

1. Set `airflow_worker_replicas > 0` in variables
2. Update `airflow-values.yaml`: Change `executor: LocalExecutor` → `executor: CeleryExecutor`
3. Enable Redis: Set `redis.enabled: true` in Helm values
4. Increase resource limits for workers/scheduler

### Use RDS Instead of In-Cluster PostgreSQL

1. Create RDS instance (separate Terraform module or manual)
2. Disable in-cluster PostgreSQL: `postgresql.enabled: false` in `airflow-values.yaml`
3. Update `AIRFLOW__CORE__SQL_ALCHEMY_CONN` to RDS endpoint
4. Add security group rules to allow EKS pods → RDS

### Scale Webserver/Scheduler

Modify in `terraform/variables.tf`:
```terraform
airflow_webserver_replicas = 2  # Enable autoscaling with replicas > 1
airflow_scheduler_replicas = 1  # Typically 1, but can scale for HA
```

## Files to Know

| File | Purpose | Edit When |
|------|---------|-----------|
| `terraform/main.tf` | VPC, EKS, Fargate, RBAC, Helm release | Infrastructure changes |
| `terraform/variables.tf` | All configurable parameters | Cluster size, versions, environment |
| `terraform/providers.tf` | Provider configs & version constraints | Provider version updates, S3 backend setup |
| `terraform/helm-values/airflow-values.yaml` | Airflow Helm chart values | Component replicas, resources, executor type |
| `terraform/outputs.tf` | Cluster access info, kubectl commands | Adding new outputs for debugging |

## Troubleshooting Tips

- **Pods stuck "Pending"**: Check Fargate profile selector matches namespace; Fargate has limited resource availability
- **Airflow pods crashing**: Check logs (`kubectl logs -n airflow <pod-name>`); verify PostgreSQL connection string
- **Terraform drift**: Run `terraform plan` to detect manual AWS/K8s changes
- **LoadBalancer stuck "Pending"**: Fargate limitation; use `port-forward` or enable ALB Ingress controller

