# ========================
# KMS
#=========================
resource "aws_kms_key" "tsstate_storage_key" {
  description             = "This key is used to enctypr bucket objects" # 訳: このキーはバケットオブジェクトを暗号化するために使用されます
  deletion_window_in_days = 7                                            # 削除する際は7日後に削除される
  enable_key_rotation     = true                                         # キーのローテションをするか
  tags = {
    Name = "${var.project}-${var.environment}-kms"
  }
}

resource "aws_kms_alias" "tsstate_storage_key_alias" {
  name          = "alias/tsstate_storage_key_alias"
  target_key_id = aws_kms_key.tsstate_storage_key.id
}
