data "aws_storagegateway_local_disk" "this" {
  disk_node   = var.disk_node_name
  gateway_arn = aws_storagegateway_gateway.this.arn
}

resource "aws_storagegateway_cache" "this" {
  disk_id     = data.aws_storagegateway_local_disk.this.disk_id
  gateway_arn = aws_storagegateway_gateway.this.arn
}
