# ################################################################################
# 노드 시작 템플릿
# ================================================================================
# 시작 템플릿 없이 관리형 노드 그룹을 만들면 노드에는 EKS 가 만든 클러스터 보안 그룹만
# 붙고, 네트워크 모듈의 eks_node_sg 는 아무데도 쓰이지 않는다. 그 보안 그룹을 실제로
# 붙이려고 템플릿을 둔다.
#
# image_id 는 일부러 지정하지 않는다. 지정하는 순간 EKS 가 AMI 와 부트스트랩 user_data 를
# 넣어주지 않으므로 nodeadm 설정을 직접 써야 한다.
resource "aws_launch_template" "node" {
  name_prefix = "${local.tag_header}eks-node-"
  description = "EKS managed node group template"

  # 시작 템플릿에 보안 그룹을 지정하면 EKS 는 클러스터 보안 그룹을 자동으로 추가하지 않는다.
  # 그래서 클러스터 보안 그룹을 여기에 직접 함께 넣어야 노드가 컨트롤 플레인과 통신한다.
  vpc_security_group_ids = [
    aws_eks_cluster.this.vpc_config[0].cluster_security_group_id,
    var.node_security_group_id,
  ]

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = var.node_disk_size
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  # IMDSv2 강제. hop limit 은 2 로 둔다. 1 로 내리면 호스트 네트워크를 쓰지 않는
  # 파드가 인스턴스 메타데이터에 닿지 못해 AWS SDK 를 쓰는 예제가 깨진다.
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "${local.tag_header}eks-node" }
  }

  # 템플릿을 교체할 때 노드 그룹이 참조 중인 버전을 먼저 지우지 않도록 한다.
  lifecycle {
    create_before_destroy = true
  }
}

# ################################################################################
# 관리형 노드 그룹
# ================================================================================
resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${local.tag_header}eks-ng"
  node_role_arn   = aws_iam_role.node.arn

  # 프라이빗(cluster) 서브넷에 둔다. 인터넷으로 나가는 경로는 NAT 를 탄다.
  subnet_ids = var.subnet_ids

  capacity_type  = var.node_capacity_type
  instance_types = var.node_instance_types

  scaling_config {
    desired_size = var.node_desired_size
    min_size     = var.node_min_size
    max_size     = var.node_max_size
  }

  update_config {
    max_unavailable = 1
  }

  # disk_size 와 remote_access 는 시작 템플릿과 함께 쓸 수 없다. 둘 다 템플릿에서 정한다.
  launch_template {
    id      = aws_launch_template.node.id
    version = aws_launch_template.node.latest_version
  }

  # 노드가 뜨면서 바로 클러스터 등록과 이미지 pull 을 시도하므로 권한이 먼저 있어야 한다.
  depends_on = [
    aws_iam_role_policy_attachment.node_worker,
    aws_iam_role_policy_attachment.node_cni,
    aws_iam_role_policy_attachment.node_ecr_read,
    aws_iam_role_policy_attachment.node_ssm,
  ]

  # 오토스케일러나 수동 조정으로 늘어난 노드 수를 apply 가 되돌리지 않게 한다.
  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }

  tags = { Name = "${local.tag_header}eks-ng" }
}
