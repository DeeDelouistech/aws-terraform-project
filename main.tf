terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.31.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# 1. Create a Custom VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "recruiter-project-vpc"
  }
}

# 2. Create an Internet Gateway so resources can talk to the internet
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "recruiter-project-igw"
  }
}

# 3. Create a Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "recruiter-project-subnet"
  }
}
# --- Security Group for our Public Resources ---
resource "aws_security_group" "recruiter_sg" {
  name        = "recruiter-project-sg"
  description = "Allow inbound traffic for SSH and HTTP/API access"
  vpc_id      = aws_vpc.main.id

  # Allow SSH access (adjust your IP if needed, or leave open for portfolio demo)
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTP access for web/API traffic
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic so instances can pull packages/updates
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "recruiter-project-sg"
  }
}
# Dynamically fetch the latest free-tier Ubuntu 22.04 AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-arm64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = [ "099720109477" ] # Canonical
}

resource "aws_instance" "recruiter_server" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t4g.micro" # ARM64 free-tier eligible instance type matching our ARM64 AMI
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.recruiter_sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "recruiter-project-server"
  }
}
# --- S3 Storage Bucket ---
resource "aws_s3_bucket" "recruiter_storage" {
  bucket = "recruiter-project-ai-storage-${random_id.bucket_suffix.hex}"

  tags = {
    Name = "recruiter-project-storage"
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# --- DynamoDB Table ---
resource "aws_dynamodb_table" "recruiter_table" {
  name         = "recruiter-project-metadata"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "ID"

  attribute {
    name = "ID"
    type = "S"
  }

  tags = {
    Name = "recruiter-project-table"
  }
}
# --- CloudWatch Log Group ---
resource "aws_cloudwatch_log_group" "recruiter_logs" {
  name              = "/aws/ec2/recruiter-project-server"
  retention_in_days = 7

  tags = {
    Name = "recruiter-project-logs"
  }
}

# --- CloudWatch CPU Utilization Alarm ---
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "recruiter-high-cpu"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "This metric monitors ec2 cpu utilization"

  dimensions = {
    InstanceId = aws_instance.recruiter_server.id
  }
}

# --- Outputs ---
output "instance_public_ip" {
  value       = aws_instance.recruiter_server.public_ip
  description = "Public IP address of the recruiter server"
}

output "s3_bucket_name" {
  value       = aws_s3_bucket.recruiter_storage.id
  description = "Name of the S3 storage bucket"
}
# 1. IAM Role allowing Lambda to talk to Amazon Bedrock
resource "aws_iam_role" "ai_lambda_role" {
  name = "ai_cost_optimizer_lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# 2. Grant Lambda permissions to invoke Bedrock models
resource "aws_iam_policy" "bedrock_access" {
  name = "bedrock_access_policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["bedrock:InvokeModel"]
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "attach_bedrock" {
  role       = aws_iam_role.ai_lambda_role.name
  policy_arn = aws_iam_policy.bedrock_access.arn
}

# 3. Serverless Lambda function for AI Insights
resource "aws_lambda_function" "ai_cost_optimizer" {
  filename         = "lambda_dummy.zip" # Placeholder for your function package
  function_name    = "ai_cost_optimizer_function"
  role             = aws_iam_role.ai_lambda_role.arn
  handler          = "index.handler"
  runtime          = "python3.9"
}
