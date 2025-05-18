resource "aws_s3_bucket" "firehose_backup_bucket" {
  bucket = var.firehose_backup_bucket
}
