 ################################################################################
# Data Sources
################################################################################

data "aws_availability_zones" "available" {
  state = "available"
}

# Exclude AZs that EKS control plane does not support in some regions
locals {
  control_plane_azs = [for az in data.aws_availability_zones.available.names : az if az != "us-east-1e"]
}

################################################################################
# VPC
################################################################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.cluster_name}-vpc"
  cidr = var.vpc_cidr

  azs             = local.control_plane_azs
  private_subnets = [for i, az in local.control_plane_azs : cidrsubnet(var.vpc_cidr, 4, i)]
  public_subnets  = [for i, az in local.control_plane_azs : cidrsubnet(var.vpc_cidr, 4, i + 10)]

  enable_nat_gateway   = var.enable_nat_gateway
  single_nat_gateway   = var.single_nat_gateway
  enable_dns_hostnames = true
  enable_dns_support   = true

  public_subnet_tags = {
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-vpc"
  })
}

################################################################################
# EKS Cluster
################################################################################

resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  version  = var.cluster_version
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids              = concat(module.vpc.private_subnets, module.vpc.public_subnets)
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = ["0.0.0.0/0"] # Restrict this in production
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_vpc_resource_controller,
  ]

  tags = merge(var.tags, {
    Name = var.cluster_name
  })
}

################################################################################
# EKS Cluster IAM Role
################################################################################

resource "aws_iam_role" "eks_cluster_role" {
  name_prefix = "${var.cluster_name}-cluster-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_iam_role_policy_attachment" "eks_vpc_resource_controller" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_cluster_role.name
}

################################################################################
# EKS Fargate Profile
################################################################################

resource "aws_eks_fargate_profile" "airflow" {
  cluster_name           = aws_eks_cluster.main.name
  fargate_profile_name   = "${var.cluster_name}-airflow"
  pod_execution_role_arn = aws_iam_role.eks_fargate_pod_execution_role.arn
  subnet_ids             = module.vpc.private_subnets

  selector {
    namespace = var.airflow_namespace
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_fargate_pod_execution_role_policy,
  ]

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-airflow"
  })
}

################################################################################
# EKS Fargate Pod Execution IAM Role
################################################################################

resource "aws_iam_role" "eks_fargate_pod_execution_role" {
  name_prefix = "${var.cluster_name}-fargate-pod-exec-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks-fargate-pods.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "eks_fargate_pod_execution_role_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.eks_fargate_pod_execution_role.name
}

################################################################################
# Kubernetes Namespace
################################################################################

resource "kubernetes_namespace" "airflow" {
  metadata {
    name = var.airflow_namespace
  }

  depends_on = [aws_eks_fargate_profile.airflow]
}

################################################################################
# Helm Release: Apache Airflow
# DISABLED TEMPORARILY - Fargate resource constraints causing timeout
# Re-enable after: kubectl apply -f helm-values/airflow-values.yaml or use helm CLI directly
################################################################################

# resource "helm_release" "airflow" {
#   name             = var.airflow_release_name
#   repository       = "https://airflow.apache.org"
#   chart            = "airflow"
#   version          = var.airflow_chart_version
#   namespace        = kubernetes_namespace.airflow.metadata[0].name
#   create_namespace = false
#
#   # Use values from YAML file
#   values = [
#     file("${path.module}/helm-values/airflow-values.yaml")
#   ]
#
#   # Override critical variables
#   set {
#     name  = "webserver.replicas"
#     value = var.airflow_webserver_replicas
#   }
#
#   set {
#     name  = "scheduler.replicas"
#     value = var.airflow_scheduler_replicas
#   }
#
#   set {
#     name  = "workers.replicas"
#     value = var.airflow_worker_replicas
#   }
#
#   set {
#     name  = "webserver.service.type"
#     value = var.expose_via_loadbalancer ? "LoadBalancer" : "ClusterIP"
#   }
#
#   set_sensitive {
#     name  = "webserverSecretKey"
#     value = "airflow-secret-key-${random_string.airflow_secret.result}"
#   }
#
#   set {
#     name  = "data.metadataSecretName"
#     value = "airflow-db"
#   }
#
#   depends_on = [
#     kubernetes_namespace.airflow,
#     aws_eks_fargate_profile.airflow,
#   ]
#
#   wait = true
# }

################################################################################
# Random Secret for Airflow
################################################################################

resource "random_string" "airflow_secret" {
  length  = 32
  special = true
}

################################################################################
# RBAC: Service Account for Airflow Workers (if needed)
################################################################################

resource "kubernetes_service_account" "airflow" {
  metadata {
    name      = "airflow-sa"
    namespace = kubernetes_namespace.airflow.metadata[0].name
  }

  depends_on = [kubernetes_namespace.airflow]
}

resource "kubernetes_cluster_role" "airflow" {
  metadata {
    name = "airflow-role"
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "pods/logs"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = [""]
    resources  = ["pods/exec"]
    verbs      = ["create"]
  }
}

resource "kubernetes_cluster_role_binding" "airflow" {
  metadata {
    name = "airflow-role-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.airflow.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.airflow.metadata[0].name
    namespace = kubernetes_namespace.airflow.metadata[0].name
  }
}
