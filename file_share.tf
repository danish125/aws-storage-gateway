resource "aws_storagegateway_nfs_file_share" "this" {
  client_list           = var.client_list
  gateway_arn           = aws_storagegateway_gateway.this.arn
  location_arn          = var.s3_bucket_arn
  role_arn              = var.nfs_file_share_role_arn
  vpc_endpoint_dns_name = var.vpc_endpoint_dns_name
  bucket_region         = var.bucket_region
  audit_destination_arn = var.audit_destination_arn
  default_storage_class = try(var.default_storage_class, "S3_STANDARD")
  kms_encrypted         = try(var.kms_encrypted, false)
  kms_key_arn           = try(var.kms_key_arn, null)
  nfs_file_share_defaults {
    directory_mode = try(var.nfs_file_share_defaults.directory_mode, "0777")
    file_mode      = try(var.nfs_file_share_defaults.file_mode, "0666")
    group_id       = try(var.nfs_file_share_defaults.group_id, "65534")
    owner_id       = try(var.nfs_file_share_defaults.owner_id, "65534")
  }
  dynamic "cache_attributes" {
    for_each = var.cache_attributes
    content {
      cache_stale_timeout_in_seconds = cache_attributes.value.cache_stale_timeout_in_seconds
    }
  }
  read_only           = try(var.read_only, false) //defaults to false
  squash              = try(var.squash, "RootSquash")
  tags                = var.tags
  notification_policy = try(var.notification_policy, {})
  #   file_share_name = try(var.file_share_name,null)
}