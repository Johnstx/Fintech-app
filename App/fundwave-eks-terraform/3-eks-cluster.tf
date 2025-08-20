
################################################################################
# EKS Cluster with Bottlerocket Nodes 
################################################################################


module "eks_demo" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = "${local.name}-demo"
  kubernetes_version = "1.33"
  authentication_mode = "API"
  ip_family = "ipv4"
  create_cni_ipv6_iam_policy = true
  

    # EKS Addons
  addons = {
    coredns = {}
    kube-proxy = {}
    vpc-cni = {
      before_compute = true
      most_recent    = true
    }
   
  }

    # Optional: Adds the current caller identity as an administrator via cluster access entry
  enable_cluster_creator_admin_permissions = true

  # Enable public endpoint access   
  endpoint_private_access = true
  endpoint_public_access  = true


  # Optional: Specify the VPC ID to use for the EKS cluster
  vpc_id     = module.vpc.vpc_id
  # control_plane_subnet_ids = concat(module.vpc.public_subnets, module.vpc.private_subnets)
  control_plane_subnet_ids = module.vpc.intra_subnets
  subnet_ids = module.vpc.private_subnets

  compute_config = {
    enabled    = true
    node_pools = ["general-purpose"]
  }

  #  IAM role
  # Option A: Let the module create IAM role
  create_iam_role = true
  iam_role_name = "${local.name}-eks-role"
  iam_role_description = "IAM role for ${local.name} EKS cluster"
  # iam_role_arn = module.eks_demo.iam_role_arn
  iam_role_arn = module.eks_demo.cluster_iam_role_arn


  # Option B: Use existing role (Especially useful for cross-account clusters, where roles are managed by a different account)
  # create_iam_role = false
  # iam_role_arn    = "arn:aws:iam::123000011102:role/ExistingEKSRole"
  
  
  # create_node_security_group = false
  # node_security_group_id = "sg-1234567890abcdef0"
  # node_security_group_name = "my-node-sg"
  # node_security_group_description = "Security group for EKS nodes"

  # Optional: Specify the security group to use for the EKS cluster
  create_security_group = true
  security_group_use_name_prefix = true
  security_group_name = "${local.name}-sg"
  security_group_description = "Security group for ${local.name} cluster"


  # Enable/disable deletion protection for the cluster
  # deletion_protection = true




#  # Creating access entries for a new user, besides the cluster creator
#   access_entries = {
#   rocket = {
#     principal_arn = module.eks_demo.cluster_iam_role_arn

#     policy_associations = {
#       example = {
#         policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
#         access_scope = {
#           namespaces = ["default"]
#           type       = "namespace"
#         }
#       }
#     }
#   }
# }


  access_entries = {
  rocket = {
    principal_arn = "arn:aws:iam::673572871288:user/Inyiri"

    policy_associations = {
      example = {
        policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
        access_scope = {
           type = "cluster"
        }
      }
    }
  }
}

  
  # IAM role for service accounts
  enable_irsa = true
  
  create_node_security_group = true
  node_security_group_enable_recommended_rules = true
  node_security_group_description = "inyiri-eks-bottlerocket-node-sg"  

  node_security_group_use_name_prefix = true

  # IAM role for the node group
  create_node_iam_role = true
  node_iam_role_name = "${local.name}-node-role"
  node_iam_role_use_name_prefix = true 
  node_iam_role_description = "IAM role for ${local.name} EKS nodes"

  node_iam_role_additional_policies = {
    ssm = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }
  # EKS managed node group
  eks_managed_node_groups = {
    rocket = {
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

    AmazonLinux2 = {
      # Starting on 1.30, AL2023 is the default AMI type for EKS managed node groups
      instance_types = ["m6i.large"]
      ami_type       = "AL2023_x86_64_STANDARD"

      min_size = 1
      max_size = 3
      # This value is ignored after the initial creation
      # https://github.com/bryantbiggs/eks-desired-size-hack
      desired_size = 1

      # This is not required - demonstrates how to pass additional configuration to nodeadm
      # Ref https://awslabs.github.io/amazon-eks-ami/nodeadm/doc/api/
      cloudinit_pre_nodeadm = [
        {
          content_type = "application/node.eks.aws"
          content      = <<-EOT
            ---
            apiVersion: node.eks.aws/v1alpha1
            kind: NodeConfig
            spec:
              kubelet:
                config:
                  shutdownGracePeriod: 30s
          EOT
        }
      ]
    }

    # custom_ami = {
    # #   ami_type = "AL2_ARM_64"
    # #   # Current default AMI used by managed node groups - pseudo "custom"
    # #   ami_id = data.aws_ami.eks_default_arm.image_id

    # #   # This will ensure the bootstrap user data is used to join the node
    # #   # By default, EKS managed node groups will not append bootstrap script;
    # #   # this adds it back in using the default template provided by the module
    # #   # Note: this assumes the AMI provided is an EKS optimized AMI derivative
    # #   enable_bootstrap_user_data = true

    # #   instance_types = ["t4g.medium"]
    # # }



    # complete = {
    #   name            = "complete-eks-mng"
    #   use_name_prefix = true

    #   subnet_ids = module.vpc.private_subnets

    #   min_size     = 1
    #   max_size     = 3
    #   desired_size = 1

    #   ami_id                     = data.aws_ami.eks_default.image_id
    #   enable_bootstrap_user_data = true

    #   pre_bootstrap_user_data = <<-EOT
    #     export FOO=bar
    #   EOT

    #   post_bootstrap_user_data = <<-EOT
    #     echo "you are free little kubelet!"
    #   EOT

    #   capacity_type        = "SPOT"
    #   force_update_version = true
    #   instance_types       = ["m6i.large", "m5.large", "m5n.large", "m5zn.large"]
    #   labels = {
    #     GithubRepo = "terraform-aws-eks"
    #     GithubOrg  = "terraform-aws-modules"
    #   }

    #   taints = [
    #     {
    #       key    = "dedicated"
    #       value  = "gpuGroup"
    #       effect = "NO_SCHEDULE"
    #     }
    #   ]

    #   update_config = {
    #     max_unavailable_percentage = 33 # or set `max_unavailable`
    #   }

  

    #   ebs_optimized           = true
    #   disable_api_termination = false
    #   enable_monitoring       = true

    #   block_device_mappings = {
    #     xvda = {
    #       device_name = "/dev/xvda"
    #       ebs = {
    #         volume_size           = 75
    #         volume_type           = "gp3"
    #         iops                  = 3000
    #         throughput            = 150
    #         encrypted             = true
    #         kms_key_id            = module.ebs_kms_key.key_arn
    #         delete_on_termination = true
    #       }
    #     }
    #   }

    #   metadata_options = {
    #     http_endpoint               = "enabled"
    #     http_tokens                 = "required"
    #     http_put_response_hop_limit = 2
    #     instance_metadata_tags      = "disabled"
    #   }

      
    # schedules = {
    # scale-up = {
    #     min_size     = 2
    #     max_size     = "-1" # Retains current max size
    #     desired_size = 2
    #     start_time   = "2023-05-10T00:00:00Z" # Updated start time to May 10, 2023. Ensure to adjust to a time in the future
    #     end_time     = "2024-03-05T00:00:00Z"
    #     timezone     = "Etc/GMT+0"
    #     recurrence   = "0 0 * * *"
    # },
    # scale-down = {
    #     min_size     = 0
    #     max_size     = "-1" # Retains current max size
    #     desired_size = 0
    #     start_time   = "2023-05-11T12:00:00Z" # Updated start time to May 11, 2023. Ensure to adjust to a time in the future
    #     end_time     = "2024-03-05T12:00:00Z"
    #     timezone     = "Etc/GMT+0"
    #     recurrence   = "0 12 * * *"
    # }
    # }

    #   tags = {
    #     ExtraTag = "EKS managed node group complete example"
    #   }
    # }
  }
  

  tags = local.tags
  
}


  




# resource "aws_iam_role" "eks_node_role" {
#   name = "${local.name}-node-role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Principal = {
#           Service = "ec2.amazonaws.com"
#         }
#         Action = "sts:AssumeRole"
#       }
#     ]
#   })
# }