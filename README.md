# aws-cicd-lab

같은 정적 사이트를 **네 가지 방식으로 배포**하면서 차이를 비교한 실습 저장소입니다.
인프라는 Terraform 으로, 배포는 GitHub Actions 로 정의했습니다.

아래로 갈수록 서버를 직접 만지는 정도가 줄고, 대신 거쳐야 할 단계가 늘어납니다.

| 방식 | 워크플로 | 경로 | 특징 |
|---|---|---|---|
| **S3** | [s3.yml](.github/workflows/s3.yml) | 러너 → `s3 sync` → S3 | 서버 없음. 가장 단순 |
| **SSM** | [ssm.yml](.github/workflows/ssm.yml) | 러너 → S3 → SSM → EC2 웹루트 복사 | SSH 키 없이 원격 배포 |
| **Docker** | [docker.yml](.github/workflows/docker.yml) | 러너 → 이미지 tar → S3 → EC2 `docker load` | 레지스트리 없이 이미지 전달 |
| **Docker + ASG** | [docker-asg.yml](.github/workflows/docker-asg.yml) | 러너 → ECR → SSM → ASG 전체 | 인스턴스가 교체돼도 동작 |

별도로 [fastapi/](fastapi/) 에 **컨테이너가 죽어도 데이터가 남는** FastAPI + Postgres 구성이 있습니다.

## 구조

```
site/                      네 방식이 공유하는 정적 사이트
deploy/
  Dockerfile               nginx 이미지 (Amazon Linux 2023 기반)
  docker-asg/
    docker-compose.yaml    볼륨·네트워크 구성
    user-data.sh           ASG 인스턴스 부팅 스크립트
fastapi/                   FastAPI + Postgres (영속성 데모)
terraform/
  modules/network          VPC · 서브넷 · NAT · 보안그룹 · EC2 · IAM
  modules/database         RDS (기본 비활성화)
  projects/                실제 구성 진입점
.github/workflows/         위 표의 워크플로 5개
```

## 준비

### 저장소 시크릿

| 이름 | 용도 |
|---|---|
| `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` | 배포용 자격증명 |
| `AWS_ACCOUNT_ID` | ECR 주소를 만드는 데 사용 |
| `S3_BUCKET_NAME` | 배포 아티팩트를 주고받는 버킷 |
| `SSM_INSTANCE_ID` | SSM 배포 대상 EC2 |
| `ASG_NAME` | ASG 배포 대상 그룹 이름 |
| `TF_STATE_BUCKET` | Terraform state 버킷 |
| `TF_VAR_SSH_ALLOWED_CIDRS` | SSH 허용 대역 (JSON 배열) |
| `DOCKERHUB_USERNAME` / `DOCKERHUB_TOKEN` | 선택. 베이스 이미지 pull 횟수 제한 회피 |

### Terraform

```bash
cd terraform/projects
cp backend.hcl.example backend.hcl                # state 버킷 이름 입력
cp ssh.auto.tfvars.example ssh.auto.tfvars        # 본인 공인 IP 입력
terraform init -backend-config=backend.hcl
terraform plan
```

`backend.hcl` 과 `ssh.auto.tfvars` 는 `.gitignore` 에 있어 저장소에 올라가지 않습니다.

## 실습하면서 실제로 걸렸던 것들

문서를 읽어서가 아니라 직접 깨져 보고 알아낸 것들입니다.

**바인드 마운트는 이미지 내용을 호스트로 복사하지 않습니다.**
빈 디렉토리를 컨테이너 웹루트에 마운트하면 이미지에 있던 파일이 *가려져서* nginx 가 403 을 냅니다.
그래서 배포할 때 이미지에서 파일을 꺼내 호스트에 채우는 단계를 넣었습니다
([user-data.sh](deploy/docker-asg/user-data.sh)).

**ASG 에서 user_data 가 비어 있으면 상태 확인이 무한 교체를 부릅니다.**
user_data 는 부팅 시 한 번만 실행되고, SSM 배포는 이미 떠 있는 인스턴스에만 닿습니다.
그래서 스케일아웃으로 뜬 인스턴스는 빈 서버가 되고, ELB 상태 확인에 실패해
ASG 가 죽이고 다시 만드는 일을 반복합니다. 새 인스턴스가 스스로 컨테이너를 띄우도록 해야 합니다.

**`aws ssm wait` 를 `send-command` 직후에 부르면 실패합니다.**
invocation 이 아직 등록되기 전이라 `InvocationDoesNotExist` 가 납니다.

**DB 컨테이너가 재시작하면 커넥션 풀의 연결은 이미 끊겨 있습니다.**
`pool_pre_ping` 없이는 재시작 후 첫 요청이 실패합니다 ([fastapi/app/db.py](fastapi/app/db.py)).

**Secrets Manager 는 이름을 30일간 예약합니다.**
destroy 후 같은 이름으로 다시 만들면
`a secret with this name is already scheduled for deletion` 로 apply 가 깨집니다.

**공식 nginx 이미지가 대신 해주던 일이 꽤 많습니다.**
`amazonlinux` 베이스로 바꾸면 `CMD` 도, 로그를 stdout 으로 보내는 것도 직접 해야 합니다.
`daemon off;` 를 빼면 PID 1 이 끝나 컨테이너가 죽습니다.
