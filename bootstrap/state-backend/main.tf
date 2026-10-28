resource "aws_s3_bucket" "shared_network_state" {
  provider = aws.shared_network
  bucket   = "${var.state_bucket_prefix}-${var.shared_network_account_id}"
}

resource "aws_s3_bucket_versioning" "shared_network_state" {
  provider = aws.shared_network
  bucket   = aws_s3_bucket.shared_network_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "shared_network_state" {
  provider = aws.shared_network
  bucket   = aws_s3_bucket.shared_network_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "shared_network_state" {
  provider = aws.shared_network
  bucket   = aws_s3_bucket.shared_network_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "shared_network_locks" {
  provider     = aws.shared_network
  name         = var.lock_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

resource "aws_s3_bucket" "workload_dev_state" {
  provider = aws.workload_dev
  bucket   = "${var.state_bucket_prefix}-${var.workload_dev_account_id}"
}

resource "aws_s3_bucket_versioning" "workload_dev_state" {
  provider = aws.workload_dev
  bucket   = aws_s3_bucket.workload_dev_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "workload_dev_state" {
  provider = aws.workload_dev
  bucket   = aws_s3_bucket.workload_dev_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "workload_dev_state" {
  provider = aws.workload_dev
  bucket   = aws_s3_bucket.workload_dev_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "workload_dev_locks" {
  provider     = aws.workload_dev
  name         = var.lock_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
