# Publica valores de rede/cluster para os demais repositórios (db-infra, api)
# lerem via `data "aws_ssm_parameter"` sem precisar de acesso ao tfstate deste repo.
#
# overwrite = true: o AWS Academy não garante que o state remoto (S3) e os
# recursos reais fiquem sempre sincronizados entre sessões (ex: um destroy
# anterior que não rodou até o fim) — sem overwrite, um PutParameter contra um
# parametro que já existe fora do state falha com ParameterAlreadyExists.

resource "aws_ssm_parameter" "vpc_id" {
  name      = "/oficina-mecanica/vpc_id"
  type      = "String"
  value     = aws_vpc.main.id
  overwrite = true
}

resource "aws_ssm_parameter" "subnet_ids" {
  name      = "/oficina-mecanica/subnet_ids"
  type      = "String"
  value     = join(",", [aws_subnet.public_a.id, aws_subnet.public_b.id])
  overwrite = true
}

resource "aws_ssm_parameter" "eks_cluster_name" {
  name      = "/oficina-mecanica/eks_cluster_name"
  type      = "String"
  value     = aws_eks_cluster.main.name
  overwrite = true
}
