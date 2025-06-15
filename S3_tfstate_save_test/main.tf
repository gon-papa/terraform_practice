terraform {
  required_version = "1.12.1"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.99.1"
    }
  }

  backend "s3" {
    bucket         = "tfstate-storage-icpnvm"
    key            = "state/terraform.tfsstate"
    region         = "ap-northeast-1"
    encrypt        = true
    kms_key_id     = "alias/tsstate_storage_key_alias"
    dynamodb_table = "tfstate-lock"
  }
}

provider "aws" {
  region  = "ap-northeast-1"
  profile = "admin"
  default_tags {
    tags = {
      Env     = var.environment
      Project = var.project
    }
  }
}
