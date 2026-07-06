#Configure the Terraform AWS Provider Framework
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1" # Mumbai Region (or ap-south-2 if using Hyderabad)
}
# Querying the AWS API to locate the active Account ID
data "aws_caller_identity" "current" {}