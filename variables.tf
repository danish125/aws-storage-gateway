variable "gateway_ip_address" {
  type        = string
  description = "the ip address of gateway server"
}

variable "gateway_name" {
  type        = string
  description = "the name of gateway in AWS console"
}

variable "gateway_timezone" {
  type        = string
  description = "the timezone of the server running gateway"
}

variable "gateway_type" {
  type           = string
  description    = "type of gateway"
  # allowed_values = ["STORED", "CACHED", "FILE_FSX_SMB", "FILE_S3", "STORED", "VTL"]
}


variable "gateway_vpc_endpoint" {
  type        = string
  description = "the vpc endpoint id of storage gateway service"
}

variable "cloudwatch_log_group_arn" {
  type        = string
  description = "the arn of gateway cloudwatch group"
}

#######################Disk##############

variable "disk_node_name" {
  type        = string
  description = "the name of the disk to be used for cache with file gateway server"
}


#####################File Share##############
variable "client_list" {
  type        = list(any)
  description = "The list of clients that are allowed to access the file gateway"
}

variable "s3_bucket_arn" {
  type        = string
  description = "The ARN of the backed storage used for storing file data"
}

variable "nfs_file_share_role_arn" {
  type        = string
  description = "The ARN of the AWS Identity and Access Management (IAM) role that a file gateway assumes when it accesses the underlying storage"
}

variable "vpc_endpoint_dns_name" {
  type        = string
  description = "The DNS name of the VPC endpoint for S3 PrivateLink."
}

variable "bucket_region" {
  type        = string
  description = " The region of the S3 bucket used by the file share"
}

variable "audit_destination_arn" {
  type        = string
  description = "The Amazon Resource Name (ARN) of the storage used for audit logs."
}

variable "default_storage_class" {
  type        = string
  description = "The default storage class for objects put into an Amazon S3 bucket by the file gateway. Defaults to S3_STANDARD"
}

variable "kms_encrypted" {
  type        = bool
  description = "Boolean value if true to use Amazon S3 server side encryption with your own AWS KMS key, or false to use a key managed by Amazon S3. Defaults to false"
}

variable "kms_key_arn" {
  type        = string
  description = "Amazon Resource Name (ARN) for KMS key used for Amazon S3 server side encryption. This value can only be set when kms_encrypted is true."
}

variable "nfs_file_share_defaults" {
  type        = map(any)
  description = "Files and folders stored as Amazon S3 objects in S3 buckets don't, by default, have Unix file permissions assigned to them. Upon discovery in an S3 bucket by Storage Gateway, the S3 objects that represent files and folders are assigned these default Unix permissions."
  default     = {}
}

variable "cache_attributes" {
  type        = list(any)
  description = " Refresh cache information. see Cache Attributes for more details."
  default     = []
}

variable "read_only" {
  type        = bool
  description = "Boolean to indicate write status of file share. File share does not accept writes if true. Defaults to false"
}

variable "squash" {
  type        = string
  description = "Maps a user to anonymous user. Defaults to RootSquash"
}

variable "tags" {
  type        = map(any)
  description = "key-value map of resource tags"
  default     = {}
}

variable "notification_policy" {
  type        = map(any)
  description = "The notification policy of the file share. For more information see the AWS Documentation. Default value is {}"
  default     = {}
} 