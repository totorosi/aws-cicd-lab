variable "tag_header" {
  description = "Resource Name or Tag:Name Header"
  type        = string
  default     = ""
}

variable "subnet_ids" {
  description = "클러스터와 노드가 들어갈 서브넷. cluster 서브넷(프라이빗)을 넘긴다. 서로 다른 AZ 두 곳 이상이어야 한다."
  type        = list(string)
}

variable "node_security_group_id" {
  description = "노드에 붙일 추가 보안 그룹. 네트워크 모듈의 eks_node_sg 를 넘긴다."
  type        = string
}

variable "kubernetes_version" {
  description = "클러스터 쿠버네티스 버전. null 로 두면 AWS 기본 버전이 선택된다. 특정 버전이 필요하면 \"1.33\" 처럼 지정한다."
  type        = string
  default     = null
}

variable "endpoint_public_access" {
  description = "API 서버 퍼블릭 엔드포인트 사용 여부. 끄면 VPC 안에서만 kubectl 이 된다."
  type        = bool
  default     = true
}

variable "public_access_cidrs" {
  description = "퍼블릭 엔드포인트에 접근할 수 있는 CIDR. 기본값은 전체 공개이므로 가능하면 좁혀 쓴다."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "node_instance_types" {
  description = "노드 인스턴스 타입. t3.small 이하는 파드 IP 수가 모자라 애드온만으로도 가득 찬다."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_capacity_type" {
  description = "ON_DEMAND 또는 SPOT"
  type        = string
  default     = "ON_DEMAND"
}

variable "node_disk_size" {
  description = "노드 루트 볼륨 크기(GiB)"
  type        = number
  default     = 20
}

variable "node_desired_size" {
  description = "노드 희망 개수"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "노드 최소 개수"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "노드 최대 개수"
  type        = number
  default     = 3
}

variable "admin_principal_arns" {
  description = <<-EOT
    클러스터 관리자 권한을 줄 IAM 주체 ARN 목록.

    클러스터를 만든 주체는 bootstrap_cluster_creator_admin_permissions 로 이미
    관리자가 되므로 여기에 다시 넣으면 access entry 가 중복되어 apply 가 실패한다.
    GitHub Actions 역할로 apply 하고 본인 계정으로 kubectl 을 쓸 때 채운다.
  EOT
  type        = list(string)
  default     = []
}
