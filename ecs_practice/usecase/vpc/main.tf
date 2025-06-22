# 今のAWSリージョンで使えるAZのリストを取得する
data "aws_availability_zones" "current" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.21.0"

  name = "${var.stage}-vpc-tf"
  cidr = var.vpc_cidr

  # 現在のリージョンで使えるアベイラビリティゾーンのリストから先頭3つだけを取り出す slice(["1a", "1c", "1d"], 0, 3) => ["1a", "1c", "1d"]
  azs = slice(data.aws_availability_zones.current.names, 0, 3)

  # 元になるCIDR（例: 10.0.0.0/16）を、細かく分割して、その中の何番目のサブネットを取得するか」を計算するためのTerraform組み込み関数
  # iprange: 元となるCIDRブロック（例: "10.0.0.0/16"）
  # newbits: 何ビット分ネットワークを分割するか（サブネットを何個に分けるか）
  # netnum: その中の何番目のサブネットを取るか
  public_subnets = [
    cidrsubnet(var.vpc_cidr, 4, 0),
    cidrsubnet(var.vpc_cidr, 4, 1),
    cidrsubnet(var.vpc_cidr, 4, 2)
  ]

  # 完全にネットワーク遮断
  intra_subnets = [
    cidrsubnet(var.vpc_cidr, 4, 4),
    cidrsubnet(var.vpc_cidr, 4, 5),
    cidrsubnet(var.vpc_cidr, 4, 6)
  ]

  # NAT Gateway経由で外部通信可能 enable_nat_gatewayがtrueなら設定する
  private_subnets = var.enable_nat_gateway ? [
    cidrsubnet(var.vpc_cidr, 4, 8),
    cidrsubnet(var.vpc_cidr, 4, 9),
    cidrsubnet(var.vpc_cidr, 4, 10)
  ] : []

  enable_nat_gateway = var.enable_nat_gateway
  # single_nat_gatewayをtureにするとVPCにひとつだけのNATGatewayを設置する
  single_nat_gateway = (
    var.enable_nat_gateway
    ? (var.one_nat_gateway_per_az ? false : true)
    : false
  )

  # one_nat_gateway_per_azをtrueにするとAZごとにNATGatewayを設置する
  one_nat_gateway_per_az = (
    var.enable_nat_gateway
    ? var.one_nat_gateway_per_az
    : false
  )

  manage_default_security_group  = true
  manage_default_network_acl     = false
  default_security_group_ingress = []
  default_network_acl_egress     = []
}
