# ################################################################################
# 컨트롤 플레인 역할
# ================================================================================
# EKS 서비스가 ENI 생성, 로드밸런서 연동 같은 작업을 사용자 계정에서 대신 하기 위해 맡는 역할.
data "aws_iam_policy_document" "cluster_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cluster" {
  name               = "${local.tag_header}eks-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.cluster_assume_role.json

  tags = { Name = "${local.tag_header}eks-cluster-role" }
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# ################################################################################
# 노드 역할
# ================================================================================
# 노드는 EC2 로 뜨므로 ec2.amazonaws.com 이 맡는다.
data "aws_iam_policy_document" "node_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "node" {
  name               = "${local.tag_header}eks-node-role"
  assume_role_policy = data.aws_iam_policy_document.node_assume_role.json

  tags = { Name = "${local.tag_header}eks-node-role" }
}

# 네 개 모두 없으면 노드가 클러스터에 붙지 못한다.
#   worker_node  kubelet 이 클러스터에 등록하기 위한 권한
#   cni          파드에 VPC IP 를 붙이기 위한 ENI 조작 권한
#   ecr_read     이미지 pull. 애드온 이미지부터 여기서 받는다
#   ssm          키페어 없이 세션 매니저로 노드에 들어가기 위한 권한
resource "aws_iam_role_policy_attachment" "node_worker" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "node_cni" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "node_ecr_read" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "node_ssm" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
