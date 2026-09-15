# 네트워크 구성을 위한 변수 설정
create_nat_gateway = false
cidr_header        = "10.0"

# Name 태그 접두사로 쓰인다. 예) demo-lab-instance
owner    = "demo"
env_type = "lab"

# 미리 만들어 둔 EC2 키 페어 이름
ssh_key = "my-keypair"

# Route 53 에 등록한 도메인 (없으면 빈 문자열)
domain_name = "example.com"

subnet_type = ["public", "private", "cluster"]

# 웹 인스턴스 생성 여부. 배포 실습을 할 때만 true 로 켠다.
create_ec2_instance = true

# 도커 이미지 tar 을 주고받는 버킷.
# GitHub Actions 의 S3_BUCKET_NAME 시크릿과 같은 값을 넣는다.
deploy_artifact_bucket = "my-deploy-artifacts-bucket"

# EKS 클러스터 생성 여부. 켜는 순간 컨트롤 플레인(시간당 과금)과 노드 비용이 발생한다.
# 실습이 끝나면 false 로 내리고 apply 해서 지운다.
create_eks = false

# 비워두면 AWS 기본 버전이 선택된다. 현재 클러스터는 이 방식으로 1.36 이 잡혔다.
# 버전을 고정하려면 주석을 푼다. 단 EKS 는 버전을 내릴 수 없으므로
# 이미 떠 있는 클러스터보다 낮은 값을 넣으면 apply 가 실패한다.
# eks_kubernetes_version = "1.36"

eks_node_instance_types = ["t3.medium"]
eks_node_desired_size   = 2
