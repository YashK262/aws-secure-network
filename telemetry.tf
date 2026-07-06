#Declare the KMS Customer Managed Key (CMK)
resource "aws_kms_key" "log_encryption_key" {
  description = "KMS key for encrypting the logs"
  deletion_window_in_days = 7
  enable_key_rotation = true
  #Key Policy
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid = "Enable Root and Admin management"
      Effect = "Allow"
      Principal = {
        AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      }
      Action = "kms:*"
      Resource = "*"
    },
      {
        Sid = "Authorize Cloudwatch Log Decryption"
        Effect = "Allow"
        Principal = {
          Service = "logs.amazonaws.com"
        }
        Action = [
          "kms:Encrypt*",
          "kms:Decrypt*",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:Describe*"
        ]
        Resource = "*"
      }
    ]
  })
}
#Assign an alias to the key
resource "aws_kms_alias" "log_key_alias" {
  name = "alias/corporate-flow-logs-key"
  target_key_id = aws_kms_key.log_encryption_key.key_id
}
#Create Cloudwatch log vault, Creates a secure vault inside AWS cloudwatch
resource "aws_cloudwatch_log_group" "vpc_flow_logs_group" {
  name = "/aws/vpc/corporate-core-flow-logs"
  retention_in_days = 7 #To purge logs after 7 days
  kms_key_id = aws_kms_key.log_encryption_key.arn

tags = {
  name = "VPC-Flow-Logs-Repository"
  Environment = "Production"
}
}
#IAM role allowing VPC engine to send logs to bucket. VPC flow engine cannot talk to Cloudwatch engine. Declared IAM role to connect them
resource "aws_iam_role" "vpc_flow_log_role" {
  name = "vpc-flow-log-delivery-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }

    ]
  })
}
#Attach least priviledge policy to the role. This role can access only 4 api capabilities
resource "aws_iam_role_policy" "vpv_flow_log_policy" {
  name = "vpc-flow-log-delivery-policy"
  role = aws_iam_role.vpc_flow_log_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribleLogGroups",
          "logs:DescribleLogStrems"
        ]
        Effect = "Allow"
        Resource = "*"
      }
    ]
  })
}
#Turn on Flow log. Hooked the flow logs to the vpc to collect logs
resource "aws_flow_log" "core_vpc_flow_logs" {
  iam_role_arn = aws_iam_role.vpc_flow_log_role.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_logs_group.arn
  traffic_type = "ALL"
  vpc_id = aws_vpc.corporate_core.id
}
