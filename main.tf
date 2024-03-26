resource "aws_storagegateway_gateway" "this" {
  gateway_ip_address       = var.gateway_ip_address
  gateway_name             = var.gateway_name
  gateway_timezone         = var.gateway_timezone
  gateway_type             = var.gateway_type
  gateway_vpc_endpoint     = try(var.gateway_vpc_endpoint, null)
  cloudwatch_log_group_arn = var.cloudwatch_log_group_arn
}






