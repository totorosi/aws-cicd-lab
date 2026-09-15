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

# 도커 이미지 tar 을 주고받는 버킷.
# GitHub Actions 의 S3_BUCKET_NAME 시크릿과 같은 값을 넣는다.
deploy_artifact_bucket = "my-deploy-artifacts-bucket"
