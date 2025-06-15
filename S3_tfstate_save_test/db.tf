# ========================
# DynamoDB
#=========================
resource "aws_dynamodb_table" "tfstate-lock-db" {
  name         = "tfstate-lock"
  billing_mode = "PAY_PER_REQUEST"

  hash_key = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
}
