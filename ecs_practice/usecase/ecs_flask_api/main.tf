# クラスターの設定
resource "aws_ecs_cluster" "flask_api" {
  name = "${var.stage}-flask-api-tf"
}

resource "aws_ecs_cluster_capacity_providers" "flask_api" {
  capacity_providers = ["FARGATE"]

  cluster_name = aws_ecs_cluster.flask_api.name
}

# ここからタスク実行ロールの設定(ECSがFargate起動時にタスクのインフラ部分を管理するために使うロール)
# 信頼ポリシーを指定して、IAMロールのリソースを記述し、IAMロールにアクションに対する許可ポリシーとAWSマネージドポリシー、インラインポリシーを設定する
# ECRからのpull、CloudWatch Logsへの出力（マネージドポリシー）　特定のSSMパラメータ取得（インラインポリシー）を与えている

# IAMポリシーのリソースでECSタスクで定義を参照する
data "aws_ssm_parameter" "flask_api_correct_answer" {
  name = "/flask-api-tf/${var.stage}/correct_answer"
}

# 信頼関係ポリシーを取得(ECSタスク起動やECRからイメージをpull、SSMパラメータストアからの値の取得)
data "aws_iam_policy_document" "ecs_task_execution_assume_role" {
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      identifiers = [
        "ecs-tasks.amazon.com"
      ]
      type = "Service" # IAMなどの場合はAWSでOK
    }
  }
}

# ECRやCloudWatch Logsのアクションを許可するAWSマネージドポリシーを取得
data "aws_iam_policy" "managed_ecs_task_execution" {
  name = "AmazonECSTaskExecutionRolePolicy"
}

# タスク実行ロールにアタッチするインラインポリシー(SSMパラメータストアから環境変数を取得するのでその許可を記述)
data "aws_iam_policy_document" "ecs_task_execution" {
  statement {
    effect = "Allow"
    actions = [
      "ssm:GetParameters",
      "ssm:GetParameter"
    ]
    # 参照可能なパラメータストアを限定する
    resources = [
      data.aws_ssm_parameter.flask_api_correct_answer.arn
    ]
  }
}

# IAMロールを記載
resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "${var.stage}-flask-api-execution-role-tf"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_execution_assume_role.json
}

# IAMロールにAWSマネージドポリシーをアタッチ
resource "aws_iam_role_policy_attachments_exclusive" "ecs_task_excution_managed_policy" {
  policy_arns = [data.aws_iam_policy.managed_ecs_task_execution.arn]
  role_name   = aws_iam_role.ecs_task_execution_role.name
}

# IAMポリシーにインラインポリシーをアタッチ
resource "aws_iam_role_policy" "ecs_task_excution_inline_policy" {
  name   = "${var.stage}-falsk-api-ecs-task-execution-policy"
  policy = data.aws_iam_policy_document.ecs_task_execution.json
  role   = aws_iam_role.ecs_task_execution_role.name
}

# ここからECSタスクロール(タスクが動作中の実行時にアプリケーションコード自身がAWSリソースにアクセスするためのロール)
data "aws_iam_policy_document" "ecs_task_assume_role" {
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      identifiers = [
        "ecs-task.amazon.com"
      ]
      type = "Service"
    }
  }
}

# タスクロールにアタッチするインラインポリシー
data "aws_iam_policy_document" "ecs_task" {
  statement {
    effect = "Allow"
    actions = [
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessage:OpenControlChannel",
      "ssmmessage:OpenDataChannel"
    ]
    resources = ["*"]
  }
}

# タスクロール記述
resource "aws_iam_role" "ecs_task" {
  name               = "${var.stage}-flask-api-ecs-task-role-tf"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json
}

# タスクロールにインラインポリシーをアタッチ
resource "aws_iam_role_policy" "ecs_task_inline_policy" {
  name   = "${var.stage}-flask-api-ecs-task-policy"
  policy = data.aws_iam_policy_document.ecs_task.json
  role   = aws_iam_role.ecs_task.name
}

# VPC名を変数定義(このモジュール内のみから参照可能->同じ階層のtfファイルは読める)
locals {
  vpc_name = "${var.stage}-vpc-tf"
}

# データソースでVPCの情報を取得
data "aws_vpc" "this" {
  filter {
    name   = "tag:Name"
    values = [local.vpc_name] # vpc名を格納
  }
}

# データソースからサブネットの情報を取得
data "aws_subnets" "public" {
  filter {
    name = "tag:Name"
    values = [
      "${local.vpc_name}-public-ap-northeast-1a",
      "${local.vpc_name}-public-ap-northeast-1c",
      "${local.vpc_name}-public-ap-northeast-1d"
    ]
  }
}

# セキュリティグループ
# ALB用のセキュリティグループ
resource "aws_security_group" "alb" {
  name   = "${var.stage}-flask_api_alb_tf"
  vpc_id = data.aws_vpc.this.id
}

# ECS Fargateインスタンス用のセキュリティグループ
resource "aws_security_group" "ecs_instance" {
  name   = "${var.stage}-flask_api_ecs_intance_tf"
  vpc_id = data.aws_vpc.this.id
}

# ALB用のインバウンドルール
resource "aws_vpc_security_group_ingress_rule" "lb_from_http" {
  ip_protocol       = "tcp"
  security_group_id = aws_security_group.alb.id
  from_port         = 80 # portの開始(範囲指定も可能である)
  to_port           = 80 # portの終了(範囲指定も可能である)
  cidr_ipv4         = "0.0.0.0/0"
}

# ALB用のアウトバウンドルール
resource "aws_vpc_security_group_egress_rule" "lb_to_ecs_instance" {
  ip_protocol       = "tcp"
  security_group_id = aws_security_group.alb.id
  from_port         = 5000
  to_port           = 5000

  # ECS Fargateインスタンス用にセキュリティグループがアタッチされたENI(Elastic Network Interface)への通信を許可
  referenced_security_group_id = aws_security_group.ecs_instance.id
}

# ECS Fargateインスタンスようにインバウンドルール(ALBから5000番ポートをポートを許可)
resource "aws_vpc_security_group_ingress_rule" "ecs_instance_from_lb" {
  ip_protocol       = "tcp"
  security_group_id = aws_security_group.ecs_instance.id
  from_port         = 5000
  to_port           = 5000
  # ALB用のセキュリティグループがアタッチされたENI(Elastic Network Interface)への通信を許可
  referenced_security_group_id = aws_security_group.alb.id
}

# ECS Fargateインスタンスようにアウトバウンドルール
resource "aws_vpc_security_group_egress_rule" "ecs_instance_to_https" {
  ip_protocol       = "tcp"
  security_group_id = aws_security_group.ecs_instance.id
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

# ALB
resource "aws_alb" "flask_api" {
  name               = "${var.stage}-flask-api-alb-tf"
  internal           = false
  load_balancer_type = "application"

  security_groups = [
    aws_security_group.alb.id
  ]
  subnets = data.aws_subnets.public.ids
}

# ALBのターゲットグループ
resource "aws_lb_target_group" "flask_api" {
  name        = "flask-api-tf"
  port        = 5000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = data.aws_vpc.this.id
  health_check {
    path     = "/health"
    protocol = "HTTP"
    matcher  = "200"
    interval = 10
  }
}

# ALBリスナー
resource "aws_lb_listener" "flask_api" {
  load_balancer_arn = aws_lb.flask_api.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.flask_api.arn
  }
}
