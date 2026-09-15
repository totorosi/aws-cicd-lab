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
