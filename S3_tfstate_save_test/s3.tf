# ========================
# S3 Bucket
#=========================
# ランダム値生成
resource "random_string" "s3_unique_key" {
  length  = 6
  upper   = false
  lower   = true
  numeric = true
  special = false
}

# 本体
resource "aws_s3_bucket" "tfstate_storage" {
  bucket = "tfstate-storage-${random_string.s3_unique_key.result}"
  tags = {
    Name = "${var.project}-${var.environment}-s3"
  }
}

# バージョニング設定
resource "aws_s3_bucket_versioning" "tfstate_storage" {
  bucket = aws_s3_bucket.tfstate_storage.id
  versioning_configuration {
    status = "Enabled"
  }
}

# 暗号化設定
resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate_storage" {
  bucket = aws_s3_bucket.tfstate_storage.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.tsstate_storage_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# アクセス設定(publicアクセスをできないようにした)
resource "aws_s3_bucket_public_access_block" "tfstate_storage" {
  bucket = aws_s3_bucket.tfstate_storage.id

  block_public_acls       = true # パブリックACLの設定を拒否する
  block_public_policy     = true # すでに存在するパブリックACLを無視する
  ignore_public_acls      = true # パブリックポリシー（Principal: "*"）の設定をブロック
  restrict_public_buckets = true # パブリックポリシーが存在しても実際のアクセスを制限
}
