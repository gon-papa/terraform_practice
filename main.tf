# Terraformバージョン設定
terraform {
  required_version = ">=1.12.1"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# プロバイダー
provider "aws" {
  profile = "admin"
  region  = "ap-northeast-1"
}

# 変数定義
variable "project" {
  type = string
}

variable "environment" {
  type = string
}