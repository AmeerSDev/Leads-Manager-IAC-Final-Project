# EC2
# Control Plane (Public Subnet 1)
resource "aws_instance" "CONTROL_PLANE" {
  provider = aws.North-Virginia
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.LEADS_MANAGER_KP.key_name
  vpc_security_group_ids = [aws_security_group.LEADS_EC2_SG.id]
  subnet_id              = aws_subnet.LEADS_Public_Subnet_1.id
  user_data = local.control_plane_user_data
  private_ip = "10.0.1.10"

  tags = {
    Name = "leads-manager-control-plane"
    Role = "k8s-control-plane"
  }
}

# Worker Node 1 (Public Subnet 1)
resource "aws_instance" "WORKER_1" {
  provider = aws.North-Virginia
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.LEADS_MANAGER_KP.key_name
  vpc_security_group_ids = [aws_security_group.LEADS_EC2_SG.id]
  subnet_id              = aws_subnet.LEADS_Public_Subnet_1.id
  user_data = local.worker_user_data
  private_ip = "10.0.1.11"

  tags = {
    Name = "leads-manager-worker-1"
    Role = "k8s-worker"
  }
}

# Worker Node 2 (Public Subnet 2)
resource "aws_instance" "WORKER_2" {
  provider = aws.North-Virginia
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.LEADS_MANAGER_KP.key_name
  vpc_security_group_ids = [aws_security_group.LEADS_EC2_SG.id]
  subnet_id              = aws_subnet.LEADS_Public_Subnet_2.id
  user_data = local.worker_user_data
  private_ip = "10.0.2.11"

  tags = {
    Name = "leads-manager-worker-2"
    Role = "k8s-worker"
  }
}
