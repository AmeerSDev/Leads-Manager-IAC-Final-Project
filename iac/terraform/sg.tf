# SG's
# SG for EC2 instances
resource "aws_security_group" "LEADS_EC2_SG" {
  provider = aws.North-Virginia
  name        = "leads-manager-ec2-sg"
  description = "SG for EC2 instances"
  vpc_id      = aws_vpc.LEADS_VPC.id

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description     = "HTTP from Load Balancer"
    from_port       = 32000
    to_port        = 32000
    protocol        = "tcp"
    security_groups = [aws_security_group.LEADS_ALB_SG.id]
  }

  # Allow all intra-cluster traffic (kubelet, Calico, kube-proxy, nodeports)
  ingress {
    description = "Cluster internal"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.LEADS_VPC.cidr_block]
  }

  ingress {
    description = "Kubernetes API Server (from VPC)"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.LEADS_VPC.cidr_block]
  }

    ingress {
    description = "Kubernetes API Server (from Internet)"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "NFS"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.LEADS_VPC.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "leads-manager-ec2-sg"
  }
}

# SG for Load Balancer
resource "aws_security_group" "LEADS_ALB_SG" {
  provider = aws.North-Virginia
  name        = "leads-manager-alb-sg"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.LEADS_VPC.id

  ingress {
    description = "HTTP"
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

  tags = {
    Name = "leads-manager-alb-sg"
  }
}
