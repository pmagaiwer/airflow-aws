# Airflow on AWS EKS - Minimal Deployment

This repository contains Terraform and Helm configurations to deploy Apache Airflow on Amazon EKS (Elastic Kubernetes Service) with minimal resources for development and proof-of-concept environments.

## 📋 What's Included

- **EKS Cluster** with Fargate compute (serverless Kubernetes) for cost efficiency
- **Apache Airflow** deployed via Helm chart with:
  - LocalExecutor (single-machine task execution)
  - In-cluster PostgreSQL for metadata database
  - Minimal webserver and scheduler replicas
  - Public LoadBalancer for Web UI access
- **VPC** with public and private subnets across multiple AZs
- **IAM roles and policies** for secure cluster access
- **Makefile** for easy deployment and management
- **Helper scripts** for setup and cleanup

## 🎯 Architecture

```
┌─────────────────────────────────────┐
│        AWS Account (us-east-1)      │
├─────────────────────────────────────┤
│  VPC (10.0.0.0/16)                  │
│  ├─ Public Subnets (x3)             │
│  │  └─ NAT Gateway                  │
│  └─ Private Subnets (x3)            │
│     └─ EKS Cluster                  │
│        ├─ Fargate Profile           │
│        └─ Airflow Namespace         │
│           ├─ Webserver Pod          │
│           ├─ Scheduler Pod          │
│           └─ PostgreSQL Pod         │
└─────────────────────────────────────┘
```

## 💰 Estimated Costs

| Component | Monthly Cost |
|-----------|-------------|
| EKS Control Plane | ~$73 |
| Fargate (with Airflow workload) | ~$5-15 |
| NAT Gateway | ~$32 |
| Data Transfer | ~$1-5 |
| **TOTAL** | **~$110-125** |

*Note: Prices are approximate and may vary by region and usage. Clean up resources when not in use.*

## 🚀 Quick Start

### Prerequisites

- AWS Account with credentials configured (`aws configure`)
- Terraform >= 1.0
- AWS CLI >= 2.0
- kubectl >= 1.24
- Helm >= 3.0

### Installation Steps

1. **Clone and Navigate**
   ```bash
   cd airflow-aws
   ```

2. **Run Setup Script**
   ```bash
   bash scripts/setup.sh
   ```
   This will:
   - Verify prerequisites
   - Initialize Terraform
   - Create `terraform.tfvars` from example
   - Validate configuration
   - Generate deployment plan

3. **Review the Plan**
   The script will display the Terraform plan. Review resources to be created.

4. **Deploy**
   ```bash
   make apply
   ```

5. **Configure kubectl**
   ```bash
   make kubeconfig
   ```

6. **Wait for Pods** (takes 5-10 minutes)
   ```bash
   kubectl get pods -n airflow -w
   ```

7. **Get Airflow URL**
   ```bash
   make get-lb-url
   ```
   Output will show the LoadBalancer DNS name. Open in browser: `http://<dns-name>:8080`

8. **Login to Airflow**
   - Default username: `admin`
   - Default password: `airflow` (change in production!)

## 📖 Usage

### Common Commands

```bash
# View all available commands
make help

# Initialize Terraform
make init

# Format Terraform files
make fmt

# Validate configuration
make validate

# Create deployment plan
make plan

# Apply deployment plan
make apply

# View deployed resources
make outputs

# Check Airflow pod status
make status

# View Airflow webserver logs
make logs

# Port-forward Web UI (if not using LoadBalancer)
make port-forward

# Get LoadBalancer URL
make get-lb-url

# Destroy all resources
make destroy
```

### Customization

Edit `terraform/terraform.tfvars` to customize:
- AWS region
- Cluster name
- VPC CIDR
- Airflow replicas
- Admin credentials
- Tags

Edit `terraform/helm-values/airflow-values.yaml` to customize:
- Airflow configuration
- Pod resource limits
- Persistence settings
- Service type (LoadBalancer vs ClusterIP)

## 🔧 Configuration Details

### Terraform Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `aws_region` | `us-east-1` | AWS region |
| `cluster_name` | `pmagaiwer-airflow` | EKS cluster name |
| `cluster_version` | `1.28` | Kubernetes version |
| `vpc_cidr` | `10.0.0.0/16` | VPC CIDR block |
| `airflow_webserver_replicas` | `1` | Webserver pod replicas |
| `airflow_scheduler_replicas` | `1` | Scheduler pod replicas |
| `airflow_worker_replicas` | `0` | Worker replicas (LocalExecutor) |
| `expose_via_loadbalancer` | `true` | Use LoadBalancer for Web UI |

### Airflow Configuration

- **Executor**: LocalExecutor (single-machine, suitable for development)
- **Database**: PostgreSQL 15 (in-cluster, no external RDS)
- **Web UI**: Accessible via LoadBalancer or `kubectl port-forward`
- **DAGs**: Store in Kubernetes PVC or S3 (update config)

## 🔒 Security Notes

⚠️ **Development Only**: This setup is suitable for development and PoC. For production:

- Change default admin credentials immediately
- Use RDS for PostgreSQL (external database)
- Enable VPC flow logs and EKS audit logging
- Restrict security groups and ingress rules
- Use AWS Secrets Manager for sensitive data
- Enable EKS control plane logging
- Implement Pod Security Policies
- Set up RBAC roles properly
- Use private subnets only (no public access)
- Enable encryption at rest

## 📚 File Structure

```
airflow-aws/
├── Makefile                           # Convenience commands
├── README.md                          # This file
├── scripts/
│   ├── setup.sh                       # Initial setup script
│   ├── deploy.sh                      # Deployment confirmation script
│   └── cleanup.sh                     # Cleanup script
└── terraform/
    ├── providers.tf                   # Provider configurations
    ├── variables.tf                   # Input variables
    ├── main.tf                        # Main infrastructure code
    ├── outputs.tf                     # Output values
    ├── .gitignore                     # Git ignore rules
    ├── example.tfvars                 # Example variables file
    └── helm-values/
        └── airflow-values.yaml        # Helm chart values
```

## 🆘 Troubleshooting

### Pods not starting
```bash
# Check pod status
kubectl describe pod -n airflow <pod-name>

# View pod logs
kubectl logs -n airflow <pod-name>
```

### Terraform state issues
```bash
# Remove local state (careful!)
make clean
```

### LoadBalancer DNS not available
```bash
# Wait a moment and retry
make get-lb-url

# Or check service directly
kubectl get svc -n airflow airflow-webserver
```

### Delete PVC before re-applying
```bash
# If using Terraform destroy and re-apply
kubectl delete pvc -n airflow --all
```

## 📝 Next Steps

1. **Add DAGs**: 
   - Mount S3 bucket via DAG sync (modify Helm values)
   - Or create ConfigMap with DAG files

2. **Scale Up**:
   - Change executor to CeleryExecutor (add workers)
   - Use RDS instead of in-cluster PostgreSQL
   - Add Redis for Celery results backend

3. **Monitor**:
   - Enable CloudWatch integration
   - Set up Prometheus/Grafana
   - Configure Airflow alerting

4. **CI/CD**:
   - Add GitHub Actions for automated deployments
   - Integrate with GitOps (ArgoCD)

## 📧 Support

For issues or questions:
1. Check AWS CloudWatch logs
2. Review EKS cluster events
3. Check Kubernetes API server logs
4. Review Terraform state

## 📄 License

This project is part of the pmagaiwer DevOps labs. See parent project for license details.

## 🤝 Contributing

Contributions welcome! Please ensure:
- Terraform code is formatted (`terraform fmt`)
- Configuration is validated (`terraform validate`)
- Documentation is updated
- Cost implications are considered

---

