module "vpc" {
  source             = "../../../usecase/vpc"
  stage              = "dev"
  vpc_cidr           = "10.0.0.0/16"
  enable_nat_gateway = false
}
