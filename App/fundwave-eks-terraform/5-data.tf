data "aws_availability_zones" "available" {
  state = "available" # Exclude local zones
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

data "aws_caller_identity" "current" {}




output "account_id" {
  value = data.aws_caller_identity.current.account_id
}


output "caller_arn" {
  value = data.aws_caller_identity.current.arn
}

output "cluster_iam_role_arn" {
  value =  module.eks_demo.cluster_iam_role_arn

}
output "node_iam_role_arn" {
  value = module.eks_demo.node_iam_role_arn
}
