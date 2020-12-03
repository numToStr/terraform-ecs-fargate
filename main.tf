terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }

  backend "s3" {
    # FIXME: This bucket might not be available, so make sure to change it
    bucket  = "terraform-state"
    key     = "tf-ecs-fargate/terraform.tfstate"
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
  azs        = data.aws_availability_zones.available.names
}

module "alb" {
  source = "./modules/alb"

  alb_name          = "demo-alb"
  vpc_id            = module.vpc.id
  public_subnet_ids = module.vpc.public_subnet_ids

  depends_on = [module.vpc]
}

module "ecs" {
  source = "./modules/ecs"

  cluster_name         = "demo"
  vpc_id               = module.vpc.id
  private_subnet_ids   = module.vpc.private_subnet_ids
  alb_target_group_arn = module.alb.target_group
  alb_security_group   = module.alb.security_group

  depends_on = [module.vpc, module.alb]
}

output "DNS" {
  value       = "http://${module.alb.dns}"
  description = "DNS name of the load balancer"
  depends_on  = [module.ecs]
}
