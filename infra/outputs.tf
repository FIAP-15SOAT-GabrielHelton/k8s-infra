output "eks_cluster_name" {
  description = "The name of the EKS cluster"
  value       = aws_eks_cluster.main.name
}

output "eks_endpoint" {
  description = "The endpoint of the EKS cluster control plane"
  value       = aws_eks_cluster.main.endpoint
}

output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "subnet_ids" {
  description = "The IDs of the public subnets"
  value       = [aws_subnet.public_a.id, aws_subnet.public_b.id]
}
