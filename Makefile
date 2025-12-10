.PHONY: help init plan apply destroy fmt validate kubeconfig logs port-forward

TERRAFORM_DIR := terraform
CLUSTER_NAME := pmagaiwer-airflow
AWS_REGION := us-east-1
AIRFLOW_NAMESPACE := airflow

help:
	@echo "Airflow EKS Deployment - Makefile Commands"
	@echo "==========================================="
	@echo ""
	@echo "Setup & Initialization:"
	@echo "  make init                 - Initialize Terraform"
	@echo "  make fmt                  - Format Terraform files"
	@echo "  make validate             - Validate Terraform configuration"
	@echo ""
	@echo "Deployment:"
	@echo "  make plan                 - Show Terraform plan"
	@echo "  make apply                - Apply Terraform configuration (requires confirmation)"
	@echo "  make apply-auto-approve   - Apply without confirmation (caution!)"
	@echo ""
	@echo "Management:"
	@echo "  make destroy              - Destroy all resources (requires confirmation)"
	@echo "  make destroy-auto-approve - Destroy without confirmation (caution!)"
	@echo "  make kubeconfig           - Configure kubectl for the cluster"
	@echo ""
	@echo "Monitoring & Access:"
	@echo "  make logs                 - Show Airflow webserver logs"
	@echo "  make port-forward         - Port-forward Airflow Web UI to localhost:8080"
	@echo "  make status               - Show Airflow pod status"
	@echo "  make get-lb-url           - Get LoadBalancer URL for Airflow"
	@echo ""
	@echo "Utilities:"
	@echo "  make clean                - Remove Terraform state files (local only)"
	@echo "  make cost-estimate        - Show estimated monthly costs"

init:
	@echo "Initializing Terraform in $(TERRAFORM_DIR)..."
	cd $(TERRAFORM_DIR) && terraform init

fmt:
	@echo "Formatting Terraform files..."
	cd $(TERRAFORM_DIR) && terraform fmt -recursive .

validate:
	@echo "Validating Terraform configuration..."
	cd $(TERRAFORM_DIR) && terraform validate

plan:
	@echo "Creating Terraform plan..."
	cd $(TERRAFORM_DIR) && terraform plan -var-file=example.tfvars -out=tfplan

apply:
	@echo "Applying Terraform configuration..."
	cd $(TERRAFORM_DIR) && terraform apply tfplan
	@echo ""
	@echo "Deployment complete! Run 'make kubeconfig' to configure kubectl."

apply-auto-approve:
	@echo "WARNING: Applying without confirmation!"
	cd $(TERRAFORM_DIR) && terraform apply -auto-approve -var-file=example.tfvars

destroy:
	@echo "WARNING: This will destroy all AWS resources for Airflow EKS cluster!"
	@echo "Press Ctrl+C to cancel, or continue..."
	cd $(TERRAFORM_DIR) && terraform destroy -var-file=example.tfvars

destroy-auto-approve:
	@echo "WARNING: Destroying without confirmation!"
	cd $(TERRAFORM_DIR) && terraform destroy -auto-approve -var-file=example.tfvars

kubeconfig:
	@echo "Updating kubeconfig for cluster $(CLUSTER_NAME)..."
	aws eks update-kubeconfig --region $(AWS_REGION) --name $(CLUSTER_NAME) --alias $(CLUSTER_NAME)
	@echo ""
	@echo "✅ kubectl configured! Test with: kubectl get nodes"

logs:
	@echo "Fetching Airflow webserver logs..."
	kubectl logs -n $(AIRFLOW_NAMESPACE) -l app.kubernetes.io/name=airflow-webserver --tail=100 -f

port-forward:
	@echo "Port-forwarding Airflow Web UI to http://localhost:8080"
	@echo "Press Ctrl+C to stop."
	kubectl port-forward -n $(AIRFLOW_NAMESPACE) svc/airflow-webserver 8080:8080

status:
	@echo "Checking Airflow pod status..."
	kubectl get pods -n $(AIRFLOW_NAMESPACE) -o wide

get-lb-url:
	@echo "Fetching LoadBalancer URL..."
	@kubectl get svc -n $(AIRFLOW_NAMESPACE) airflow-webserver -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "LoadBalancer URL not yet available. Wait a moment and try again."

outputs:
	@echo "Terraform outputs:"
	cd $(TERRAFORM_DIR) && terraform output

clean:
	@echo "Removing local Terraform state files..."
	rm -rf $(TERRAFORM_DIR)/.terraform/
	rm -f $(TERRAFORM_DIR)/.terraform.lock.hcl
	rm -f $(TERRAFORM_DIR)/tfplan
	@echo "Local Terraform files cleaned."

cost-estimate:
	@echo "Estimated monthly costs (approximate):"
	@echo "  - EKS Control Plane: $73 USD"
	@echo "  - EKS Fargate: ~$5-15 USD (depending on pod resource utilization)"
	@echo "  - NAT Gateway: ~$32 USD"
	@echo "  - Data Transfer: ~$1-5 USD"
	@echo ""
	@echo "  TOTAL: ~$110-125 USD/month"
	@echo ""
	@echo "To reduce costs:"
	@echo "  1. Use 'make destroy' when not in use"
	@echo "  2. Set single_nat_gateway = true (already enabled)"
	@echo "  3. Use smaller pod resources in helm-values/airflow-values.yaml"
	@echo "  4. Reduce webserver/scheduler replicas"

.PHONY: help init fmt validate plan apply apply-auto-approve destroy destroy-auto-approve kubeconfig logs port-forward status get-lb-url outputs clean cost-estimate
