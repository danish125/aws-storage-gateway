provider "aws" {
  region = "eu-west-2"  # Change as needed
}

# S3 Bucket for Terraform State
resource "aws_s3_bucket" "tf_state_bucket" {
  bucket = var.bucket_name

  tags = {
    Name        = var.bucket_name
    Environment = "dev"
  }
}

# Enable versioning for state protection
resource "aws_s3_bucket_versioning" "tf_state_versioning" {
  bucket = aws_s3_bucket.tf_state_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

# (Optional) Block public access
resource "aws_s3_bucket_public_access_block" "tf_state_bucket_block" {
  bucket = aws_s3_bucket.tf_state_bucket.id

  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls  = true
  restrict_public_buckets = true
}

# DynamoDB Table for State Locking
resource "aws_dynamodb_table" "tf_lock_table" {
  name           = var.dynamodb_table_name
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = var.dynamodb_table_name
    Environment = "dev"
  }
}



variable "bucket_name" {
  description = "S3 bucket name for Terraform backend state"
  type        = string
  default     = "my-terraform-backend-bucket-1234"  # Change to a unique name
}

variable "dynamodb_table_name" {
  description = "DynamoDB table name for state locking"
  type        = string
  default     = "terraform-locks"
}










terraform {
  backend "s3" {
    bucket         = "your-terraform-state-bucket"     # Replace with your bucket name
    key            = "env/dev/security-group.tfstate"  # Path to the state file
    region         = "us-east-1"                        # Region of the bucket
    dynamodb_table = "terraform-locks"                  # (Optional) for state locking
    encrypt        = true
  }
}


provider "aws" {
  region = "us-east-1"  # Change as needed
}

resource "aws_security_group" "example_sg" {
  name        = var.sg_name
  description = "Security Group created via Terraform"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = var.sg_name
  }
}




variable "sg_name" {
  description = "Name of the security group"
  type        = string
  default     = "example-security-group"
}

variable "vpc_id" {
  description = "The VPC ID where the security group will be created"
  type        = string
}
