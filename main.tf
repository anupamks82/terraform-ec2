provider "aws" {
  region     = "us-east-1"
  access_key = "<Pass_your_access_key>"
  secret_key = "<Pass_your_secret_key>"
}

resource "aws_security_group" "instance_sg" {
  name        = "instance_sg"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Configure AWS Systems Manager Parameterm to save CloudWatch Agent
resource "aws_ssm_parameter" "cw_agent_config" {
  name  = "/alarm/AWS-CWAgentLinConfig"
  type  = "String"
  value = <<EOF
{
  "metrics": {
    "append_dimensions": {
      "InstanceId": "${aws_instance.my_instance.id}"
    },
    "metrics_collected": {
      "mem": {
        "measurement": [
          "mem_used_percent"
        ],
        "metrics_collection_interval": 60
      }
    }
  }
}
EOF
}

# IAM Role will allow the EC2 instance to communicate with CloudWatch and Systems Manager.
resource "aws_iam_role" "ec2_custom_cloudwatch_role" {
  name = "EC2-Custom-CloudWatch-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

data "aws_caller_identity" "current" {}

resource "aws_iam_policy" "cloudwatch_permissions" {
  name        = "CloudWatchPermissions"
  description = "Permissions for CloudWatch and Systems Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "CWACloudWatchServerPermissions"
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "ec2:DescribeVolumes",
          "ec2:DescribeTags",
          "logs:PutLogEvents",
          "logs:PutRetentionPolicy",
          "logs:DescribeLogStreams",
          "logs:DescribeLogGroups",
          "logs:CreateLogStream",
          "logs:CreateLogGroup"
        ]
        Resource = "*"
      },
      {
        Sid = "CWASSMServerPermissions"
        Effect = "Allow"
        Action = [
          "ssm:GetParameter"
        ]
        Resource = "arn:aws:ssm:us-east-1:${data.aws_caller_identity.current.account_id}:parameter/alarm/AWS-CWAgentLinConfig"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cloudwatch_role_policy_attachment" {
  role       = aws_iam_role.ec2_custom_cloudwatch_role.name
  policy_arn = aws_iam_policy.cloudwatch_permissions.arn
}

resource "aws_instance" "my_instance" {
  ami             = "ami-08b5b3a93ed654d19"
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.instance_sg.name]
  iam_instance_profile = aws_iam_instance_profile.ec2_custom_cloudwatch_role.name
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "Hello World from $(hostname -f)" > /var/www/html/index.html
              
              #Step to configure cloudwatch agent
              wget https://s3.amazonaws.com/amazoncloudwatch-agent/linux/amd64/latest/AmazonCloudWatchAgent.zip
              unzip AmazonCloudWatchAgent.zip
              chmod +x ./install.sh
              sudo ./install.sh
              sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c ssm:/alarm/AWS-CWAgentLinConfig -s
            EOF

  tags = {
    Name = "webserver"
  }
}

resource "aws_iam_instance_profile" "ec2_custom_cloudwatch_role" {
  name = "EC2CustomCloudWatchRole"

  role = aws_iam_role.ec2_custom_cloudwatch_role.name
}

# CloudWatch Alarm for CPU Utilization
resource "aws_cloudwatch_metric_alarm" "cpu_utilization_alarm" {
  alarm_name          = "HighCPUUtilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 85
  alarm_description   = "Triggers when CPU exceeds 85% for instance ${aws_instance.my_instance.id}"
  dimensions = {
    InstanceId = aws_instance.my_instance.id
  }
}

# CloudWatch Alarm for Memory Utilization
resource "aws_cloudwatch_metric_alarm" "memory_utilization_alarm" {
  alarm_name          = "HighMemoryUtilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "mem_used_percent"
  namespace           = "CWAgent"
  period              = 60
  statistic           = "Average"
  threshold           = 85
  alarm_description   = "Triggers when Memory exceeds 85% for the instance ${aws_instance.my_instance.id}"
  dimensions = {
    InstanceId = aws_instance.my_instance.id
  }
}

output "instance_public_ip" {
  value = aws_instance.my_instance.public_ip
}
