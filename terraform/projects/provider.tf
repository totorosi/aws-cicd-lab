# ################################################################################
# Terraform Block 
# ================================================================================
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>6.0" # 6.0~<7.0
    }
  }
  # 부분(partial) backend 설정.
  # 버킷 이름은 저장소에 두지 않고 init 할 때 주입한다:
  #   terraform init -backend-config=backend.hcl
  backend "s3" {
    key          = "TerraformState/Lab/project-module/terraform.tfstate" # 버킷 내 저장 경로
    use_lockfile = true                                                  # S3 자체 락 사용 (DynamoDB 불필요)
    encrypt      = true                                                  # 상태 파일 암호화
  }

  #  required_providers {
  #    google = {
  #      source = "hashicorp/google"
  #      version = "~>6.0" # 6.0~<7.0
  #    }
  #  }
}

# ################################################################################
# Provider Block
# ================================================================================
provider "aws" {
  region = "sa-east-1"

  # 기본 태그 설정: 태라폼으로 생성한 리소스들에 추가
  default_tags {
    tags = local.common_tags
  }
}

# 별칭을 사용한 추가 리전 (서울)
provider "aws" {
  alias  = "seoul"
  region = "ap-northeast-2"

  default_tags {
    tags = local.common_tags
  }
}
