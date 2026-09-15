# ################################################################################
# 애드온
# ================================================================================
# addon_version 을 지정하지 않으면 클러스터 버전에 맞는 기본 버전이 선택된다.
# resolve_conflicts_on_* 는 EKS 가 관리하는 설정을 테라폼 쪽 값으로 덮어쓰게 한다.

# 파드에 VPC IP 를 붙인다. 노드보다 먼저 있어야 노드가 Ready 로 올라온다.
resource "aws_eks_addon" "vpc_cni" {
  cluster_name = aws_eks_cluster.this.name
  addon_name   = "vpc-cni"

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = { Name = "${local.tag_header}vpc-cni" }
}

# 서비스 트래픽을 전달한다. 노드에서 DaemonSet 으로 돈다.
resource "aws_eks_addon" "kube_proxy" {
  cluster_name = aws_eks_cluster.this.name
  addon_name   = "kube-proxy"

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = { Name = "${local.tag_header}kube-proxy" }
}

# 클러스터 DNS. Deployment 라서 스케줄될 노드가 없으면 Degraded 로 남는다.
# 그래서 이 애드온만 노드 그룹 뒤에 만든다.
resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.this.name
  addon_name   = "coredns"

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [aws_eks_node_group.this]

  tags = { Name = "${local.tag_header}coredns" }
}
