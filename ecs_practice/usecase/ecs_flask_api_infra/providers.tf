provider "aws" {
  region = "ap-northeast-1"
  default_tags {
    tags = {
      Terraform = "true"
      STAGE     = "usecase"
      MODULE    = "ecs_flask_api_infra"
    }
  }
}
provider "aws" {
  alias = "us_east_1"
  region = "us-east-1"
  default_tags {
    tags = {
      Terraform = "true"
      STAGE     = "usecase"
      MODULE    = "ecs_flask_api_infra"
    }
  }
}
