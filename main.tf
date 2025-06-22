resource "aws_storagegateway_gateway" "this" {
  gateway_ip_address       = var.gateway_ip_address
  gateway_name             = var.gateway_name
  gateway_timezone         = var.gateway_timezone
  gateway_type             = var.gateway_type
  gateway_vpc_endpoint     = try(var.gateway_vpc_endpoint, null)
  cloudwatch_log_group_arn = var.cloudwatch_log_group_arn
}





provider "aws" {
  region = "us-east-1"
}
 
resource "aws_db_parameter_group" "postgres16_ssl" {
  name        = "postgres16-ssl-minproto"
  family      = "postgres16"
  description = "Custom parameter group for PostgreSQL 16 with SSL settings"
 
  parameter {
    name  = "ssl_min_protocol_version"
    value = "TLSv1.2"
  }
 
  parameter {
    name  = "ssl_ciphers"
    value = "ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256"
  }
}
 
resource "aws_db_subnet_group" "example" {
  name       = "example-subnet-group"
  subnet_ids = ["subnet-1234567890abcdef0", "subnet-abcdef0123456789a"]
 
  tags = {
    Name = "Example DB subnet group"
  }
}
 
resource "aws_db_instance" "postgres16" {
  identifier              = "postgres16-ssl"
  engine                  = "postgres"
  engine_version          = "16.2"
  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  username                = "mydbuser"
  password                = "mydbpassword"
  db_subnet_group_name    = aws_db_subnet_group.example.name
  vpc_security_group_ids  = ["sg-0123456789abcdef0"]
  parameter_group_name    = aws_db_parameter_group.postgres16_ssl.name
  skip_final_snapshot     = true
  publicly_accessible     = false
  multi_az                = false
  storage_encrypted       = true
 
  tags = {
    Name = "Postgres16 RDS"
  }
}
 
resource "aws_secretsmanager_secret" "db_credentials" {
  name = "postgres16-db-credentials"
}
 
resource "aws_secretsmanager_secret_version" "db_credentials_version" {
  secret_id     = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = aws_db_instance.postgres16.username
    password = aws_db_instance.postgres16.password
  })
}
 
resource "aws_rds_proxy" "postgres_proxy" {
  name                   = "postgres16-proxy"
  engine_family          = "POSTGRESQL"
  role_arn               = "arn:aws:iam::123456789012:role/rds-proxy-role"
  vpc_subnet_ids         = aws_db_subnet_group.example.subnet_ids
  vpc_security_group_ids = ["sg-0123456789abcdef0"]
 
  auth {
    auth_scheme = "SECRETS"
    secret_arn  = aws_secretsmanager_secret.db_credentials.arn
    iam_auth    = "DISABLED"
  }
 
  require_tls = true
 
  tags = {
    Name = "Postgres16 RDS Proxy"
  }
}
 
resource "aws_rds_proxy_default_target_group" "default" {
  db_proxy_name = aws_rds_proxy.postgres_proxy.name
 
  connection_pool_config {
    connection_borrow_timeout    = 120
    max_connections_percent      = 100
    max_idle_connections_percent = 50
    session_pinning_filters      = []
  }
}
 
resource "aws_rds_proxy_target" "db_instance_target" {
  db_proxy_name          = aws_rds_proxy.postgres_proxy.name
  target_group_name      = aws_rds_proxy_default_target_group.default.name
  db_instance_identifier = aws_db_instance.postgres16.id
}



import psycopg2
import ssl
 
ctx = ssl.SSLContext(ssl.PROTOCOL_TLSv1_1)
 
conn = psycopg2.connect(
    host="<proxy-endpoint>",
    port=5432,
    user="your_user",
    password="your_password",
    dbname="your_db",
    sslmode="require",
    ssl_context=ctx
)
openssl s_client -connect <proxy-endpoint>:5432 -tls1_1

I have created RDS Postgres Database behind RDS Proxy . I have put in the ssl_min_protocol_version to TLSv1.2. How can I try to make connection with TLSv1.1 to check if it rejects or not
