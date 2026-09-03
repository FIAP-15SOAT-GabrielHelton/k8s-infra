resource "aws_eks_cluster" "main" {
  name     = "oficina-mecanica-cluster"
  role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/LabRole"

  vpc_config {
    subnet_ids = [
      aws_subnet.public_a.id,
      aws_subnet.public_b.id
    ]
    endpoint_public_access = true
  }
}
