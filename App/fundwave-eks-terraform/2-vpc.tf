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


  # For ipv6 support
   # Enable IPv6 CIDR assignment from AWS
#   enable_ipv6  = true



  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

  tags = local.tags
}
