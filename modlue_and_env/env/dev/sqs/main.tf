# モジュール呼び出し
# terraform planを行うとmodule.sqs_module_test.aws_sqs_queue.this will be createdと表示され
# module.[moduleの識別名].[子モジュールの中のでリソースアドレス]が表示されていることがわかる。
module "sqs_module_test" {
  source                               = "../../../modules/sqs" # 子モジュールディレクトリの指定
  stage                                = "dev"                  # 子モジュールの変数設定
  queue_name_suffix                    = "queue-test"           # 子モジュールの変数設定
  sqs_queue_visibility_timeout_seconds = 60                     # 子モジュールの変数設定
}

output "sqs_queue_url" {
  value = module.sqs_module_test.sqs_queue_url # 子モジュールのoutputから参照
}
