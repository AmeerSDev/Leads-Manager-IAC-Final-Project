# Outputs

output "CONTROL-PLANE-PUBLIC-IP" {
  description = "Control Plane Public IP"
  value       = aws_instance.CONTROL_PLANE.public_ip
}

output "WORKER-1-PUBLIC-IP" {
  description = "Worker 1 Public IP"
  value       = aws_instance.WORKER_1.public_ip
}

output "WORKER-2-PUBLIC-IP" {
  description = "Worker 2 Public IP"
  value       = aws_instance.WORKER_2.public_ip
}

output "ALB-DNS-NAME" {
  description = "ALB DNS Name"
  value       = aws_lb.LEADS_ALB.dns_name
}

output "CONTROL-PLANE-PRIVATE-IP" {
  description = "Control Plane Private IP"
  value       = aws_instance.CONTROL_PLANE.private_ip
}

output "WORKER-1-PRIVATE-IP" {
  description = "Worker 1 Private IP"
  value       = aws_instance.WORKER_1.private_ip
}

output "WORKER-2-PRIVATE-IP" {
  description = "Worker 2 Private IP"
  value       = aws_instance.WORKER_2.private_ip
}

output "SSH-TO-CONTROL-PLANE" {
  description = "SSH Command to K8s Control Plane"
  value       = "ssh -i KP.pem ubuntu@${aws_instance.CONTROL_PLANE.public_ip}"
}
