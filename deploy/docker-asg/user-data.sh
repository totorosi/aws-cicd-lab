#!/bin/bash
# ASG 인스턴스 부팅 시 1회 실행.
# ECR 에서 최신 이미지를 받아 정적 사이트 컨테이너를 띄운다.
# 이게 없으면 스케일아웃으로 뜬 인스턴스가 빈 서버가 되어
# ALB 상태 확인에 실패하고 ASG 가 무한히 교체한다.

set -euxo pipefail

REGION=sa-east-1
REPOSITORY=nginx

# 계정 ID 를 코드에 박지 않고 인스턴스 자격증명으로 알아낸다.
# 같은 스크립트를 다른 계정에서 그대로 쓸 수 있다.
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGISTRY="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"
IMAGE_TAG=latest
IMAGE="${REGISTRY}/${REPOSITORY}:${IMAGE_TAG}"

# 볼륨 루트. Ubuntu AMI 라 /home/ec2-user 가 없으므로 중립 경로를 쓴다.
SITE_ROOT=/opt/site

export DEBIAN_FRONTEND=noninteractive

# ---------------------------------------------------------------- 1. 필요한 도구
# docker 는 AMI 에 이미 들어있지만 없을 수도 있으니 확인 후 설치한다.
# "a || b && c" 는 (a || b) && c 로 평가되므로 if 문으로 쓴다.
if ! command -v docker >/dev/null 2>&1; then
  apt-get update -y
  apt-get install -y docker.io
fi

# Ubuntu 24.04 apt 저장소에는 awscli 패키지가 없다("no installation candidate").
# AWS 공식 v2 설치본을 받아서 설치한다.
if ! command -v aws >/dev/null 2>&1; then
  apt-get update -y
  apt-get install -y curl unzip
  curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
  unzip -q -o /tmp/awscliv2.zip -d /tmp
  /tmp/aws/install --update
  rm -rf /tmp/aws /tmp/awscliv2.zip
fi

if ! docker compose version >/dev/null 2>&1; then
  apt-get update -y
  apt-get install -y docker-compose-v2
fi

systemctl enable --now docker

# ---------------------------------------------------------------- 1-1. 80 포트 비우기
# 이 AMI 에는 nginx 가 설치·활성화된 채로 들어있어 80 포트를 점유한다.
# 그대로 두면 컨테이너가 "address already in use" 로 뜨지 못한다.
systemctl disable --now nginx 2>/dev/null || true

# ---------------------------------------------------------------- 2. 볼륨 디렉토리
mkdir -p "${SITE_ROOT}/html" "${SITE_ROOT}/logs"

# ---------------------------------------------------------------- 3. ECR 로그인
# 인스턴스 프로파일의 AmazonEC2ContainerRegistryReadOnly 권한으로 토큰을 받는다.
# 토큰은 12시간 만료라 부팅할 때마다 새로 받는다.
aws ecr get-login-password --region "${REGION}" \
  | docker login --username AWS --password-stdin "${REGISTRY}"

docker pull "${IMAGE}"

# ---------------------------------------------------------------- 4. 볼륨 채우기
# 바인드 마운트는 이미지 내용을 호스트로 복사해주지 않는다.
# 여기서 먼저 꺼내두지 않으면 웹루트가 비어서 nginx 가 403 을 낸다.
docker run --rm -v "${SITE_ROOT}/html:/out" "${IMAGE}" \
  sh -c 'rm -rf /out/* && cp -a /usr/share/nginx/html/. /out/'

# ---------------------------------------------------------------- 5. compose 파일
cat > "${SITE_ROOT}/docker-compose.yaml" <<'COMPOSE'
services:
  my-service-web:
    image: ${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}
    container_name: static-site
    restart: always

    ports:
      - "80:80"

    volumes:
      - ${SITE_ROOT}/html:/usr/share/nginx/html:ro
      - ${SITE_ROOT}/logs:/var/log/nginx

    networks:
      site-net:
        aliases:
          - nginx

networks:
  site-net:
    name: site-net
    driver: bridge
COMPOSE

cat > "${SITE_ROOT}/.env" <<ENV
ECR_REGISTRY=${REGISTRY}
ECR_REPOSITORY=${REPOSITORY}
IMAGE_TAG=${IMAGE_TAG}
SITE_ROOT=${SITE_ROOT}
ENV

# ---------------------------------------------------------------- 6. 기동
cd "${SITE_ROOT}"
docker compose up -d

# ---------------------------------------------------------------- 7. 자체 확인
# ALB 상태 확인(GET / :80)이 통과할 상태인지 여기서 먼저 본다.
for i in $(seq 1 10); do
  code=$(curl -s -o /dev/null -w '%{http_code}' http://localhost/ || true)
  echo "self-check ${i}: HTTP ${code}"
  if [ "${code}" = "200" ]; then break; fi
  sleep 3
done

echo "=== 볼륨 디렉토리 내용 ==="
ls -lR "${SITE_ROOT}/html"
