#!/bin/bash
# deploy.sh - Automated deployment script

set -e

TERRAFORM_DIR="terraform"
CLUSTER_NAME="pmagaiwer-airflow"
AWS_REGION="us-east-1"

echo "=========================================="
echo "Deploying Airflow to AWS EKS"
echo "=========================================="
echo ""

# Check if plan exists
if [ ! -f "$TERRAFORM_DIR/tfplan" ]; then
    echo "❌ No Terraform plan found. Run 'make plan' first."
    exit 1
fi

# Ask for confirmation
read -p "Do you want to proceed with deployment? (yes/no): " confirmation
if [ "$confirmation" != "yes" ]; then
    echo "Deployment cancelled."
    exit 0
fi

echo ""
echo "Deploying..."
cd "$TERRAFORM_DIR"
terraform apply tfplan
cd ..

echo ""
echo "=========================================="
echo "✅ Deployment Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "  1. Configure kubectl: make kubeconfig"
echo "  2. Wait for pods to start (takes ~5-10 minutes)"
echo "     kubectl get pods -n airflow -w"
echo "  3. Get Airflow URL: make get-lb-url"
echo ""
echo "For logs: make logs"
echo "For port-forward: make port-forward"
echo ""
