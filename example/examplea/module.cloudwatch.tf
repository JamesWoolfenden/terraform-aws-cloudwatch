module "cloudwatch" {
  source      = "../../"
  kms_key_id  = aws_kms_key.example.arn
  common_tags = var.common_tags
}
