module "mumbai_network" {
  source = "../modules/network"
  # providers = { aws = aws.seoul }
  azs                = local.azs
  vpc_cidr_block     = local.vpc_cidr_block
  subnet_map         = local.subnet_map
  route_map          = local.route_map
  subnet_type        = var.subnet_type
  tag_header         = local.tag_header
  create_nat_gateway = var.create_nat_gateway
  ssh_key            = var.ssh_key
  ssh_allowed_cidrs  = var.ssh_allowed_cidrs
  vpc_options        = local.vpc_options
  ami_id             = local.ami_id
  region             = local.region

  deploy_artifact_bucket = var.deploy_artifact_bucket
  create_ec2_instance    = var.create_ec2_instance
}

# ################################################################################
# EKS
# ================================================================================
# 네트워크 모듈이 만든 cluster 서브넷과 eks_node_sg 위에 올린다.
#
# 기본값은 false 다. 컨트롤 플레인만으로도 시간당 요금이 발생하고 노드 비용이 따로 붙는다.
# 실습할 때만 terraform.tfvars 에서 켜고, 끝나면 다시 false 로 내리고 apply 한다.
module "eks" {
  count  = var.create_eks ? 1 : 0
  source = "../modules/eks"

  tag_header             = local.tag_header
  subnet_ids             = local.cluster_subnet_ids
  node_security_group_id = local.eks_node_sg_id

  kubernetes_version  = var.eks_kubernetes_version
  node_instance_types = var.eks_node_instance_types
  node_desired_size   = var.eks_node_desired_size
}

# RDS 는 현재 어느 리소스도 참조하지 않아 비활성화한다.
# Aurora 클러스터 생성과 시크릿 로테이션용 CloudFormation 스택 때문에
# apply 시간이 10분 이상 늘어나고, db.m8gd.large 비용도 계속 발생한다.
#
# fastapi/ 가 들어왔지만 이 모듈은 아직 그쪽에 쓸 수 없다. 앱은 Postgres 를
# 쓰는데(psycopg) 이 모듈은 MySQL 클러스터와 MYSQL 프록시를 만든다.
# 되살리려면 주석 해제만으로는 부족하고 엔진부터 바꿔야 한다.
# module "rds" {
#   source      = "../modules/database"
#   tag_header  = local.tag_header
#   vpc_id      = local.vpc_id
#   region      = local.region
#   mysql_sg_id = local.mysql_sg_id
# }
