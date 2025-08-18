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
