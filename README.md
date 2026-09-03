# k8s-infra

Infraestrutura Kubernetes (Terraform) do projeto **Oficina Mecânica** — Fase 3 do Tech Challenge FIAP.

Provisiona a rede e o cluster onde a aplicação principal (repositório [`api`](https://github.com/FIAP-15SOAT-GabrielHelton/api)) é implantada:

- VPC (`10.0.0.0/16`) com 2 subnets públicas (`us-east-1a`/`us-east-1b`), Internet Gateway e route table.
- Cluster EKS (`oficina-mecanica-cluster`) e node group (via `LabRole`, compatível com AWS Academy).
- `metrics-server` (Helm) para habilitar o HPA da aplicação.

Este repositório faz parte de um conjunto de 5 (a arquitetura completa está descrita na [RFC-001](https://github.com/FIAP-15SOAT-GabrielHelton/api/blob/main/docs/fase3/RFC-001-authentication-authorization-serverless.md) do repo `api`):

| Repositório | Responsabilidade |
| :--- | :--- |
| `k8s-infra` (este repo) | VPC + EKS + node group |
| [`db-infra`](https://github.com/FIAP-15SOAT-GabrielHelton/db-infra) | RDS PostgreSQL |
| [`api`](https://github.com/FIAP-15SOAT-GabrielHelton/api) | Aplicação Rails + ECR + deploy no cluster |
| [`auth-serverless`](https://github.com/FIAP-15SOAT-GabrielHelton/auth-serverless) | API Gateway + Lambdas de autenticação/RBAC |
| [`deploy-orchestrator`](https://github.com/FIAP-15SOAT-GabrielHelton/deploy-orchestrator) | Dispara e aguarda o deploy dos 4 repos acima, em ordem |

## Parâmetros publicados (AWS SSM Parameter Store)

Após o `terraform apply`, este repositório publica os seguintes parâmetros para os demais repositórios consumirem:

| Parâmetro | Valor | Consumido por |
| :--- | :--- | :--- |
| `/oficina-mecanica/vpc_id` | ID da VPC | `db-infra` |
| `/oficina-mecanica/subnet_ids` | IDs das subnets públicas, separados por vírgula | `db-infra` |
| `/oficina-mecanica/eks_cluster_name` | Nome do cluster EKS | `api` |

## Deploy

Workflow `CD Deploy (VPC & EKS)` (`workflow_dispatch`), recebendo as credenciais temporárias da sessão do AWS Academy (Access Key, Secret Key, Session Token — expiram em ~4h, por isso não ficam salvas como secret).

**Ordem de deploy do projeto**: `k8s-infra` → `db-infra` → `api` → `auth-serverless` (ou use o [`deploy-orchestrator`](https://github.com/FIAP-15SOAT-GabrielHelton/deploy-orchestrator) para disparar tudo de uma vez).

## Destroy

Workflow `CD Destroy (VPC & EKS)`. **Deve rodar por último** (depois de `db-infra` e `api`), pois eles dependem dos parâmetros SSM publicados aqui.
