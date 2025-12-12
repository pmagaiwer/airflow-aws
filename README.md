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

## 🐳 Minikube - Local Kubernetes Development

Minikube is a tool that makes it easy to run Kubernetes locally. It's perfect for development, testing, and learning Kubernetes without needing cloud resources.

### 📦 Installation

Minikube is already installed in this environment. If you need to install it elsewhere:

#### Windows (Chocolatey)
```bash
choco install minikube -y
```

#### Manual Installation (Cross-platform)
```bash
# Download latest version
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-windows-amd64.exe

# Move to PATH
mkdir -p ~/bin
mv minikube-windows-amd64.exe ~/bin/minikube.exe
chmod +x ~/bin/minikube.exe

# Add to PATH (add to ~/.bashrc)
export PATH="$HOME/bin:$PATH"
```

### 🚀 Basic Usage

```bash
# Start cluster (first time takes longer)
minikube start

# Check status
minikube status

# Get cluster info
kubectl cluster-info

# Access dashboard
minikube dashboard

# Stop cluster
minikube stop

# Delete cluster
minikube delete

# View logs
minikube logs
```

### 🛠️ Drivers Available on Windows

Minikube supports multiple drivers for running the Kubernetes cluster:

#### 1. **Docker Driver** (Recommended)
```bash
minikube start --driver=docker
```
- **Requirements**: Docker Desktop installed and running
- **Pros**: Fast startup, integrated with Docker
- **Cons**: Requires Docker Desktop
- **Best for**: Development with container workflows

#### 2. **Hyper-V Driver**
```bash
minikube start --driver=hyperv
```
- **Requirements**: Windows 10/11 Pro/Enterprise, Hyper-V enabled
- **Pros**: Native Windows virtualization, good performance
- **Cons**: Requires admin privileges, Hyper-V conflicts with VirtualBox/VMware
- **Best for**: Production-like local testing

#### 3. **VirtualBox Driver**
```bash
minikube start --driver=virtualbox
```
- **Requirements**: VirtualBox installed
- **Pros**: Cross-platform compatibility, no admin rights needed
- **Cons**: Slower than Hyper-V, additional software required
- **Best for**: Compatibility testing

#### 4. **WSL2 Driver** (Experimental)
```bash
minikube start --driver=wsl2
```
- **Requirements**: WSL2 enabled, Ubuntu distribution
- **Pros**: Native Linux experience on Windows
- **Cons**: Experimental, may have stability issues
- **Best for**: Linux-native development

### ⚙️ Configuration Options

```bash
# Specify resources
minikube start --cpus=4 --memory=8192 --disk-size=50g

# Use specific Kubernetes version
minikube start --kubernetes-version=v1.28.0

# Enable addons
minikube start --addons=ingress,dashboard,metrics-server

# Use specific driver
minikube start --driver=docker --container-runtime=containerd

# Start with custom profile
minikube start -p my-profile
```

### 🔧 Troubleshooting

#### Common Issues:

**"minikube start" hangs or fails:**
```bash
# Check driver status
minikube start --alsologtostderr -v=7

# Clean start
minikube delete --all
minikube start
```

**Hyper-V issues:**
```bash
# Enable Hyper-V (as Administrator)
dism.exe /Online /Enable-Feature:Microsoft-Hyper-V /All

# Check Hyper-V status
Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All
```

**Docker driver issues:**
```bash
# Ensure Docker Desktop is running
docker version

# Restart Docker service
minikube stop
minikube start --driver=docker
```

**Port conflicts:**
```bash
# Use different ports
minikube start --apiserver-port=8444 --apiserver-name=minikube2
```

### 📊 Managing Multiple Clusters

```bash
# Create multiple profiles
minikube start -p cluster1 --driver=docker
minikube start -p cluster2 --driver=hyperv

# Switch between clusters
kubectl config use-context cluster1
kubectl config use-context cluster2

# List all clusters
minikube profile list

# Delete specific profile
minikube delete -p cluster1
```

### 🔗 Integration with Tools

#### kubectl Integration:
```bash
# Minikube automatically configures kubectl
kubectl get nodes
kubectl get pods -A

# Use specific profile
kubectl config use-context minikube
```

#### Docker Integration:
```bash
# Use Minikube's Docker daemon
eval $(minikube docker-env)

# Build images directly in Minikube
docker build -t my-app .
```

#### Helm Integration:
```bash
# Install Helm
minikube addons enable helm-tiller

# Or install Helm separately and use with Minikube
helm repo add stable https://charts.helm.sh/stable
helm install my-release stable/mysql
```

### 💡 Best Practices

1. **Resource Allocation**: Start with minimal resources and increase as needed
2. **Regular Cleanup**: Use `minikube delete` when not in use to free resources
3. **Version Pinning**: Specify Kubernetes versions for reproducible environments
4. **Profile Usage**: Use profiles for different projects/environments
5. **Addon Management**: Only enable necessary addons to reduce resource usage

### 📚 Additional Resources

- [Minikube Documentation](https://minikube.sigs.k8s.io/docs/)
- [Kubernetes Basics](https://kubernetes.io/docs/tutorials/kubernetes-basics/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [Helm Documentation](https://helm.sh/docs/)

---
