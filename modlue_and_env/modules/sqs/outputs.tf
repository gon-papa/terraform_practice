# 親モジュールから子モジュールのリソース属性などを参照できるようにするたoutputを用意
output "sqs_queue_url" {
  value = aws_sqs_queue.this.url
}
