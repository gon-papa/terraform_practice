# リポジトリ
resource "aws_ecr_repository" "flask_api" {
  name = "${var.stage}-flask-api-tf"
}

# ssmパラメータ(手動でssmにパラメータを設定している場合はapplyで更新されないように差分を無視して変更しないように設定)
resource "aws_ssm_parameter" "flask_api_correct_answer" {
  name = "/flask-api-tf/${var.stage}/correct_answer"
  type = "SecureString"
  # ダミーの値
  value = "dummy"

  # 保存されていた値が変更されても無視して実環境に反映しない
  lifecycle {
    ignore_changes = [value]
  }
}
