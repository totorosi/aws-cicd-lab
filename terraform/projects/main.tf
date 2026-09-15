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
  vpc_options        = local.vpc_options
  ami_id             = local.ami_id
  region             = local.region

  deploy_artifact_bucket = var.deploy_artifact_bucket
}

# RDS 는 현재 어느 리소스도 참조하지 않아 비활성화한다.
# Aurora 클러스터 생성과 시크릿 로테이션용 CloudFormation 스택 때문에
# apply 시간이 10분 이상 늘어나고, db.m8gd.large 비용도 계속 발생한다.
# 다시 쓰려면 아래 주석을 해제하면 된다.
# module "rds" {
#   source      = "../modules/database"
#   tag_header  = local.tag_header
#   vpc_id      = local.vpc_id
#   region      = local.region
#   mysql_sg_id = local.mysql_sg_id
# }
