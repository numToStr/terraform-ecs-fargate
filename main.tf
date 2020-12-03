terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 3.0"
    }
  }

  backend "s3" {
    bucket  = "cricuru-terraform-state"
    key     = "tf-demo/terraform.tfstate"
    region  = "ap-south-1"
    profile = "tfuser"
  }
}

provider "aws" {
  region  = "ap-south-1"
  profile = "tfuser"
}

data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source = "./modules/vpc"

  cidr_block = "10.0.0.0/16"
  azs = data.aws_availability_zones.available.names
}
