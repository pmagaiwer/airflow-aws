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
