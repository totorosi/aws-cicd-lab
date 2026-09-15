variable "subnet_type" {
  description = "Subnet Type"
  type        = list(string)
  default     = []
}

variable "cidr_header" {
  description = "Network CIDR"
  type        = string
  default     = ""
}

variable "owner" {
  description = "Owner Name"
  type        = string
  default     = ""
}

variable "env_type" {
  description = "Environment"
  type        = string
  default     = ""
}
# -------------------------------------------
# VPC 속성 정의
variable "vpc_options" {
  description = "VPC 상세 설정 옵션"
  type = object({
    instance_tenancy                     = optional(string, "default")
    enable_dns_support                   = optional(bool, true)
    enable_dns_hostnames                 = optional(bool, true)
    assign_generated_ipv6_cidr_block     = optional(bool, false)
    enable_network_address_usage_metrics = optional(bool, false)
  })

  default = {
    instance_tenancy                     = "default"
    enable_dns_support                   = true
    enable_dns_hostnames                 = true
    assign_generated_ipv6_cidr_block     = false
    enable_network_address_usage_metrics = false
  }
}

variable "create_nat_gateway" {
  description = "NAT Gateway의 생성 여부(true-생성 / false-미생성)"
  type        = bool
  default     = true
}

variable "ssh_key" {
  description = "SSH Key"
  type        = string
  default     = ""
}

variable "domain_name" {
  description = "Domain Name"
  type        = string
  default     = ""
}

variable "create_ec2_instance" {
  description = "웹 인스턴스를 생성할지 여부. 배포 실습을 할 때만 true 로 켠다."
  type        = bool
  default     = false
}

variable "deploy_artifact_bucket" {
  description = "배포 아티팩트(도커 이미지 tar)가 올라가는 S3 버킷 이름"
  type        = string
  default     = ""
}

variable "ssh_allowed_cidrs" {
  description = "SSH(22) 접속을 허용할 CIDR 목록"
  type        = list(string)
  default     = []
}

# -------------------------------------------
# EKS
variable "create_eks" {
  description = "EKS 클러스터를 생성할지 여부. 컨트롤 플레인과 노드 비용이 계속 발생하므로 실습할 때만 true 로 켠다."
  type        = bool
  default     = false
}

variable "eks_kubernetes_version" {
  description = "EKS 쿠버네티스 버전. 비워두면 AWS 기본 버전이 선택된다."
  type        = string
  default     = null
}

variable "eks_node_instance_types" {
  description = "EKS 노드 인스턴스 타입"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "eks_node_desired_size" {
  description = "EKS 노드 희망 개수"
  type        = number
  default     = 2
}
