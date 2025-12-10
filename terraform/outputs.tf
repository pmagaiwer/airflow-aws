output "eks_cluster_id" {
  description = "EKS cluster ID"
  value       = aws_eks_cluster.main.id
}

output "eks_cluster_arn" {
  description = "EKS cluster ARN"
  value       = aws_eks_cluster.main.arn
}

output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = aws_eks_cluster.main.endpoint
}

output "eks_cluster_version" {
  description = "EKS cluster version"
  value       = aws_eks_cluster.main.version
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = module.vpc.vpc_cidr_block
}

output "private_subnets" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnets
}

output "airflow_namespace" {
  description = "Kubernetes namespace for Airflow"
  value       = kubernetes_namespace.airflow.metadata[0].name
}

output "airflow_release_name" {
  description = "Helm release name for Airflow"
  value       = helm_release.airflow.name
}

output "airflow_webserver_service_type" {
  description = "Airflow webserver service type"
  value       = var.expose_via_loadbalancer ? "LoadBalancer" : "ClusterIP"
}

output "airflow_webserver_loadbalancer_dns" {
  description = "Airflow webserver LoadBalancer DNS (if exposed via LB)"
  value       = var.expose_via_loadbalancer ? "Run: make get-lb-url (after deployment)" : "N/A - using ClusterIP"
}

output "kubeconfig_command" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.main.id} --alias ${var.cluster_name}"
}

output "get_airflow_password" {
  description = "Command to get Airflow admin password from secret"
  value       = "kubectl get secret -n ${kubernetes_namespace.airflow.metadata[0].name} airflow-webserver -o jsonpath='{.data.webserver-secret-key}' | base64 -d"
}

output "port_forward_command" {
  description = "Command to port-forward to Airflow Web UI (if not using LoadBalancer)"
  value       = var.expose_via_loadbalancer ? "Not needed (using LoadBalancer)" : "kubectl port-forward -n ${kubernetes_namespace.airflow.metadata[0].name} svc/airflow-webserver 8080:8080"
}

output "eks_fargate_profile_name" {
  description = "EKS Fargate profile name"
  value       = aws_eks_fargate_profile.airflow.fargate_profile_name
}
