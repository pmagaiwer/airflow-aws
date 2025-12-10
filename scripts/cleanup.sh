#!/bin/bash
# cleanup.sh - Clean up Airflow deployment from AWS

set -e

TERRAFORM_DIR="terraform"
CLUSTER_NAME="pmagaiwer-airflow"
AWS_REGION="us-east-1"

echo "=========================================="
echo "⚠️  WARNING: Cleanup Airflow EKS"
echo "=========================================="
echo ""
echo "This will DESTROY all AWS resources:"
echo "  - EKS Cluster"
echo "  - VPC and Subnets"
echo "  - NAT Gateway"
echo "  - IAM Roles"
echo "  - All Airflow data and configurations"
echo ""

# Ask for confirmation (twice for safety)
read -p "Type 'delete' to confirm: " confirmation
if [ "$confirmation" != "delete" ]; then
    echo "Cleanup cancelled."
    exit 0
fi

read -p "This action cannot be undone. Type 'DELETE ALL' to confirm: " final_confirmation
if [ "$final_confirmation" != "DELETE ALL" ]; then
    echo "Cleanup cancelled."
    exit 0
fi

echo ""
echo "Destroying infrastructure..."
cd "$TERRAFORM_DIR"
terraform destroy -auto-approve -var-file=terraform.tfvars
cd ..

echo ""
echo "=========================================="
echo "✅ Cleanup Complete!"
echo "=========================================="
echo ""
echo "All AWS resources have been destroyed."
echo ""
