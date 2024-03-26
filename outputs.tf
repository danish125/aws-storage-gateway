#################gateway outputs###############

output "gateway_arn" {
  value       = aws_storagegateway_gateway.this.arn
  description = "Amazon Resource Name (ARN) of the gateway."
}
output "gateway_id" {
  value       = aws_storagegateway_gateway.this.gateway_id
  description = "Identifier of the gateway."
}

output "host_environment" {
  value       = aws_storagegateway_gateway.this.host_environment
  description = "The type of hypervisor environment used by the host."
}
output "gateway_network_interface" {
  value       = aws_storagegateway_gateway.this.gateway_network_interface
  description = " An array that contains descriptions of the gateway network interfaces. See Gateway Network Interface."
}

#################file share outputs###############
output "fileshare_arn" {
  value       = aws_storagegateway_nfs_file_share.this.arn
  description = "Amazon Resource Name (ARN) of the NFS File Share."
}

output "fileshare_id" {
  value       = aws_storagegateway_nfs_file_share.this.fileshare_id
  description = "ID of the NFS File Share."
}

output "fileshare_path" {
  value       = aws_storagegateway_nfs_file_share.this.path
  description = "File share path used by the NFS client to identify the mount point."
}
