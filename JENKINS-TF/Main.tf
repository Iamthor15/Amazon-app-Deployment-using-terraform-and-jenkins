provider "aws" {
  region = "us-east-1"  # Replace with your desired AWS region
}

# Data source to fetch existing security group if it already exists
data "aws_security_group" "existing_jenkins_sg" {
  name   = "Jenkins-Security Group"
  vpc_id = "vpc-09dfd48db83b18130"  # Replace with your VPC ID
}

# Create a new security group only if it doesn't already exist
resource "aws_security_group" "Jenkins-sg" {
  count = length(data.aws_security_group.existing_jenkins_sg) == 0 ? 1 : 0  # Create only if not exists

  name        = "Jenkins-Security Group"
  description = "Open 22,443,80,8080,9000,9100,9090,3000"

  # Define ingress rules
  ingress = [
    for port in [22, 80, 443, 8080, 9000, 9100, 9090, 3000] : {
      description      = "TLS from VPC"
      from_port        = port
      to_port          = port
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]

  # Define egress rules
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Jenkins-sg"
  }
}

# Create instances referencing the security group
resource "aws_instance" "web" {
  ami                    = "ami-0c7217cdde317cfec"
  instance_type          = "t2.large"
  key_name               = "my-key"
  vpc_security_group_ids = [aws_security_group.Jenkins-sg.id]
  user_data              = templatefile("./install_jenkins.sh", {})

  tags = {
    Name = "amazon clone"
  }

  root_block_device {
    volume_size = 30
  }
}

resource "aws_instance" "web2" {
  ami                    = "ami-0c7217cdde317cfec"
  instance_type          = "t2.medium"
  key_name               = "my-key"
  vpc_security_group_ids = [aws_security_group.Jenkins-sg.id]

  tags = {
    Name = "Monitoring via grafana"
  }

  root_block_device {
    volume_size = 30
  }
}
