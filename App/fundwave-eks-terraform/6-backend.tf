terraform {
  backend "s3" {
    bucket         = "inyiri-eks-bucket"
    key            = "eks/fundwave.tfstate"
    region         = "us-west-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
