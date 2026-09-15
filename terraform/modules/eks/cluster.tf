# ################################################################################
# EKS 클러스터
# ================================================================================
resource "aws_eks_cluster" "this" {
  name     = local.cluster_name
  role_arn = aws_iam_role.cluster.arn

  # null 이면 이 인자를 보내지 않고 AWS 기본 버전이 선택된다.
  version = var.kubernetes_version

  # 인증 방식.
  #
  # API 는 aws-auth ConfigMap 대신 access entry 리소스로 권한을 관리한다.
  # ConfigMap 을 잘못 고쳐 클러스터 접근을 통째로 잃는 사고가 없어진다.
  #
  # bootstrap_... 은 이 클러스터를 만든 주체(지금 terraform 을 돌리는 자격증명)에게
  # 자동으로 관리자 권한을 준다. 이게 false 면 apply 직후 아무도 kubectl 을 쓸 수 없다.
  access_config {
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = true
  }

  vpc_config {
    # 컨트롤 플레인 ENI 가 놓일 서브넷. 노드와 같은 cluster 서브넷을 쓴다.
    subnet_ids = var.subnet_ids

    # 프라이빗 엔드포인트를 켜야 노드가 NAT 를 거치지 않고 API 서버에 붙는다.
    endpoint_private_access = true
    endpoint_public_access  = var.endpoint_public_access
    public_access_cidrs     = var.endpoint_public_access ? var.public_access_cidrs : null
  }

  # 감사 로그는 CloudWatch 비용이 계속 발생하므로 기본적으로 끈다.
  # 필요하면 아래를 켠다.
  # enabled_cluster_log_types = ["api", "audit", "authenticator"]

  # 역할에 정책이 붙기 전에 클러스터를 만들면 ENI 생성 단계에서 실패한다.
  depends_on = [aws_iam_role_policy_attachment.cluster_policy]

  tags = { Name = local.cluster_name }
}

# ################################################################################
# 추가 관리자
# ================================================================================
# 클러스터를 만든 주체 외에 kubectl 을 써야 하는 사람이 있을 때만 쓴다.
resource "aws_eks_access_entry" "admin" {
  for_each = toset(var.admin_principal_arns)

  cluster_name  = aws_eks_cluster.this.name
  principal_arn = each.value
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "admin" {
  for_each = aws_eks_access_entry.admin

  cluster_name  = aws_eks_cluster.this.name
  principal_arn = each.value.principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}
