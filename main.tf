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












provider "aws" {
  region = "us-east-1"
}

# 1. VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "main-vpc"
  }
}

# 2. Internet Gateway for Public Subnets
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "main-igw"
  }
}

# 3. Public Subnets (2 AZs)
resource "aws_subnet" "public" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 4, count.index)
  map_public_ip_on_launch = true
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
  tags = {
    Name = "public-subnet-${count.index + 1}"
  }
}

# 4. Private Subnets (2 AZs)
resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 4, count.index + 2)
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
  tags = {
    Name = "private-subnet-${count.index + 1}"
  }
}

# 5. Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "public-rt"
  }
}

resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# 6. Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  count = 1
  vpc   = true
}

# 7. NAT Gateway in first public subnet
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id
  tags = {
    Name = "main-nat"
  }
  depends_on = [aws_internet_gateway.igw]
}

# 8. Private Route Table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "private-rt"
  }
}

resource "aws_route" "private_nat_access" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# 9. Availability Zones (for dynamic AZ selection)
data "aws_availability_zones" "available" {
  state = "available"
}















# Security Group for VPC endpoints (allow HTTPS from your VPC CIDR)
resource "aws_security_group" "ssm_endpoints" {
  name        = "ssm-endpoint-sg"
  description = "Allow HTTPS traffic for SSM endpoints"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ssm-endpoint-sg"
  }
}

# Create Interface VPC Endpoints (in private subnets)
locals {
  ssm_endpoints = [
    "ssm",
    "ec2messages",
    "ssmmessages"
  ]
}

resource "aws_vpc_endpoint" "ssm" {
  for_each = toset(local.ssm_endpoints)

  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.region}.${each.key}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.ssm_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name = "vpc-endpoint-${each.key}"
  }
}



# Install PostgreSQL 16 client on Amazon Linux 2
sudo amazon-linux-extras enable postgresql16
sudo yum clean metadata
sudo yum install -y postgresql16





export PGHOST=<rds-proxy-endpoint>
export PGPORT=5432
export PGUSER=<your-db-username>
export PGPASSWORD=<your-password>  # Use cautiously, or use `.pgpass`
export PGDATABASE=<your-database-name>



echo "<host>:5432:<db>:<user>:<password>" >> ~/.pgpass
chmod 600 ~/.pgpass




psql -h <rds-proxy-endpoint> -U <user> -d <db>


