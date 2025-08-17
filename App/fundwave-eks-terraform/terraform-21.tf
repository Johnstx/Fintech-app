provider "aws" {
  region = local.region
}

data "aws_availability_zones" "available" {
  state = "available" # Exclude local zones
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

data "aws_caller_identity" "current" {}



locals {
  name   = "inyiri-eks"
  region = "us-west-1"

  vpc_cidr = "10.0.0.0/16"
  # azs      = slice(data.aws_availability_zones.available.names, 0, 2)
  azs = [data.aws_availability_zones.available.names[0], data.aws_availability_zones.available.names[1]]

  tags = {
    Example    = local.name
    GithubRepo = "terraform-aws-eks"
    GithubOrg  = "terraform-aws-modules"
  }
}

################################################################################
# VPC
################################################################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.0"

  name = "${local.name}-vpc"
  cidr = local.vpc_cidr

  # azs             = local.azs
  azs = [data.aws_availability_zones.available.names[0], data.aws_availability_zones.available.names[1]]
  private_subnets = [cidrsubnet(local.vpc_cidr, 8, 110), cidrsubnet(local.vpc_cidr, 8, 120)]
  public_subnets  = [cidrsubnet(local.vpc_cidr, 8, 10), cidrsubnet(local.vpc_cidr, 8, 20)]
  intra_subnets   = [cidrsubnet(local.vpc_cidr, 8, 30), cidrsubnet(local.vpc_cidr, 8, 40)]

  # private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k)]
  # public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 48)]
  # intra_subnets   = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 52)]
  create_igw = true
  enable_dns_hostnames = true


  enable_nat_gateway = true
  single_nat_gateway = true
  one_nat_gateway_per_az = false

  create_private_nat_gateway_route = true


  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

  tags = local.tags
}


################################################################################
# EKS Cluster with Bottlerocket Nodes 
################################################################################


module "eks_bottlerocket" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = "${local.name}-bottlerocket"
  kubernetes_version = "1.33"
  authentication_mode = "API"

    # Optional: Adds the current caller identity as an administrator via cluster access entry
  enable_cluster_creator_admin_permissions = true
  # Enable public endpoint access   
  endpoint_private_access = true
  endpoint_public_access  = true

  control_plane_subnet_ids = concat(module.vpc.public_subnets, module.vpc.private_subnets)

  create_security_group =true
  security_group_description = "inyiri-eks-bottlerocket-sg"


  
  compute_config = {
    enabled    = true
    node_pools = ["general-purpose"]
  }
  create_iam_role = true

  
  
  # EKS Addons
  addons = {
    coredns = {}
    eks-pod-identity-agent = {
      before_compute = true
    }
    kube-proxy = {}
    vpc-cni = {
      before_compute = true
    }
  }

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  access_entries = {
    # One access entry with a policy associated
    example = {
      principal_arn = "arn:aws:iam::673572871288:user/Inyiri"

      policy_associations = {
        example = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
          access_scope = {
            namespaces = ["default"]
            type       = "namespace"
          }
        }
      }
    }
  }
  
  
  
  
  create_node_security_group = true
  node_security_group_enable_recommended_rules = true
  node_security_group_description = "inyiri-eks-bottlerocket-node-sg"  

  node_security_group_use_name_prefix = true
  eks_managed_node_groups = {
    example = {
      # Optional: Specify the AMI type to use for the node group
      name          = "demo-eks-managed-node"
      ami_type       = "BOTTLEROCKET_x86_64"
      instance_types = ["m6i.large"]
      capacity_type = "SPOT"
    

      min_size = 1
      max_size = 2
      # This value is ignored after the initial creation
      # https://github.com/bryantbiggs/eks-desired-size-hack
      desired_size = 1
      
      # This is not required - demonstrates how to pass additional configuration
      # Ref https://bottlerocket.dev/en/os/1.19.x/api/settings/
      bootstrap_extra_args = <<-EOT
        # The admin host container provides SSH access and runs with "superpowers".
        # It is disabled by default, but can be disabled explicitly.
        [settings.host-containers.admin]
        enabled = false

        # The control host container provides out-of-band access via SSM.
        # It is enabled by default, and can be disabled if you do not expect to use SSM.
        # This could leave you with no way to access the API and change settings on an existing node!
        [settings.host-containers.control]
        enabled = true

        # extra args added
        [settings.kernel]
        lockdown = "integrity"
      EOT
    }

  }
  

  tags = local.tags
  
}

resource "aws_iam_role" "eks_admin" {
  name = "EKSAdmin"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

