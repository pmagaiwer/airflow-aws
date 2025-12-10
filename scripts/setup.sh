#!/bin/bash
# setup.sh - Quick setup script for Airflow EKS deployment

set -e

TERRAFORM_DIR="terraform"
CLUSTER_NAME="pmagaiwer-airflow"
AWS_REGION="us-east-1"
NAMESPACE="airflow"

echo "=========================================="
echo "Airflow EKS Setup Script"
echo "=========================================="
echo ""

# Step 1: Check prerequisites
echo "[1/6] Checking prerequisites..."
command -v aws &> /dev/null || { echo "❌ AWS CLI not found. Please install it."; exit 1; }
command -v terraform &> /dev/null || { echo "❌ Terraform not found. Please install it."; exit 1; }
command -v kubectl &> /dev/null || { echo "❌ kubectl not found. Please install it."; exit 1; }
command -v helm &> /dev/null || { echo "❌ Helm not found. Please install it."; exit 1; }
echo "✅ All prerequisites installed"
echo ""

# Step 2: Verify AWS credentials
echo "[2/6] Verifying AWS credentials..."
aws sts get-caller-identity &> /dev/null || { echo "❌ AWS credentials not configured."; exit 1; }
AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
echo "✅ AWS account: $AWS_ACCOUNT"
echo ""

# Step 3: Copy example.tfvars if not exists
echo "[3/6] Setting up Terraform variables..."
if [ ! -f "$TERRAFORM_DIR/terraform.tfvars" ]; then
    cp "$TERRAFORM_DIR/example.tfvars" "$TERRAFORM_DIR/terraform.tfvars"
    echo "⚠️  Created terraform.tfvars from example. Please review and customize if needed."
else
    echo "✅ terraform.tfvars already exists"
fi
echo ""

# Step 4: Initialize Terraform
echo "[4/6] Initializing Terraform..."
cd "$TERRAFORM_DIR"
terraform init
cd ..
echo "✅ Terraform initialized"
echo ""

# Step 5: Validate Terraform
echo "[5/6] Validating Terraform configuration..."
cd "$TERRAFORM_DIR"
terraform validate
cd ..
echo "✅ Terraform configuration valid"
echo ""

# Step 6: Show plan
echo "[6/6] Generating Terraform plan..."
cd "$TERRAFORM_DIR"
terraform plan -var-file=terraform.tfvars -out=tfplan
cd ..
echo ""
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "  1. Review the Terraform plan above"
echo "  2. Run 'make apply' to deploy"
echo "  3. After deployment, run 'make kubeconfig' to configure kubectl"
echo "  4. Run 'make get-lb-url' to get the Airflow Web UI URL"
echo ""
echo "For more commands, run: make help"
echo ""
